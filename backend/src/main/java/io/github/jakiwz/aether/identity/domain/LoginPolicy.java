package io.github.jakiwz.aether.identity.domain;

import jakarta.validation.constraints.Min;
import java.time.Duration;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.validation.annotation.Validated;

/**
 * Failed-login policy (IAM-008), configurable per environment: after {@code maxFailedAttempts}
 * consecutive failures the account is locked for {@code lockDuration}.
 */
@Validated
@ConfigurationProperties("aether.security.login")
public record LoginPolicy(@Min(1) int maxFailedAttempts, Duration lockDuration) {

    public LoginPolicy {
        if (maxFailedAttempts == 0) {
            maxFailedAttempts = 5;
        }
        if (lockDuration == null) {
            lockDuration = Duration.ofMinutes(15);
        }
    }
}
