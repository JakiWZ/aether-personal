# Git Workflow

Modello: **GitHub Flow** con branch di breve durata e squash merge.

## Branch principale

`main` rappresenta sempre una versione integrabile e dimostrabile.

- Nessun push diretto su `main`: ogni modifica arriva tramite Pull Request.
- La CI deve essere verde prima del merge.
- Merge con **squash**: un commit per PR, con messaggio Conventional Commit e riferimento alla Issue.
- Il branch viene eliminato dopo il merge.

## Naming dei branch

```text
feature/<issue>-descrizione
fix/<issue>-descrizione
refactor/<issue>-descrizione
docs/<issue>-descrizione
chore/<issue>-descrizione
```

Esempi:

```text
feature/22-create-mission
fix/31-prevent-double-rover-assignment
docs/60-engineering-handbook
```

## Commit — Conventional Commits

Formato: `<type>(<scope>): <descrizione all'imperativo, in inglese>`

| Type | Uso |
|------|-----|
| `feat` | nuova funzionalità |
| `fix` | correzione di un bug |
| `test` | aggiunta/modifica di test |
| `docs` | sola documentazione |
| `refactor` | ristrutturazione senza cambiare il comportamento |
| `chore` / `build` / `ci` | manutenzione, dipendenze, pipeline |

Scope consigliati: `crew`, `colonies`, `missions`, `fleet`, `maintenance`, `inventory`,
`incidents`, `dashboard`, `db`, `api`, `ui`, `ci`, `docs`.

```text
feat(missions): add mission creation endpoint
fix(crew): reject inactive crew member assignment
test(inventory): cover rollback on failed transfer
docs(adr): record database schema baseline
```

Commit piccoli e coerenti: ogni commit dovrebbe compilare.

## Flusso

1. Prendere una Issue in `Ready` e assegnarsela.
2. Aggiornare `main` e creare il branch.
3. Sviluppare con commit piccoli; push frequente.
4. Aprire una **Draft PR** appena possibile, compilando il template e inserendo `Closes #<issue>`.
5. Eseguire localmente build e test; auto-revisionare il diff.
6. Segnare la PR come *Ready for review* quando la CI è verde.
7. Almeno un reviewer diverso dall'autore (o una review automatica documentata se si lavora da soli).
8. Risolvere i commenti, verificare gli Acceptance Criteria.
9. Squash merge, eliminazione del branch, Issue chiusa automaticamente.

## Regole di review

L'autore non approva la propria Pull Request.

Il reviewer controlla:

- correttezza e Acceptance Criteria;
- leggibilità, naming, duplicazione;
- query SQL, NULL, casi limite;
- validazioni ed error handling;
- transazioni e concorrenza nelle operazioni multi-step;
- test, inclusi i casi negativi;
- regressioni evidenti e impatto sugli altri domini.
