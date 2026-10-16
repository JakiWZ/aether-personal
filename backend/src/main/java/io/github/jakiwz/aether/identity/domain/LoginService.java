package io.github.jakiwz.aether.identity.domain;

import io.github.jakiwz.aether.identity.persistence.UserAccountEntity;
import io.github.jakiwz.aether.identity.persistence.UserAccountRepository;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.time.temporal.ChronoUnit;
import java.util.Locale;
import java.util.Optional;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Checks a username and password (IAM-002) without telling the caller why a login failed:
 * unknown user, wrong password, locked or inactive account all look the same, and a password
 * hash is computed in every case so response times do not reveal which (OWASP ASVS V6).
 */
@Service
public class LoginService {

    private static final Logger log = LoggerFactory.getLogger(LoginService.class);
    private static final String ACTIVE = "ACTIVE";

    private final UserAccountRepository accounts;
    private final PasswordEncoder encoder;
    private final LoginPolicy policy;
    /** Hash checked when the username is unknown, to spend the same time as for a real account. */
    private final String unknownUserHash;

    LoginService(UserAccountRepository accounts, PasswordEncoder encoder, LoginPolicy policy) {
        this.accounts = accounts;
        this.encoder = encoder;
        this.policy = policy;
        this.unknownUserHash = encoder.encode("no account has this password");
    }

    /**
     * Records the outcome on the account and returns the user when the login succeeds. Commits in
     * both cases, so failed attempts are counted even though the caller then rejects the request.
     */
    @Transactional
    public Optional<AuthenticatedUser> login(String username, String password) {
        OffsetDateTime now = OffsetDateTime.now(ZoneOffset.UTC).truncatedTo(ChronoUnit.MICROS);
        Optional<UserAccountEntity> found = accounts.findByUsername(username.trim().toLowerCase(Locale.ROOT));
        if (found.isEmpty()) {
            encoder.matches(password, unknownUserHash);
            log.info("Login failed: unknown account");
            return Optional.empty();
        }
        UserAccountEntity account = found.get();
        boolean passwordMatches = encoder.matches(password, account.getPasswordHash());
        if (!ACTIVE.equals(account.getAccountStatus()) || isLocked(account, now)) {
            log.info("Login refused for account {}: status {}, locked until {}", account.getId(),
                    account.getAccountStatus(), account.getLockedUntil());
            return Optional.empty();
        }
        if (!passwordMatches) {
            account.recordFailedLogin(now, policy.maxFailedAttempts(), now.plus(policy.lockDuration()));
            log.info("Login failed for account {}: wrong password", account.getId());
            return Optional.empty();
        }
        account.recordSuccessfulLogin(now);
        if (encoder.upgradeEncoding(account.getPasswordHash())) {
            account.upgradePasswordHash(encoder.encode(password), now);
        }
        return Optional.of(new AuthenticatedUser(account.getUsername(),
                accounts.findPersonName(account.getPersonId()).orElse(account.getUsername()),
                accounts.findRoleCodes(account.getId()), accounts.findPermissionCodes(account.getId())));
    }

    private static boolean isLocked(UserAccountEntity account, OffsetDateTime now) {
        return account.getLockedUntil() != null && account.getLockedUntil().isAfter(now);
    }
}
