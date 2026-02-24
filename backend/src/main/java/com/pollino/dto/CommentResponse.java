package com.pollino.dto;

import com.pollino.model.Comment;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CommentResponse {

    private String id;
    private String pollId;
    private String userName;
    private boolean anonymous;
    private String content;
    private String clientId;
    private Instant createdAt;
    private Instant updatedAt;

    public static CommentResponse fromComment(Comment comment) {
        return CommentResponse.builder()
                .id(comment.getId())
                .pollId(comment.getPollId())
                .userName(comment.getUserName())
                .anonymous(comment.isAnonymous())
                .content(comment.getContent())
                .clientId(comment.getClientId())
                .createdAt(comment.getCreatedAt())
                .updatedAt(comment.getUpdatedAt())
                .build();
    }
}
