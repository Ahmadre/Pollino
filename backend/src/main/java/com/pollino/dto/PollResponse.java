package com.pollino.dto;

import com.pollino.model.Poll;
import com.pollino.model.PollOption;
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
public class PollResponse {

    private String id;
    private String title;
    private String description;
    private List<OptionResponse> options;
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

    public static PollResponse fromPoll(Poll poll) {
        return PollResponse.builder()
                .id(poll.getId())
                .title(poll.getTitle())
                .description(poll.getDescription())
                .options(poll.getOptions().stream()
                        .map(PollResponse::toOptionResponse)
                        .toList())
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
}
