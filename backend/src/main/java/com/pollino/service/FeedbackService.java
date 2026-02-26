package com.pollino.service;

import com.pollino.dto.*;
import com.pollino.exception.BusinessException;
import com.pollino.exception.ResourceNotFoundException;
import com.pollino.exception.UnauthorizedException;
import com.pollino.model.*;
import com.pollino.repository.FeedbackResponseRepository;
import com.pollino.repository.PollRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.*;
import java.time.Instant;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class FeedbackService {

    private final PollRepository pollRepository;
    private final FeedbackResponseRepository feedbackResponseRepository;
    private final AiSummaryService aiSummaryService;

    /**
     * Submit feedback for a feedback poll.
     */
    public FeedbackResponseDto submitFeedback(String pollId, SubmitFeedbackRequest request) {
        Poll poll = findFeedbackPollOrThrow(pollId);

        // Check if poll is expired
        if (poll.getExpiresAt() != null && poll.getExpiresAt().isBefore(Instant.now())) {
            throw new BusinessException("This feedback poll has expired");
        }

        // Check if poll is active
        if (!poll.isActive()) {
            throw new BusinessException("This feedback poll is no longer active");
        }

        // Check for duplicate submissions by respondent name
        if (request.getRespondentName() != null && !request.getRespondentName().isBlank()) {
            if (feedbackResponseRepository.existsByPollIdAndRespondentName(pollId, request.getRespondentName().trim())) {
                throw new BusinessException("You have already submitted feedback for this poll");
            }
        }

        // Validate answers against poll questions
        Map<String, FeedbackQuestion> questionMap = new HashMap<>();
        for (FeedbackQuestion q : poll.getFeedbackQuestions()) {
            questionMap.put(q.getId(), q);
        }

        List<FeedbackAnswer> answers = new ArrayList<>();
        for (SubmitFeedbackRequest.FeedbackAnswerRequest answerReq : request.getAnswers()) {
            FeedbackQuestion question = questionMap.get(answerReq.getQuestionId());
            if (question == null) {
                throw new BusinessException("Question " + answerReq.getQuestionId() + " does not belong to this poll");
            }

            validateAnswer(question, answerReq);

            answers.add(FeedbackAnswer.builder()
                    .questionId(answerReq.getQuestionId())
                    .textAnswer(answerReq.getTextAnswer())
                    .selectedOptions(answerReq.getSelectedOptions())
                    .build());
        }

        FeedbackResponse feedbackResponse = FeedbackResponse.builder()
                .pollId(pollId)
                .respondentName(request.getRespondentName() != null ? request.getRespondentName().trim() : null)
                .answers(answers)
                .build();

        FeedbackResponse saved = feedbackResponseRepository.save(feedbackResponse);

        // Update feedback response count on the poll
        long count = feedbackResponseRepository.countByPollId(pollId);
        poll.setFeedbackResponseCount((int) count);
        pollRepository.save(poll);

        // Trigger AI summary regeneration asynchronously
        aiSummaryService.generateSummaryAsync(pollId, poll.getTitle(), poll.getFeedbackQuestions());

        log.info("Feedback submitted for poll {} by {}", pollId,
                request.getRespondentName() != null ? request.getRespondentName() : "anonymous");

        return FeedbackResponseDto.fromFeedbackResponse(saved);
    }

    /**
     * Get all feedback results for a poll (admin only, requires admin token).
     */
    public FeedbackResultsResponse getFeedbackResults(String pollId, String adminToken) {
        Poll poll = findFeedbackPollOrThrow(pollId);

        // Validate admin token
        if (!adminToken.equals(poll.getAdminToken())) {
            throw new UnauthorizedException("Invalid admin token");
        }

        List<FeedbackResponse> responses = feedbackResponseRepository.findByPollId(pollId);

        List<FeedbackResultsResponse.QuestionSummary> questionSummaries = poll.getFeedbackQuestions().stream()
                .map(q -> FeedbackResultsResponse.QuestionSummary.builder()
                        .questionId(q.getId())
                        .questionText(q.getQuestionText())
                        .questionType(q.getQuestionType().name())
                        .options(q.getOptions())
                        .order(q.getOrder())
                        .build())
                .toList();

        List<FeedbackResponseDto> responseDtos = responses.stream()
                .map(FeedbackResponseDto::fromFeedbackResponse)
                .toList();

        return FeedbackResultsResponse.builder()
                .pollId(pollId)
                .pollTitle(poll.getTitle())
                .responseCount(responses.size())
                .questions(questionSummaries)
                .responses(responseDtos)
                .build();
    }

    /**
     * Get the AI summary publicly (no admin token required).
     * Only returns the text if a summary has already been generated.
     */
    public AiSummaryResponse getPublicAiSummary(String pollId) {
        findFeedbackPollOrThrow(pollId); // validates it's a FEEDBACK poll

        Optional<AiSummary> summary = aiSummaryService.getSummary(pollId);

        if (summary.isPresent()) {
            AiSummary s = summary.get();
            return AiSummaryResponse.builder()
                    .summaryText(s.getSummaryText())
                    .responseCount(s.getResponseCount())
                    .generatedAt(s.getGeneratedAt())
                    .available(true)
                    .generating(aiSummaryService.isGenerating(pollId))
                    .build();
        }

        return AiSummaryResponse.builder()
                .available(false)
                .generating(aiSummaryService.isGenerating(pollId))
                .build();
    }

    /**
     * Get the AI summary for a feedback poll (admin only).
     */
    public AiSummaryResponse getAiSummary(String pollId, String adminToken) {
        Poll poll = findFeedbackPollOrThrow(pollId);

        // Validate admin token
        if (!adminToken.equals(poll.getAdminToken())) {
            throw new UnauthorizedException("Invalid admin token");
        }

        Optional<AiSummary> summary = aiSummaryService.getSummary(pollId);

        if (summary.isPresent()) {
            AiSummary s = summary.get();
            return AiSummaryResponse.builder()
                    .summaryText(s.getSummaryText())
                    .responseCount(s.getResponseCount())
                    .generatedAt(s.getGeneratedAt())
                    .available(true)
                    .generating(aiSummaryService.isGenerating(pollId))
                    .build();
        }

        return AiSummaryResponse.builder()
                .available(false)
                .generating(aiSummaryService.isGenerating(pollId))
                .build();
    }

    /**
     * Regenerate AI summary (admin only).
     */
    public void regenerateAiSummary(String pollId, String adminToken) {
        Poll poll = findFeedbackPollOrThrow(pollId);

        if (!adminToken.equals(poll.getAdminToken())) {
            throw new UnauthorizedException("Invalid admin token");
        }

        aiSummaryService.generateSummaryAsync(pollId, poll.getTitle(), poll.getFeedbackQuestions());
    }

    /**
     * Check if a respondent has already submitted feedback.
     */
    public boolean hasResponded(String pollId, String respondentName) {
        return feedbackResponseRepository.existsByPollIdAndRespondentName(pollId, respondentName);
    }

    /**
     * Delete all feedback data for a poll.
     */
    public void deleteFeedbackData(String pollId) {
        feedbackResponseRepository.deleteByPollId(pollId);
        aiSummaryService.deleteSummary(pollId);
        log.info("Feedback data deleted for poll {}", pollId);
    }

    private void validateAnswer(FeedbackQuestion question, SubmitFeedbackRequest.FeedbackAnswerRequest answer) {
        switch (question.getQuestionType()) {
            case FREE_TEXT:
                if (answer.getTextAnswer() == null || answer.getTextAnswer().isBlank()) {
                    throw new BusinessException("Text answer is required for question: " + question.getQuestionText());
                }
                if (answer.getTextAnswer().length() > 5000) {
                    throw new BusinessException("Text answer must not exceed 5000 characters");
                }
                break;

            case SINGLE_CHOICE:
                if (answer.getSelectedOptions() == null || answer.getSelectedOptions().size() != 1) {
                    throw new BusinessException("Exactly one option must be selected for question: " + question.getQuestionText());
                }
                validateOptionsExist(question, answer.getSelectedOptions());
                break;

            case MULTIPLE_CHOICE:
                if (answer.getSelectedOptions() == null || answer.getSelectedOptions().isEmpty()) {
                    throw new BusinessException("At least one option must be selected for question: " + question.getQuestionText());
                }
                validateOptionsExist(question, answer.getSelectedOptions());
                break;
        }
    }

    private void validateOptionsExist(FeedbackQuestion question, List<String> selectedOptions) {
        Set<String> validOptions = new HashSet<>(question.getOptions());
        for (String opt : selectedOptions) {
            if (!validOptions.contains(opt)) {
                throw new BusinessException("Invalid option '" + opt + "' for question: " + question.getQuestionText());
            }
        }
    }

    private Poll findFeedbackPollOrThrow(String pollId) {
        Poll poll = pollRepository.findById(pollId)
                .orElseThrow(() -> new ResourceNotFoundException("Poll not found: " + pollId));

        if (poll.getPollType() != PollType.FEEDBACK) {
            throw new BusinessException("Poll " + pollId + " is not a feedback poll");
        }

        return poll;
    }
}
