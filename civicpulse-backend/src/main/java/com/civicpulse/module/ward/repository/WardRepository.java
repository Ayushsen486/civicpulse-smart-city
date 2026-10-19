package com.civicpulse.module.ward.repository;

import com.civicpulse.module.ward.entity.Ward;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface WardRepository extends JpaRepository<Ward, UUID> {

    Optional<Ward> findByCode(String code);

    boolean existsByCode(String code);

    boolean existsByName(String name);

    List<Ward> findAllByOrderByNameAsc();

    @Query(value = "SELECT * FROM wards WHERE ST_Contains(boundary, ST_SetSRID(ST_MakePoint(:longitude, :latitude), 4326)) LIMIT 1", nativeQuery = true)
    Optional<Ward> findWardContainingPoint(@Param("latitude") double latitude, @Param("longitude") double longitude);
}
