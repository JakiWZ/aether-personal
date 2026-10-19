# Domande aperte al Product Owner (D-01)

Il [capitolato](capitolato.md) e i mission pack in [`docs/sprints/`](../sprints/) contengono incongruenze volute. Per ognuna:
- le fonti che si contraddicono;
- le opzioni;
- la proposta del team;
- cosa fa oggi il codice.

Per rispondere basta il numero e la lettera, per esempio `Q-03: C`. Quando il PO decide, la riga **Decisione** viene compilata e la domanda passa a ✅.

Legenda: ❓ aperta · ✅ decisa.

## Magazzino e logistica

### Q-01 – Una giacenza può diventare negativa? ❓
- **Fonti in conflitto:**
  - BR-007 la ammette con «rettifica autorizzata e auditata».
  - ORI-402 dice «quantità mai negativa».
  - ORI-404 e lo scenario 19.1/3 vietano lo stock negativo.
- **Codice oggi:** `CHECK (quantity >= 0)` su `inventory_stock`.
- **Opzioni:**
  - A) Mai negativa: la rettifica corregge il conteggio ma non scende sotto zero.
  - B) Negativa solo con un movimento di rettifica speciale, con permesso dedicato e audit.
- **Proposta:** A. Una quantità fisica negativa non ha significato; la rettifica serve a riallineare l'inventario reale.

### Q-02 – La giacenza è per base o per luogo di stoccaggio e lotto? ❓
- **Fonti in conflitto:** LOG-003 la vuole «per luogo di stoccaggio» e LOG-005 per lotti, mentre ORI-402 chiede «una sola posizione stock per coppia base-risorsa».
- **Codice oggi:** lo schema tiene la giacenza per luogo e lotto (`uq_stock_with_lot`, `uq_stock_without_lot`).
- **Opzioni:**
  - A) Una riga per base e risorsa.
  - B) Righe per luogo e lotto, con la vista «per base» calcolata come somma.
- **Proposta:** B. Soddisfa ORI-402 come vista senza perdere lotti e scadenze.

### Q-03 – Un trasferimento tra basi è istantaneo o è una spedizione? ❓
- **Fonti in conflitto:**
  - ORI-404 aggiorna origine e destinazione nella stessa operazione atomica.
  - LOG-007 e LOG-008 descrivono spedizioni tra colonie con stato e date, in cui la disponibilità si aggiorna alla ricezione.
  - Il dataset (§19) prevede «consegne parziali».
- **Opzioni:**
  - A) Sempre istantaneo.
  - B) Sempre una spedizione: scarico alla partenza, carico alla ricezione.
  - C) Istantaneo tra luoghi della stessa colonia, spedizione tra colonie diverse.
- **Proposta:** C. Tra due colonie marziane il materiale resta in viaggio per un tempo reale.

## Missioni

### Q-04 – Un conflitto di equipaggio blocca o avvisa? ❓
- **Fonti in conflitto:** MIS-006 chiede di «segnalare» i conflitti prima dell'approvazione, mentre BR-003, PHX-205 e lo scenario 19.1/1 chiedono di impedirli.
- **Codice oggi:** vincolo di esclusione `EXCLUDE USING gist` su `mission_crew` (V6).
- **Opzioni:**
  - A) Rifiuto all'assegnazione, con un nuovo controllo all'approvazione.
  - B) Assegnazione accettata con un avviso; il blocco scatta solo all'approvazione.
- **Proposta:** A. Il nuovo controllo all'approvazione serve perché un'indisponibilità (CRW-005) può nascere dopo l'assegnazione.

### Q-05 – Quali impegni rendono una persona «incompatibile»? ❓
- **Fonti in conflitto:** BR-003 parla di «attività incompatibili» in generale, mentre PHX-205 considera solo le missioni. Non è chiaro se contino le missioni DRAFT, gli interventi di manutenzione (MNT-003) e il ruolo di responder di un incidente (HEL-503).
- **Proposta:** contano tutte le missioni non chiuse né annullate, DRAFT compresa, più i periodi di indisponibilità (CRW-005). Manutenzioni e incidenti non bloccano.

### Q-06 – Quali stati deve avere una missione? ❓
- **Fonti in conflitto:** MIS-008 chiede almeno Draft, Planned, Approved, In Progress, **Suspended**, Completed e Cancelled. PHX-202 richiede solo DRAFT→PLANNED→APPROVED.
- **Codice oggi:** gli stati sono DRAFT, PLANNED, APPROVAL_PENDING, APPROVED, IN_PROGRESS, COMPLETED, ABORTED e CANCELLED. **SUSPENDED manca.**
- **Proposta:**
  - Aggiungere SUSPENDED (IN_PROGRESS ↔ SUSPENDED) con una nuova migrazione.
  - Tenere CANCELLED per le missioni annullate prima della partenza e ABORTED per quelle interrotte dopo.
  - Tenere APPROVAL_PENDING.

