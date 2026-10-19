package com.civicpulse.module.issue.controller;

import com.civicpulse.module.issue.service.FileStorageService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;

@RestController
@RequestMapping("/api/v1/attachments")
@Tag(name = "Attachments", description = "Secure attachment delivery endpoints")
public class AttachmentController {

    private final FileStorageService fileStorageService;

    public AttachmentController(FileStorageService fileStorageService) {
        this.fileStorageService = fileStorageService;
    }

    @GetMapping("/{storageKey:.+}")
    @Operation(summary = "Download or stream attachment file", description = "Serves media files stored on the server")
    public ResponseEntity<Resource> serveAttachment(@PathVariable String storageKey) {
        Resource resource = fileStorageService.loadFileAsResource(storageKey);

        String contentType = "application/octet-stream";
        try {
            Path path = resource.getFile().toPath();
            String probed = Files.probeContentType(path);
            if (probed != null) {
                contentType = probed;
            }
        } catch (IOException ignored) {
        }

        return ResponseEntity.ok()
                .contentType(MediaType.parseMediaType(contentType))
                .header(HttpHeaders.CONTENT_DISPOSITION, "inline; filename=\"" + resource.getFilename() + "\"")
                .body(resource);
    }
}
