package com.civicpulse.module.issue.service;

import com.civicpulse.common.exception.BadRequestException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import org.springframework.mock.web.MockMultipartFile;

import java.nio.file.Path;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class LocalStorageServiceTest {

    @TempDir
    Path tempDir;

    private LocalStorageService storageService;

    @BeforeEach
    void setUp() {
        storageService = new LocalStorageService(tempDir.toString());
    }

    @Test
    @DisplayName("storeFile: stores valid PNG image with magic bytes")
    void storeFile_ValidPng_Success() {
        byte[] pngBytes = new byte[]{(byte) 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0, 0, 0, 0};
        MockMultipartFile file = new MockMultipartFile("file", "evidence.png", "image/png", pngBytes);

        String storageKey = storageService.storeFile(file, "issues/test");

        assertThat(storageKey).isNotNull();
        assertThat(storageKey).startsWith("issues/test/");
        assertThat(storageKey).endsWith(".png");
    }

    @Test
    @DisplayName("storeFile: rejects file with mismatched magic bytes")
    void storeFile_FakePng_ThrowsBadRequest() {
        byte[] fakeBytes = "Hello this is just text".getBytes();
        MockMultipartFile file = new MockMultipartFile("file", "fake.png", "image/png", fakeBytes);

        assertThatThrownBy(() -> storageService.storeFile(file, "issues/test"))
                .isInstanceOf(BadRequestException.class)
                .hasMessageContaining("File content does not match PNG signature");
    }

    @Test
    @DisplayName("storeFile: rejects unallowed MIME type")
    void storeFile_UnallowedMimeType_ThrowsBadRequest() {
        MockMultipartFile file = new MockMultipartFile("file", "script.sh", "application/x-sh", new byte[]{1, 2, 3, 4});

        assertThatThrownBy(() -> storageService.storeFile(file, "issues/test"))
                .isInstanceOf(BadRequestException.class)
                .hasMessageContaining("File MIME type not allowed");
    }

    @Test
    @DisplayName("loadFileAsResource: rejects path traversal attempt")
    void loadFileAsResource_PathTraversal_ThrowsBadRequest() {
        assertThatThrownBy(() -> storageService.loadFileAsResource("../../etc/passwd"))
                .isInstanceOf(BadRequestException.class);
    }
}
