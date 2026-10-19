package com.civicpulse.module.user.repository;

import com.civicpulse.module.user.entity.User;
import com.civicpulse.module.user.entity.UserRole;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface UserRepository extends JpaRepository<User, UUID> {

    Optional<User> findByEmailAndDeletedAtIsNull(String email);

    Optional<User> findByIdAndDeletedAtIsNull(UUID id);

    boolean existsByEmailAndDeletedAtIsNull(String email);

    boolean existsByPhoneAndDeletedAtIsNull(String phone);

    Page<User> findAllByDeletedAtIsNull(Pageable pageable);

    Page<User> findAllByRoleAndDeletedAtIsNull(UserRole role, Pageable pageable);

    List<User> findAllByRoleAndDeletedAtIsNull(UserRole role);
}
