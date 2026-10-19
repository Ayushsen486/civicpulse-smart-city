package com.civicpulse.module.issue.service;

import com.civicpulse.common.exception.BadRequestException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.io.InputStream;
import java.net.MalformedURLException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.Arrays;
import java.util.Set;
import java.util.UUID;

@Service
public class LocalStorageService implements FileStorageService {

    private static final Logger log = LoggerFactory.getLogger(LocalStorageService.class);

    private static final long MAX_FILE_SIZE = 10 * 1024 * 1024; // 10 MB per AGENTS.md Rule 3

    private static final Set<String> ALLOWED_MIME_TYPES = Set.of(
            "image/jpeg",
            "image/png",
            "image/webp",
            "image/gif",
            "video/mp4",
            "application/pdf"
    );

    private final Path rootLocation;

    public LocalStorageService(@Value("${app.storage.upload-dir:./uploads}") String uploadDir) {
        this.rootLocation = Paths.get(uploadDir).toAbsolutePath().normalize();
        try {
            Files.createDirectories(this.rootLocation);
        } catch (IOException e) {
            log.error("Could not initialize upload storage location", e);
            throw new RuntimeException("Could not initialize storage directory", e);
        }
    }

    @Override
    public String storeFile(MultipartFile file, String subDirectory) {
        if (file.isEmpty()) {
            throw new BadRequestException("Uploaded file cannot be empty");
        }

        if (file.getSize() > MAX_FILE_SIZE) {
            throw new BadRequestException("File size exceeds maximum allowed limit of 10MB");
        }

        String contentType = file.getContentType();
        if (contentType == null || !ALLOWED_MIME_TYPES.contains(contentType.toLowerCase())) {
            throw new BadRequestException("File MIME type not allowed: " + contentType);
        }

        validateFileSignature(file, contentType);

        String originalFilename = StringUtils.cleanPath(file.getOriginalFilename() != null ? file.getOriginalFilename() : "file");
        String extension = getFileExtension(originalFilename);

        String safeFileName = UUID.randomUUID() + (extension.isEmpty() ? "" : "." + extension);
        String relativeStorageKey = (subDirectory != null && !subDirectory.isBlank())
                ? subDirectory + "/" + safeFileName
                : safeFileName;

        Path targetLocation = this.rootLocation.resolve(relativeStorageKey).normalize();

        try {
            Files.createDirectories(targetLocation.getParent());
            try (InputStream inputStream = file.getInputStream()) {
                Files.copy(inputStream, targetLocation, StandardCopyOption.REPLACE_EXISTING);
            }
            return relativeStorageKey;
        } catch (IOException e) {
            log.error("Failed to store file {}", originalFilename, e);
            throw new RuntimeException("Failed to store file: " + originalFilename, e);
        }
    }

    @Override
    public Resource loadFileAsResource(String storageKey) {
        try {
            Path filePath = this.rootLocation.resolve(storageKey).normalize();
            if (!filePath.startsWith(this.rootLocation)) {
                throw new BadRequestException("Invalid file path traversal attempt");
            }
            Resource resource = new UrlResource(filePath.toUri());
            if (resource.exists() && resource.isReadable()) {
                return resource;
            } else {
                throw new BadRequestException("File not found or not readable: " + storageKey);
            }
        } catch (MalformedURLException e) {
            throw new BadRequestException("Invalid file URL: " + storageKey);
        }
    }

    @Override
    public void deleteFile(String storageKey) {
        try {
            Path filePath = this.rootLocation.resolve(storageKey).normalize();
            if (filePath.startsWith(this.rootLocation)) {
                Files.deleteIfExists(filePath);
            }
        } catch (IOException e) {
            log.warn("Failed to delete file from storage: {}", storageKey, e);
        }
    }

    private void validateFileSignature(MultipartFile file, String mimeType) {
        try (InputStream is = file.getInputStream()) {
            byte[] header = new byte[12];
            int read = is.read(header);
            if (read < 4) {
                throw new BadRequestException("File corrupted or unreadable");
            }

            switch (mimeType.toLowerCase()) {
                case "image/jpeg" -> {
                    // JPEG: FF D8 FF
                    if ((header[0] & 0xFF) != 0xFF || (header[1] & 0xFF) != 0xD8 || (header[2] & 0xFF) != 0xFF) {
                        throw new BadRequestException("File content does not match JPEG signature");
                    }
                }
                case "image/png" -> {
                    // PNG: 89 50 4E 47
                    if ((header[0] & 0xFF) != 0x89 || header[1] != 0x50 || header[2] != 0x4E || header[3] != 0x47) {
                        throw new BadRequestException("File content does not match PNG signature");
                    }
                }
                case "image/gif" -> {
                    // GIF: 47 49 46 38 ('GIF8')
                    if (header[0] != 'G' || header[1] != 'I' || header[2] != 'F' || header[3] != '8') {
                        throw new BadRequestException("File content does not match GIF signature");
                    }
                }
                case "application/pdf" -> {
                    // PDF: 25 50 44 46 ('%PDF')
                    if (header[0] != '%' || header[1] != 'P' || header[2] != 'D' || header[3] != 'F') {
                        throw new BadRequestException("File content does not match PDF signature");
                    }
                }
                case "image/webp" -> {
                    // RIFF....WEBP
                    if (header[0] != 'R' || header[1] != 'I' || header[2] != 'F' || header[3] != 'F') {
                        throw new BadRequestException("File content does not match WebP RIFF signature");
                    }
                }
                case "video/mp4" -> {
                    // MP4 has 'ftyp' at offset 4
                    if (read >= 8) {
                        boolean isFtyp = header[4] == 'f' && header[5] == 't' && header[6] == 'y' && header[7] == 'p';
                        if (!isFtyp) {
                            throw new BadRequestException("File content does not match MP4 ftyp container");
                        }
                    }
                }
            }
        } catch (IOException e) {
            throw new BadRequestException("Could not read file stream for signature verification");
        }
    }

    private String getFileExtension(String filename) {
        int dotIndex = filename.lastIndexOf('.');
        if (dotIndex > 0 && dotIndex < filename.length() - 1) {
            return filename.substring(dotIndex + 1).toLowerCase();
        }
        return "";
    }
}
