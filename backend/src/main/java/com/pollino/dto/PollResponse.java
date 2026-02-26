package com.pollino.dto;

import com.pollino.model.FeedbackQuestion;
import com.pollino.model.Poll;
import com.pollino.model.PollOption;
import com.pollino.model.PollType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;
import java.util.Collections;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PollResponse {

    private String id;
    private String title;
    private String description;
    private String pollType;
    private List<OptionResponse> options;
    private List<FeedbackQuestionResponse> feedbackQuestions;
    private int feedbackResponseCount;
    private boolean anonymous;
    private boolean allowsMultipleVotes;
    private String createdByName;
    private String createdBy;
    private Instant expiresAt;
    private boolean autoDeleteAfterExpiry;
    private boolean active;
    private int likesCount;
    private Instant createdAt;
    private Instant updatedAt;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class OptionResponse {
        private String id;
        private String text;
        private int votes;
        private int order;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class FeedbackQuestionResponse {
        private String id;
        private String questionText;
        private String questionType;
        private List<String> options;
        private int order;
    }

    public static PollResponse fromPoll(Poll poll) {
        List<FeedbackQuestionResponse> fbQuestions = null;
        if (poll.getPollType() == PollType.FEEDBACK && poll.getFeedbackQuestions() != null) {
            fbQuestions = poll.getFeedbackQuestions().stream()
                    .map(PollResponse::toFeedbackQuestionResponse)
                    .toList();
        }

        List<OptionResponse> optionResponses = poll.getOptions() != null
                ? poll.getOptions().stream().map(PollResponse::toOptionResponse).toList()
                : Collections.emptyList();

        return PollResponse.builder()
                .id(poll.getId())
                .title(poll.getTitle())
                .description(poll.getDescription())
                .pollType(poll.getPollType() != null ? poll.getPollType().name() : PollType.STANDARD.name())
                .options(optionResponses)
                .feedbackQuestions(fbQuestions)
                .feedbackResponseCount(poll.getFeedbackResponseCount())
                .anonymous(poll.isAnonymous())
                .allowsMultipleVotes(poll.isAllowsMultipleVotes())
                .createdByName(poll.getCreatedByName())
                .createdBy(poll.getCreatedBy())
                .expiresAt(poll.getExpiresAt())
                .autoDeleteAfterExpiry(poll.isAutoDeleteAfterExpiry())
                .active(poll.isActive())
                .likesCount(poll.getLikesCount())
                .createdAt(poll.getCreatedAt())
                .updatedAt(poll.getUpdatedAt())
                .build();
    }

    private static OptionResponse toOptionResponse(PollOption option) {
        return OptionResponse.builder()
                .id(option.getId())
                .text(option.getText())
                .votes(option.getVotes())
                .order(option.getOrder())
                .build();
    }

    private static FeedbackQuestionResponse toFeedbackQuestionResponse(FeedbackQuestion question) {
        return FeedbackQuestionResponse.builder()
                .id(question.getId())
                .questionText(question.getQuestionText())
                .questionType(question.getQuestionType().name())
                .options(question.getOptions())
                .order(question.getOrder())
                .build();
    }
}
