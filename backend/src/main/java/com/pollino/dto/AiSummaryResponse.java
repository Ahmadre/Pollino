package com.pollino.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AiSummaryResponse {

    private String summaryText;
    private int responseCount;
    private Instant generatedAt;
    private boolean available;
    /** True while a new summary is currently being generated in the background. */
    private boolean generating;
}
