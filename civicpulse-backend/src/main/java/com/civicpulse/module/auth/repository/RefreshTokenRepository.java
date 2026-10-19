package com.civicpulse.module.auth.repository;

import com.civicpulse.module.auth.entity.RefreshToken;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface RefreshTokenRepository extends JpaRepository<RefreshToken, UUID> {

    Optional<RefreshToken> findByTokenHashAndIsRevokedFalse(String tokenHash);

    List<RefreshToken> findAllByUserIdAndIsRevokedFalse(UUID userId);

    void deleteAllByUserId(UUID userId);
}
