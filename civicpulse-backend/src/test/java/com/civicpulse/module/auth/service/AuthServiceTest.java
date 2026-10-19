package com.civicpulse.module.auth.service;

import com.civicpulse.common.exception.ConflictException;
import com.civicpulse.common.exception.UnauthorizedException;
import com.civicpulse.module.auth.dto.AuthResponse;
import com.civicpulse.module.auth.dto.LoginRequest;
import com.civicpulse.module.auth.dto.RefreshTokenRequest;
import com.civicpulse.module.auth.dto.RegisterRequest;
import com.civicpulse.module.auth.entity.RefreshToken;
import com.civicpulse.module.auth.repository.RefreshTokenRepository;
import com.civicpulse.module.user.entity.User;
import com.civicpulse.module.user.entity.UserRole;
import com.civicpulse.module.user.repository.UserRepository;
import com.civicpulse.common.exception.ForbiddenException;
import com.civicpulse.module.auth.dto.GoogleLoginRequest;
import com.civicpulse.module.auth.dto.GoogleUserPayload;
import com.civicpulse.module.auth.service.GoogleTokenVerifierService;
import com.civicpulse.security.JwtTokenProvider;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AuthServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private RefreshTokenRepository refreshTokenRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    @Mock
    private JwtTokenProvider jwtTokenProvider;

    @Mock
    private GoogleTokenVerifierService googleTokenVerifierService;

    @InjectMocks
    private AuthService authService;

    private User sampleUser;

    @BeforeEach
    void setUp() {
        sampleUser = new User();
        sampleUser.setId(UUID.randomUUID());
        sampleUser.setEmail("citizen@civicpulse.city");
        sampleUser.setPasswordHash("hashed_password");
        sampleUser.setFirstName("Aarav");
        sampleUser.setLastName("Sharma");
        sampleUser.setRole(UserRole.CITIZEN);
        sampleUser.setActive(true);
    }

    @Test
    @DisplayName("register: successfully registers new citizen and returns auth response")
    void register_Success() {
        RegisterRequest request = new RegisterRequest(
                "newcitizen@civicpulse.city",
                "Password123!",
                "Priya",
                "Patel",
                "+919876543210"
        );

        when(userRepository.existsByEmailAndDeletedAtIsNull(anyString())).thenReturn(false);
        when(userRepository.existsByPhoneAndDeletedAtIsNull(anyString())).thenReturn(false);
        when(passwordEncoder.encode(anyString())).thenReturn("hashed_secret");
        when(userRepository.save(any(User.class))).thenAnswer(invocation -> {
            User u = invocation.getArgument(0);
            u.setId(UUID.randomUUID());
            return u;
        });
        when(jwtTokenProvider.generateAccessToken(any(), any(), any())).thenReturn("mock_access_jwt");
        when(jwtTokenProvider.generateRefreshToken()).thenReturn("mock_refresh_raw");
        when(jwtTokenProvider.getRefreshTokenExpirationMs()).thenReturn(604800000L);
        when(jwtTokenProvider.hashToken(anyString())).thenReturn("mock_token_hash");
        when(jwtTokenProvider.getAccessTokenExpirationSeconds()).thenReturn(900L);

        AuthResponse response = authService.register(request);

        assertThat(response).isNotNull();
        assertThat(response.accessToken()).isEqualTo("mock_access_jwt");
        assertThat(response.refreshToken()).isEqualTo("mock_refresh_raw");
        assertThat(response.user().email()).isEqualTo("newcitizen@civicpulse.city");
        assertThat(response.user().role()).isEqualTo(UserRole.CITIZEN);

        verify(userRepository).save(any(User.class));
        verify(refreshTokenRepository).save(any(RefreshToken.class));
    }

    @Test
    @DisplayName("register: throws ConflictException when email is already in use")
    void register_DuplicateEmail_ThrowsConflict() {
        RegisterRequest request = new RegisterRequest(
                "citizen@civicpulse.city",
                "Password123!",
                "Aarav",
                "Sharma",
                null
        );

        when(userRepository.existsByEmailAndDeletedAtIsNull("citizen@civicpulse.city")).thenReturn(true);

        assertThatThrownBy(() -> authService.register(request))
                .isInstanceOf(ConflictException.class)
                .hasMessageContaining("Email is already registered");

        verify(userRepository, never()).save(any(User.class));
    }

    @Test
    @DisplayName("login: successfully authenticates valid credentials")
    void login_Success() {
        LoginRequest request = new LoginRequest("citizen@civicpulse.city", "Password123!");

        when(userRepository.findByEmailAndDeletedAtIsNull("citizen@civicpulse.city")).thenReturn(Optional.of(sampleUser));
        when(passwordEncoder.matches("Password123!", "hashed_password")).thenReturn(true);
        when(jwtTokenProvider.generateAccessToken(sampleUser.getId(), sampleUser.getEmail(), sampleUser.getRole())).thenReturn("mock_access_jwt");
        when(jwtTokenProvider.generateRefreshToken()).thenReturn("mock_refresh_raw");
        when(jwtTokenProvider.getRefreshTokenExpirationMs()).thenReturn(604800000L);
        when(jwtTokenProvider.hashToken(anyString())).thenReturn("mock_token_hash");
        when(jwtTokenProvider.getAccessTokenExpirationSeconds()).thenReturn(900L);

        AuthResponse response = authService.login(request);

        assertThat(response).isNotNull();
        assertThat(response.accessToken()).isEqualTo("mock_access_jwt");
        assertThat(response.user().id()).isEqualTo(sampleUser.getId());
    }

    @Test
    @DisplayName("login: throws UnauthorizedException on incorrect password")
    void login_WrongPassword_ThrowsUnauthorized() {
        LoginRequest request = new LoginRequest("citizen@civicpulse.city", "WrongPassword");

        when(userRepository.findByEmailAndDeletedAtIsNull("citizen@civicpulse.city")).thenReturn(Optional.of(sampleUser));
        when(passwordEncoder.matches("WrongPassword", "hashed_password")).thenReturn(false);

        assertThatThrownBy(() -> authService.login(request))
                .isInstanceOf(UnauthorizedException.class)
                .hasMessageContaining("Invalid email or password");
    }

    @Test
    @DisplayName("refreshToken: rotates refresh token and returns new tokens")
    void refreshToken_RotatesToken_Success() {
        RefreshTokenRequest request = new RefreshTokenRequest("valid_refresh_raw");
        RefreshToken storedToken = new RefreshToken(sampleUser, "hashed_token", Instant.now().plusSeconds(3600));

        when(jwtTokenProvider.hashToken("valid_refresh_raw")).thenReturn("hashed_token");
        when(refreshTokenRepository.findByTokenHashAndIsRevokedFalse("hashed_token")).thenReturn(Optional.of(storedToken));
        when(jwtTokenProvider.generateAccessToken(any(), any(), any())).thenReturn("new_access_jwt");
        when(jwtTokenProvider.generateRefreshToken()).thenReturn("new_refresh_raw");
        when(jwtTokenProvider.getRefreshTokenExpirationMs()).thenReturn(604800000L);
        when(jwtTokenProvider.hashToken("new_refresh_raw")).thenReturn("new_hashed_token");
        when(jwtTokenProvider.getAccessTokenExpirationSeconds()).thenReturn(900L);

        AuthResponse response = authService.refreshToken(request);

        assertThat(response).isNotNull();
        assertThat(response.accessToken()).isEqualTo("new_access_jwt");
        assertThat(storedToken.isRevoked()).isTrue();
        verify(refreshTokenRepository, times(2)).save(any(RefreshToken.class));
    }

    @Test
    @DisplayName("loginWithGoogle: automatically registers new citizen on first sign-in")
    void loginWithGoogle_FirstTimeCitizen_Success() {
        GoogleLoginRequest request = new GoogleLoginRequest("valid_google_id_token");
        GoogleUserPayload payload = new GoogleUserPayload(
                "newgoogleuser@gmail.com",
                "Sunita",
                "Verma",
                "https://lh3.googleusercontent.com/avatar.jpg",
                true,
                "sub-12345"
        );

        when(googleTokenVerifierService.verifyToken("valid_google_id_token")).thenReturn(payload);
        when(userRepository.findByEmailAndDeletedAtIsNull("newgoogleuser@gmail.com")).thenReturn(Optional.empty());
        when(passwordEncoder.encode(anyString())).thenReturn("hashed_random_secret");
        when(userRepository.save(any(User.class))).thenAnswer(invocation -> {
            User u = invocation.getArgument(0);
            u.setId(UUID.randomUUID());
            return u;
        });
        when(jwtTokenProvider.generateAccessToken(any(), any(), any())).thenReturn("mock_access_jwt");
        when(jwtTokenProvider.generateRefreshToken()).thenReturn("mock_refresh_raw");
        when(jwtTokenProvider.getRefreshTokenExpirationMs()).thenReturn(604800000L);
        when(jwtTokenProvider.hashToken(anyString())).thenReturn("mock_token_hash");
        when(jwtTokenProvider.getAccessTokenExpirationSeconds()).thenReturn(900L);

        AuthResponse response = authService.loginWithGoogle(request);

        assertThat(response).isNotNull();
        assertThat(response.user().email()).isEqualTo("newgoogleuser@gmail.com");
        assertThat(response.user().role()).isEqualTo(UserRole.CITIZEN);
        assertThat(response.user().firstName()).isEqualTo("Sunita");
        verify(userRepository).save(argThat(u -> u.getRole() == UserRole.CITIZEN && u.isEmailVerified()));
    }

    @Test
    @DisplayName("loginWithGoogle: signs in returning citizen without re-registering")
    void loginWithGoogle_ReturningCitizen_Success() {
        GoogleLoginRequest request = new GoogleLoginRequest("valid_returning_token");
        GoogleUserPayload payload = new GoogleUserPayload(
                "citizen@civicpulse.city",
                "Aarav",
                "Sharma",
                "https://lh3.googleusercontent.com/avatar.jpg",
                true,
                "sub-12345"
        );

        when(googleTokenVerifierService.verifyToken("valid_returning_token")).thenReturn(payload);
        when(userRepository.findByEmailAndDeletedAtIsNull("citizen@civicpulse.city")).thenReturn(Optional.of(sampleUser));
        when(userRepository.save(any(User.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(jwtTokenProvider.generateAccessToken(any(), any(), any())).thenReturn("mock_access_jwt");
        when(jwtTokenProvider.generateRefreshToken()).thenReturn("mock_refresh_raw");
        when(jwtTokenProvider.getRefreshTokenExpirationMs()).thenReturn(604800000L);
        when(jwtTokenProvider.hashToken(anyString())).thenReturn("mock_token_hash");
        when(jwtTokenProvider.getAccessTokenExpirationSeconds()).thenReturn(900L);

        AuthResponse response = authService.loginWithGoogle(request);

        assertThat(response).isNotNull();
        assertThat(response.user().email()).isEqualTo("citizen@civicpulse.city");
        verify(userRepository).save(sampleUser);
    }

    @Test
    @DisplayName("loginWithGoogle: rejects non-citizen administrative roles to prevent privilege escalation")
    void loginWithGoogle_AdminRole_ThrowsForbidden() {
        GoogleLoginRequest request = new GoogleLoginRequest("valid_admin_token");
        GoogleUserPayload payload = new GoogleUserPayload(
                "admin@civicpulse.city",
                "Super",
                "Admin",
                null,
                true,
                "sub-999"
        );

        User adminUser = new User();
        adminUser.setId(UUID.randomUUID());
        adminUser.setEmail("admin@civicpulse.city");
        adminUser.setRole(UserRole.ADMIN);
        adminUser.setActive(true);

        when(googleTokenVerifierService.verifyToken("valid_admin_token")).thenReturn(payload);
        when(userRepository.findByEmailAndDeletedAtIsNull("admin@civicpulse.city")).thenReturn(Optional.of(adminUser));

        assertThatThrownBy(() -> authService.loginWithGoogle(request))
                .isInstanceOf(ForbiddenException.class)
                .hasMessageContaining("Staff and administrative accounts must sign in using official municipal credentials");
    }

    @Test
    @DisplayName("loginWithGoogle: rejects disabled citizen accounts")
    void loginWithGoogle_DisabledAccount_ThrowsForbidden() {
        GoogleLoginRequest request = new GoogleLoginRequest("valid_disabled_token");
        GoogleUserPayload payload = new GoogleUserPayload(
                "citizen@civicpulse.city",
                "Aarav",
                "Sharma",
                null,
                true,
                "sub-12345"
        );

        sampleUser.setActive(false);
        when(googleTokenVerifierService.verifyToken("valid_disabled_token")).thenReturn(payload);
        when(userRepository.findByEmailAndDeletedAtIsNull("citizen@civicpulse.city")).thenReturn(Optional.of(sampleUser));

        assertThatThrownBy(() -> authService.loginWithGoogle(request))
                .isInstanceOf(ForbiddenException.class)
                .hasMessageContaining("Account is disabled");
    }
}
