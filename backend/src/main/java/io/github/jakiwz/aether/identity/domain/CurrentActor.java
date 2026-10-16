package io.github.jakiwz.aether.identity.domain;

/**
 * The user account a write is attributed to (BR-012): the authenticated user of the request
 * (ADR-0012). The {@code system} account of ADR-0008 stays for future unattended jobs.
 */
public interface CurrentActor {

    /** Username of an existing {@code user_account}. */
    String username();
}
