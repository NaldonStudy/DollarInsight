package com.ssafy.b205.backend.domain.companyanalysis.dto.response;

import lombok.Getter;

import java.util.List;

@Getter
public class PagedNewsResponse {

    private final List<NewsHeadlineResponse> items;
    private final long totalElements;
    private final int page;
    private final int size;

    public PagedNewsResponse(List<NewsHeadlineResponse> items, long totalElements, int page, int size) {
        this.items = items;
        this.totalElements = totalElements;
        this.page = page;
        this.size = size;
    }
}
