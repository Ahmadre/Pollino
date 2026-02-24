package com.pollino.controller;

import com.pollino.dto.*;
import com.pollino.service.PollService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/polls")
@RequiredArgsConstructor
public class PollController {

    private final PollService pollService;

    /**
     * GET /api/polls?page=1&limit=20
     * Fetch paginated list of public polls.
     */
    @GetMapping
    public ResponseEntity<PollListResponse> getPolls(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int limit) {
        PollListResponse response = pollService.getPolls(page, limit);
        return ResponseEntity.ok(response);
    }

    /**
     * GET /api/polls/{id}
     * Fetch a single poll by ID.
     */
    @GetMapping("/{id}")
    public ResponseEntity<PollResponse> getPoll(@PathVariable String id) {
        PollResponse response = pollService.getPoll(id);
        return ResponseEntity.ok(response);
    }

    /**
     * POST /api/polls
     * Create a new poll.
     */
    @PostMapping
    public ResponseEntity<CreatePollResponse> createPoll(
            @Valid @RequestBody CreatePollRequest request,
            @RequestHeader(value = "X-Web-App-Url", defaultValue = "") String webAppUrl) {
        CreatePollResponse response = pollService.createPoll(request, webAppUrl);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    /**
     * POST /api/polls/{id}/vote
     * Cast one or more votes on a poll.
     */
    @PostMapping("/{id}/vote")
    public ResponseEntity<PollResponse> vote(
            @PathVariable String id,
            @Valid @RequestBody VoteRequest request) {
        PollResponse response = pollService.vote(id, request);
        return ResponseEntity.ok(response);
    }

    /**
     * GET /api/polls/{id}/votes
     * Get all votes for a poll (for displaying voter names).
     */
    @GetMapping("/{id}/votes")
    public ResponseEntity<List<VoteResponse>> getVotes(@PathVariable String id) {
        List<VoteResponse> votes = pollService.getVotesForPoll(id);
        return ResponseEntity.ok(votes);
    }

    /**
     * GET /api/polls/{id}/votes/{optionId}
     * Get voters for a specific option.
     */
    @GetMapping("/{id}/votes/{optionId}")
    public ResponseEntity<List<VoteResponse>> getVotersForOption(
            @PathVariable String id,
            @PathVariable String optionId) {
        List<VoteResponse> voters = pollService.getVotersForOption(id, optionId);
        return ResponseEntity.ok(voters);
    }

    /**
     * GET /api/polls/{id}/user-votes?voterName=xxx
     * Get voted option IDs for a given voter.
     */
    @GetMapping("/{id}/user-votes")
    public ResponseEntity<List<String>> getUserVotedOptions(
            @PathVariable String id,
            @RequestParam String voterName) {
        List<String> votedOptionIds = pollService.getUserVotedOptions(id, voterName);
        return ResponseEntity.ok(votedOptionIds);
    }

    /**
     * GET /api/polls/{id}/has-voted?voterName=xxx
     * Check if a user has voted on a poll.
     */
    @GetMapping("/{id}/has-voted")
    public ResponseEntity<Map<String, Boolean>> hasUserVoted(
            @PathVariable String id,
            @RequestParam String voterName) {
        boolean hasVoted = pollService.hasUserVoted(id, voterName);
        return ResponseEntity.ok(Map.of("hasVoted", hasVoted));
    }

    /**
     * POST /api/polls/{id}/like
     * Toggle like on a poll.
     */
    @PostMapping("/{id}/like")
    public ResponseEntity<PollResponse> toggleLike(
            @PathVariable String id,
            @RequestParam(defaultValue = "false") boolean currentlyLiked) {
        PollResponse response = pollService.toggleLike(id, currentlyLiked);
        return ResponseEntity.ok(response);
    }

    /**
     * POST /api/polls/{id}/validate-token
     * Validate an admin token for a poll.
     */
    @PostMapping("/{id}/validate-token")
    public ResponseEntity<Map<String, Boolean>> validateAdminToken(
            @PathVariable String id,
            @RequestBody Map<String, String> body) {
        String token = body.get("adminToken");
        boolean isValid = pollService.validateAdminToken(id, token);
        return ResponseEntity.ok(Map.of("valid", isValid));
    }

    /**
     * PUT /api/polls/{id}
     * Update a poll (requires admin token in request body).
     */
    @PutMapping("/{id}")
    public ResponseEntity<PollResponse> updatePoll(
            @PathVariable String id,
            @Valid @RequestBody UpdatePollRequest request) {
        PollResponse response = pollService.updatePoll(id, request);
        return ResponseEntity.ok(response);
    }

    /**
     * DELETE /api/polls/{id}?adminToken=xxx
     * Delete a poll (requires admin token).
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deletePoll(
            @PathVariable String id,
            @RequestParam String adminToken) {
        pollService.deletePoll(id, adminToken);
        return ResponseEntity.noContent().build();
    }
}
