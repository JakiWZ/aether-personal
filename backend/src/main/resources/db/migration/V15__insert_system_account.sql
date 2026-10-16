-- Technical account recorded as the author of changes until authentication exists (ADR-0008).
-- `created_by` / `changed_by` columns are NOT NULL (BR-012), so every write needs an account.
-- The account is disabled and its hash matches no password: nobody can log in with it.

INSERT INTO person(first_name, last_name, status)
VALUES ('AETHER', 'System', 'ACTIVE');

INSERT INTO user_account(id_person, username, password_hash, account_status, disabled_at)
SELECT p.id_person, 'system', 'SYSTEM-ACCOUNT-NO-LOGIN', 'DISABLED', now()
FROM person p
WHERE p.first_name = 'AETHER' AND p.last_name = 'System' AND p.email IS NULL;
