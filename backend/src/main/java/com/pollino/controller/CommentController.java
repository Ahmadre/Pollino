package com.pollino.controller;

import com.pollino.dto.CommentRequest;
import com.pollino.dto.CommentResponse;
import com.pollino.service.CommentService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/comments")
@RequiredArgsConstructor
public class CommentController {

    private final CommentService commentService;

    /**
     * GET /api/comments/{pollId}
     * Get all comments for a poll.
     */
    @GetMapping("/{pollId}")
    public ResponseEntity<List<CommentResponse>> getComments(@PathVariable String pollId) {
        List<CommentResponse> comments = commentService.getComments(pollId);
        return ResponseEntity.ok(comments);
    }

    /**
     * GET /api/comments/{pollId}/count
     * Get comment count for a poll.
     */
    @GetMapping("/{pollId}/count")
    public ResponseEntity<Map<String, Long>> getCommentCount(@PathVariable String pollId) {
        long count = commentService.getCommentCount(pollId);
        return ResponseEntity.ok(Map.of("count", count));
    }

    /**
     * POST /api/comments/{pollId}
     * Add a comment to a poll.
     */
    @PostMapping("/{pollId}")
    public ResponseEntity<CommentResponse> addComment(
            @PathVariable String pollId,
            @Valid @RequestBody CommentRequest request) {
        CommentResponse response = commentService.addComment(pollId, request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    /**
     * PUT /api/comments/{pollId}/{commentId}
     * Update a comment (requires matching clientId).
     */
    @PutMapping("/{pollId}/{commentId}")
    public ResponseEntity<CommentResponse> updateComment(
            @PathVariable String pollId,
            @PathVariable String commentId,
            @RequestBody Map<String, String> body) {
        String content = body.get("content");
        String clientId = body.get("clientId");
        CommentResponse response = commentService.updateComment(commentId, content, clientId);
        return ResponseEntity.ok(response);
    }

    /**
     * DELETE /api/comments/{pollId}/{commentId}?clientId=xxx
     * Delete a comment (requires matching clientId).
     */
    @DeleteMapping("/{pollId}/{commentId}")
    public ResponseEntity<Void> deleteComment(
            @PathVariable String pollId,
            @PathVariable String commentId,
            @RequestParam String clientId) {
        commentService.deleteComment(commentId, clientId);
        return ResponseEntity.noContent().build();
    }
}
