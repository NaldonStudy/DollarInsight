package com.ssafy.b205.backend.domain.watchlist.repository;

import com.ssafy.b205.backend.domain.user.entity.User;
import com.ssafy.b205.backend.domain.watchlist.entity.UserWatchlist;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface UserWatchlistRepository extends JpaRepository<UserWatchlist, Integer> {

    List<UserWatchlist> findByUserOrderByCreatedAtDesc(User user);
    boolean existsByUserAndTicker(User user, String ticker);
    Optional<UserWatchlist> findByUserAndTicker(User user, String ticker);
}
