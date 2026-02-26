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

    @Bean
    public CommandLineRunner checkAiServer(@Value("${pollino.ai.enabled:false}") boolean aiEnabled,
                                           @Value("${pollino.ai.base-url:http://localhost:1234/v1}") String aiBaseUrl) {
        return args -> {
            if (aiEnabled) {
                try {
                    java.net.http.HttpClient client = java.net.http.HttpClient.newHttpClient();
                    java.net.http.HttpRequest request = java.net.http.HttpRequest.newBuilder()
                            .uri(java.net.URI.create(aiBaseUrl.replace("/v1", ""))) // Assuming the AI server has a /health endpoint for checking availability
                            .timeout(java.time.Duration.ofSeconds(2))
                            .build();
                    java.net.http.HttpResponse<String> response = client.send(request, java.net.http.HttpResponse.BodyHandlers.ofString());
                    if (response.statusCode() == 200) {
                        System.out.println("--- AI Server is AVAILABLE ---");
                    } else {
                        System.out.println("--- AI Server is UNAVAILABLE (status code: " + response.statusCode() + ") ---");
                    }
                } catch (Exception e) {
                    System.out.println("--- AI Server is UNAVAILABLE (exception: " + e.getMessage() + ") ---");
                }
            } else {
                System.out.println("--- AI features are DISABLED ---");
            }
        };
    }

}
