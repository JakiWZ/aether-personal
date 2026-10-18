package io.github.jakiwz.aether.audit.domain;

/** What an audit event records (BR-012, IAM-008). Stored by name in {@code audit_event.action}. */
public enum AuditAction {
    LOGIN_SUCCEEDED,
    /** Wrong password or unknown username. */
    LOGIN_FAILED,
    /** Right or wrong password on a locked or inactive account. */
    LOGIN_REFUSED,
    /** Too many failed logins: the account is locked for the configured time. */
    ACCOUNT_LOCKED,
    LOGOUT,
    MISSION_CREATED,
    CREW_MEMBER_REGISTERED,
    RESOURCE_CREATED,
    RESOURCE_ACTIVATED,
    RESOURCE_DEACTIVATED
}