### Q-07 – Quali missioni vanno approvate, e da chi? ❓
- **Fonti in conflitto:**
  - MIS-007 chiede l'approvazione solo per le missioni «ad alta criticità».
  - UC-01, il KPI §2.1 e PHX-202 fanno passare ogni missione da APPROVED.
  - Non è definito se «criticità» sia la priorità o il livello di rischio.
  - L'approvatore è indicato solo come «ruolo autorizzato»; il Colony Commander «approva attività ad alto impatto» (§3).
  - BR-013 introduce la separazione dei compiti «quando configurato».
- **Opzioni:**
  - A) Tutte le missioni sono approvate dal Colony Commander.
  - B) Tutte passano da APPROVED; il Mission Controller approva quelle normali, il Colony Commander quelle con rischio HIGH_RISK o CRITICAL. Per queste ultime vale la separazione dei compiti: chi crea non approva.
- **Proposta:** B. Criticità = `safetyLevel`.

### Q-08 – Fino a quando deve valere una certificazione? ❓
- **Fonti in conflitto:**
  - BR-004 parla di validità «alla data della missione», ma una missione ha un inizio e una fine.
  - ARES-105 dice che non è ancora obbligatorio bloccare le assegnazioni.
  - Lo scenario 19.1/2 e UC-06 invece bloccano l'approvazione.
- **Proposta:** la certificazione deve essere valida per tutta la finestra pianificata, fino alla fine. Il blocco si applica all'approvazione appena esistono i requisiti di missione (MIS-004).

## Flotta e manutenzione

### Q-09 – Quando un mezzo non è assegnabile? ❓
- **Fonti in conflitto:**
  - BR-005 e lo scenario 19.1/5 citano solo Out of Service.
  - TIT-303 aggiunge MAINTENANCE.
  - TIT-306 parla di «intervento bloccante», quindi esistono anche interventi non bloccanti.
  - Non è chiaro cosa succede alle missioni già assegnate quando il mezzo si guasta.
- **Codice oggi:** gli stati del mezzo sono AVAILABLE, IN_USE, MAINTENANCE, OUT_OF_SERVICE e DECOMMISSIONED.
- **Proposta:**
  - Un mezzo è assegnabile solo se è AVAILABLE e non ha interventi bloccanti aperti.
  - Aprire un intervento bloccante porta il mezzo in MAINTENANCE (risponde anche a TIT-304).
  - Le missioni future già assegnate vengono segnalate, non annullate.

### Q-10 – Guasto, manutenzione e incidente sono la stessa cosa? ❓
- **Fonti in conflitto:**
  - MNT-002 descrive un «ticket guasto» con severità.
  - TIT-304 descrive una manutenzione con priorità.
  - Per MNT-006 un incidente può riguardare anche un asset.
  - Per UC-02 un guasto critico «crea l'incidente».
- **Proposta:**
  - Un guasto apre un intervento di manutenzione, che ha una priorità.
  - Se è critico apre anche un incidente collegato, che ha una severità.
  - La severità esiste solo sugli incidenti.

## Incidenti

### Q-11 – Cosa serve per chiudere un incidente? ❓
- **Fonti in conflitto:**
  - BR-009 chiede motivazione e ruolo autorizzato solo per gli incidenti critici.
  - HEL-505 rende la risoluzione obbligatoria per tutti.
  - MNT-008 chiede la causa radice per gli incidenti «importanti».
  - HEL-505 permette la chiusura da qualunque stato non chiuso, mentre MNT-005 descrive un flusso a passi.
- **Codice oggi:** gli stati sono OPEN, ACKNOWLEDGED, IN_PROGRESS, RESOLVED, CLOSED e CANCELLED.
- **Proposta:**
  - Risoluzione obbligatoria per tutti.
  - Per HIGH e CRITICAL (= «importante») servono anche la causa radice e il permesso `INCIDENT_MANAGE`.
  - La chiusura è ammessa da qualunque stato non terminale.

### Q-12 – Quali incidenti sono «attivi»? ❓
- **Fonte:** HEL-506 dice «solo incidenti attivi» senza definirli.
- **Proposta:** sono attivi gli incidenti OPEN, ACKNOWLEDGED e IN_PROGRESS. RESOLVED, CLOSED e CANCELLED non sono attivi.

## Basi ed equipaggio

