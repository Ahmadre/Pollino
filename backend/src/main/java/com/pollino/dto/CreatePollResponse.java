package com.pollino.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CreatePollResponse {

    private PollResponse poll;
    private String adminToken;
    private String adminUrl;
}
