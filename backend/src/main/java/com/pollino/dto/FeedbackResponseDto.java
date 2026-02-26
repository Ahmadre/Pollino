package com.pollino.dto;

import com.pollino.model.FeedbackAnswer;
import com.pollino.model.FeedbackResponse;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FeedbackResponseDto {

    private String id;
    private String respondentName;
    private List<AnswerDto> answers;
    private Instant createdAt;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class AnswerDto {
        private String questionId;
        private String textAnswer;
        private List<String> selectedOptions;
    }

    public static FeedbackResponseDto fromFeedbackResponse(FeedbackResponse response) {
        return FeedbackResponseDto.builder()
                .id(response.getId())
                .respondentName(response.getRespondentName())
                .answers(response.getAnswers().stream()
                        .map(FeedbackResponseDto::toAnswerDto)
                        .toList())
                .createdAt(response.getCreatedAt())
                .build();
    }

    private static AnswerDto toAnswerDto(FeedbackAnswer answer) {
        return AnswerDto.builder()
                .questionId(answer.getQuestionId())
                .textAnswer(answer.getTextAnswer())
                .selectedOptions(answer.getSelectedOptions())
                .build();
    }
}
