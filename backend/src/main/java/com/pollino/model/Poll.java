package com.pollino.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.Id;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Document(collection = "polls")
public class Poll {

    @Id
    private String id;

    private String title;

    private String description;

    @Builder.Default
    private List<PollOption> options = new ArrayList<>();

    @Builder.Default
    private boolean anonymous = true;

    @Builder.Default
    private boolean allowsMultipleVotes = false;

    private String createdByName;

    private String createdBy;

    private String adminToken;

    @Indexed
    private Instant expiresAt;

    @Builder.Default
    private boolean autoDeleteAfterExpiry = false;

    @Builder.Default
    private boolean active = true;

    @Builder.Default
    private int likesCount = 0;

    @CreatedDate
    private Instant createdAt;

    @LastModifiedDate
    private Instant updatedAt;
}
