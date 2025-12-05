package com.ssafy.b205.backend.support.response;

import org.springframework.data.domain.Page;
import java.util.List;

public final class PageResponse<T> {
    private final List<T> items;
    private final int page;
    private final int size;
    private final long totalElements;
    private final int totalPages;
    private final boolean hasNext;

    private PageResponse(List<T> items, int page, int size, long totalElements, int totalPages, boolean hasNext) {
        this.items = items;
        this.page = page;
        this.size = size;
        this.totalElements = totalElements;
        this.totalPages = totalPages;
        this.hasNext = hasNext;
    }

    public static <T> PageResponse<T> of(Page<T> p) {
        return new PageResponse<>(
                p.getContent(), p.getNumber(), p.getSize(),
                p.getTotalElements(), p.getTotalPages(), p.hasNext()
        );
    }

    public List<T> getItems() { return items; }
    public int getPage() { return page; }
    public int getSize() { return size; }
    public long getTotalElements() { return totalElements; }
    public int getTotalPages() { return totalPages; }
    public boolean isHasNext() { return hasNext; }
}
