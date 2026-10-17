package io.github.jakiwz.aether.identity.domain;

import io.github.jakiwz.aether.shared.error.TooManyLoginAttemptsException;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

/**
 * Throttles login attempts per client address (ADR-0012), so that one host cannot spray a password
 * over many accounts or make the server compute Argon2id hashes without end. Fixed windows kept in
 * memory: enough for one instance; several instances would each apply the limit on their own.
 * Every attempt counts, successful or not, and a refused one never reaches the password check.
 */
@Component
public class LoginRateLimiter {

    private static final Logger log = LoggerFactory.getLogger(LoginRateLimiter.class);

    private final LoginPolicy.RateLimit policy;
    private final Clock clock;
    private final Map<String, Window> windows = new ConcurrentHashMap<>();

    @Autowired
    LoginRateLimiter(LoginPolicy policy) {
        this(policy, Clock.systemUTC());
    }

    LoginRateLimiter(LoginPolicy policy, Clock clock) {
        this.policy = policy.rateLimit();
        this.clock = clock;
    }

    /**
     * Counts an attempt from {@code address}.
     *
     * @throws TooManyLoginAttemptsException when the address has used up its window
     */
    public void acquire(String address) {
        Instant now = clock.instant();
        if (!windows.containsKey(address) && windows.size() >= policy.maxTrackedAddresses()) {
            windows.values().removeIf(window -> window.hasEnded(now));
            if (windows.size() >= policy.maxTrackedAddresses()) {
                log.warn("Login rate limit table full ({} addresses): not throttling a new address",
                        windows.size());
                return;
            }
        }
        Window window = windows.compute(address, (key, current) -> current == null || current.hasEnded(now)
                ? new Window(now.plus(policy.window()), 1)
                : new Window(current.endsAt(), current.attempts() + 1));
        if (window.attempts() > policy.maxAttempts()) {
            Duration retryAfter = Duration.between(now, window.endsAt());
            log.warn("Login attempts from {} throttled for {}s", address, retryAfter.toSeconds());
            throw new TooManyLoginAttemptsException(retryAfter);
        }
    }

    private record Window(Instant endsAt, int attempts) {

        boolean hasEnded(Instant now) {
            return !now.isBefore(endsAt);
        }
    }
}
