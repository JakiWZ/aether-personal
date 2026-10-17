package io.github.jakiwz.aether.identity.domain;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Min;
import java.time.Duration;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.validation.annotation.Validated;

/**
 * Login protections, configurable per environment (ADR-0012):
 * <ul>
 *   <li>after {@code maxFailedAttempts} consecutive failures the account is locked for
 *       {@code lockDuration} (IAM-008);</li>
 *   <li>one client address may try at most {@code rateLimit.maxAttempts} logins per
 *       {@code rateLimit.window}, whatever the accounts (OWASP Authentication Cheat Sheet).</li>
 * </ul>
 */
@Validated
@ConfigurationProperties("aether.security.login")
public record LoginPolicy(@Min(1) int maxFailedAttempts, Duration lockDuration, @Valid RateLimit rateLimit) {

    public LoginPolicy {
        if (maxFailedAttempts == 0) {
            maxFailedAttempts = 5;
        }
        if (lockDuration == null) {
            lockDuration = Duration.ofMinutes(15);
        }
        if (rateLimit == null) {
            rateLimit = new RateLimit(0, null, 0);
        }
    }

    /**
     * Per-address throttling. {@code maxTrackedAddresses} bounds the memory used: when that many
     * addresses are inside their window, new ones are let through to the account lockout.
     */
    public record RateLimit(@Min(1) int maxAttempts, Duration window, @Min(1) int maxTrackedAddresses) {

        public RateLimit {
            if (maxAttempts == 0) {
                maxAttempts = 10;
            }
            if (window == null) {
                window = Duration.ofMinutes(1);
            }
            if (maxTrackedAddresses == 0) {
                maxTrackedAddresses = 10_000;
            }
        }
    }
}
