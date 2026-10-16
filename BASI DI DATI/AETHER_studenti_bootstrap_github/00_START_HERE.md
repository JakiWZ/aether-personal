# AETHER — PACCHETTO FINALE 3 SPRINT

**Prima cosa:** aprire `00_LEGGIMI_PRIMA_ORDINE_DOCUMENTI.txt` e poi `00_DOCUMENTI_WORD_IN_ORDINE/`.

Il pacchetto contiene l’intero percorso Foundation → Core Operations → Integrated MVP, con materiale studenti, materiale docente, bootstrap GitHub e handover finale.

---

# AETHER — Class Company Bootstrap

Questo pacchetto trasforma la classe in una piccola software house che sviluppa **AETHER – Mars Operations Platform** usando GitHub Organization, GitHub Projects, Issues, Pull Request e GitHub Actions.

## Principio fondamentale

**Nessun account del docente è necessario.**

L'Organization appartiene agli studenti. Ogni studente utilizza il proprio account personale GitHub. La proprietà del lavoro resta alla classe anche quando il docente termina il corso.

## Struttura consigliata per 26 studenti

- 3 studenti: **Organization Owners** (uno crea l'Organization, altri due vengono promossi Owner)
- 5 squad cross-functional:
  - ARES — Colonie, habitat, astronauti
  - PHOENIX — Missioni ed equipaggi
  - TITAN — Rover, veicoli e manutenzione
  - ORION — Risorse e logistica
  - HELIOS — Incidenti, alert e sicurezza operativa
- 1 Team Maintainer per ogni squad
- Scrum Master: ruolo didattico a rotazione ogni Sprint
- Product Owner / Cliente: il docente, anche completamente offline da GitHub

## Cosa viene automatizzato

Lo script di bootstrap crea:
- repository `aether-platform`
- 5 GitHub Teams
- label per Type, Squad, Priority e Area
- 3 milestone Sprint
- GitHub Project `AETHER Delivery Board`
- campi Stage, Type, Priority, Sprint, Story Points, Squad, Area
- backlog iniziale con Epic, Story e Task
- associazione automatica delle issue al Project
- template Issue e Pull Request
- workflow CI iniziale
- documenti Definition of Ready / Done, Git workflow e cerimonie
- protezione di `main` con Pull Request + 1 approval se il repository è PUBLIC

## Le uniche attività manuali

1. Uno studente crea una GitHub Organization Free.
2. Tutti gli studenti comunicano il proprio username GitHub.
3. Gli inviti all'Organization vengono inviati con `01_invite_students.ps1`.
4. Gli studenti accettano l'invito.
5. L'Owner promuove altri **due studenti ad Owner**.
6. L'Owner esegue `02_bootstrap_aether.ps1`.
7. Nel Project GitHub si crea una vista Board e la si raggruppa per il campo **Stage**.
8. Si abilita il workflow **Auto-add to project** per le nuove issue del repository.

Il resto del lavoro è quotidiano: planning, stand-up, sviluppo, PR, review, demo e retro.
