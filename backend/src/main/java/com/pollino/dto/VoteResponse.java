package com.pollino.dto;

import com.pollino.model.Vote;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class VoteResponse {

    private String optionId;
    private String voterName;
    private boolean anonymous;
    private Instant createdAt;

    public static VoteResponse fromVote(Vote vote) {
        return VoteResponse.builder()
                .optionId(vote.getOptionId())
                .voterName(vote.getVoterName())
                .anonymous(vote.isAnonymous())
                .createdAt(vote.getCreatedAt())
                .build();
    }
}
