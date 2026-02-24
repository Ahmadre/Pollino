package com.pollino.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PollListResponse {

    private List<PollResponse> polls;
    private long total;
    private int page;
    private int limit;
    private boolean hasMore;
}
