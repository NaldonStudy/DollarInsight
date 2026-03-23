package com.ssafy.b205.backend.chat.adapter.web.dto.response;

import lombok.Getter;

@Getter
public class AppendMessageResponse {
    private final String messageId;

    public AppendMessageResponse(String messageId) {
        this.messageId = messageId;
    }
}
