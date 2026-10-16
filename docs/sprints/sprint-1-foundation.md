<!-- Generated from the original Word document with pandoc; edit this Markdown, it is now the source of truth. -->

**PROJECT AETHER**

**SPRINT 1 – STUDENT MISSION PACK**

*Backlog, regole di lavoro e criteri di consegna*

| **Prodotto**    | AETHER – Mars Operations Platform                                  |
|-----------------|--------------------------------------------------------------------|
| **Ciclo**       | Sprint 1 – FOUNDATION • 5 giorni                                   |
| **Destinatari** | Studenti / Development Teams                                       |
| **Metodo**      | Scrum • GitHub Projects • GitHub Flow • Pull Request • Code Review |

**Sprint Goal: costruire le fondamenta condivise e dimostrare una prima vertical slice per ogni dominio.**

# 1. La missione della settimana

> **SPRINT GOAL**
>
> AETHER deve ottenere una base dati e tecnica condivisa e ogni dominio deve dimostrare almeno un primo flusso verticale integrabile, tracciato da Issue a Pull Request.

Non dovete completare tutto il backlog. Dovete selezionare un insieme realistico di lavoro, terminarlo bene e renderlo integrabile.

# 2. Cosa significa “vertical slice”

Una feature AETHER non è “il frontend” o “la tabella”. È un piccolo risultato utente che attraversa i layer necessari.

> **Esempio concettuale**
>
> Requisito → modello dati → SQL/migrazione → persistence → service/business rules → REST API → Angular (quando richiesto) → test → Pull Request → Review → Done.

# 3. Backlog foundation comune

| **ID**   | **Obiettivo**         | **Done quando…**                                               |
|----------|-----------------------|----------------------------------------------------------------|
| TASK-001 | Modello E-R v1        | Entità/cardinalità principali motivate e diagramma versionato. |
| TASK-002 | Schema relazionale v1 | PK/FK/vincoli definiti e normalizzazione discussa.             |
| TASK-003 | DB ricreabile         | Script/migrazioni versionate ricostruiscono lo schema.         |
| TASK-004 | Seed demo             | Dati coerenti permettono sviluppo e demo.                      |
| TASK-005 | Spring Boot bootstrap | Backend condiviso avviabile da repository.                     |
| TASK-006 | Angular bootstrap     | Frontend condiviso avviabile da repository.                    |
| TASK-007 | Error contract        | Errori REST hanno struttura e significato coerenti.            |

I task CROSS appartengono a tutti. Verranno gestiti con delegati temporanei e Pull Request condivise, non da un reparto separato.

# 4. Story Sprint 1 per le squad

## ARES-103 – Anagrafica membro equipaggio

> **User Story**
>
> Come responsabile equipaggi voglio registrare un profilo operativo di un membro dell’equipaggio affinché possa essere assegnato alle attività AETHER.

**Acceptance Criteria**

- Ogni membro possiede un identificativo operativo univoco.
- Il profilo contiene almeno nome, mansione/ruolo operativo, stato e colonia/base di assegnazione quando applicabile.
- Il backend rifiuta dati obbligatori mancanti o un identificativo già utilizzato.
- Lo stato deve appartenere a un insieme di valori definito e documentato dal team.
- Il dato creato è persistito e recuperabile tramite l’applicazione/API.
- La UI comunica in modo comprensibile successo ed errori di validazione.

**Dipendenze / interfacce**

- Entità/relazione Colony/Base condivisa con ARES-101 o modello dati comune.
- Convenzione comune per identificativi, timestamp e JSON.
- Contratto errori API TASK-007.

**Evidenze richieste in Sprint Review**

- Creare un membro valido.
- Tentare di riutilizzare lo stesso codice e mostrare il rifiuto.
- Mostrare il dato persistito dopo refresh/nuova richiesta.

Prima di sviluppare, scrivete nella Issue le domande aperte al Product Owner. Non assumete che ciò che non è scritto abbia una sola soluzione possibile.

## PHX-201 – Creazione missione

> **User Story**
>
> Come operatore di Mission Control voglio creare una missione in bozza affinché possa iniziare la pianificazione senza considerarla già approvata.

**Acceptance Criteria**

- La missione possiede un codice univoco e un obiettivo descrittivo.
- È collegata a una colonia/base esistente.
- La finestra temporale prevista è rappresentata con inizio e fine coerenti.
- Priorità e livello di rischio utilizzano valori controllati e documentati.
- Alla creazione lo stato iniziale è DRAFT.
- Una base inesistente, una finestra temporale incoerente o un codice duplicato producono un errore comprensibile.
- La missione creata è persistita e recuperabile.

**Dipendenze / interfacce**

- Dati base/colonia prodotti dal modello comune/ARES.
- Convenzione timestamp comune.
- Contratto errori API.

**Evidenze richieste in Sprint Review**

- Creare una missione valida.
- Mostrare stato DRAFT assegnato dal sistema.
- Provare almeno un caso negativo: base inesistente, date incoerenti o codice duplicato.

