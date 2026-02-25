package com.pollino.service;

import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.thymeleaf.TemplateEngine;
import org.thymeleaf.context.Context;

@Slf4j
@Service
@RequiredArgsConstructor
public class EmailService {

    private final JavaMailSender mailSender;
    private final TemplateEngine templateEngine;

    @Value("${pollino.mail.sender-address:Pollino <poll@ahmadre.com>}")
    private String senderAddress;

    @Value("${pollino.mail.enabled:true}")
    private boolean mailEnabled;

    /**
     * Send the poll creation confirmation email with admin URL and poll URL.
     * Runs async to not block the poll creation response.
     */
    @Async
    public void sendPollCreatedEmail(String recipientEmail, String pollTitle,
                                      String pollUrl, String adminUrl) {
        if (!mailEnabled) {
            log.info("Mail sending disabled. Skipping email to {}", recipientEmail);
            return;
        }

        try {
            Context context = new Context();
            context.setVariable("pollTitle", pollTitle);
            context.setVariable("pollUrl", pollUrl);
            context.setVariable("adminUrl", adminUrl);
            context.setVariable("year", java.time.Year.now().getValue());

            String htmlContent = templateEngine.process("poll-created", context);

            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");

            helper.setFrom(senderAddress);
            helper.setTo(recipientEmail);
            helper.setSubject("Deine Umfrage wurde erstellt: " + pollTitle);
            helper.setText(htmlContent, true);

            mailSender.send(message);
            log.info("Poll created email sent successfully to {}", recipientEmail);

        } catch (MessagingException e) {
            log.error("Failed to send poll created email to {}: {}", recipientEmail, e.getMessage(), e);
        } catch (Exception e) {
            log.error("Unexpected error sending email to {}: {}", recipientEmail, e.getMessage(), e);
        }
    }
}
