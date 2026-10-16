# Avvio operativo della classe

## Fase A — 15 minuti: account e proprietà

Ogni studente deve avere un account GitHub personale.

Scegliere tre studenti affidabili:
- Owner 1: crea l'Organization
- Owner 2
- Owner 3

Nome suggerito dell'Organization:
`aether-apulia-fullstack-2026`

Non creare account condivisi e non condividere password.

L'Owner 1 crea l'Organization dal sito GitHub scegliendo il piano gratuito.

## Fase B — 10 minuti: compilare il roster

Aprire:

`roster/students.csv`

Compilare `github_username` e `display_name`.

Le squad sono già predisposte 6+5+5+5+5. Modificarle liberamente per bilanciare competenze e presenze.

Il primo studente di ogni squadra è impostato come `maintainer`.

## Fase C — 10 minuti: GitHub CLI

Sul PC dello studente Owner installare:
- Git
- GitHub CLI (`gh`)

Poi:

```powershell
gh auth login
gh auth refresh -h github.com -s admin:org -s project
```

## Fase D — inviti

Dalla cartella del kit:

```powershell
.\scripts\01_invite_students.ps1 -Org "aether-apulia-fullstack-2026"
```

Tutti gli studenti accettano l'invito ricevuto su GitHub/email.

L'Owner 1 promuove poi altri due studenti:
Organization → People → seleziona utente → Change role → Owner.

## Fase E — bootstrap

Quando gli inviti sono stati accettati:

```powershell
.\scripts\02_bootstrap_aether.ps1 `
  -Org "aether-apulia-fullstack-2026" `
  -Repo "aether-platform" `
  -Visibility "public" `
  -Sprint1Start "2026-09-14"
```

Lo script è idempotente per quanto possibile: può essere rieseguito se alcuni studenti non avevano ancora accettato l'invito.

## Fase F — due configurazioni visuali

### Board

Aprire il Project `AETHER Delivery Board`.

Creare una nuova vista:
- Layout: Board
- Group by: `Stage`

Colonne:
- Backlog
- Ready
- In Progress
- Code Review
- Testing
- Done

### Auto-add

Project → menu `...` → Workflows → Auto-add to project.

Repository: `aether-platform`

Filtro:
`is:issue,pr`

Abilitare il workflow.

Da quel momento nuove Issue e PR possono entrare automaticamente nella gestione del Project.

## Repository pubblico o privato?

Per questa esercitazione è consigliato **public**, se non vengono inseriti dati reali o sensibili:
- rimane portfolio degli studenti;
- sul piano GitHub Free è possibile applicare la protezione del branch `main`.

Con repository privato lo script continua a funzionare, ma sul piano Free alcune protezioni avanzate del branch potrebbero non essere applicabili.
