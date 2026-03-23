package com.ssafy.b205.backend.watchlist.domain.repository;

import com.ssafy.b205.backend.user.domain.entity.User;
import com.ssafy.b205.backend.watchlist.domain.entity.UserWatchlist;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface UserWatchlistRepository extends JpaRepository<UserWatchlist, Integer> {

    List<UserWatchlist> findByUserOrderByCreatedAtDesc(User user);
    boolean existsByUserAndTicker(User user, String ticker);
    Optional<UserWatchlist> findByUserAndTicker(User user, String ticker);
}
