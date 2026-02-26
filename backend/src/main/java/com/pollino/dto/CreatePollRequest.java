package com.pollino.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.Size;
import jakarta.validation.constraints.Email;
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
public class CreatePollRequest {

    @NotBlank(message = "Title is required")
    @Size(max = 500, message = "Title must not exceed 500 characters")
    private String title;

    @Size(max = 2000, message = "Description must not exceed 2000 characters")
    private String description;

    /**
     * Poll type: "STANDARD" (default) or "FEEDBACK".
     * For STANDARD polls, options are required.
     * For FEEDBACK polls, feedbackQuestions are required instead.
     */
    @Builder.Default
    private String pollType = "STANDARD";

    /**
     * Options for STANDARD polls. Required when pollType is STANDARD.
     */
    @Size(min = 2, max = 20, message = "Poll must have between 2 and 20 options")
    private List<@NotBlank(message = "Option text must not be blank") String> options;

    /**
     * Questions for FEEDBACK polls. Required when pollType is FEEDBACK.
     */
    @Valid
    @Size(min = 1, max = 50, message = "Feedback poll must have between 1 and 50 questions")
    private List<FeedbackQuestionRequest> feedbackQuestions;

    @Builder.Default
    private boolean anonymous = true;

    @Builder.Default
    private boolean allowsMultipleVotes = false;

    private Instant expiresAt;

    @Builder.Default
    private boolean autoDeleteAfterExpiry = false;

    private String creatorName;

    @Email(message = "Invalid email address")
    private String creatorEmail;
}
