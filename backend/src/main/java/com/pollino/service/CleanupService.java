package com.pollino.service;

import com.pollino.model.Poll;
import com.pollino.repository.PollRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.List;

/**
 * Scheduled service for automatic cleanup of expired polls.
 * Replaces the previous standalone pollino-cleanup container.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class CleanupService {

    private final PollRepository pollRepository;
    private final PollService pollService;

    @Value("${pollino.cleanup.enabled:true}")
    private boolean cleanupEnabled;

    /**
     * Runs on the configured cron schedule (default: every hour).
     * Deletes expired polls that have auto_delete_after_expiry enabled.
     */
    @Scheduled(cron = "${pollino.cleanup.cron:0 0 * * * *}")
    public void cleanupExpiredPolls() {
        if (!cleanupEnabled) {
            log.debug("Cleanup is disabled, skipping");
            return;
        }

        try {
            Instant now = Instant.now();
            List<Poll> expiredPolls = pollRepository.findExpiredAutoDeletePolls(now);

            if (expiredPolls.isEmpty()) {
                log.debug("No expired polls to clean up");
                return;
            }

            int deletedCount = 0;
            for (Poll poll : expiredPolls) {
                try {
                    pollService.deletePollInternal(poll.getId());
                    deletedCount++;
                } catch (Exception e) {
                    log.error("Failed to delete expired poll {}: {}", poll.getId(), e.getMessage());
                }
            }

            log.info("Cleanup completed: {} of {} expired polls deleted", deletedCount, expiredPolls.size());
        } catch (Exception e) {
            log.error("Error during cleanup execution: {}", e.getMessage(), e);
        }
    }

    /**
     * Manual trigger for cleanup (can be called via admin API).
     */
    public int runManualCleanup() {
        Instant now = Instant.now();
        List<Poll> expiredPolls = pollRepository.findExpiredAutoDeletePolls(now);

        int deletedCount = 0;
        for (Poll poll : expiredPolls) {
            try {
                pollService.deletePollInternal(poll.getId());
                deletedCount++;
            } catch (Exception e) {
                log.error("Failed to delete expired poll {}: {}", poll.getId(), e.getMessage());
            }
        }

        log.info("Manual cleanup completed: {} polls deleted", deletedCount);
        return deletedCount;
    }
}