### Q-13 – Base, colonia e habitat: chi ha la capacità? ❓
- **Fonti in conflitto:**
  - I mission pack usano «base/colonia» come sinonimi, e il dataset (§19) ha anche «Outpost» e «Relay».
  - COL-002 assegna la capacità agli habitat, mentre ARES-102 e ARES-104 la chiedono per la base.
- **Codice oggi:** `max_capacity` esiste solo su `habitat`.
- **Proposta:** base = colonia, outpost compresi. La capacità della base è la somma delle capacità degli habitat attivi.

### Q-14 – Chi conta nell'occupazione di una base? ❓
- **Fonti in conflitto:** ARES-102 e ARES-107 parlano di «membri attualmente assegnati» senza dire se contano le persone in malattia, fuori servizio o in missione esterna.
- **Proposta:** contano tutti i membri non INACTIVE che hanno quella base come colonia di assegnazione.

### Q-15 – Quali stati del membro impediscono un'assegnazione? ❓
- **Fonti in conflitto:** ARES-104, PHX-203 e HEL-503 escludono solo INACTIVE, ma il modello ha anche OFF_DUTY, TRAINING, MEDICAL_LEAVE e SUSPENDED.
- **Proposta:**
  - A una base si assegnano tutti tranne INACTIVE.
  - A una missione o come responder di un incidente si assegnano solo gli ACTIVE.

## Accessi, ruoli e dati

### Q-16 – Quali ruoli applicativi servono? ❓
- **Fonti in conflitto:**
  - La §3 elenca Medical Officer, Security & Compliance, Data & Analytics e Platform Administrator, che mancano dai ruoli minimi della §3.1.
  - Il Platform Administrator «non interviene sulle regole di business», mentre Security & Compliance «definisce ruoli».
  - HEL-505 cita un «responsabile sicurezza» che non è un ruolo.
- **Proposta:**
  - Admin = Platform Administrator: gestisce account e ruoli, con audit.
  - Il «responsabile sicurezza» è chi ha `INCIDENT_MANAGE` (Colony Commander, Mission Controller).
  - Nessun ruolo Medical Officer finché non serve, perché i dati clinici sono fuori ambito (§4.2).

### Q-17 – La sessione è accettata o servono OAuth2/JWT? ❓
- **Fonti in conflitto:** IAM-007 parla di «sessione/token», mentre la Release 6 (§15) cita OAuth2/JWT.
- **Codice oggi:** cookie di sessione + CSRF ([ADR-0012](../adr/0012-session-authentication-and-permission-checks.md)).
- **Proposta:** tenere la sessione per la SPA. OAuth2/SSO resta come estensione (§20).

### Q-18 – Quali stati deve avere un account? ❓
- **Fonti in conflitto:**
  - IAM-003 chiede attivato, sospeso e disabilitato.
  - La §11 chiede di poter «bloccare» un account.
  - IAM-008 chiede il blocco dopo tentativi falliti.
- **Codice oggi:** gli stati sono ACTIVE, LOCKED, DISABLED e PENDING. Il blocco per tentativi falliti è temporaneo (`locked_until`) e non cambia lo stato.
- **Proposta:** «sospeso» = LOCKED, impostato a mano dall'Admin. Il blocco per tentativi resta temporaneo.

### Q-19 – Qualcuno può cancellare fisicamente i dati storici? ❓
- **Fonti in conflitto:**
  - BR-010 vieta la cancellazione fisica solo all'«utente ordinario», lasciando intendere che altri possano.
  - La §11 chiede di minimizzare i dati personali.
  - Audit e storico vanno conservati.
- **Proposta:**
  - Nessuno cancella fisicamente dati storici dall'applicazione.
  - I dati personali di chi lascia il programma vengono anonimizzati, mantenendo la storia.

### Q-20 – Che convenzione oraria si usa? ❓
- **Fonte:** BR-011 chiede «una convenzione unica» senza dire quale. Su Marte potrebbe servire l'ora marziana (MTC/sol).
- **Codice oggi:** UTC.
- **Proposta:** UTC in persistenza e nelle API. Il sol potrà essere aggiunto come formato di visualizzazione.

### Q-21 – Una missione può avere una categoria non prevista? ❓
- **Fonti in conflitto:** MIS-002 chiede una categoria «configurabile», ma lo schema ha un elenco fisso.
- **Proposta:** elenco fisso per l'MVP; la tabella di categorie configurabili arriva quando servirà.

## Processo

### Q-22 – Che review vale in un progetto individuale? ❓
- **Fonti in conflitto:** i mission pack chiedono la review di «una persona diversa dall'autore» in squadre di 26 studenti, ma questo progetto ha un solo sviluppatore.
- **Proposta:** la CI verde, i controlli automatici (ArchitectureTest, Error Prone, test negativi) e l'auto-revisione documentata nella PR sostituiscono la review di un compagno.
