package com.civicpulse.module.user.service;

import com.civicpulse.common.exception.ConflictException;
import com.civicpulse.common.exception.ResourceNotFoundException;
import com.civicpulse.module.user.dto.CreateUserRequest;
import com.civicpulse.module.user.dto.UpdateProfileRequest;
import com.civicpulse.module.user.dto.UserResponse;
import com.civicpulse.module.user.entity.User;
import com.civicpulse.module.user.entity.UserRole;
import com.civicpulse.module.user.repository.UserRepository;
import com.civicpulse.module.ward.entity.Ward;
import com.civicpulse.module.ward.repository.WardRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class UserServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private WardRepository wardRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    @InjectMocks
    private UserService userService;

    private User sampleUser;
    private UUID sampleUserId;

    @BeforeEach
    void setUp() {
        sampleUserId = UUID.randomUUID();
        sampleUser = new User();
        sampleUser.setId(sampleUserId);
        sampleUser.setEmail("officer@civicpulse.city");
        sampleUser.setFirstName("Vikram");
        sampleUser.setLastName("Singh");
        sampleUser.setRole(UserRole.OFFICER);
        sampleUser.setActive(true);
    }

    @Test
    @DisplayName("getUserProfile: returns user profile for active user")
    void getUserProfile_Success() {
        when(userRepository.findByIdAndDeletedAtIsNull(sampleUserId)).thenReturn(Optional.of(sampleUser));

        UserResponse response = userService.getUserProfile(sampleUserId);

        assertThat(response).isNotNull();
        assertThat(response.email()).isEqualTo("officer@civicpulse.city");
        assertThat(response.firstName()).isEqualTo("Vikram");
    }

    @Test
    @DisplayName("getUserProfile: throws ResourceNotFoundException if user not found")
    void getUserProfile_NotFound_ThrowsException() {
        UUID randomId = UUID.randomUUID();
        when(userRepository.findByIdAndDeletedAtIsNull(randomId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> userService.getUserProfile(randomId))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("User not found");
    }

    @Test
    @DisplayName("updateProfile: successfully updates user fields")
    void updateProfile_Success() {
        UpdateProfileRequest request = new UpdateProfileRequest("Vikramjeet", "Singh", "+919876543210", null, null);

        when(userRepository.findByIdAndDeletedAtIsNull(sampleUserId)).thenReturn(Optional.of(sampleUser));
        when(userRepository.existsByPhoneAndDeletedAtIsNull("+919876543210")).thenReturn(false);
        when(userRepository.save(any(User.class))).thenReturn(sampleUser);

        UserResponse response = userService.updateProfile(sampleUserId, request);

        assertThat(response).isNotNull();
        assertThat(sampleUser.getFirstName()).isEqualTo("Vikramjeet");
        verify(userRepository).save(sampleUser);
    }

    @Test
    @DisplayName("createUser: admin creates officer with ward")
    void createUser_Success() {
        UUID wardId = UUID.randomUUID();
        Ward ward = new Ward();
        ward.setId(wardId);
        ward.setName("North Ward");

        CreateUserRequest request = new CreateUserRequest(
                "newofficer@civicpulse.city",
                "Password123!",
                "Ananya",
                "Verma",
                null,
                UserRole.OFFICER,
                wardId
        );

        when(userRepository.existsByEmailAndDeletedAtIsNull(request.email())).thenReturn(false);
        when(passwordEncoder.encode(request.password())).thenReturn("hashed_pass");
        when(wardRepository.findById(wardId)).thenReturn(Optional.of(ward));
        when(userRepository.save(any(User.class))).thenAnswer(invocation -> {
            User u = invocation.getArgument(0);
            u.setId(UUID.randomUUID());
            return u;
        });

        UserResponse response = userService.createUser(request);

        assertThat(response).isNotNull();
        assertThat(response.email()).isEqualTo("newofficer@civicpulse.city");
        assertThat(response.role()).isEqualTo(UserRole.OFFICER);
        assertThat(response.wardId()).isEqualTo(wardId);
    }

    @Test
    @DisplayName("deleteUser: soft-deletes user by setting deletedAt timestamp")
    void deleteUser_SoftDeletesUser() {
        when(userRepository.findByIdAndDeletedAtIsNull(sampleUserId)).thenReturn(Optional.of(sampleUser));
        when(userRepository.save(any(User.class))).thenReturn(sampleUser);

        userService.deleteUser(sampleUserId);

        assertThat(sampleUser.getDeletedAt()).isNotNull();
        assertThat(sampleUser.isActive()).isFalse();
        verify(userRepository).save(sampleUser);
    }

    @Test
    @DisplayName("getOfficers: returns paginated officers")
    void getOfficers_Success() {
        PageRequest pageRequest = PageRequest.of(0, 10);
        when(userRepository.findAllByRoleAndDeletedAtIsNull(UserRole.OFFICER, pageRequest))
                .thenReturn(new PageImpl<>(List.of(sampleUser)));

        Page<UserResponse> page = userService.getOfficers(pageRequest);

        assertThat(page.getContent()).hasSize(1);
        assertThat(page.getContent().get(0).role()).isEqualTo(UserRole.OFFICER);
    }
}
