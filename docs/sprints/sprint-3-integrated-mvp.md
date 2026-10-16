<!-- Generated from the original Word document with pandoc; edit this Markdown, it is now the source of truth. -->

**PROJECT AETHER**

**SPRINT 3 – STUDENT MISSION PACK**

*INTEGRATED MVP • Release • Demo • Handover*

| **Prodotto**    | AETHER – Mars Operations Platform                             |
|-----------------|---------------------------------------------------------------|
| **Ciclo**       | Sprint 3 – INTEGRATED MVP • 5 giorni                          |
| **Destinatari** | Development Teams                                             |
| **Metodo**      | Scrum • GitHub Projects • GitHub Flow • PR • Code Review • CI |

**Sprint Goal: consegnare un MVP integrato, stabile, dimostrabile e trasferibile alla classe.**

# 1. Missione dello Sprint

> **Sprint Goal**
>
> Consegnare un MVP AETHER integrato e stabile: i cinque domini devono collaborare, main deve essere dimostrabile e il progetto deve poter continuare dopo questo Sprint senza dipendere dal docente.

Questo Sprint premia la capacità di FINIRE e integrare. Non è necessario completare tutto il backlog: è necessario sapere cosa entra nella release, cosa resta fuori e perché.

# 2. Regole Sprint 3

- Partire da carry-over e velocity reale, non da ottimismo.
- Massimo 2 Story in progress per squadra.
- Bug Critical/High e dipendenze d’integrazione hanno precedenza sulle Story stretch.
- Ogni Story mantiene Primary + Buddy.
- Modifiche ai contratti API richiedono sync con i consumer.
- Da Giorno 14: Feature Freeze. Solo bug fix, test, documentazione e stabilizzazione.
- “Quasi finito” non è Done.

# 3. Integration Guild

Ogni squadra nomina un delegato temporaneo. Il Guild coordina Dashboard Mission Control, contratti tra domini, test d’integrazione e Release Candidate. Non sostituisce le squad e non diventa proprietario di tutto il codice.

| **Squad** | **Responsabilità nel Guild**    |
|-----------|---------------------------------|
| ARES      | Basi, occupazione, equipaggi    |
| PHOENIX   | Missioni ed equipaggi assegnati |
| TITAN     | Veicoli e indisponibilità       |
| ORION     | Stock e criticità               |
| HELIOS    | Incidenti attivi                |

# 4. Backlog candidato

| **Squad** | **Core candidate**                                       | **Stretch**           |
|-----------|----------------------------------------------------------|-----------------------|
| ARES      | ARES-106 ricerca equipaggio; ARES-107 report occupazione | supporto dashboard    |
| PHOENIX   | PHX-205 conflitti equipaggio; PHX-207 dettaglio missione | PHX-206 ricerca       |
| TITAN     | TIT-306 blocco missione; TIT-305 chiusura manutenzione   | TIT-307 report flotta |
| ORION     | ORI-404 trasferimento atomico; ORI-406 sotto soglia      | ORI-407 storico       |
| HELIOS    | HEL-506 dashboard incidenti                              | HEL-504 timeline      |
| CROSS     | INT-601 dashboard; INT-604 test; INT-606 release         | INT-602/603/605       |

Le card entrano nello Sprint soltanto dopo Planning, Definition of Ready e stima condivisa.

# 5. Mission Control Dashboard – CR-003

La direzione richiede una vista unica per capire lo stato operativo senza aprire cinque moduli separati.

- missioni operative;
- incidenti attivi;
- risorse sotto soglia;
- veicoli indisponibili;
- occupazione delle basi.

I dati devono arrivare dal sistema reale. Il team deve decidere e motivare come comporre le informazioni: più endpoint, endpoint aggregatore o altra soluzione compatibile con l’architettura esistente.

# 6. Story ARES

## ARES-106 — Ricerca equipaggio per ruolo e base • 3 SP

Come Mission Control voglio filtrare il personale per trovare rapidamente persone adatte.

**Acceptance Criteria**

- Filtro per base.
- Filtro per ruolo.
- Filtri combinabili.
- Risultato proveniente dal backend/database.
- UI gestisce nessun risultato senza errore.

**Dipendenze / rischi**

- Usa il modello personale/basi già integrato.

**Evidenza attesa in Review**

