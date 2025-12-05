package com.ssafy.b205.backend.infra.mongo.chat;

import org.bson.types.ObjectId;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.data.mongodb.repository.Query;

import java.util.List;
import java.util.UUID;

public interface ChatMessageRepository extends MongoRepository<ChatMessageDoc, String> {

    long countBySessionUuidAndRole(UUID sessionUuid, String role);

    // 기존(ts) 페이지 — 그대로 유지
    Page<ChatMessageDoc> findBySessionUuidOrderByTsDesc(UUID sessionUuid, Pageable pageable);

    @Query(value = "{ 'sessionUuid': ?0 }", sort = "{ '_id': -1 }")
    List<ChatMessageDoc> pageFirst(UUID sessionUuid, Pageable pageable);

    @Query(value = "{ 'sessionUuid': ?0, '_id': { $lt: ?1 } }", sort = "{ '_id': -1 }")
    List<ChatMessageDoc> pageByCursor(UUID sessionUuid, ObjectId beforeId, Pageable pageable);

    @Query(value = "{ 'sessionUuid': ?0, '_id': { $gt: ?1 } }", sort = "{ '_id': 1 }")
    List<ChatMessageDoc> findAfterId(UUID sessionUuid, ObjectId afterId);
}
