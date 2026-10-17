package io.github.jakiwz.aether.audit.domain;

import io.github.jakiwz.aether.audit.persistence.AuditEventEntity;
import io.github.jakiwz.aether.audit.persistence.AuditEventRepository;
import io.github.jakiwz.aether.shared.web.CorrelationId;
import jakarta.servlet.http.HttpServletRequest;
import java.net.InetAddress;
import java.net.UnknownHostException;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.time.temporal.ChronoUnit;
import java.util.Map;
import java.util.Optional;
import java.util.regex.Pattern;
import org.jspecify.annotations.Nullable;
import org.springframework.security.authentication.AnonymousAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;
import tools.jackson.databind.json.JsonMapper;

/**
 * Appends to the audit trail (BR-012, IAM-008, UC-07; ADR-0014), separate from the application log.
 * An event joins the caller's transaction, so it is stored if and only if the change it describes is.
 * Each event carries the account it is attributed to, the client address and the request's
 * correlation id. Callers pass only what an auditor needs: never passwords or what an unknown
 * user typed as a username (OWASP Logging Cheat Sheet, data to exclude).
 */
@Service
public class AuditTrail {

    /** What a servlet container reports as a client address: an IPv4 or IPv6 literal, never a name. */
    private static final Pattern IP_LITERAL = Pattern.compile("[0-9A-Fa-f:.]{2,45}");

    private final AuditEventRepository events;
    private final JsonMapper json;

    AuditTrail(AuditEventRepository events, JsonMapper json) {
        this.events = events;
        this.json = json;
    }

    /** Records an event attributed to the user authenticated for the current request. */
    @Transactional
    public void record(AuditAction action, String entityType, String entityId, @Nullable Map<String, ?> newValue) {
        Long accountId = currentUsername().flatMap(events::findAccountId).orElse(null);
        recordFor(accountId, action, entityType, entityId, newValue, null);
    }

    /**
     * Records an event attributed to the given account, for the moments with no authenticated user
     * yet (a login) or any more (a logout); {@code null} when no account is known.
     */
    @Transactional
    public void recordFor(@Nullable Long accountId, AuditAction action, String entityType, String entityId,
            @Nullable Map<String, ?> newValue, @Nullable String reason) {
        events.save(new AuditEventEntity(accountId, action.name(), entityType, entityId,
                newValue == null ? null : json.writeValueAsString(newValue), reason, clientAddress(),
                CorrelationId.current().orElse(null),
                OffsetDateTime.now(ZoneOffset.UTC).truncatedTo(ChronoUnit.MICROS)));
    }

    private static Optional<String> currentUsername() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !authentication.isAuthenticated()
                || authentication instanceof AnonymousAuthenticationToken) {
            return Optional.empty();
        }
        return Optional.of(authentication.getName());
    }

    private static @Nullable InetAddress clientAddress() {
        if (!(RequestContextHolder.getRequestAttributes() instanceof ServletRequestAttributes attributes)) {
            return null;
        }
        HttpServletRequest request = attributes.getRequest();
        String address = request.getRemoteAddr();
        if (address == null || !IP_LITERAL.matcher(address).matches()) {
            return null;
        }
        try {
            return InetAddress.getByName(address); // a literal: parsed, no name lookup
        } catch (UnknownHostException e) {
            return null;
        }
    }
}