Prima di sviluppare, scrivete nella Issue le domande aperte al Product Owner. Non assumete che ciò che non è scritto abbia una sola soluzione possibile.

## TIT-301 – Catalogo veicoli e rover

> **User Story**
>
> Come tecnico voglio consultare la flotta AETHER affinché possa conoscere mezzi, posizione e disponibilità operativa.

**Acceptance Criteria**

- I veicoli/rover hanno un codice univoco e un tipo/modello riconoscibile.
- Sono memorizzati almeno stato operativo, criticità e base/colonia corrente quando nota.
- L’elenco arriva dal backend e può essere filtrato almeno per stato.
- Un mezzo fuori servizio rimane visibile nello storico/catalogo.
- L’elenco vuoto e i filtri senza risultati sono gestiti correttamente.

**Dipendenze / interfacce**

- Base/colonia condivisa.
- Vocabolario comune degli stati o decisione ADR.

**Evidenze richieste in Sprint Review**

- Mostrare veicoli in almeno tre stati differenti.
- Filtrare per uno stato.
- Mostrare un mezzo OUT_OF_SERVICE che non viene cancellato.

Prima di sviluppare, scrivete nella Issue le domande aperte al Product Owner. Non assumete che ciò che non è scritto abbia una sola soluzione possibile.

## ORI-401 – Catalogo risorse

> **User Story**
>
> Come addetto logistico voglio gestire il catalogo delle risorse consumabili affinché il sistema possa successivamente tracciare scorte e movimenti.

**Acceptance Criteria**

- Ogni risorsa possiede codice univoco, nome, categoria e unità di misura.
- L’unità di misura è obbligatoria e non viene dedotta implicitamente dal nome.
- Il sistema permette almeno creazione e consultazione del catalogo.
- Codici duplicati e dati obbligatori mancanti vengono rifiutati.
- Una risorsa può essere disattivata logicamente senza perdere eventuali riferimenti futuri/storici.

**Dipendenze / interfacce**

- Convenzioni comuni su identificativi e cancellazione logica.
- Contratto errori API.

**Evidenze richieste in Sprint Review**

- Creare una risorsa valida.
- Mostrare elenco catalogo.
- Provare codice duplicato o unità mancante.

Prima di sviluppare, scrivete nella Issue le domande aperte al Product Owner. Non assumete che ciò che non è scritto abbia una sola soluzione possibile.

## HEL-501 – Apertura incidente operativo

> **User Story**
>
> Come operatore voglio aprire un incidente operativo affinché Mission Control possa iniziare a gestirlo e conservarne la traccia.

**Acceptance Criteria**

- L’incidente possiede identificativo univoco, titolo, descrizione, severità, base/colonia e timestamp di apertura.
- Lo stato iniziale è OPEN ed è assegnato dal sistema.
- La severità appartiene a un insieme controllato e documentato.
- La base/colonia collegata deve esistere.
- Dati obbligatori mancanti o severità non valida vengono rifiutati.
- L’incidente creato è persistito e consultabile.

**Dipendenze / interfacce**

- Dati base/colonia condivisi.
- Convenzione timestamp.
- Contratto errori API.

**Evidenze richieste in Sprint Review**

- Aprire un incidente valido.
- Mostrare stato OPEN e timestamp.
- Provare severità non valida o base inesistente.

Prima di sviluppare, scrivete nella Issue le domande aperte al Product Owner. Non assumete che ciò che non è scritto abbia una sola soluzione possibile.

# 5. Story opzionale ARES – se esiste capacità reale

## ARES-101 – Elenco basi marziane

> **User Story**
>
> Come operatore voglio consultare le basi operative affinché possa riconoscere dove sono assegnate persone e attività.

**Acceptance Criteria**

- Elenco ottenuto da dati persistiti, non hardcoded nel frontend.
- Per ogni base sono visibili almeno codice, nome e stato operativo.
- Sono rappresentabili basi non attive senza eliminarne la storia.
- L’interfaccia gestisce correttamente anche un elenco vuoto.

**Dipendenze / interfacce**

- Modello Colony/Base concordato nel Data Contract.

**Evidenze richieste in Sprint Review**

- Visualizzare almeno tre basi del seed.
- Dimostrare che i dati provengono dall’API/DB.

> **Regola di capacità**
>
> Una Story opzionale entra nello Sprint solo se il lavoro già preso è sotto controllo. Non aumentare WIP per “tenere occupate” le persone.

# 6. Planning Poker

- Usate solo 1, 2, 3, 5, 8 Story Point.
- La stima rappresenta complessità, quantità, rischio e incertezza: non è una conversione diretta in ore.
- Mostrate le stime contemporaneamente.
- Chi ha stimato molto alto e molto basso spiega il perché.
- Chiarite il requisito e rivotate una volta.
- Una Story che sembra 13+ deve essere spezzata prima di entrare nello Sprint.

# 7. Regole Git obbligatorie

**1.** Partire da una GitHub Issue.

**2.** Spostare la card in Ready/In Progress secondo il workflow concordato.

