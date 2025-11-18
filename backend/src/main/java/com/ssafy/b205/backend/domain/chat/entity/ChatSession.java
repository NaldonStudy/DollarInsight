package com.ssafy.b205.backend.domain.chat.entity;

import com.ssafy.b205.backend.support.jpa.AuditableBase;
import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "chat_sessions")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class ChatSession extends AuditableBase {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @Column(nullable = false, columnDefinition = "uuid")
    private UUID uuid;

    @Column(name = "user_id", nullable = false)
    private Integer userId;

    @Enumerated(EnumType.STRING)
    @JdbcTypeCode(SqlTypes.NAMED_ENUM)
    @Column(name = "topic_type", nullable = false, columnDefinition = "chat_topic_type")
    private ChatTopicType topicType;

    @Column(length = 256)
    private String title;

    @Column(length = 16)
    private String ticker;

    @Column(name = "company_news_id")
    private Long companyNewsId;

    @Column(name = "deleted_at")
    private OffsetDateTime deletedAt;

    // 생성 팩토리
    public static ChatSession create(Integer userId,
                                     ChatTopicType topicType,
                                     String title,
                                     String ticker,
                                     Long companyNewsId) {
        ChatSession s = new ChatSession();
        s.userId = userId;
        s.topicType = (topicType == null ? ChatTopicType.CUSTOM : topicType);
        s.title = title;
        s.ticker = ticker;
        s.companyNewsId = companyNewsId;
        return s;
    }

    // UUID를 지정하여 생성하는 팩토리
    public static ChatSession createWithUuid(Integer userId,
                                             UUID sessionUuid,
                                             ChatTopicType topicType,
                                             String title,
                                             String ticker,
                                             Long companyNewsId) {
        ChatSession s = new ChatSession();
        s.uuid = sessionUuid; // UUID를 미리 설정
        s.userId = userId;
        s.topicType = (topicType == null ? ChatTopicType.CUSTOM : topicType);
        s.title = title;
        s.ticker = ticker;
        s.companyNewsId = companyNewsId;
        return s;
    }

    @PrePersist
    private void prePersist() {
        if (uuid == null) {
            uuid = UUID.randomUUID();
        }
    }

    public void markDeleted() {
        this.deletedAt = OffsetDateTime.now();
    }
}
