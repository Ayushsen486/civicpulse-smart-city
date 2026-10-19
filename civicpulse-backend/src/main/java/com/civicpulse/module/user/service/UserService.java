package com.civicpulse.module.user.service;

import com.civicpulse.common.exception.ConflictException;
import com.civicpulse.common.exception.ResourceNotFoundException;
import com.civicpulse.module.user.dto.CreateUserRequest;
import com.civicpulse.module.user.dto.UpdateProfileRequest;
import com.civicpulse.module.user.dto.UpdateUserRequest;
import com.civicpulse.module.user.dto.UserResponse;
import com.civicpulse.module.user.entity.User;
import com.civicpulse.module.user.entity.UserRole;
import com.civicpulse.module.user.repository.UserRepository;
import com.civicpulse.module.ward.entity.Ward;
import com.civicpulse.module.ward.repository.WardRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.UUID;

@Service
public class UserService {

    private final UserRepository userRepository;
    private final WardRepository wardRepository;
    private final PasswordEncoder passwordEncoder;

    public UserService(
            UserRepository userRepository,
            WardRepository wardRepository,
            PasswordEncoder passwordEncoder
    ) {
        this.userRepository = userRepository;
        this.wardRepository = wardRepository;
        this.passwordEncoder = passwordEncoder;
    }

    @Transactional(readOnly = true)
    public UserResponse getUserProfile(UUID userId) {
        User user = findActiveUserById(userId);
        return UserResponse.fromEntity(user);
    }

    @Transactional
    public UserResponse updateProfile(UUID userId, UpdateProfileRequest request) {
        User user = findActiveUserById(userId);

        if (request.firstName() != null && !request.firstName().isBlank()) {
            user.setFirstName(request.firstName().trim());
        }
        if (request.lastName() != null && !request.lastName().isBlank()) {
            user.setLastName(request.lastName().trim());
        }
        if (request.phone() != null && !request.phone().isBlank()) {
            String cleanPhone = request.phone().trim();
            if (!cleanPhone.equals(user.getPhone()) && userRepository.existsByPhoneAndDeletedAtIsNull(cleanPhone)) {
                throw new ConflictException("Phone number is already associated with another account");
            }
            user.setPhone(cleanPhone);
        }
        if (request.wardId() != null) {
            Ward ward = wardRepository.findById(request.wardId())
                    .orElseThrow(() -> new ResourceNotFoundException("Ward not found with id: " + request.wardId()));
            user.setWard(ward);
        }
        if (request.avatarUrl() != null) {
            user.setAvatarUrl(request.avatarUrl().trim());
        }

        User updatedUser = userRepository.save(user);
        return UserResponse.fromEntity(updatedUser);
    }

    @Transactional(readOnly = true)
    public UserResponse getUserById(UUID id) {
        User user = findActiveUserById(id);
        return UserResponse.fromEntity(user);
    }

    @Transactional(readOnly = true)
    public Page<UserResponse> getAllUsers(Pageable pageable, UserRole role) {
        Page<User> users;
        if (role != null) {
            users = userRepository.findAllByRoleAndDeletedAtIsNull(role, pageable);
        } else {
            users = userRepository.findAllByDeletedAtIsNull(pageable);
        }
        return users.map(UserResponse::fromEntity);
    }

    @Transactional(readOnly = true)
    public Page<UserResponse> getOfficers(Pageable pageable) {
        return userRepository.findAllByRoleAndDeletedAtIsNull(UserRole.OFFICER, pageable)
                .map(UserResponse::fromEntity);
    }

    @Transactional
    public UserResponse createUser(CreateUserRequest request) {
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
        user.setRole(request.role() != null ? request.role() : UserRole.CITIZEN);
        user.setActive(true);

        if (request.wardId() != null) {
            Ward ward = wardRepository.findById(request.wardId())
                    .orElseThrow(() -> new ResourceNotFoundException("Ward not found with id: " + request.wardId()));
            user.setWard(ward);
        }

        User savedUser = userRepository.save(user);
        return UserResponse.fromEntity(savedUser);
    }

    @Transactional
    public UserResponse updateUser(UUID id, UpdateUserRequest request) {
        User user = findActiveUserById(id);

        if (request.firstName() != null && !request.firstName().isBlank()) {
            user.setFirstName(request.firstName().trim());
        }
        if (request.lastName() != null && !request.lastName().isBlank()) {
            user.setLastName(request.lastName().trim());
        }
        if (request.phone() != null && !request.phone().isBlank()) {
            String cleanPhone = request.phone().trim();
            if (!cleanPhone.equals(user.getPhone()) && userRepository.existsByPhoneAndDeletedAtIsNull(cleanPhone)) {
                throw new ConflictException("Phone number is already associated with another account");
            }
            user.setPhone(cleanPhone);
        }
        if (request.role() != null) {
            user.setRole(request.role());
        }
        if (request.isActive() != null) {
            user.setActive(request.isActive());
        }
        if (request.wardId() != null) {
            Ward ward = wardRepository.findById(request.wardId())
                    .orElseThrow(() -> new ResourceNotFoundException("Ward not found with id: " + request.wardId()));
            user.setWard(ward);
        }
        if (request.avatarUrl() != null) {
            user.setAvatarUrl(request.avatarUrl().trim());
        }

        User updatedUser = userRepository.save(user);
        return UserResponse.fromEntity(updatedUser);
    }

    @Transactional
    public void deleteUser(UUID id) {
        User user = findActiveUserById(id);
        // Soft delete per AGENTS.md Rule 2.4
        user.setDeletedAt(Instant.now());
        user.setActive(false);
        userRepository.save(user);
    }

    private User findActiveUserById(UUID id) {
        return userRepository.findByIdAndDeletedAtIsNull(id)
                .orElseThrow(() -> new ResourceNotFoundException("User not found with id: " + id));
    }
}
