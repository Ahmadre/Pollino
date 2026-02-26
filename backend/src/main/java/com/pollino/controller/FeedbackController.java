package com.pollino.controller;

import com.pollino.dto.*;
import com.pollino.service.FeedbackService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/polls/{pollId}/feedback")
@RequiredArgsConstructor
public class FeedbackController {

    private final FeedbackService feedbackService;

    /**
     * POST /api/polls/{pollId}/feedback
     * Submit feedback for a feedback poll.
     */
    @PostMapping
    public ResponseEntity<FeedbackResponseDto> submitFeedback(
            @PathVariable String pollId,
            @Valid @RequestBody SubmitFeedbackRequest request) {
        FeedbackResponseDto response = feedbackService.submitFeedback(pollId, request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    /**
     * GET /api/polls/{pollId}/feedback?adminToken=xxx
     * Get all feedback results (admin only).
     */
    @GetMapping
    public ResponseEntity<FeedbackResultsResponse> getFeedbackResults(
            @PathVariable String pollId,
            @RequestParam String adminToken) {
        FeedbackResultsResponse response = feedbackService.getFeedbackResults(pollId, adminToken);
        return ResponseEntity.ok(response);
    }

    /**
     * GET /api/polls/{pollId}/feedback/summary?adminToken=xxx
     * Get AI-generated summary (admin only).
     */
    @GetMapping("/summary")
    public ResponseEntity<AiSummaryResponse> getAiSummary(
            @PathVariable String pollId,
            @RequestParam String adminToken) {
        AiSummaryResponse response = feedbackService.getAiSummary(pollId, adminToken);
        return ResponseEntity.ok(response);
    }

    /**
     * POST /api/polls/{pollId}/feedback/summary/regenerate?adminToken=xxx
     * Trigger AI summary regeneration (admin only).
     */
    @PostMapping("/summary/regenerate")
    public ResponseEntity<Map<String, String>> regenerateAiSummary(
            @PathVariable String pollId,
            @RequestParam String adminToken) {
        feedbackService.regenerateAiSummary(pollId, adminToken);
        return ResponseEntity.ok(Map.of("status", "regeneration_started"));
    }

    /**
     * GET /api/polls/{pollId}/feedback/has-responded?respondentName=xxx
     * Check if a respondent has already submitted feedback.
     */
    @GetMapping("/has-responded")
    public ResponseEntity<Map<String, Boolean>> hasResponded(
            @PathVariable String pollId,
            @RequestParam String respondentName) {
        boolean hasResponded = feedbackService.hasResponded(pollId, respondentName);
        return ResponseEntity.ok(Map.of("hasResponded", hasResponded));
    }
}
