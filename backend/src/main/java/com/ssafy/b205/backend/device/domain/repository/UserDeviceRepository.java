package com.ssafy.b205.backend.device.domain.repository;

import com.ssafy.b205.backend.device.domain.entity.UserDevice;
import com.ssafy.b205.backend.user.domain.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface UserDeviceRepository extends JpaRepository<UserDevice, Integer> {
    List<UserDevice> findByUser(User user);
    Optional<UserDevice> findByUserAndDeviceId(User user, String deviceId);
}
