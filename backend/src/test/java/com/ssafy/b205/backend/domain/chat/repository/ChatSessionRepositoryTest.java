package com.ssafy.b205.backend.domain.chat.repository;

import com.ssafy.b205.backend.config.JpaConfig;
import com.ssafy.b205.backend.domain.chat.entity.ChatSession;
import com.ssafy.b205.backend.domain.chat.entity.ChatTopicType;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.context.annotation.Import;
import org.springframework.data.domain.PageRequest;

import java.time.OffsetDateTime;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

@DataJpaTest(properties = {
        "spring.jpa.hibernate.ddl-auto=create-drop",
        "spring.jpa.properties.hibernate.dialect=org.hibernate.dialect.PostgreSQLDialect",
        "spring.datasource.url=jdbc:h2:mem:testdb;MODE=PostgreSQL;DB_CLOSE_DELAY=-1;DATABASE_TO_LOWER=TRUE;DATABASE_TO_UPPER=false"
})
@Import(JpaConfig.class)
class ChatSessionRepositoryTest {

    @Autowired
    ChatSessionRepository repo;

    @Test
    @DisplayName("UUID로 조회 시 deletedAt이 null인 세션만 반환한다")
    void findByUuidAndDeletedAtIsNull() {
        ChatSession s = ChatSession.create(1, ChatTopicType.CUSTOM, "t", null, null);
        repo.saveAndFlush(s);
        UUID uuid = s.getUuid();

        s.markDeleted();
        repo.saveAndFlush(s);

        assertThat(repo.findByUuidAndDeletedAtIsNull(uuid)).isEmpty();
    }

    @Test
    @DisplayName("touchUpdatedAt이 updated_at을 갱신한다")
    void touchUpdatedAt() {
        ChatSession s = ChatSession.create(1, ChatTopicType.CUSTOM, "t", null, null);
        repo.saveAndFlush(s);
        OffsetDateTime original = s.getUpdatedAt();

        OffsetDateTime newTs = original.plusMinutes(5);
        repo.touchUpdatedAt(s.getId(), newTs);

        ChatSession refreshed = repo.findById(s.getId()).orElseThrow();
        assertThat(refreshed.getUpdatedAt()).isEqualTo(newTs);
    }

    @Test
    @DisplayName("findByUserIdAndDeletedAtIsNull은 삭제되지 않은 세션만 페이지 조회한다")
    void listByUserId() {
        ChatSession alive = ChatSession.create(1, ChatTopicType.CUSTOM, "alive", null, null);
        ChatSession deleted = ChatSession.create(1, ChatTopicType.CUSTOM, "deleted", null, null);
        repo.saveAndFlush(alive);
        repo.saveAndFlush(deleted);
        deleted.markDeleted();
        repo.saveAndFlush(deleted);

        var page = repo.findByUserIdAndDeletedAtIsNull(1, PageRequest.of(0, 10));

        assertThat(page.getTotalElements()).isEqualTo(1);
        assertThat(page.getContent().get(0).getTitle()).isEqualTo("alive");
    }
}