Dimostrare almeno due combinazioni di filtri e un caso con zero risultati.

## ARES-107 — Report occupazione delle basi • 5 SP

Come direttore operativo voglio confrontare capacità e occupazione delle basi.

**Acceptance Criteria**

- Una riga per base.
- Incluse basi senza personale.
- Numero occupanti e capacità.
- Percentuale occupazione calcolata.
- Ordinamento utile alla lettura.

**Dipendenze / rischi**

- Dipende da assegnazioni membro-base coerenti.

**Evidenza attesa in Review**

Mostrare una base vuota, una parzialmente occupata e una vicina al limite.

# 7. Story PHOENIX

## PHX-205 — Prevenzione sovrapposizione equipaggi • 8 SP

Come planner voglio impedire assegnazioni a missioni temporalmente incompatibili.

**Acceptance Criteria**

- Intervalli missione confrontati.
- Controllo effettuato lato backend.
- Conflitto produce errore di business comprensibile.
- Caso negativo coperto da test.
- Nessuna duplicazione del controllo soltanto nel frontend.

**Dipendenze / rischi**

- Richiede date missione affidabili e assegnazioni equipaggio Sprint 2.

**Evidenza attesa in Review**

Dimostrare una assegnazione valida e una sovrapposta rifiutata.

## PHX-207 — Dettaglio operativo missione • 5 SP

Come Mission Control voglio una vista unica della missione.

**Acceptance Criteria**

- Dati missione e stato.
- Base collegata.
- Equipaggio assegnato.
- Veicolo se presente.
- Relazioni mancanti gestite senza errore 500/UI.

**Dipendenze / rischi**

- Consuma dati di ARES e TITAN.

**Evidenza attesa in Review**

Aprire una missione completa e una priva di almeno una relazione opzionale.

# 8. Story TITAN

## TIT-306 — Blocco missione per manutenzione • 5 SP

Come Mission Control voglio evitare l’uso di mezzi non sicuri.

**Acceptance Criteria**

- Controllo server-side.
- Intervento bloccante impedisce assegnazione.
- Errore comprensibile.
- Test negativo presente.
- Stato manutenzione e assegnazione restano coerenti.

**Dipendenze / rischi**

- Dipende da manutenzione e assegnazione veicolo Sprint 2.

**Evidenza attesa in Review**

Aprire manutenzione bloccante e tentare l’assegnazione.

## TIT-305 — Chiusura manutenzione • 5 SP

Come tecnico voglio chiudere un intervento registrando l’esito.

**Acceptance Criteria**

- Solo interventi aperti chiudibili.
- Esito obbligatorio.
- Timestamp di chiusura.
- Stato veicolo rivalutato coerentemente.
- Seconda chiusura rifiutata.

**Evidenza attesa in Review**

Chiudere un intervento valido e provare una seconda chiusura.

# 9. Story ORION

## ORI-404 — Trasferimento tra basi atomico • 8 SP

Come logistica voglio trasferire risorse tra due basi senza perdere consistenza.

**Acceptance Criteria**

- Origine e destinazione esistono e sono differenti.
- Quantità positiva.
- Stock origine sufficiente.
- Origine, destinazione e storico aggiornati come unica operazione atomica.
- Fallimento non lascia aggiornamenti parziali.
- Concorrenza non può produrre stock negativo.

**Dipendenze / rischi**

- Story ad alto rischio: progettare prima la transazione e i test.

**Evidenza attesa in Review**

Mostrare trasferimento valido, insufficienza stock e almeno un test che dimostri rollback/coerenza.

## ORI-406 — Report risorse sotto soglia • 5 SP

Come Mission Control voglio vedere le risorse che richiedono rifornimento.

**Acceptance Criteria**

- Base e risorsa.
- Quantità corrente e soglia.
- Scostamento rispetto alla soglia.
- Solo situazioni realmente critiche.
- Dati disponibili alla Dashboard Mission Control.

**Dipendenze / rischi**

- Dipende da stock e soglie Sprint 2.

**Evidenza attesa in Review**

Mostrare almeno una risorsa normale e una sotto soglia, verificando che solo la seconda venga segnalata.

# 10. Story HELIOS

## HEL-506 — Dashboard incidenti attivi • 5 SP

Come Mission Control voglio vedere gli incidenti ancora aperti e la loro criticità.

