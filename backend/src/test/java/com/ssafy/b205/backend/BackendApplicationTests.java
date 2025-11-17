package com.ssafy.b205.backend;

import com.ssafy.b205.backend.infra.mongo.chat.ChatMessageRepository;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.data.mongodb.core.MongoTemplate;

@SpringBootTest
class BackendApplicationTests {

    @MockitoBean
    ChatMessageRepository chatMessageRepository;

    @MockitoBean
    MongoTemplate mongoTemplate;

    @Test
    void contextLoads() {
    }

}
