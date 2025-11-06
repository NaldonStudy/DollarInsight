package com.ssafy.b205.backend.domain.chat.entity;

import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "chat_sessions")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class ChatSession {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @Column(nullable = false, columnDefinition = "uuid")
    private UUID uuid;

    @Column(name = "user_id", nullable = false)
    private Integer userId;

    @Enumerated(EnumType.STRING)
    @Column(name = "topic_type", nullable = false, length = 20)
    private ChatTopicType topicType;

    @Column(length = 256)
    private String title;

    @Column(length = 16)
    private String ticker;
    
    @Column(name = "company_news_id")
    private Long companyNewsId;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

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

    @PrePersist
    private void prePersist() {
        if (uuid == null) uuid = UUID.randomUUID();
    }
}