**3.** Creare un branch: feature/\<issue\>-descrizione, fix/\<issue\>-descrizione, docs/\<issue\>-descrizione.

**4.** Fare commit piccoli e comprensibili.

**5.** Push frequente: nessun lavoro importante deve esistere soltanto su un PC.

**6.** Aprire una Pull Request collegata alla Issue con “Closes \#numero”.

**7.** Richiedere review a una persona diversa dall’autore.

**8.** Risolvere commenti e verificare Acceptance Criteria.

**9.** Merge su main solo dopo review/controlli previsti.

**10.** Eliminare il branch e portare la Story a Done solo quando la Definition of Done è rispettata.

# 8. Definition of Ready

- Valore/obiettivo comprensibile.
- Acceptance Criteria verificabili.
- Dipendenze principali note.
- Domande bloccanti chiarite con il Product Owner.
- Story abbastanza piccola per uno Sprint.
- Stima effettuata dal team.

# 9. Definition of Done – Sprint 1

- Acceptance Criteria dimostrabili.
- Codice compilabile e repository aggiornato.
- Modifiche DB versionate; nessuna modifica manuale indispensabile.
- Validazioni importanti lato backend.
- Errori comprensibili per client/UI.
- Almeno i test/casi manuali concordati eseguiti.
- Pull Request revisionata da un altro studente.
- Commenti della review risolti.
- Merge in main.
- README/documentazione aggiornata quando necessaria.
- La feature può essere dimostrata da un membro diverso dall’autore.

# 10. Daily Stand-up per 26 studenti

I Daily avvengono in parallelo per squadra, massimo 7 minuti. Poi lo Scrum Master fa un sync di 30–45 secondi con la classe.

| **Domanda**                | **Risposta attesa**                                 |
|----------------------------|-----------------------------------------------------|
| Cosa ho completato?        | Risultato verificabile, idealmente Issue/PR/commit. |
| Cosa farò oggi?            | Prossimo passo concreto.                            |
| Ho impedimenti?            | Problema che richiede aiuto/decisione.              |
| Dipendo da un’altra squad? | Contratto, dato, PR o decisione necessaria.         |

> **Il Daily non è una riunione tecnica**
>
> Se emerge un problema lungo, annotate chi deve parlarne e affrontatelo subito dopo. Non fate debugging con 26 persone in ascolto.

# 11. Collaborazione cross-team

- Un delegato per squad partecipa al Data Council; poi riporta le decisioni al team.
- Le convenzioni condivise devono essere documentate, non tramandate a voce.
- Prima di cambiare una struttura dati usata da altre squad, aprite una Issue/PR comprensibile e avvisate le dipendenze.
- Se una Story dipende da una feature non pronta, concordate un contratto temporaneo; non inventate due versioni incompatibili.
- Nelle review, valutate anche l’impatto sulle altre squad.

# 12. Qualità database – checklist

- Ogni tabella rappresenta un concetto/fatto preciso.
- Chiavi primarie e chiavi esterne sono esplicite.
- UNIQUE, NOT NULL e altri vincoli vengono usati quando proteggono una regola reale.
- Niente liste “A,B,C” dentro una singola colonna per evitare relazioni.
- Evitare dati duplicati che possono divergere.
- Valutare NULL come scelta di dominio, non come default casuale.
- DDL/migrazioni e seed sono versionati in Git.

# 13. Qualità backend/API – checklist

- Controller non contiene tutta la logica di business.
- Validazioni non dipendono soltanto dal frontend.
- Entity, DTO e contratto API vengono distinti quando serve; la scelta deve essere comprensibile.
- Errori hanno status HTTP e payload coerenti.
- Niente stack trace o dettagli interni come messaggio utente.
- Configurazione DB/API non è hardcoded nei componenti applicativi.

# 14. Qualità frontend – checklist

- Dati reali caricati dal backend quando la Story lo richiede.
- Form con validazione utile per l’utente, senza affidarsi solo ad essa per la sicurezza dei dati.
- Stati loading / errore / vuoto gestiti almeno in forma semplice.
- URL backend e configurazioni non sparsi nei componenti.
- Messaggi di errore comprensibili e coerenti con l’API.

# 15. Sprint Review – cosa dovete portare

| **Evidenza**  | **Richiesta**                                                         |
|---------------|-----------------------------------------------------------------------|
| Board         | Story/Task con stato aggiornato.                                      |
| Git           | Issue, branch, commit, Pull Request e review reali.                   |
| DB            | Schema ricreabile + seed.                                             |
| Software      | Demo su main o release candidate condivisa.                           |
| Happy path    | Almeno un flusso valido della Story.                                  |
| Negative path | Almeno un Acceptance Criterion che produce rifiuto/errore.            |
| Spiegazione   | Una persona diversa dall’autore deve saper spiegare almeno una parte. |

> **Una Story incompleta non è Done**
>
> È normale portare lavoro al prossimo Sprint. È invece scorretto spostare una card in Done se manca una parte della Definition of Done. Prima della Retro ogni squadra prepara Start / Stop / Continue e sceglie una sola azione misurabile da provare nello Sprint 2.
