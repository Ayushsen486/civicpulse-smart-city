package com.civicpulse.module.auth.service;

import com.civicpulse.common.exception.ConflictException;
import com.civicpulse.common.exception.ForbiddenException;
import com.civicpulse.common.exception.UnauthorizedException;
import com.civicpulse.module.auth.dto.AuthResponse;
import com.civicpulse.module.auth.dto.GoogleLoginRequest;
import com.civicpulse.module.auth.dto.GoogleUserPayload;
import com.civicpulse.module.auth.dto.LoginRequest;
import com.civicpulse.module.auth.dto.RefreshTokenRequest;
import com.civicpulse.module.auth.dto.RegisterRequest;
import com.civicpulse.module.auth.entity.RefreshToken;
import com.civicpulse.module.auth.repository.RefreshTokenRepository;
import com.civicpulse.module.user.dto.UserResponse;
import com.civicpulse.module.user.entity.User;
import com.civicpulse.module.user.entity.UserRole;
import com.civicpulse.module.user.repository.UserRepository;
import com.civicpulse.security.JwtTokenProvider;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.UUID;

@Service
public class AuthService {

    private final UserRepository userRepository;
    private final RefreshTokenRepository refreshTokenRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider jwtTokenProvider;
    private final GoogleTokenVerifierService googleTokenVerifierService;

    public AuthService(
            UserRepository userRepository,
            RefreshTokenRepository refreshTokenRepository,
            PasswordEncoder passwordEncoder,
            JwtTokenProvider jwtTokenProvider,
            GoogleTokenVerifierService googleTokenVerifierService
    ) {
        this.userRepository = userRepository;
        this.refreshTokenRepository = refreshTokenRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtTokenProvider = jwtTokenProvider;
        this.googleTokenVerifierService = googleTokenVerifierService;
    }

    @Transactional
    public AuthResponse loginWithGoogle(GoogleLoginRequest request) {
        GoogleUserPayload payload = googleTokenVerifierService.verifyToken(request.idToken());
        String email = payload.email().trim().toLowerCase();

        User user = userRepository.findByEmailAndDeletedAtIsNull(email)
                .map(existingUser -> {
                    if (!existingUser.isActive()) {
                        throw new ForbiddenException("Account is disabled. Please contact municipal support.");
                    }
                    if (existingUser.getRole() != UserRole.CITIZEN) {
                        throw new ForbiddenException("Staff and administrative accounts must sign in using official municipal credentials.");
                    }
                    if (existingUser.getAvatarUrl() == null && payload.avatarUrl() != null) {
                        existingUser.setAvatarUrl(payload.avatarUrl());
                    }
                    existingUser.setEmailVerified(true);
                    return userRepository.save(existingUser);
                })
                .orElseGet(() -> {
                    User newUser = new User();
                    newUser.setEmail(email);
                    newUser.setFirstName(payload.firstName());
                    newUser.setLastName(payload.lastName());
                    newUser.setAvatarUrl(payload.avatarUrl());
                    newUser.setRole(UserRole.CITIZEN);
                    newUser.setActive(true);
                    newUser.setEmailVerified(true);
                    newUser.setPasswordHash(passwordEncoder.encode("G_OAUTH_" + UUID.randomUUID()));
                    return userRepository.save(newUser);
                });

        return createAuthResponse(user);
    }

    @Transactional
    public AuthResponse register(RegisterRequest request) {
        if (userRepository.existsByEmailAndDeletedAtIsNull(request.email())) {
            throw new ConflictException("Email is already registered: " + request.email());
        }

        if (request.phone() != null && !request.phone().isBlank()) {
            if (userRepository.existsByPhoneAndDeletedAtIsNull(request.phone())) {
                throw new ConflictException("Phone number is already registered: " + request.phone());
            }
        }

        User user = new User();
        user.setEmail(request.email().trim().toLowerCase());
        user.setPasswordHash(passwordEncoder.encode(request.password()));
        user.setFirstName(request.firstName().trim());
        user.setLastName(request.lastName().trim());
        user.setPhone(request.phone() != null ? request.phone().trim() : null);
        user.setRole(UserRole.CITIZEN);
        user.setActive(true);

        User savedUser = userRepository.save(user);

        return createAuthResponse(savedUser);
    }

    @Transactional
    public AuthResponse login(LoginRequest request) {
        User user = userRepository.findByEmailAndDeletedAtIsNull(request.email().trim().toLowerCase())
                .orElseThrow(() -> new UnauthorizedException("Invalid email or password"));

        if (!passwordEncoder.matches(request.password(), user.getPasswordHash())) {
            throw new UnauthorizedException("Invalid email or password");
        }

        if (!user.isActive()) {
            throw new ForbiddenException("Account is disabled. Please contact municipal support.");
        }

        return createAuthResponse(user);
    }

    @Transactional
    public AuthResponse refreshToken(RefreshTokenRequest request) {
        String tokenHash = jwtTokenProvider.hashToken(request.refreshToken());
        RefreshToken storedToken = refreshTokenRepository.findByTokenHashAndIsRevokedFalse(tokenHash)
                .orElseThrow(() -> new UnauthorizedException("Invalid or revoked refresh token"));

        if (storedToken.getExpiresAt().isBefore(Instant.now())) {
            storedToken.setRevoked(true);
            refreshTokenRepository.save(storedToken);
            throw new UnauthorizedException("Refresh token has expired");
        }

        User user = storedToken.getUser();
        if (!user.isActive() || user.getDeletedAt() != null) {
            throw new ForbiddenException("Account is inactive or has been deleted");
        }

        // Token rotation per Rule 3: Revoke old token upon use
        storedToken.setRevoked(true);
        refreshTokenRepository.save(storedToken);

        return createAuthResponse(user);
    }

    @Transactional
    public void logout(RefreshTokenRequest request) {
        String tokenHash = jwtTokenProvider.hashToken(request.refreshToken());
        refreshTokenRepository.findByTokenHashAndIsRevokedFalse(tokenHash)
                .ifPresent(token -> {
                    token.setRevoked(true);
                    refreshTokenRepository.save(token);
                });
    }

    private AuthResponse createAuthResponse(User user) {
        String accessToken = jwtTokenProvider.generateAccessToken(user.getId(), user.getEmail(), user.getRole());
        String rawRefreshToken = jwtTokenProvider.generateRefreshToken();

        Instant expiresAt = Instant.now().plusMillis(jwtTokenProvider.getRefreshTokenExpirationMs());
        RefreshToken refreshTokenEntity = new RefreshToken(
                user,
                jwtTokenProvider.hashToken(rawRefreshToken),
                expiresAt
        );
        refreshTokenRepository.save(refreshTokenEntity);

        return AuthResponse.of(
                accessToken,
                rawRefreshToken,
                jwtTokenProvider.getAccessTokenExpirationSeconds(),
                UserResponse.fromEntity(user)
        );
    }
}
