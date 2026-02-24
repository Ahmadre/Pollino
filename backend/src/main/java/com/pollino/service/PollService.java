package com.pollino.service;

import com.pollino.dto.*;
import com.pollino.exception.BusinessException;
import com.pollino.exception.ResourceNotFoundException;
import com.pollino.exception.UnauthorizedException;
import com.pollino.model.Poll;
import com.pollino.model.PollOption;
import com.pollino.model.Vote;
import com.pollino.repository.CommentRepository;
import com.pollino.repository.PollRepository;
import com.pollino.repository.VoteRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;

import java.security.SecureRandom;
import java.time.Instant;
import java.util.*;
import java.util.stream.IntStream;

@Slf4j
@Service
@RequiredArgsConstructor
public class PollService {

    private final PollRepository pollRepository;
    private final VoteRepository voteRepository;
    private final CommentRepository commentRepository;

    private static final SecureRandom SECURE_RANDOM = new SecureRandom();
    private static final String TOKEN_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";

    /**
     * Fetch paginated list of visible polls (non-anonymous, active, not auto-deleted expired).
     */
    public PollListResponse getPolls(int page, int limit) {
        Instant now = Instant.now();
        PageRequest pageRequest = PageRequest.of(page - 1, limit, Sort.by(Sort.Direction.DESC, "createdAt"));

        Page<Poll> pollPage = pollRepository.findVisiblePolls(now, pageRequest);
        long total = pollRepository.countVisiblePolls(now);

        List<PollResponse> pollResponses = pollPage.getContent().stream()
                .map(PollResponse::fromPoll)
                .toList();

        return PollListResponse.builder()
                .polls(pollResponses)
                .total(total)
                .page(page)
                .limit(limit)
                .hasMore(pollPage.hasNext())
                .build();
    }

    /**
     * Fetch a single poll by ID.
     */
    public PollResponse getPoll(String pollId) {
        Poll poll = findPollOrThrow(pollId);
        return PollResponse.fromPoll(poll);
    }

    /**
     * Create a new poll with options and generate an admin token.
     */
    public CreatePollResponse createPoll(CreatePollRequest request, String webAppUrl) {
        String adminToken = generateAdminToken();

        List<PollOption> options = IntStream.range(0, request.getOptions().size())
                .mapToObj(i -> PollOption.builder()
                        .id(UUID.randomUUID().toString())
                        .text(request.getOptions().get(i))
                        .votes(0)
                        .order(i + 1)
                        .build())
                .toList();

        Poll poll = Poll.builder()
                .title(request.getTitle())
                .description(request.getDescription() != null ? request.getDescription() : "")
                .options(new ArrayList<>(options))
                .anonymous(request.isAnonymous())
                .allowsMultipleVotes(request.isAllowsMultipleVotes())
                .expiresAt(request.getExpiresAt())
                .autoDeleteAfterExpiry(request.isAutoDeleteAfterExpiry())
                .createdByName(request.getCreatorName())
                .adminToken(adminToken)
                .active(true)
                .likesCount(0)
                .build();

        Poll savedPoll = pollRepository.save(poll);

        String adminUrl = webAppUrl + "/admin/" + savedPoll.getId() + "/" + adminToken;

        return CreatePollResponse.builder()
                .poll(PollResponse.fromPoll(savedPoll))
                .adminToken(adminToken)
                .adminUrl(adminUrl)
                .build();
    }

    /**
     * Cast one or more votes on a poll.
     */
    public PollResponse vote(String pollId, VoteRequest request) {
        Poll poll = findPollOrThrow(pollId);

        // Check if poll is expired
        if (poll.getExpiresAt() != null && poll.getExpiresAt().isBefore(Instant.now())) {
            throw new BusinessException("This poll has expired");
        }

        // Check if poll is active
        if (!poll.isActive()) {
            throw new BusinessException("This poll is no longer active");
        }

        List<String> optionIds = request.getOptionIds();

        // Validate option count for single-vote polls
        if (!poll.isAllowsMultipleVotes() && optionIds.size() > 1) {
            throw new BusinessException("This poll only allows a single vote");
        }

        // Validate all option IDs exist in this poll
        Set<String> validOptionIds = new HashSet<>();
        for (PollOption option : poll.getOptions()) {
            validOptionIds.add(option.getId());
        }
        for (String optionId : optionIds) {
            if (!validOptionIds.contains(optionId)) {
                throw new BusinessException("Option " + optionId + " does not belong to this poll");
            }
        }

        // Check for duplicate votes (non-anonymous only)
        if (!request.isAnonymous() && request.getVoterName() != null && !request.getVoterName().isBlank()) {
            String voterName = request.getVoterName().trim();

            if (!poll.isAllowsMultipleVotes()) {
                // Single voting: check if user already voted on this poll
                if (voteRepository.existsByPollIdAndVoterName(pollId, voterName)) {
                    throw new BusinessException("User " + voterName + " has already voted on this poll");
                }
            } else {
                // Multiple voting: check per option
                for (String optionId : optionIds) {
                    if (voteRepository.existsByPollIdAndOptionIdAndVoterName(pollId, optionId, voterName)) {
                        throw new BusinessException("User " + voterName + " has already voted for this option");
                    }
                }
            }
        }

        // Record votes and increment counters atomically
        for (String optionId : optionIds) {
            Vote vote = Vote.builder()
                    .pollId(pollId)
                    .optionId(optionId)
                    .voterName(request.isAnonymous() ? null : request.getVoterName())
                    .anonymous(request.isAnonymous())
                    .build();

            voteRepository.save(vote);

            // Increment vote count on the option
            poll.getOptions().stream()
                    .filter(opt -> opt.getId().equals(optionId))
                    .findFirst()
                    .ifPresent(opt -> opt.setVotes(opt.getVotes() + 1));
        }

        Poll updatedPoll = pollRepository.save(poll);
        return PollResponse.fromPoll(updatedPoll);
    }

