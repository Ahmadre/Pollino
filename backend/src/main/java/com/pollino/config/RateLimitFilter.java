package com.pollino.config;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicLong;

/**
 * Simple in-memory rate limiter based on client IP.
 * CORS preflight (OPTIONS) and actuator requests are excluded.
 * For production with multiple instances, use Redis-based rate limiting.
 */
@Component
public class RateLimitFilter extends OncePerRequestFilter {

    @Value("${rate-limit.enabled:true}")
    private boolean rateLimitEnabled;

    @Value("${rate-limit.requests-per-minute:200}")
    private int requestsPerMinute;

    @Value("${rate-limit.vote-requests-per-minute:20}")
    private int voteRequestsPerMinute;

    private final Map<String, RateLimitBucket> buckets = new ConcurrentHashMap<>();

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {
        // Rate limiting disabled (e.g. local dev mode)
        if (!rateLimitEnabled) {
            filterChain.doFilter(request, response);
            return;
        }

        // Skip OPTIONS preflight requests (CORS handshake — not real API traffic)
        if (HttpMethod.OPTIONS.matches(request.getMethod())) {
            filterChain.doFilter(request, response);
            return;
        }

        // Skip actuator / health endpoints
        String path = request.getRequestURI();
        if (path.startsWith("/actuator")) {
            filterChain.doFilter(request, response);
            return;
        }

        String clientIp = getClientIp(request);
        boolean isVoteRequest = path.contains("/vote");
        int limit = isVoteRequest ? voteRequestsPerMinute : requestsPerMinute;
        String bucketKey = clientIp + (isVoteRequest ? ":vote" : ":general");

        RateLimitBucket bucket = buckets.computeIfAbsent(bucketKey,
                k -> new RateLimitBucket(limit));

        if (!bucket.tryConsume()) {
            response.setStatus(HttpStatus.TOO_MANY_REQUESTS.value());
            response.setContentType("application/json");
            response.getWriter().write("{\"error\":\"Rate limit exceeded. Please try again later.\"}");
            return;
        }

        filterChain.doFilter(request, response);
    }

    private String getClientIp(HttpServletRequest request) {
        String xForwardedFor = request.getHeader("X-Forwarded-For");
        if (xForwardedFor != null && !xForwardedFor.isEmpty()) {
            return xForwardedFor.split(",")[0].trim();
        }
        String xRealIp = request.getHeader("X-Real-IP");
        if (xRealIp != null && !xRealIp.isEmpty()) {
            return xRealIp;
        }
        return request.getRemoteAddr();
    }

    /**
     * Thread-safe token bucket rate limiter with per-minute refill.
     * Uses AtomicLong for lastRefillTime to ensure atomic compare-and-set.
     */
    private static class RateLimitBucket {
        private final int maxTokens;
        private final AtomicInteger tokens;
        private final AtomicLong lastRefillTime;

        RateLimitBucket(int maxTokens) {
            this.maxTokens = maxTokens;
            this.tokens = new AtomicInteger(maxTokens);
            this.lastRefillTime = new AtomicLong(System.currentTimeMillis());
        }

        boolean tryConsume() {
            refillIfNeeded();
            // Allow brief bursting: never let tokens go below -10
            // to avoid a deep negative hole that takes long to climb out of
            int current = tokens.get();
            if (current <= 0) return false;
            return tokens.decrementAndGet() >= 0;
        }

        private void refillIfNeeded() {
            long now = System.currentTimeMillis();
            long last = lastRefillTime.get();
            if (now - last > 60_000 && lastRefillTime.compareAndSet(last, now)) {
                tokens.set(maxTokens);
            }
        }
    }
}
