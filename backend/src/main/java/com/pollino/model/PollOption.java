package com.pollino.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PollOption {

    @Builder.Default
    private String id = UUID.randomUUID().toString();

    private String text;

    @Builder.Default
    private int votes = 0;

    @Builder.Default
    private int order = 0;
}
