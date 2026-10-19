package com.civicpulse.module.ward.service;

import com.civicpulse.common.exception.BadRequestException;
import com.civicpulse.common.exception.ConflictException;
import com.civicpulse.module.ward.dto.CreateWardRequest;
import com.civicpulse.module.ward.dto.WardResponse;
import com.civicpulse.module.ward.entity.Ward;
import com.civicpulse.module.ward.repository.WardRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class WardServiceTest {

    @Mock
    private WardRepository wardRepository;

    @InjectMocks
    private WardService wardService;

    @Test
    @DisplayName("createWard: successfully creates ward with valid polygon WKT")
    void createWard_WithPolygonWkt_Success() {
        String polygonWkt = "POLYGON((77.20 28.60, 77.25 28.60, 77.25 28.65, 77.20 28.65, 77.20 28.60))";
        CreateWardRequest request = new CreateWardRequest("Central Ward", "WARD-01", polygonWkt);

        when(wardRepository.existsByCode("WARD-01")).thenReturn(false);
        when(wardRepository.save(any(Ward.class))).thenAnswer(invocation -> {
            Ward w = invocation.getArgument(0);
            w.setId(UUID.randomUUID());
            return w;
        });

        WardResponse response = wardService.createWard(request);

        assertThat(response).isNotNull();
        assertThat(response.name()).isEqualTo("Central Ward");
        assertThat(response.code()).isEqualTo("WARD-01");
        assertThat(response.boundaryWkt()).contains("POLYGON");

        verify(wardRepository).save(any(Ward.class));
    }

    @Test
    @DisplayName("createWard: throws BadRequestException when WKT is invalid")
    void createWard_InvalidWkt_ThrowsBadRequest() {
        CreateWardRequest request = new CreateWardRequest("Invalid Ward", "WARD-99", "INVALID_POLYGON_WKT");

        when(wardRepository.existsByCode("WARD-99")).thenReturn(false);

        assertThatThrownBy(() -> wardService.createWard(request))
                .isInstanceOf(BadRequestException.class)
                .hasMessageContaining("Failed to parse Polygon WKT");

        verify(wardRepository, never()).save(any(Ward.class));
    }

    @Test
    @DisplayName("createWard: throws ConflictException when code already exists")
    void createWard_DuplicateCode_ThrowsConflict() {
        CreateWardRequest request = new CreateWardRequest("Duplicate Ward", "WARD-01", null);

        when(wardRepository.existsByCode("WARD-01")).thenReturn(true);

        assertThatThrownBy(() -> wardService.createWard(request))
                .isInstanceOf(ConflictException.class)
                .hasMessageContaining("already exists");

        verify(wardRepository, never()).save(any(Ward.class));
    }

    @Test
    @DisplayName("findWardContainingPoint: returns ward when coordinates fall inside")
    void findWardContainingPoint_Found_ReturnsWard() {
        Ward ward = new Ward();
        ward.setId(UUID.randomUUID());
        ward.setName("Central Ward");
        ward.setCode("WARD-01");

        when(wardRepository.findWardContainingPoint(28.61, 77.21)).thenReturn(Optional.of(ward));

        WardResponse response = wardService.findWardContainingPoint(28.61, 77.21);

        assertThat(response).isNotNull();
        assertThat(response.code()).isEqualTo("WARD-01");
    }
}
