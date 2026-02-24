package com.pollino.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
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
public class CreatePollRequest {

    @NotBlank(message = "Title is required")
    @Size(max = 500, message = "Title must not exceed 500 characters")
    private String title;

    @Size(max = 2000, message = "Description must not exceed 2000 characters")
    private String description;

    @NotEmpty(message = "At least one option is required")
    @Size(min = 2, max = 20, message = "Poll must have between 2 and 20 options")
    private List<@NotBlank(message = "Option text must not be blank") String> options;

    @Builder.Default
    private boolean anonymous = true;

    @Builder.Default
    private boolean allowsMultipleVotes = false;

    private Instant expiresAt;

    @Builder.Default
    private boolean autoDeleteAfterExpiry = false;

    private String creatorName;
}
