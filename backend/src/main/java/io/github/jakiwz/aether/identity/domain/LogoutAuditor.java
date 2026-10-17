package io.github.jakiwz.aether.identity.domain;

import io.github.jakiwz.aether.audit.domain.AuditAction;
import io.github.jakiwz.aether.audit.domain.AuditTrail;
import io.github.jakiwz.aether.identity.persistence.UserAccountRepository;
import org.springframework.context.event.EventListener;
import org.springframework.security.authentication.event.LogoutSuccessEvent;
import org.springframework.stereotype.Component;

/**
 * Records sign-outs (IAM-007, ADR-0014). Spring Security's logout filter publishes the event after
 * the session is invalidated, so the account is passed explicitly rather than read from the request.
 */
@Component
class LogoutAuditor {

    private final UserAccountRepository accounts;
    private final AuditTrail audit;

    LogoutAuditor(UserAccountRepository accounts, AuditTrail audit) {
        this.accounts = accounts;
        this.audit = audit;
    }

    @EventListener
    void onLogout(LogoutSuccessEvent event) {
        String username = event.getAuthentication().getName();
        accounts.findByUsername(username).ifPresent(account ->
                audit.recordFor(account.getId(), AuditAction.LOGOUT, "USER_ACCOUNT", username, null, null));
    }
}
