package com.ssafy.b205.backend.domain.device.repository;

import com.ssafy.b205.backend.domain.device.entity.UserDevice;
import com.ssafy.b205.backend.domain.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface UserDeviceRepository extends JpaRepository<UserDevice, Integer> {
    List<UserDevice> findByUser(User user);
    Optional<UserDevice> findByUserAndDeviceId(User user, String deviceId);
}
