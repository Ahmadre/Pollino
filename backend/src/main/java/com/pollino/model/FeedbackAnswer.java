package com.pollino.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.ArrayList;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FeedbackAnswer {

    private String questionId;

    private String textAnswer;

    @Builder.Default
    private List<String> selectedOptions = new ArrayList<>();
}
