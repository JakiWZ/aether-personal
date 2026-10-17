package io.github.jakiwz.aether.identity.domain;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import io.github.jakiwz.aether.shared.error.TooManyLoginAttemptsException;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneId;
import java.time.ZoneOffset;
import org.junit.jupiter.api.Test;

class LoginRateLimiterTest {

    private final MutableClock clock = new MutableClock(Instant.parse("2026-10-17T10:00:00Z"));
    private final LoginRateLimiter limiter = new LoginRateLimiter(
            new LoginPolicy(5, Duration.ofMinutes(15), new LoginPolicy.RateLimit(3, Duration.ofMinutes(1), 2)),
            clock);

    @Test
    void letsTheAllowedAttemptsThroughThenRefusesWithTheTimeLeft() {
        for (int attempt = 1; attempt <= 3; attempt++) {
            limiter.acquire("10.0.0.1");
        }
        clock.advance(Duration.ofSeconds(20));

        assertThatThrownBy(() -> limiter.acquire("10.0.0.1"))
                .isInstanceOfSatisfying(TooManyLoginAttemptsException.class,
                        e -> assertThat(e.retryAfterSeconds()).isEqualTo(40));
    }

    @Test
    void keepsEveryAddressSeparate() {
        exhaust("10.0.0.1");

        assertThatCode(() -> limiter.acquire("10.0.0.2")).doesNotThrowAnyException();
    }

    @Test
    void startsAFreshWindowOnceTheOldOneHasEnded() {
        exhaust("10.0.0.1");
        clock.advance(Duration.ofMinutes(1));

        assertThatCode(() -> limiter.acquire("10.0.0.1")).doesNotThrowAnyException();
    }

    @Test
    void keepsRefusingWhileTheCallerInsists() {
        exhaust("10.0.0.1");
        for (int attempt = 0; attempt < 5; attempt++) {
            assertThatThrownBy(() -> limiter.acquire("10.0.0.1")).isInstanceOf(TooManyLoginAttemptsException.class);
        }
    }

    @Test
    void neverTracksMoreAddressesThanAllowed() {
        exhaust("10.0.0.1");
        exhaust("10.0.0.2");

        // the table is full: a third address is let through (the account lockout still applies)
        for (int attempt = 0; attempt < 5; attempt++) {
            assertThatCode(() -> limiter.acquire("10.0.0.3")).doesNotThrowAnyException();
        }
        // tracked addresses stay throttled
        assertThatThrownBy(() -> limiter.acquire("10.0.0.1")).isInstanceOf(TooManyLoginAttemptsException.class);
    }

    @Test
    void reclaimsEndedWindowsWhenTheTableIsFull() {
        exhaust("10.0.0.1");
        exhaust("10.0.0.2");
        clock.advance(Duration.ofMinutes(1));

        exhaust("10.0.0.3");

        assertThatThrownBy(() -> limiter.acquire("10.0.0.3")).isInstanceOf(TooManyLoginAttemptsException.class);
    }

    @Test
    void usesTheDocumentedDefaults() {
        LoginPolicy.RateLimit defaults = new LoginPolicy(0, null, null).rateLimit();

        assertThat(defaults).isEqualTo(new LoginPolicy.RateLimit(10, Duration.ofMinutes(1), 10_000));
    }

    private void exhaust(String address) {
        for (int attempt = 1; attempt <= 3; attempt++) {
            limiter.acquire(address);
        }
    }

    private static final class MutableClock extends Clock {

        private Instant now;

        MutableClock(Instant now) {
            this.now = now;
        }

        void advance(Duration duration) {
            now = now.plus(duration);
        }

        @Override
        public ZoneId getZone() {
            return ZoneOffset.UTC;
        }

        @Override
        public Clock withZone(ZoneId zone) {
            return this;
        }

        @Override
        public Instant instant() {
            return now;
        }
    }
}
