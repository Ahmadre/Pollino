package com.pollino.service;

import com.pollino.dto.CommentRequest;
import com.pollino.dto.CommentResponse;
import com.pollino.exception.BusinessException;
import com.pollino.exception.ResourceNotFoundException;
import com.pollino.exception.UnauthorizedException;
import com.pollino.model.Comment;
import com.pollino.repository.CommentRepository;
import com.pollino.repository.PollRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;

import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class CommentService {

    private final CommentRepository commentRepository;
    private final PollRepository pollRepository;

    /**
     * Get all comments for a poll, sorted by creation date descending.
     */
    public List<CommentResponse> getComments(String pollId) {
        validatePollExists(pollId);

        return commentRepository.findByPollId(pollId, Sort.by(Sort.Direction.DESC, "createdAt"))
                .stream()
                .map(CommentResponse::fromComment)
                .toList();
    }

    /**
     * Get comment count for a poll.
     */
    public long getCommentCount(String pollId) {
        return commentRepository.countByPollId(pollId);
    }

    /**
     * Add a comment to a poll.
     */
    public CommentResponse addComment(String pollId, CommentRequest request) {
        validatePollExists(pollId);

        String content = request.getContent().trim();
        if (content.isEmpty()) {
            throw new BusinessException("Comment content must not be empty");
        }
        if (content.length() > 1000) {
            throw new BusinessException("Comment must not exceed 1000 characters");
        }

        Comment comment = Comment.builder()
                .pollId(pollId)
                .userName(request.isAnonymous() ? null : request.getUserName())
                .anonymous(request.isAnonymous())
                .content(content)
                .clientId(request.getClientId())
                .build();

        Comment saved = commentRepository.save(comment);
        return CommentResponse.fromComment(saved);
    }

    /**
     * Update a comment (only the original client can edit).
     */
    public CommentResponse updateComment(String commentId, String content, String clientId) {
        Comment comment = commentRepository.findById(commentId)
                .orElseThrow(() -> new ResourceNotFoundException("Comment not found: " + commentId));

        if (!clientId.equals(comment.getClientId())) {
            throw new UnauthorizedException("You can only edit your own comments");
        }

        String trimmedContent = content.trim();
        if (trimmedContent.isEmpty()) {
            throw new BusinessException("Comment content must not be empty");
        }
        if (trimmedContent.length() > 1000) {
            throw new BusinessException("Comment must not exceed 1000 characters");
        }

        comment.setContent(trimmedContent);
        Comment savedComment = commentRepository.save(comment);
        return CommentResponse.fromComment(savedComment);
    }

    /**
     * Delete a comment (only the original client can delete).
     */
    public void deleteComment(String commentId, String clientId) {
        Comment comment = commentRepository.findById(commentId)
                .orElseThrow(() -> new ResourceNotFoundException("Comment not found: " + commentId));

        if (!clientId.equals(comment.getClientId())) {
            throw new UnauthorizedException("You can only delete your own comments");
        }

        commentRepository.delete(comment);
    }

    private void validatePollExists(String pollId) {
        if (!pollRepository.existsById(pollId)) {
            throw new ResourceNotFoundException("Poll not found: " + pollId);
        }
    }
}
