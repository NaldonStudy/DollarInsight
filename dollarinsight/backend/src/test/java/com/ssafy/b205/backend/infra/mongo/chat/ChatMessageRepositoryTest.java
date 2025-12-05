package com.ssafy.b205.backend.infra.mongo.chat;

import org.bson.types.ObjectId;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.data.mongo.DataMongoTest;
import org.springframework.data.domain.PageRequest;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

@DataMongoTest(properties = {
        "spring.mongodb.embedded.version=7.0.5"
})
class ChatMessageRepositoryTest {

    @Autowired
    ChatMessageRepository repo;

    private ChatMessageDoc doc(String id, UUID session, String content) {
        return ChatMessageDoc.builder()
                .id(id)
                .sessionUuid(session)
                .content(content)
                .role("assistant")
                .ts(Instant.now())
                .build();
    }

    @Test
    @DisplayName("pageFirst는 _id 내림차순으로 정렬된 슬라이스를 반환한다")
    void pageFirst() {
        UUID session = UUID.randomUUID();
        String idA = "00000000000000000000000a";
        String idB = "00000000000000000000000b";
        String idC = "00000000000000000000000c";
        repo.saveAll(List.of(doc(idA, session, "a"), doc(idB, session, "b"), doc(idC, session, "c")));

        var slice = repo.pageFirst(session, PageRequest.of(0, 2));

        assertThat(slice).extracting(ChatMessageDoc::getId).containsExactly(idC, idB);
    }

    @Test
    @DisplayName("pageByCursor는 기준 _id보다 작은 문서만 내림차순으로 반환한다")
    void pageByCursor() {
        UUID session = UUID.randomUUID();
        String id1 = "000000000000000000000011";
        String id2 = "000000000000000000000012";
        String id3 = "000000000000000000000013";
        repo.saveAll(List.of(doc(id1, session, "1"), doc(id2, session, "2"), doc(id3, session, "3")));

        var slice = repo.pageByCursor(session, new ObjectId(id2), PageRequest.of(0, 10));

        assertThat(slice).extracting(ChatMessageDoc::getId).containsExactly(id1);
    }

    @Test
    @DisplayName("findAfterId는 기준 _id보다 큰 문서를 오름차순으로 반환한다")
    void findAfterId() {
        UUID session = UUID.randomUUID();
        String id1 = "000000000000000000000021";
        String id2 = "000000000000000000000022";
        String id3 = "000000000000000000000023";
        repo.saveAll(List.of(doc(id1, session, "1"), doc(id2, session, "2"), doc(id3, session, "3")));

        var slice = repo.findAfterId(session, new ObjectId(id1));

        assertThat(slice).extracting(ChatMessageDoc::getId).containsExactly(id2, id3);
    }
}
