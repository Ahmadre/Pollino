package com.pollino.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FeedbackQuestion {

    @Builder.Default
    private String id = UUID.randomUUID().toString();

    private String questionText;

    @Builder.Default
    private QuestionType questionType = QuestionType.FREE_TEXT;

    @Builder.Default
    private List<String> options = new ArrayList<>();

    @Builder.Default
    private int order = 0;
}
