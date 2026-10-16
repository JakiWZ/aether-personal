# Git Workflow obbligatorio

## Branch principale

`main` deve rappresentare sempre una versione integrabile.

Nessuno sviluppatore deve lavorare direttamente su `main`.

## Naming

```text
feature/<issue>-descrizione
fix/<issue>-descrizione
refactor/<issue>-descrizione
docs/<issue>-descrizione
```

Esempi:

```text
feature/31-create-mission
fix/44-prevent-double-rover-assignment
docs/12-update-er-diagram
```

## Commit

Convenzione consigliata:

```text
feat: add mission creation endpoint
fix: reject unavailable crew member
test: add resource transfer tests
docs: document mission state machine
refactor: extract validation service
chore: update dependencies
```

## Flusso

1. Prendere una Issue in `Ready`.
2. Assegnarsela.
3. Spostarla in `In Progress`.
4. Creare il branch.
5. Fare commit piccoli.
6. Push.
7. Aprire Pull Request.
8. Spostare la Story in `Code Review`.
9. Almeno un altro studente fa review.
10. Correggere eventuali richieste.
11. Verificare Acceptance Criteria.
12. Merge.
13. Chiudere Issue e spostarla in `Done`.

## Pull Request

La descrizione deve contenere:

```text
Closes #<issue>
```

## Regola di review

L'autore non approva la propria Pull Request.

Il reviewer controlla:
- correttezza;
- leggibilità;
- naming;
- duplicazione;
- query SQL;
- casi limite;
- NULL;
- validazioni;
- error handling;
- Acceptance Criteria;
- regressioni evidenti.
