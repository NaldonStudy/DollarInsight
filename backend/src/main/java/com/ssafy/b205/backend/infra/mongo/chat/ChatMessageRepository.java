package com.ssafy.b205.backend.infra.mongo.chat;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.mongodb.repository.MongoRepository;

import java.util.UUID;

public interface ChatMessageRepository extends MongoRepository<ChatMessageDoc, String> {
    long countBySessionUuidAndRole(UUID sessionUuid, String role);
    Page<ChatMessageDoc> findBySessionUuidOrderByTsDesc(UUID sessionUuid, Pageable pageable);
}
