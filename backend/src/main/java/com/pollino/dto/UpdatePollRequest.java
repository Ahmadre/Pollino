package com.pollino.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
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
public class UpdatePollRequest {

    @NotBlank(message = "Admin token is required")
    private String adminToken;

    @NotBlank(message = "Title is required")
    @Size(max = 500, message = "Title must not exceed 500 characters")
    private String title;

    @Size(max = 2000, message = "Description must not exceed 2000 characters")
    private String description;

    @Size(max = 20, message = "Poll must not have more than 20 options")
    private List<@NotBlank(message = "Option text must not be blank") String> options;

    private List<FeedbackQuestionRequest> feedbackQuestions;

    @Builder.Default
    private boolean anonymous = true;

    @Builder.Default
    private boolean allowsMultipleVotes = false;

    private Instant expiresAt;

    @Builder.Default
    private boolean autoDeleteAfterExpiry = false;

    private String creatorName;
}
