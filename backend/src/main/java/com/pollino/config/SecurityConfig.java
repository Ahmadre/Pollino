package com.pollino.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.Arrays;
import java.util.List;

@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Value("${pollino.cors.allowed-origins:*}")
    private String allowedOrigins;

    @Value("${pollino.api.api-key}")
    private String apiKey;

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
                .csrf(AbstractHttpConfigurer::disable)
                .cors(cors -> cors.configurationSource(corsConfigurationSource()))
                .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .authorizeHttpRequests(auth -> auth
                        // Public endpoints - read operations
                        .requestMatchers(HttpMethod.GET, "/api/polls/**").permitAll()
                        .requestMatchers(HttpMethod.GET, "/api/comments/**").permitAll()
                        // Public endpoints - vote and comment creation
                        .requestMatchers(HttpMethod.POST, "/api/polls/*/vote").permitAll()
                        .requestMatchers(HttpMethod.POST, "/api/polls").permitAll()
                        .requestMatchers(HttpMethod.POST, "/api/polls/*/like").permitAll()
                        .requestMatchers(HttpMethod.POST, "/api/comments/**").permitAll()
                        // Public endpoints - comment edit/delete (ownership checked in service)
                        .requestMatchers(HttpMethod.PUT, "/api/comments/**").permitAll()
                        .requestMatchers(HttpMethod.DELETE, "/api/comments/**").permitAll()
                        // Poll update/delete (admin token checked in service)
                        .requestMatchers(HttpMethod.PUT, "/api/polls/**").permitAll()
                        .requestMatchers(HttpMethod.DELETE, "/api/polls/**").permitAll()
                        // Admin token validation
                        .requestMatchers(HttpMethod.POST, "/api/polls/*/validate-token").permitAll()
                        // Health & actuator
                        .requestMatchers("/actuator/**").permitAll()
                        // Everything else requires API key
                        .anyRequest().authenticated()
                )
                .addFilterBefore(new ApiKeyAuthFilter(apiKey), UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();

        if ("*".equals(allowedOrigins)) {
            configuration.setAllowedOriginPatterns(List.of("*"));
        } else {
            configuration.setAllowedOrigins(Arrays.asList(allowedOrigins.split(",")));
        }

        configuration.setAllowedMethods(Arrays.asList("GET", "POST", "PUT", "DELETE", "OPTIONS"));
        configuration.setAllowedHeaders(Arrays.asList("*"));
        configuration.setAllowCredentials(true);
        configuration.setMaxAge(3600L);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);
        return source;
    }
}
