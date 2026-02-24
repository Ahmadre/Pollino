package com.pollino.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class VoteRequest {

    @NotEmpty(message = "At least one option must be selected")
    private List<@NotBlank(message = "Option ID must not be blank") String> optionIds;

    private String voterName;

    @Builder.Default
    private boolean anonymous = true;
}
