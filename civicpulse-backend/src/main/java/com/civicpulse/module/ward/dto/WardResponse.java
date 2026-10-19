package com.civicpulse.module.ward.dto;

import com.civicpulse.module.ward.entity.Ward;
import org.locationtech.jts.io.WKTWriter;

import java.time.Instant;
import java.util.UUID;

public record WardResponse(
        UUID id,
        String name,
        String code,
        String boundaryWkt,
        Instant createdAt,
        Instant updatedAt
) {
    public static WardResponse fromEntity(Ward ward) {
        if (ward == null) {
            return null;
        }
        String wkt = null;
        if (ward.getBoundary() != null) {
            WKTWriter writer = new WKTWriter();
            wkt = writer.write(ward.getBoundary());
        }
        return new WardResponse(
                ward.getId(),
                ward.getName(),
                ward.getCode(),
                wkt,
                ward.getCreatedAt(),
                ward.getUpdatedAt()
        );
    }
}
