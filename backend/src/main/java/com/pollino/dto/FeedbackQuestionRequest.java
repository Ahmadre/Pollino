package com.pollino.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
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
public class FeedbackQuestionRequest {

    @NotBlank(message = "Question text is required")
    @Size(max = 1000, message = "Question text must not exceed 1000 characters")
    private String questionText;

    @NotNull(message = "Question type is required")
    private String questionType; // FREE_TEXT, SINGLE_CHOICE, MULTIPLE_CHOICE

    private List<String> options; // Required for SINGLE_CHOICE and MULTIPLE_CHOICE
}
