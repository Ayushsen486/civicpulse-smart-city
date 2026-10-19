package com.civicpulse.module.ward.service;

import com.civicpulse.common.exception.BadRequestException;
import com.civicpulse.common.exception.ConflictException;
import com.civicpulse.common.exception.ResourceNotFoundException;
import com.civicpulse.module.ward.dto.CreateWardRequest;
import com.civicpulse.module.ward.dto.UpdateWardRequest;
import com.civicpulse.module.ward.dto.WardResponse;
import com.civicpulse.module.ward.entity.Ward;
import com.civicpulse.module.ward.repository.WardRepository;
import org.locationtech.jts.geom.Geometry;
import org.locationtech.jts.geom.Polygon;
import org.locationtech.jts.io.ParseException;
import org.locationtech.jts.io.WKTReader;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
public class WardService {

    private final WardRepository wardRepository;

    public WardService(WardRepository wardRepository) {
        this.wardRepository = wardRepository;
    }

    @Transactional(readOnly = true)
    public List<WardResponse> getAllWards() {
        return wardRepository.findAllByOrderByNameAsc().stream()
                .map(WardResponse::fromEntity)
                .toList();
    }

    @Transactional(readOnly = true)
    public WardResponse getWardById(UUID id) {
        Ward ward = findWardById(id);
        return WardResponse.fromEntity(ward);
    }

    @Transactional(readOnly = true)
    public WardResponse findWardContainingPoint(double latitude, double longitude) {
        return wardRepository.findWardContainingPoint(latitude, longitude)
                .map(WardResponse::fromEntity)
                .orElse(null);
    }

    @Transactional
    public WardResponse createWard(CreateWardRequest request) {
        String cleanCode = request.code().trim().toUpperCase();
        if (wardRepository.existsByCode(cleanCode)) {
            throw new ConflictException("Ward with code '" + cleanCode + "' already exists");
        }

        Ward ward = new Ward();
        ward.setName(request.name().trim());
        ward.setCode(cleanCode);

        if (request.boundaryWkt() != null && !request.boundaryWkt().isBlank()) {
            ward.setBoundary(parsePolygonWkt(request.boundaryWkt()));
        }

        Ward saved = wardRepository.save(ward);
        return WardResponse.fromEntity(saved);
    }

    @Transactional
    public WardResponse updateWard(UUID id, UpdateWardRequest request) {
        Ward ward = findWardById(id);

        if (request.code() != null && !request.code().isBlank()) {
            String cleanCode = request.code().trim().toUpperCase();
            if (!cleanCode.equals(ward.getCode()) && wardRepository.existsByCode(cleanCode)) {
                throw new ConflictException("Ward with code '" + cleanCode + "' already exists");
            }
            ward.setCode(cleanCode);
        }

        if (request.name() != null && !request.name().isBlank()) {
            ward.setName(request.name().trim());
        }

        if (request.boundaryWkt() != null) {
            if (request.boundaryWkt().isBlank()) {
                ward.setBoundary(null);
            } else {
                ward.setBoundary(parsePolygonWkt(request.boundaryWkt()));
            }
        }

        Ward updated = wardRepository.save(ward);
        return WardResponse.fromEntity(updated);
    }

    @Transactional
    public void deleteWard(UUID id) {
        Ward ward = findWardById(id);
        wardRepository.delete(ward);
    }

    private Ward findWardById(UUID id) {
        return wardRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Ward not found with id: " + id));
    }

    private Polygon parsePolygonWkt(String wkt) {
        try {
            WKTReader reader = new WKTReader();
            Geometry geom = reader.read(wkt.trim());
            geom.setSRID(4326);
            if (!(geom instanceof Polygon polygon)) {
                throw new BadRequestException("WKT geometry must be a Polygon, got: " + geom.getGeometryType());
            }
            return polygon;
        } catch (ParseException e) {
            throw new BadRequestException("Failed to parse Polygon WKT: " + e.getMessage());
        }
    }
}
