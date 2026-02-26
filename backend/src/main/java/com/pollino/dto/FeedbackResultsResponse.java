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
public class FeedbackResultsResponse {

    private String pollId;
    private String pollTitle;
    private int responseCount;
    private List<QuestionSummary> questions;
    private List<FeedbackResponseDto> responses;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class QuestionSummary {
        private String questionId;
        private String questionText;
        private String questionType;
        private List<String> options;
        private int order;
    }
}
