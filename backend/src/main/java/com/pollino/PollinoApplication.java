package com.pollino;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.scheduling.annotation.EnableAsync;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
@EnableAsync
public class PollinoApplication {

    public static void main(String[] args) {
        SpringApplication.run(PollinoApplication.class, args);
    }

    // Add a CommandLineRunner which logs if Rate-Limiter is enabled or disabled. If Rate-Limiter is disabled, log a warning that this should not be used in production.
    // This is useful for debugging and to confirm that the environment variable is being read correctly.
    // Also log the configured RPM values for general requests and vote requests.
    @Bean
    public CommandLineRunner logRateLimiterConfig(@Value("${rate-limit.enabled:true}") boolean rateLimitEnabled,
                                               @Value("${rate-limit.requests-per-minute:200}") int rpm,
                                               @Value("${rate-limit.vote-requests-per-minute:20}") int voteRpm) {
        return args -> {
            if (rateLimitEnabled) {
                System.out.println("--- Rate-Limiter is ENABLED ---");
                System.out.println("--> General RPM: " + rpm);
                System.out.println("--> Vote RPM: " + voteRpm);
            } else {
                System.out.println("--- Rate-Limiter is DISABLED ---");
                System.out.println("--> This should not be used in production!");
            }
        };
    }

}