**Acceptance Criteria**

- Solo incidenti attivi.
- Base e severità visibili.
- Conteggio per severità.
- Ordinamento dei più critici.
- Dati riutilizzabili nella Mission Control Dashboard.

**Evidenza attesa in Review**

Mostrare incidenti di severità diverse e verificare esclusione dei chiusi.

## HEL-504 — Timeline incidente • 8 SP

Come coordinatore voglio ricostruire gli aggiornamenti di un incidente in ordine cronologico.

**Acceptance Criteria**

- Più eventi per incidente.
- Autore e timestamp.
- Ordine cronologico.
- Storico non alterato accidentalmente.
- Incidente inesistente gestito.

**Evidenza attesa in Review**

Dimostrare una timeline con almeno tre eventi e ordine temporale corretto.

# 11. Attività CROSS della release

| **ID**  | **Attività**                      | **Done quando…**                                                             |
|---------|-----------------------------------|------------------------------------------------------------------------------|
| INT-601 | Mission Control Dashboard         | mostra indicatori reali di almeno 4 domini; nessun mock                      |
| INT-604 | Test integrazione regole critiche | coperti equipaggio/missione, veicolo/missione, stock atomico + casi negativi |
| INT-602 | OpenAPI / endpoint catalog        | API principali comprensibili e provabili                                     |
| INT-605 | Configurazioni ambiente           | nessun secret; URL DB/API configurabili                                      |
| INT-606 | Release candidate e demo          | clone pulito, demo script, known issues, tag/release                         |

# 12. Piano dei 5 giorni

| **Giorno** | **Obiettivo**                                            |
|------------|----------------------------------------------------------|
| 11         | Planning, carry-over, Integration Map, Dashboard CR      |
| 12         | Sviluppo core e contratti cross-team                     |
| 13         | Quality Day: test, error handling, audit impact analysis |
| 14         | Feature Freeze, clone pulito, Release Candidate          |
| 15         | Demo finale, Sprint Review, Retro e handover             |

# 13. Quality Gate

- main verde;
- database ricreabile da script/migrazioni;
- README sufficiente ad avviare il progetto da clone pulito;
- nessun secret reale;
- bug Critical assenti;
- bug noti registrati come Issue;
- almeno un caso negativo per ogni area critica;
- PR revisionate e collegate alle Issue;
- nessuna dipendenza da modifiche manuali al DB per fare la demo.

# 14. Feature Freeze e Release Candidate

Dal Giorno 14 non entrano nuove feature. Si lavora su stabilizzazione, bug fix, test, documentazione e release.

**1.** Clonare il repository in una cartella nuova.

**2.** Seguire README senza usare configurazioni locali nascoste.

**3.** Avviare DB, backend e frontend.

**4.** Eseguire demo end-to-end.

**5.** Aprire Bug per ogni problema.

**6.** Correggere tramite branch/PR normale.

**7.** Quando main è stabile, creare \`v0.1.0-rc1\`.

# 15. Demo finale

La demo è del prodotto, non delle slide. Ogni squadra deve essere in grado di spiegare almeno una scelta tecnica e mostrare una feature reale su main.

- Mission Control Dashboard;
- missione con equipaggio/mezzo;
- regola negativa su sovrapposizione o manutenzione;
- trasferimento risorsa coerente;
- risorsa sotto soglia;
- incidente attivo;
- una catena GitHub Issue → PR → review → CI → merge;
- backlog residuo dichiarato senza nascondere il lavoro incompleto.

# 16. Handover: da progetto del corso a progetto vostro

- Almeno 3 studenti restano Owner dell’Organization.
- README contiene istruzioni di avvio e contribuzione.
- Board, Issue e backlog restano nell’Organization della classe.
- Se la release è accettata, creare \`v0.1.0\`; altrimenti mantenere la RC e continuare con i bug.
- Le future materie del corso devono evolvere lo stesso prodotto: NoSQL, Big Data, Docker, Cloud, Security, event-driven, AI.
- Il docente non è necessario per amministrare account o repository.

> **Principio finale**
>
> AETHER non è una consegna da archiviare. È il vostro portfolio tecnico collettivo: ogni miglioramento futuro deve essere tracciato nel backlog, sviluppato con branch/PR e integrato come avete fatto durante questi Sprint.
