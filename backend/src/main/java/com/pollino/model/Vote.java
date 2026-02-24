package com.pollino.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.CompoundIndex;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.Instant;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Document(collection = "votes")
@CompoundIndex(name = "idx_poll_voter", def = "{'pollId': 1, 'voterName': 1}")
@CompoundIndex(name = "idx_poll_option_voter", def = "{'pollId': 1, 'optionId': 1, 'voterName': 1}")
public class Vote {

    @Id
    private String id;

    @Indexed
    private String pollId;

    private String optionId;

    private String voterName;

    @Builder.Default
    private boolean anonymous = true;

    @CreatedDate
    private Instant createdAt;
}