    /**
     * Get voted option IDs for a given voter on a poll.
     */
    public List<String> getUserVotedOptions(String pollId, String voterName) {
        return voteRepository.findByPollIdAndVoterName(pollId, voterName).stream()
                .map(Vote::getOptionId)
                .toList();
    }

    /**
     * Check if a user has voted on a poll.
     */
    public boolean hasUserVoted(String pollId, String voterName) {
        return voteRepository.existsByPollIdAndVoterName(pollId, voterName);
    }

    /**
     * Get all votes for a specific poll (for displaying voter names).
     */
    public List<VoteResponse> getVotesForPoll(String pollId) {
        findPollOrThrow(pollId);
        return voteRepository.findByPollId(pollId).stream()
                .map(VoteResponse::fromVote)
                .toList();
    }

    /**
     * Get voters for a specific option.
     */
    public List<VoteResponse> getVotersForOption(String pollId, String optionId) {
        return voteRepository.findByPollIdAndOptionId(pollId, optionId).stream()
                .map(VoteResponse::fromVote)
                .toList();
    }

    /**
     * Toggle like on a poll (increment or decrement).
     */
    public PollResponse toggleLike(String pollId, boolean currentlyLiked) {
        Poll poll = findPollOrThrow(pollId);

        if (currentlyLiked) {
            poll.setLikesCount(Math.max(0, poll.getLikesCount() - 1));
        } else {
            poll.setLikesCount(poll.getLikesCount() + 1);
        }

        Poll updatedPoll = pollRepository.save(poll);
        return PollResponse.fromPoll(updatedPoll);
    }

    /**
     * Validate an admin token for a poll.
     */
    public boolean validateAdminToken(String pollId, String adminToken) {
        return pollRepository.findById(pollId)
                .map(poll -> adminToken.equals(poll.getAdminToken()))
                .orElse(false);
    }

    /**
     * Update a poll (requires valid admin token).
     */
    public PollResponse updatePoll(String pollId, UpdatePollRequest request) {
        Poll poll = findPollOrThrow(pollId);

        // Validate admin token
        if (!request.getAdminToken().equals(poll.getAdminToken())) {
            throw new UnauthorizedException("Invalid admin token");
        }

        // Update basic fields
        poll.setTitle(request.getTitle());
        poll.setDescription(request.getDescription() != null ? request.getDescription() : "");
        poll.setAnonymous(request.isAnonymous());
        poll.setAllowsMultipleVotes(request.isAllowsMultipleVotes());
        poll.setExpiresAt(request.getExpiresAt());
        poll.setAutoDeleteAfterExpiry(request.isAutoDeleteAfterExpiry());
        poll.setCreatedByName(request.getCreatorName());

        // Update options: preserve votes for existing options, add new ones, remove extras
        List<PollOption> existingOptions = poll.getOptions();
        List<PollOption> updatedOptions = new ArrayList<>();

        for (int i = 0; i < request.getOptions().size(); i++) {
            String newText = request.getOptions().get(i);
            int newOrder = i + 1;

            if (i < existingOptions.size()) {
                // Update existing option (preserve votes)
                PollOption existing = existingOptions.get(i);
                existing.setText(newText);
                existing.setOrder(newOrder);
                updatedOptions.add(existing);
            } else {
                // Add new option
                updatedOptions.add(PollOption.builder()
                        .id(UUID.randomUUID().toString())
                        .text(newText)
                        .votes(0)
                        .order(newOrder)
                        .build());
            }
        }

        poll.setOptions(updatedOptions);
        Poll savedPoll = pollRepository.save(poll);
        return PollResponse.fromPoll(savedPoll);
    }

    /**
     * Delete a poll and all associated data.
     */
    public void deletePoll(String pollId, String adminToken) {
        Poll poll = findPollOrThrow(pollId);

        if (!adminToken.equals(poll.getAdminToken())) {
            throw new UnauthorizedException("Invalid admin token");
        }

        // Delete associated votes and comments
        voteRepository.deleteByPollId(pollId);
        commentRepository.deleteByPollId(pollId);
        pollRepository.delete(poll);

        log.info("Poll {} deleted successfully", pollId);
    }

    /**
     * Delete a poll without admin token check (used by cleanup service).
     */
    public void deletePollInternal(String pollId) {
        voteRepository.deleteByPollId(pollId);
        commentRepository.deleteByPollId(pollId);
        pollRepository.deleteById(pollId);
        log.info("Poll {} cleaned up (internal)", pollId);
    }

    private Poll findPollOrThrow(String pollId) {
        return pollRepository.findById(pollId)
                .orElseThrow(() -> new ResourceNotFoundException("Poll not found: " + pollId));
    }

    private String generateAdminToken() {
        StringBuilder sb = new StringBuilder(32);
        for (int i = 0; i < 32; i++) {
            sb.append(TOKEN_CHARS.charAt(SECURE_RANDOM.nextInt(TOKEN_CHARS.length())));
        }
        return sb.toString();
    }
}
