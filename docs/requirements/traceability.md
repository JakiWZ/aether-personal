# Matrice di tracciabilità dei requisiti

Ogni requisito del [capitolato](capitolato.md) con la storia che lo realizza, lo stato e l'evidenza che lo dimostra.
È l'obiettivo misurabile del progetto: quando una storia chiude, la stessa PR aggiorna le sue righe.
`TraceabilityMatrixTest` (backend, `mvn test`) fallisce se:
- un requisito manca o è sconosciuto;
- un test citato non esiste.

Legenda: ✅ implementato e testato · 🟡 parziale · ⬜ da fare · ➖ fuori dal piano attuale (Future Track o nessuna storia).

**Copertura:** ✅ 11 · 🟡 20 · ⬜ 48 · ➖ 15 su 94 requisiti (aggiornata al 2026-10-17).

## Identità e accessi

| Requisito | Titolo | Stato | Issue | Evidenza / note |
|---|---|---|---|---|
| IAM-001 | Registrazione account | ⬜ | — | Gli account esistono solo da migrazione e dataset demo |
| IAM-002 | Autenticazione | ✅ | #56 | AuthenticationIT, AuthControllerTest |
| IAM-003 | Stato account | 🟡 | #56 | Login rifiutato su account non attivi (AuthenticationIT); manca la gestione dello stato |
| IAM-004 | Ruoli | 🟡 | #56 | Ruoli in V14 e nel dataset demo; manca la gestione dei ruoli |
| IAM-005 | Autorizzazioni | ✅ | #56 | EndpointSecurityTest, ArchitectureTest (permesso su ogni endpoint) |
| IAM-006 | Profilo personale | ⬜ | — |  |
| IAM-007 | Sessione e logout | ✅ | #56 | AuthenticationIT (timeout, logout, nuova sessione al login) |
| IAM-008 | Tentativi falliti | ✅ | #56, #97 | AuthenticationIT (blocco dopo 5 tentativi), AuditTrailIT |

## Colonie e asset

| Requisito | Titolo | Stato | Issue | Evidenza / note |
|---|---|---|---|---|
| COL-001 | Anagrafica colonia | 🟡 | #15, #16 | Elenco: ColonyListIT, ColonyControllerTest; dettaglio in #16 |
| COL-002 | Struttura habitat | ⬜ | #16 |  |
| COL-003 | Asset tecnici | ⬜ | #29 |  |
| COL-004 | Stato asset | ⬜ | #30 |  |
| COL-005 | Responsabile asset | ⬜ | — |  |
| COL-006 | Disattivazione | 🟡 | #16 | Soft delete nello schema; una base inattiva non avvia missioni (MissionCreationIT) |
| COL-007 | Ricerca e filtri | ⬜ | — |  |

## Equipaggio

| Requisito | Titolo | Stato | Issue | Evidenza / note |
|---|---|---|---|---|
| CRW-001 | Profilo equipaggio | ✅ | #17 | CrewMemberRegistrationIT, CrewMemberControllerTest |
| CRW-002 | Competenze | ⬜ | #19 |  |
| CRW-003 | Certificazioni | ⬜ | #19 |  |
| CRW-004 | Verifica idoneità | ⬜ | #19, #24 |  |
| CRW-005 | Indisponibilità | ⬜ | — |  |
| CRW-006 | Storico assegnazioni | ⬜ | #18 |  |
| CRW-007 | Ricerca competenze | ⬜ | #20 |  |

## Missioni

| Requisito | Titolo | Stato | Issue | Evidenza / note |
|---|---|---|---|---|
| MIS-001 | Creazione missione | ✅ | #22 | MissionCreationIT, MissionControllerTest |
| MIS-002 | Tipologia missione | ✅ | #22 | MissionControllerTest (tipo obbligatorio e validato) |
| MIS-003 | Fasi e task | ⬜ | #28 |  |
| MIS-004 | Requisiti missione | ⬜ | — |  |
| MIS-005 | Assegnazione equipaggio | ⬜ | #24 |  |
| MIS-006 | Controllo conflitti | 🟡 | #26 | Vincolo di esclusione nel DB (DemoDatasetIT); manca il controllo nel servizio |
| MIS-007 | Approvazione | ⬜ | #23 |  |
| MIS-008 | Stati | 🟡 | #23 | Creazione sempre in DRAFT (MissionCreationIT); transizioni in #23 |
| MIS-009 | Consuntivazione | ⬜ | — |  |
| MIS-010 | Storico | 🟡 | #22, #23 | Stato iniziale nello storico con autore (MissionCreationIT) |

## Risorse e logistica

| Requisito | Titolo | Stato | Issue | Evidenza / note |
|---|---|---|---|---|
| LOG-001 | Catalogo risorse | ⬜ | #36 |  |
| LOG-002 | Unità di misura | ⬜ | #36 |  |
| LOG-003 | Giacenza | ⬜ | #37 |  |
| LOG-004 | Movimenti | ⬜ | #38 |  |
| LOG-005 | Lotti e scadenze | ⬜ | #83 |  |
| LOG-006 | Soglia minima | ⬜ | #40 |  |
| LOG-007 | Rifornimenti | ⬜ | — |  |
| LOG-008 | Ricezione | ⬜ | — |  |
| LOG-009 | Consumo per missione | ⬜ | #38 |  |

## Manutenzione e incidenti

