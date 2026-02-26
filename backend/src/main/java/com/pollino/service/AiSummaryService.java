package com.pollino.service;

import com.pollino.model.AiSummary;
import com.pollino.model.FeedbackAnswer;
import com.pollino.model.FeedbackQuestion;
import com.pollino.model.FeedbackResponse;
import com.pollino.repository.AiSummaryRepository;
import com.pollino.repository.FeedbackResponseRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.time.Instant;
import java.util.*;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class AiSummaryService {

    private final AiSummaryRepository aiSummaryRepository;
    private final FeedbackResponseRepository feedbackResponseRepository;

    @Value("${pollino.ai.base-url:http://localhost:1234/v1}")
    private String aiBaseUrl;

    @Value("${pollino.ai.model:default}")
    private String aiModel;

    @Value("${pollino.ai.enabled:false}")
    private boolean aiEnabled;

    @Value("${pollino.ai.api-key:}")
    private String aiApiKey;

    /**
     * Get an existing AI summary for a poll, if available.
     */
    public Optional<AiSummary> getSummary(String pollId) {
        return aiSummaryRepository.findByPollId(pollId);
    }

    /**
     * Generate or regenerate the AI summary for a feedback poll asynchronously.
     */
    @Async
    public void generateSummaryAsync(String pollId, String pollTitle, List<FeedbackQuestion> questions) {
        if (!aiEnabled) {
            log.debug("AI summary generation is disabled");
            return;
        }

        try {
            List<FeedbackResponse> responses = feedbackResponseRepository.findByPollId(pollId);
            if (responses.isEmpty()) {
                log.debug("No feedback responses for poll {}, skipping summary generation", pollId);
                return;
            }

            String prompt = buildPrompt(pollTitle, questions, responses);
            String summaryText = callAiApi(prompt);

            if (summaryText != null && !summaryText.isBlank()) {
                // Upsert: delete old summary and save new one
                aiSummaryRepository.deleteByPollId(pollId);

                AiSummary summary = AiSummary.builder()
                        .pollId(pollId)
                        .summaryText(summaryText)
                        .responseCount(responses.size())
                        .generatedAt(Instant.now())
                        .build();

                aiSummaryRepository.save(summary);
                log.info("AI summary generated for poll {} with {} responses", pollId, responses.size());
            }
        } catch (Exception e) {
            log.error("Failed to generate AI summary for poll {}: {}", pollId, e.getMessage(), e);
        }
    }

    /**
     * Build a structured prompt from poll data and feedback responses.
     * Anonymised: no names, no participant count, no per-person listing.
     */
    private String buildPrompt(String pollTitle, List<FeedbackQuestion> questions, List<FeedbackResponse> responses) {
        // Build a map: questionId -> list of answers (text or selected options)
        Map<String, FeedbackQuestion> questionMap = new LinkedHashMap<>();
        for (FeedbackQuestion q : questions) {
            questionMap.put(q.getId(), q);
        }

        // Aggregate all answers grouped by question
        Map<String, List<String>> answersByQuestion = new LinkedHashMap<>();
        for (FeedbackQuestion q : questions) {
            answersByQuestion.put(q.getId(), new ArrayList<>());
        }
        for (FeedbackResponse resp : responses) {
            for (FeedbackAnswer answer : resp.getAnswers()) {
                List<String> bucket = answersByQuestion.get(answer.getQuestionId());
                if (bucket == null) continue;
                if (answer.getTextAnswer() != null && !answer.getTextAnswer().isBlank()) {
                    bucket.add(answer.getTextAnswer().trim());
                }
                if (answer.getSelectedOptions() != null && !answer.getSelectedOptions().isEmpty()) {
                    bucket.add(String.join(", ", answer.getSelectedOptions()));
                }
            }
        }

        StringBuilder sb = new StringBuilder();
        sb.append("Du bist ein hilfreicher Assistent, der Feedback-Umfragen analysiert.\n\n");
        sb.append("Erstelle eine prägnante, semantische Zusammenfassung der folgenden Feedback-Antworten auf Deutsch.\n\n");
        sb.append("WICHTIGE REGELN:\n");
        sb.append("- Nenne KEINE Namen von Personen\n");
        sb.append("- Erwähne NICHT die Anzahl der Teilnehmenden\n");
        sb.append("- Liste die einzelnen Antworten NICHT wörtlich auf\n");
        sb.append("- Fasse stattdessen Themen, Trends und Meinungen zusammen\n");
        sb.append("- Hebe Gemeinsamkeiten und Unterschiede in den Meinungen hervor\n");
        sb.append("- Verwende Markdown zur Formatierung (Überschriften, Fettdruck, Listen)\n");
        sb.append("- Verwende passende Emojis sparsam\n");
        sb.append("- Schreibe fließend und professionell\n\n");

        sb.append("## Umfrage: ").append(pollTitle).append("\n\n");

        for (FeedbackQuestion q : questions) {
            List<String> answers = answersByQuestion.getOrDefault(q.getId(), Collections.emptyList())
                    .stream().filter(a -> !a.isBlank()).collect(Collectors.toList());
            if (answers.isEmpty()) continue;

            sb.append("### Frage: ").append(q.getQuestionText()).append("\n");
            sb.append("Gesammelte Antworten:\n");
            for (String a : answers) {
                sb.append("- ").append(a).append("\n");
            }
            sb.append("\n");
        }

        sb.append("---\n\n");
        sb.append("Erstelle nun die Zusammenfassung. Sie darf maximal 1000 Zeichen lang sein. ");
        sb.append("Beginne direkt mit der inhaltlichen Zusammenfassung — ohne Einleitung wie \"Hier ist die Zusammenfassung\" o.ä. ");
        sb.append("Gliedere nach inhaltlichen Themen. Benenne keine Personen und keine Teilnehmerzahl.");

        return sb.toString();
    }

    /**
     * Call the OpenAI-compatible chat completions API.
     */
    private String callAiApi(String prompt) {
        RestTemplate restTemplate = new RestTemplate();

        String url = aiBaseUrl.endsWith("/") ? aiBaseUrl + "chat/completions" : aiBaseUrl + "/chat/completions";

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        if (aiApiKey != null && !aiApiKey.isBlank()) {
            headers.setBearerAuth(aiApiKey);
        }

        Map<String, Object> message = Map.of(
                "role", "user",
                "content", prompt
        );

        Map<String, Object> requestBody = new LinkedHashMap<>();
        requestBody.put("model", aiModel);
        requestBody.put("messages", List.of(message));
        requestBody.put("temperature", 0.7);
        requestBody.put("max_tokens", 4096);

        HttpEntity<Map<String, Object>> entity = new HttpEntity<>(requestBody, headers);

        try {
            ResponseEntity<Map> response = restTemplate.exchange(url, HttpMethod.POST, entity, Map.class);

            if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
                List<Map<String, Object>> choices = (List<Map<String, Object>>) response.getBody().get("choices");
                if (choices != null && !choices.isEmpty()) {
                    Map<String, Object> firstChoice = choices.get(0);
                    Map<String, Object> messageResponse = (Map<String, Object>) firstChoice.get("message");
                    if (messageResponse != null) {
                        return (String) messageResponse.get("content");
                    }
                }
            }
        } catch (Exception e) {
            log.error("AI API call failed: {}", e.getMessage(), e);
        }

        return null;
    }

    /**
     * Delete the AI summary for a poll.
     */
    public void deleteSummary(String pollId) {
        aiSummaryRepository.deleteByPollId(pollId);
    }
}
