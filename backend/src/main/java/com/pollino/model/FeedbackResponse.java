package com.pollino.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Document(collection = "feedback_responses")
public class FeedbackResponse {

    @Id
    private String id;

    @Indexed
    private String pollId;

    private String respondentName;

    @Builder.Default
    private List<FeedbackAnswer> answers = new ArrayList<>();

    @CreatedDate
    private Instant createdAt;
}
