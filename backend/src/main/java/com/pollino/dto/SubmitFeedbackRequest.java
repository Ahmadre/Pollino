package com.pollino.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SubmitFeedbackRequest {

    private String respondentName;

    @NotEmpty(message = "At least one answer is required")
    private List<FeedbackAnswerRequest> answers;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class FeedbackAnswerRequest {

        @NotBlank(message = "Question ID is required")
        private String questionId;

        @Size(max = 5000, message = "Text answer must not exceed 5000 characters")
        private String textAnswer;

        private List<String> selectedOptions;
    }
}