| Requisito | Titolo | Stato | Issue | Evidenza / note |
|---|---|---|---|---|
| MNT-001 | Piano manutenzione | ⬜ | #32 |  |
| MNT-002 | Ticket guasto | ⬜ | #32 |  |
| MNT-003 | Assegnazione tecnico | ⬜ | #32 |  |
| MNT-004 | Ricambi utilizzati | ⬜ | #33 |  |
| MNT-005 | Stato intervento | ⬜ | #33 |  |
| MNT-006 | Incidenti operativi | ⬜ | #43 |  |
| MNT-007 | Escalation | ⬜ | #44 |  |
| MNT-008 | Root cause | ⬜ | #47 |  |
| MNT-009 | Storico asset | ⬜ | #33 |  |

## Ricerca scientifica

| Requisito | Titolo | Stato | Issue | Evidenza / note |
|---|---|---|---|---|
| SCI-001 | Esperimenti | ➖ | — |  |
| SCI-002 | Laboratori | ➖ | — |  |
| SCI-003 | Campioni | ➖ | — |  |
| SCI-004 | Chain of custody | ➖ | — |  |
| SCI-005 | Missione di raccolta | ➖ | — |  |
| SCI-006 | Risultati | ➖ | — |  |
| SCI-007 | Ricerca | ➖ | — |  |

## Telemetria, dashboard e report

| Requisito | Titolo | Stato | Issue | Evidenza / note |
|---|---|---|---|---|
| TEL-001 | Sensori | ➖ | #57 |  |
| TEL-002 | Misurazioni | ➖ | #57 |  |
| TEL-003 | Eventi anomali | ➖ | #57 |  |
| TEL-004 | Alert | ➖ | #57 |  |
| TEL-005 | Presa visione | ➖ | #57 |  |
| TEL-006 | Dashboard colonia | ⬜ | #50 |  |
| TEL-007 | Dashboard personale | ⬜ | #50 |  |
| TEL-008 | Filtri temporali | ⬜ | #49 |  |
| TEL-009 | Report | ⬜ | #21, #35, #41 |  |
| TEL-010 | Storico alert | ➖ | #57 |  |

## Regole di business

| Requisito | Titolo | Stato | Issue | Evidenza / note |
|---|---|---|---|---|
| BR-001 | Identificativi univoci | 🟡 | — | Codici univoci nel DB; MissionCreationIT, CrewMemberRegistrationIT, DemoDatasetIT |
| BR-002 | Missioni concluse | ⬜ | #23 |  |
| BR-003 | Conflitto equipaggio | 🟡 | #26 | Vincolo di esclusione nel DB (DemoDatasetIT); manca il controllo nel servizio |
| BR-004 | Certificazioni | ⬜ | #19, #24 |  |
| BR-005 | Asset non operativo | ⬜ | #34 |  |
| BR-006 | Movimenti inventario | ⬜ | #38 |  |
| BR-007 | Quantità negative | 🟡 | #38, #39 | CHECK quantity >= 0 nel DB (DemoDatasetIT); movimenti in #38 |
| BR-008 | Campioni | ➖ | — |  |
| BR-009 | Incidenti critici | ⬜ | #47 |  |
| BR-010 | Cancellazione logica | 🟡 | — | Nessun endpoint di cancellazione; soft delete nello schema; audit solo in inserimento (ADR-0014) |
| BR-011 | Orari | ✅ | #13, #22 | TIMESTAMPTZ in UTC; MissionControllerTest, HostileInputTest (istanti fuori range) |
| BR-012 | Audit | 🟡 | #97 | AuditTrailIT; da estendere a ruoli, stati missione, inventario e incidenti |
| BR-013 | Approvazioni | ⬜ | #23 |  |
| BR-014 | Allarmi | ➖ | #57 |  |
| BR-015 | Integrità referenziale | ✅ | #9 | Chiavi esterne in tutte le migrazioni; AetherApplicationIT, DemoDatasetIT |

## Requisiti non funzionali

| Requisito | Titolo | Stato | Issue | Evidenza / note |
|---|---|---|---|---|
| NFR-001 | Usabilità | 🟡 | #12 | Shell Angular con stati di caricamento, vuoto ed errore |
| NFR-002 | Responsive | 🟡 | #12 |  |
| NFR-003 | Performance | 🟡 | #92 | Elenchi paginati con limite lato server (ADR-0011) |
| NFR-004 | Scalabilità | ⬜ | #58, #59 |  |
| NFR-005 | Affidabilità | 🟡 | — | Scritture transazionali; vincoli nel DB |
| NFR-006 | Manutenibilità | ✅ | — | ArchitectureTest, ADR, CLAUDE.md |
| NFR-007 | Testabilità | ✅ | #53 | Test di unità, di controller e di integrazione su PostgreSQL reale |
| NFR-008 | Portabilità | 🟡 | #54 | Configurazione da variabili d'ambiente (.env.example) |
| NFR-009 | Osservabilità | 🟡 | #97 | Log strutturati con correlation id, health check (AetherApplicationIT, CorrelationIdFilterTest); mancano le metriche |
| NFR-010 | Accessibilità | 🟡 | #12 | Regole ESLint di accessibilità |
| NFR-011 | Internazionalizzazione | ⬜ | — |  |
| NFR-012 | Qualità dati | 🟡 | #90 | HostileInputTest, HostileInputIT, vincoli CHECK |
