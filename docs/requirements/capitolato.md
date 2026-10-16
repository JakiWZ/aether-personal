<!-- Generated from the original Word document with pandoc; edit this Markdown, it is now the source of truth. -->

**AETHER**

**MARS OPERATIONS PLATFORM**

**Capitolato di progetto e Documento di Analisi dei Requisiti**

*Capstone evolutivo per percorso Full-Stack Developer*

| **Cliente**             | Aether Frontier Consortium (AFC)                                                    |
|-------------------------|-------------------------------------------------------------------------------------|
| **Prodotto**            | AETHER – piattaforma digitale per operazioni di colonia e mission control           |
| **Versione documento**  | 1.0 – Student Project Brief                                                         |
| **Modello di consegna** | Progetto incrementale: Data → Backend → Frontend → Big Data → Security → Cloud → AI |

> *Il cliente descrive il problema e i requisiti. Il team di sviluppo deve progettare dati, architettura, API, interfacce, test e infrastruttura. Nessuna soluzione tecnica completa è fornita nel presente documento.*

# Indice del documento

- 1. Mandato del cliente e contesto
- 2. Visione, obiettivi e indicatori di successo
- 3. Stakeholder e utenti
- 4. Ambito e confini del progetto
- 5. Domini funzionali
- 6. Requisiti funzionali
- 7. Regole di business
- 8. Requisiti informativi e dati
- 9. Casi d’uso e processi critici
- 10. Requisiti non funzionali
- 11. Sicurezza, privacy e audit
- 12. Analytics, Big Data e telemetria
- 13. Evoluzione AI
- 14. Infrastruttura, DevOps e cloud
- 15. Roadmap di progetto
- 16. Deliverable richiesti al team
- 17. Criteri di accettazione
- 18. Organizzazione del lavoro
- 19. Dataset narrativo iniziale
- 20. Estensioni opzionali e tesi finale

# 1. Mandato del cliente e contesto

Aether Frontier Consortium (AFC) è un consorzio internazionale pubblico-privato che coordina la costruzione e la gestione di insediamenti permanenti su Marte. Dopo una prima fase sperimentale gestita con strumenti separati, fogli di calcolo, sistemi di telemetria verticali e procedure manuali, AFC ha approvato la realizzazione di una piattaforma software unica denominata AETHER.

AETHER dovrà diventare il punto centrale per Mission Control, personale scientifico, logistica, manutenzione e responsabili delle colonie. Il sistema dovrà supportare sia attività amministrative relativamente semplici sia processi operativi critici, mantenendo una chiara separazione fra dati transazionali, telemetria ad alta frequenza, analytics e funzionalità future basate su AI.

AFC affida al team di sviluppo l’intero ciclo di vita del prodotto: analisi, modellazione dei dati, implementazione backend, frontend, integrazione, qualità, sicurezza, osservabilità, automazione e distribuzione cloud.

## 1.1 Problemi attuali

- Dati operativi dispersi in sistemi diversi e difficili da correlare.
- Assenza di una visione unica su missioni, persone, risorse, incidenti e attività scientifiche.
- Difficoltà nel ricostruire chi ha modificato un dato e quando.
- Pianificazione delle missioni manuale, con rischio di conflitti su personale, mezzi e attrezzature.
- Telemetria dei sistemi ambientali disponibile ma poco sfruttata per analisi storiche e prevenzione.
- Report prodotti manualmente e non omogenei tra una colonia e l’altra.
- Processi di emergenza ancora troppo dipendenti da comunicazioni non strutturate.

## 1.2 Mandato al team

Il team dovrà tradurre i requisiti di business in una soluzione software professionale. È esplicitamente richiesto che il team motivi le proprie scelte: modello dati, normalizzazione, vincoli, pattern, struttura del backend, contratti API, organizzazione del frontend, strategia di sicurezza, deployment e osservabilità.

# 2. Visione, obiettivi e indicatori di successo

Visione di prodotto: “Un’unica control room digitale capace di trasformare dati operativi, scientifici e logistici in decisioni affidabili per la vita quotidiana di una colonia marziana.”

| **Obiettivo**          | **Descrizione**                                                                                    |
|------------------------|----------------------------------------------------------------------------------------------------|
| **O1 – Unificazione**  | Centralizzare le informazioni essenziali senza creare duplicazioni incontrollate.                  |
| **O2 – Operatività**   | Permettere pianificazione, assegnazione, esecuzione e consuntivazione delle missioni.              |
| **O3 – Sicurezza**     | Applicare autorizzazioni coerenti con ruoli e responsabilità e registrare le operazioni sensibili. |
| **O4 – Osservabilità** | Rendere visibili anomalie, incidenti, consumi e stato dei sistemi critici.                         |
| **O5 – Scalabilità**   | Consentire l’aggiunta di nuove colonie, sensori, missioni e utenti senza riprogettare il prodotto. |
| **O6 – Evoluzione**    | Preparare una base tecnica su cui inserire Big Data, streaming, AI e automazione cloud.            |

## 2.1 KPI indicativi del cliente

- Almeno il 95% delle attività operative deve poter essere ricostruito dal sistema senza consultare file esterni.
- Una missione non deve poter essere approvata se viola vincoli essenziali di disponibilità del personale o dei mezzi.
- Gli utenti autorizzati devono raggiungere le informazioni principali di una colonia in pochi passaggi.
- Gli incidenti critici devono essere tracciati dalla segnalazione alla chiusura, con responsabilità e tempi.
- La piattaforma deve poter gestire dati di telemetria con volumi molto maggiori rispetto ai normali dati gestionali.

# 3. Stakeholder e utenti

| **Voce**                   | **Descrizione**                                                                                           |
|----------------------------|-----------------------------------------------------------------------------------------------------------|
| **AFC Program Director**   | Sponsor del prodotto; definisce priorità, budget e criteri di successo.                                   |
| **Mission Control**        | Pianifica missioni, assegna risorse, controlla esecuzione e anomalie.                                     |
| **Colony Commander**       | Responsabile operativo di una colonia; approva attività ad alto impatto.                                  |
| **Science Lead**           | Gestisce esperimenti, laboratori, campioni e risultati scientifici.                                       |
| **Logistics Officer**      | Gestisce scorte, rifornimenti, trasferimenti e soglie minime.                                             |
| **Maintenance Engineer**   | Gestisce asset tecnici, manutenzioni preventive e interventi correttivi.                                  |
| **Medical Officer**        | Consulta informazioni operative necessarie alla sicurezza del personale, nei limiti delle autorizzazioni. |
| **Crew Member**            | Consulta missioni assegnate, turni, notifiche e attività personali.                                       |
| **Security & Compliance**  | Definisce ruoli, audit, accessi e requisiti di sicurezza.                                                 |
| **Data & Analytics Team**  | Analizza telemetria, consumi, performance e trend storici.                                                |
| **Platform Administrator** | Configura il sistema senza intervenire direttamente sulle regole di business.                             |
| **External Auditor**       | Accede in sola lettura a evidenze e log autorizzati.                                                      |

## 3.1 Ruoli applicativi minimi

Il prodotto dovrà prevedere almeno i ruoli Admin, Mission Controller, Colony Commander, Scientist, Logistics, Maintenance, Crew e Auditor. Il team può introdurre ruoli aggiuntivi purché motivati. Le autorizzazioni non devono dipendere unicamente da ciò che il frontend mostra o nasconde.

# 4. Ambito e confini del progetto

## 4.1 In scope

- Gestione identità applicative, profili, ruoli e stato account.
- Gestione colonie, habitat, moduli, aree operative e asset principali.
- Gestione membri dell’equipaggio, competenze, certificazioni e disponibilità.
- Pianificazione ed esecuzione di missioni interne ed esterne.
- Gestione risorse consumabili e inventario logistico.
- Gestione manutenzioni, guasti, incidenti e azioni correttive.
- Gestione esperimenti scientifici e campioni.
- Acquisizione e analisi di telemetria ambientale e tecnica.
- Notifiche, dashboard, reportistica e audit.
- API documentate, interfaccia web responsive, test automatizzati e deployment ripetibile.

## 4.2 Fuori scope iniziale

- Controllo diretto di hardware reale o sistemi life-support fisici.
- Autenticazione biometrica reale.
- Elaborazione di cartelle cliniche complete.
- Sistemi di pagamento, fatturazione o e-commerce.
- Navigazione autonoma di rover o veicoli reali.
- Decisioni totalmente autonome dell’AI su attività safety-critical.

# 5. Domini funzionali

| **Dominio**                     | **Responsabilità**                                                       |
|---------------------------------|--------------------------------------------------------------------------|
| **Colony & Habitat Management** | Struttura delle colonie, habitat, moduli, aree e capacità operative.     |
| **Crew & Skills**               | Persone, ruoli, competenze, certificazioni, turni e disponibilità.       |
| **Mission Operations**          | Missioni, obiettivi, fasi, equipaggi, mezzi, attrezzature e stato.       |
| **Resource & Logistics**        | Scorte, lotti, movimenti, consumi, soglie e rifornimenti.                |
| **Maintenance & Incidents**     | Asset tecnici, guasti, ticket, interventi, severità e chiusura.          |
| **Science & Samples**           | Esperimenti, laboratori, protocolli, campioni, provenienza e risultati.  |
| **Telemetry & Events**          | Misure sensoriali, eventi tecnici, stream, qualità del dato e retention. |
| **Communication & Alerts**      | Notifiche, alert, escalation e conferma presa visione.                   |
| **Analytics & Reporting**       | Indicatori, trend, aggregazioni e dataset analitici.                     |
| **Security & Audit**            | Autorizzazione, registrazione azioni, accessi e tracciabilità.           |

# 6. Requisiti funzionali

I requisiti seguenti descrivono il comportamento atteso, non la soluzione tecnica. Il team dovrà derivare user story, casi d’uso, modello dati e API.

## 6.1 Identità e accesso

| **ID**      | **Titolo**                | **Requisito**                                                                                                          |
|-------------|---------------------------|------------------------------------------------------------------------------------------------------------------------|
| **IAM-001** | **Registrazione account** | Un amministratore deve poter creare un account associandolo a una persona esistente o a un profilo operativo previsto. |
| **IAM-002** | **Autenticazione**        | Un utente deve autenticarsi prima di accedere alle funzioni riservate.                                                 |
| **IAM-003** | **Stato account**         | Gli account devono poter essere attivati, sospesi e disabilitati senza cancellare la storia delle attività.            |
| **IAM-004** | **Ruoli**                 | Un utente può possedere uno o più ruoli applicativi compatibili con le policy stabilite.                               |
| **IAM-005** | **Autorizzazioni**        | Ogni operazione protetta deve essere verificata lato server.                                                           |
| **IAM-006** | **Profilo personale**     | L’utente deve poter consultare le proprie informazioni operative, competenze e incarichi correnti.                     |
| **IAM-007** | **Sessione e logout**     | Il sistema deve gestire scadenza della sessione/token e logout sicuro.                                                 |
| **IAM-008** | **Tentativi falliti**     | Gli accessi falliti devono essere registrati secondo una policy configurabile.                                         |

## 6.2 Colonie, habitat e asset

| **ID**      | **Titolo**             | **Requisito**                                                                                       |
|-------------|------------------------|-----------------------------------------------------------------------------------------------------|
| **COL-001** | **Anagrafica colonia** | Gestire più colonie con nome, codice, coordinate/area, stato operativo e comandante responsabile.   |
| **COL-002** | **Struttura habitat**  | Ogni colonia può essere composta da più habitat/moduli con funzione, capacità e stato.              |
| **COL-003** | **Asset tecnici**      | Registrare asset come generatori, impianti aria/acqua, serre, rover, antenne e sistemi di supporto. |
| **COL-004** | **Stato asset**        | Ogni asset deve avere uno stato operativo coerente e una cronologia degli eventi principali.        |
| **COL-005** | **Responsabile asset** | Gli asset critici possono avere uno o più responsabili tecnici.                                     |
| **COL-006** | **Disattivazione**     | Un asset dismesso non deve sparire dalla storia di missioni, manutenzioni o incidenti.              |
| **COL-007** | **Ricerca e filtri**   | Gli utenti autorizzati devono poter cercare asset per colonia, tipo, stato e criticità.             |

## 6.3 Equipaggio, competenze e certificazioni

| **ID**      | **Titolo**               | **Requisito**                                                                                                     |
|-------------|--------------------------|-------------------------------------------------------------------------------------------------------------------|
| **CRW-001** | **Profilo equipaggio**   | Registrare dati identificativi operativi, mansione, colonia di assegnazione e stato di disponibilità.             |
| **CRW-002** | **Competenze**           | Un membro può possedere più competenze con livello e data di valutazione.                                         |
| **CRW-003** | **Certificazioni**       | Registrare certificazioni con rilascio, scadenza e autorità emittente.                                            |
| **CRW-004** | **Verifica idoneità**    | Il sistema deve poter verificare se una persona possiede le competenze/certificazioni richieste per una missione. |
| **CRW-005** | **Indisponibilità**      | Gestire periodi di indisponibilità che impediscano assegnazioni incompatibili.                                    |
| **CRW-006** | **Storico assegnazioni** | Conservare la storia delle missioni e degli incarichi svolti.                                                     |
| **CRW-007** | **Ricerca competenze**   | Mission Control deve poter trovare persone disponibili con una determinata competenza.                            |

## 6.4 Missioni e pianificazione

| **ID**      | **Titolo**                  | **Requisito**                                                                                                    |
|-------------|-----------------------------|------------------------------------------------------------------------------------------------------------------|
| **MIS-001** | **Creazione missione**      | Creare una missione indicando obiettivo, colonia, finestra temporale, priorità, rischio e responsabile.          |
| **MIS-002** | **Tipologia missione**      | Classificare missioni: esplorazione, manutenzione, logistica, scienza, soccorso o altra categoria configurabile. |
| **MIS-003** | **Fasi e task**             | Una missione può essere suddivisa in fasi o attività con ordine, stato e responsabile.                           |
| **MIS-004** | **Requisiti missione**      | Definire competenze, mezzi, asset e attrezzature necessarie.                                                     |
| **MIS-005** | **Assegnazione equipaggio** | Assegnare più membri con ruolo specifico nella missione.                                                         |
| **MIS-006** | **Controllo conflitti**     | Segnalare conflitti temporali o indisponibilità prima dell’approvazione.                                         |
| **MIS-007** | **Approvazione**            | Le missioni ad alta criticità richiedono approvazione da un ruolo autorizzato.                                   |
| **MIS-008** | **Stati**                   | Gestire almeno Draft, Planned, Approved, In Progress, Suspended, Completed, Cancelled.                           |
| **MIS-009** | **Consuntivazione**         | A chiusura missione registrare esito, durata effettiva, note, incidenti e risorse consumate.                     |
| **MIS-010** | **Storico**                 | Le modifiche significative a stato, pianificazione e responsabilità devono essere ricostruibili.                 |

## 6.5 Risorse, magazzino e rifornimenti

| **ID**      | **Titolo**               | **Requisito**                                                                                        |
|-------------|--------------------------|------------------------------------------------------------------------------------------------------|
| **LOG-001** | **Catalogo risorse**     | Gestire risorse consumabili come acqua, ossigeno, cibo, carburante, ricambi e materiali scientifici. |
| **LOG-002** | **Unità di misura**      | Ogni risorsa deve utilizzare un’unità di misura coerente e dichiarata.                               |
| **LOG-003** | **Giacenza**             | Conoscere la quantità disponibile per luogo di stoccaggio.                                           |
| **LOG-004** | **Movimenti**            | Registrare carichi, scarichi, trasferimenti, consumi e rettifiche con causale.                       |
| **LOG-005** | **Lotti e scadenze**     | Per le categorie che lo richiedono gestire lotto, provenienza e data di scadenza.                    |
| **LOG-006** | **Soglia minima**        | Generare una condizione di attenzione quando la giacenza scende sotto la soglia prevista.            |
| **LOG-007** | **Rifornimenti**         | Registrare spedizioni pianificate da Terra o tra colonie con contenuto, quantità, stato e date.      |
| **LOG-008** | **Ricezione**            | La ricezione deve aggiornare le disponibilità senza perdere la tracciabilità della spedizione.       |
| **LOG-009** | **Consumo per missione** | Quando pertinente, associare consumi a una missione o attività specifica.                            |

## 6.6 Manutenzione e incidenti

| **ID**      | **Titolo**               | **Requisito**                                                                                                 |
|-------------|--------------------------|---------------------------------------------------------------------------------------------------------------|
| **MNT-001** | **Piano manutenzione**   | Definire manutenzioni preventive ricorrenti o basate su utilizzo/tempo.                                       |
| **MNT-002** | **Ticket guasto**        | Aprire un ticket su un asset specificando sintomo, severità, segnalatore e momento.                           |
| **MNT-003** | **Assegnazione tecnico** | Assegnare uno o più tecnici agli interventi.                                                                  |
| **MNT-004** | **Ricambi utilizzati**   | Registrare i materiali/ricambi consumati durante un intervento.                                               |
| **MNT-005** | **Stato intervento**     | Gestire apertura, presa in carico, lavorazione, attesa, risoluzione e chiusura.                               |
| **MNT-006** | **Incidenti operativi**  | Registrare incidenti che possono coinvolgere missioni, persone, habitat o asset.                              |
| **MNT-007** | **Escalation**           | Gli incidenti critici devono poter attivare escalation e notifiche a ruoli definiti.                          |
| **MNT-008** | **Root cause**           | A chiusura di un incidente importante deve essere possibile registrare causa, azioni correttive e preventive. |
| **MNT-009** | **Storico asset**        | Dalla scheda di un asset deve essere possibile ricostruire guasti, manutenzioni e incidenti correlati.        |

## 6.7 Scienza, laboratori e campioni

| **ID**      | **Titolo**               | **Requisito**                                                                                         |
|-------------|--------------------------|-------------------------------------------------------------------------------------------------------|
| **SCI-001** | **Esperimenti**          | Gestire esperimenti con obiettivo, responsabile scientifico, stato e protocollo.                      |
| **SCI-002** | **Laboratori**           | Associare esperimenti a laboratori/aree e alle attrezzature utilizzate.                               |
| **SCI-003** | **Campioni**             | Registrare campioni con identificativo univoco, tipo, origine, data di raccolta e posizione corrente. |
| **SCI-004** | **Chain of custody**     | Ogni trasferimento di un campione deve essere tracciabile.                                            |
| **SCI-005** | **Missione di raccolta** | Un campione può essere collegato alla missione che lo ha raccolto.                                    |
| **SCI-006** | **Risultati**            | Registrare risultati sintetici, allegati/metadati e stato di validazione.                             |
| **SCI-007** | **Ricerca**              | Cercare campioni ed esperimenti per origine, missione, responsabile, stato e periodo.                 |

## 6.8 Telemetria, notifiche e dashboard

| **ID**      | **Titolo**              | **Requisito**                                                                             |
|-------------|-------------------------|-------------------------------------------------------------------------------------------|
| **TEL-001** | **Sensori**             | Registrare sensori associati a un asset, modulo o area, con tipo di misura e unità.       |
| **TEL-002** | **Misurazioni**         | Acquisire misure con timestamp, valore, qualità e riferimento al sensore.                 |
| **TEL-003** | **Eventi anomali**      | Identificare e memorizzare eventi che superano soglie o regole definite.                  |
| **TEL-004** | **Alert**               | Creare alert con severità, origine, stato e destinatari.                                  |
| **TEL-005** | **Presa visione**       | Un destinatario deve poter confermare la presa visione di un alert.                       |
| **TEL-006** | **Dashboard colonia**   | Mostrare indicatori sintetici di missioni, incidenti, risorse critiche e sistemi tecnici. |
| **TEL-007** | **Dashboard personale** | Mostrare a ciascun utente attività, missioni e notifiche pertinenti.                      |
| **TEL-008** | **Filtri temporali**    | Grafici e indicatori devono supportare intervalli temporali e aggregazioni coerenti.      |
| **TEL-009** | **Report**              | Consentire l’estrazione di report operativi periodici in un formato esportabile.          |
| **TEL-010** | **Storico alert**       | Conservare chiusura, presa visione ed eventuali escalation.                               |

# 7. Regole di business

| **ID**     | **Titolo**                 | **Requisito**                                                                                                                               |
|------------|----------------------------|---------------------------------------------------------------------------------------------------------------------------------------------|
| **BR-001** | **Identificativi univoci** | Persone, missioni, asset, campioni, spedizioni e incidenti devono essere identificabili univocamente.                                       |
| **BR-002** | **Missioni concluse**      | Una missione Completed non può tornare liberamente in Draft; eventuali correzioni devono lasciare evidenza.                                 |
| **BR-003** | **Conflitto equipaggio**   | Una persona non può essere assegnata a due attività incompatibili nello stesso intervallo temporale.                                        |
| **BR-004** | **Certificazioni**         | Una certificazione scaduta non soddisfa un requisito di idoneità alla data della missione.                                                  |
| **BR-005** | **Asset non operativo**    | Un asset marcato Out of Service non può essere assegnato come disponibile a una nuova missione.                                             |
| **BR-006** | **Movimenti inventario**   | Ogni variazione significativa di giacenza deve derivare da un movimento tracciato, non da modifica arbitraria del totale.                   |
| **BR-007** | **Quantità negative**      | Le giacenze non possono diventare negative salvo esplicita modalità di rettifica autorizzata e auditata.                                    |
| **BR-008** | **Campioni**               | Un campione deve avere una sola posizione corrente, ma molte posizioni storiche.                                                            |
| **BR-009** | **Incidenti critici**      | La chiusura di un incidente critico richiede motivazione e ruolo autorizzato.                                                               |
| **BR-010** | **Cancellazione logica**   | Dati storici collegati a missioni concluse, incidenti o audit non devono essere eliminati fisicamente dall’utente ordinario.                |
| **BR-011** | **Orari**                  | Gli istanti operativi devono essere gestiti in modo coerente; la UI può localizzarli, ma la persistenza deve seguire una convenzione unica. |
| **BR-012** | **Audit**                  | Le modifiche a ruoli, stati missione, inventario critico e incidenti devono essere attribuibili a un utente.                                |
| **BR-013** | **Approvazioni**           | La stessa persona non deve poter approvare alcune operazioni da essa stessa create, quando configurato come separazione dei compiti.        |
| **BR-014** | **Allarmi**                | La chiusura di un alert non elimina le misure che lo hanno originato.                                                                       |
| **BR-015** | **Integrità referenziale** | Non devono esistere riferimenti a entità inesistenti o non coerenti con il dominio.                                                         |

# 8. Requisiti informativi e dati

Il cliente non fornisce un elenco di tabelle. Il team deve ricavare il modello concettuale E-R e successivamente lo schema logico relazionale dai requisiti. La progettazione dovrà essere almeno in terza forma normale quando appropriato, motivando eventuali denormalizzazioni introdotte in fasi successive per finalità analitiche o prestazionali.

## 8.1 Informazioni che il sistema deve rappresentare

- Colonie, habitat, moduli, aree e gerarchie fisico-funzionali.
- Persone, account, ruoli, competenze, certificazioni, disponibilità e assegnazioni.
- Missioni, fasi, task, obiettivi, stati, rischi, approvazioni, persone e asset coinvolti.
- Asset tecnici, tipologie, ubicazione, criticità, stato e storico manutentivo.
- Risorse, unità di misura, lotti, posizioni, movimenti, spedizioni e consumi.
- Incidenti, segnalazioni, assegnazioni, cause, azioni e timeline.
- Esperimenti, protocolli, laboratori, campioni, spostamenti e risultati.
- Sensori, serie di misure, soglie, eventi, alert e presa visione.
- Notifiche, preferenze essenziali, log di audit e metadati tecnici.

## 8.2 Aspetti da decidere e documentare dal team

- Entità, attributi, domini e cardinalità.
- Chiavi naturali e/o surrogate, motivandone l’uso.
- Gestione delle relazioni molti-a-molti e dei relativi attributi.
- Vincoli di unicità, NOT NULL, CHECK e integrità referenziale.
- Politiche ON DELETE/ON UPDATE coerenti con la storia del dato.
- Indici iniziali e motivazione in base ai casi d’uso.
- Strategia di migrazione/versionamento dello schema.
- Dati da trattare come transazionali e dati da trasferire in sistemi analitici/NoSQL in fasi successive.

## 8.3 Requisiti SQL minimi

- Query di ricerca con filtri e ordinamenti combinabili.
- JOIN tra più domini, incluse relazioni molti-a-molti.
- Aggregazioni per colonia, missione, periodo, categoria e stato.
- GROUP BY e HAVING per report e indicatori.
- Subquery e/o EXISTS/NOT EXISTS per verifiche di disponibilità e assenza/presenza di eventi.
- Transazioni per operazioni multi-step come ricezione spedizioni, assegnazioni e consumi.
- Gestione coerente di NULL e valori opzionali.
- Query dedicate a individuare anomalie logiche: risorse sotto soglia, certificazioni in scadenza, asset con troppi guasti, missioni senza copertura di competenze.

# 9. Casi d’uso e processi critici

| **Caso d’uso**                               | **Scenario sintetico**                                                                                                                                |
|----------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------|
| **UC-01 – Pianificare una missione esterna** | Mission Control crea la missione, definisce requisiti, seleziona personale e asset, verifica conflitti e sottopone ad approvazione.                   |
| **UC-02 – Gestire un guasto critico**        | Un tecnico o sensore apre/segnala il problema; il sistema crea l’incidente, notifica i responsabili, assegna intervento e conserva tutta la timeline. |
| **UC-03 – Ricevere un rifornimento**         | Logistica registra arrivo, verifica contenuto, acquisisce lotti/scadenze, aggiorna le scorte tramite movimenti e chiude la spedizione.                |
| **UC-04 – Raccogliere un campione**          | Una missione raccoglie il campione, lo identifica, ne registra origine e custodia, quindi lo trasferisce a un laboratorio.                            |
| **UC-05 – Analizzare consumo di ossigeno**   | Un responsabile confronta consumi per periodo/colonia e identifica scostamenti rispetto alle medie.                                                   |
| **UC-06 – Controllare idoneità equipaggio**  | Prima dell’approvazione, il sistema verifica disponibilità e validità delle certificazioni richieste.                                                 |
| **UC-07 – Audit su una variazione critica**  | Un auditor deve ricostruire autore, data, valore precedente/nuovo o evento equivalente e motivazione dove prevista.                                   |
| **UC-08 – Escalation alert**                 | Un alert critico non preso in carico entro la finestra prevista viene escalato a un livello superiore.                                                |

# 10. Requisiti non funzionali

| **ID**      | **Titolo**                 | **Requisito**                                                                                                                   |
|-------------|----------------------------|---------------------------------------------------------------------------------------------------------------------------------|
| **NFR-001** | **Usabilità**              | L’interfaccia deve essere comprensibile a personale operativo non sviluppatore, con feedback chiari su errori e conferme.       |
| **NFR-002** | **Responsive**             | Le schermate principali devono essere utilizzabili su notebook e tablet; il design mobile può essere progressivo.               |
| **NFR-003** | **Performance**            | Le normali operazioni CRUD e di ricerca devono rispondere in tempi percepiti come interattivi con dataset realistici.           |
| **NFR-004** | **Scalabilità**            | L’architettura deve consentire la crescita del volume di telemetria senza sovraccaricare inutilmente il database transazionale. |
| **NFR-005** | **Affidabilità**           | Le operazioni critiche multi-step devono utilizzare transazioni e non lasciare stati parziali incoerenti.                       |
| **NFR-006** | **Manutenibilità**         | Codice organizzato per responsabilità, con convenzioni condivise, moduli chiari e documentazione minima.                        |
| **NFR-007** | **Testabilità**            | Logica di business importante testabile in modo automatizzato.                                                                  |
| **NFR-008** | **Portabilità**            | Configurazione esterna al codice; ambienti locali e cloud devono differire per configurazione, non per fork applicativi.        |
| **NFR-009** | **Osservabilità**          | Log strutturati, metriche e health check devono permettere diagnosi dei problemi.                                               |
| **NFR-010** | **Accessibilità**          | Form, tabelle e componenti principali devono seguire buone pratiche di accessibilità web.                                       |
| **NFR-011** | **Internazionalizzazione** | Testi e formati devono essere progettati in modo da consentire futura localizzazione.                                           |
| **NFR-012** | **Qualità dati**           | Validazioni lato client utili all’utente e validazioni lato server autoritative.                                                |

# 11. Sicurezza, privacy e audit

- Autenticazione robusta e gestione sicura delle credenziali/token.
- RBAC con autorizzazione lato backend e principio del minimo privilegio.
- Hash delle password con algoritmo adatto; nessuna password in chiaro nei log o nel database.
- Validazione input, gestione errori senza leakage di informazioni interne e protezione dalle principali vulnerabilità OWASP.
- Protezione delle API da accessi non autorizzati e corretta gestione CORS/CSRF in base all’architettura scelta.
- Audit delle operazioni sensibili e distinzione tra log applicativi e audit trail.
- Separazione dei segreti dalla configurazione versionata nel repository.
- Protezione dei dati personali minimizzando ciò che viene memorizzato.
- Possibilità di bloccare un account senza cancellarne l’attività storica.
- Backup e restore documentati almeno per il database transazionale nelle fasi di deploy.

# 12. Analytics, Big Data e telemetria

AETHER nasce con un database relazionale per le operazioni transazionali, ma la telemetria può crescere fino a milioni di misurazioni. In una fase successiva il team dovrà progettare un percorso dati separato per analytics e serie temporali, mantenendo chiaro quale sistema è source of truth per ogni categoria di dato.

## 12.1 Dataset analitici richiesti

- Consumo di risorse per colonia, habitat, giorno/settimana/mese.
- Tasso di guasto degli asset per tipologia e ore di utilizzo.
- Tempi medi di presa in carico e risoluzione degli incidenti.
- Performance delle missioni: durata pianificata vs effettiva, esiti, incidenti, consumo risorse.
- Telemetria ambientale: pressione, temperatura, CO2, ossigeno, energia, radiazione e altre misure configurabili.
- Eventi anomali e frequenza degli alert per sensore/asset/area.
- Carico operativo dell’equipaggio e distribuzione delle competenze.

## 12.2 Evoluzione tecnica attesa

1\. Ingestion batch iniziale da file CSV/JSON per simulare sensori.
2\. Introduzione successiva di messaggistica/event streaming.
3\. Persistenza telemetrica in tecnologia adatta al volume e al tipo di query.
4\. Pipeline di trasformazione/aggregazione e dashboard analitiche.
5\. Dataset storico per sperimentare modelli predittivi e anomaly detection.

# 13. Evoluzione AI

Le funzioni AI non fanno parte del primo MVP. Dovranno essere introdotte solo dopo aver costruito una base dati affidabile e API ben definite. L’AI non potrà eseguire autonomamente azioni safety-critical senza conferma umana.

- Assistente conversazionale che risponde su procedure e stato operativo tramite dati autorizzati.
- RAG su manuali tecnici, procedure e report di incidenti.
- Classificazione automatica di ticket e incidenti con proposta di priorità.
- Rilevamento anomalie su telemetria e consumi.
- Previsione della domanda di risorse e suggerimenti per rifornimenti.
- Riassunto automatico di una missione conclusa e dei relativi eventi.
- Copilot per Mission Control che suggerisce risorse/persone compatibili senza effettuare l’approvazione finale.

# 14. Infrastruttura, DevOps e cloud

Il cliente impone uno stack iniziale coerente con le competenze del team: backend Java/Spring Boot, frontend Angular, database SQL relazionale. Le scelte specifiche di database, provider cloud e servizi aggiuntivi devono essere motivate e documentate.

| **Area**           | **Vincolo / aspettativa**                                                                                                |
|--------------------|--------------------------------------------------------------------------------------------------------------------------|
| **Repository**     | Codice versionato con Git; README riproducibile, convenzioni di commit e gestione delle issue.                           |
| **Backend**        | Servizi REST in Java/Spring Boot; contratto API documentato con OpenAPI.                                                 |
| **Frontend**       | Single Page Application Angular con componenti riutilizzabili e gestione coerente dello stato applicativo.               |
| **Database**       | RDBMS SQL con script/migrazioni versionate e dati demo riproducibili.                                                    |
| **Container**      | Applicazione containerizzabile; sviluppo locale avviabile con istruzioni chiare.                                         |
| **CI**             | Build e test automatici ad ogni push/merge significativo.                                                                |
| **CD**             | Distribuzione automatizzata verso almeno un ambiente di test/staging in una fase avanzata.                               |
| **Cloud**          | Deployment su cloud con configurazione esterna, segreti protetti e accesso al database non esposto inutilmente.          |
| **Monitoring**     | Health endpoint, log centralizzabili e metriche applicative/tecniche.                                                    |
| **IaC**            | Come estensione, infrastruttura descritta con Infrastructure as Code.                                                    |
| **Orchestrazione** | Come estensione, valutare Kubernetes quando il sistema viene suddiviso in servizi o quando la complessità lo giustifica. |
| **Event-driven**   | Come estensione, utilizzare una piattaforma di messaging/streaming per telemetria ed eventi ad alto volume.              |

# 15. Roadmap di progetto

| **Release**                           | **Contenuto principale**                                                                                            |
|---------------------------------------|---------------------------------------------------------------------------------------------------------------------|
| **Release 0 – Discovery**             | Analisi requisiti, glossario, stakeholder map, user story iniziali, casi d’uso, mockup concettuali e backlog.       |
| **Release 1 – Data Foundation**       | Modello E-R, schema logico, normalizzazione, vincoli, DDL, seed data, query di test e transazioni.                  |
| **Release 2 – Backend Core**          | Spring Boot, dominio, persistence, service layer, REST API, validazione, error handling e test.                     |
| **Release 3 – Web Application**       | Angular, routing, autenticazione base, dashboard, CRUD principali, ricerca e integrazione end-to-end.               |
| **Release 4 – Workflow & Quality**    | Mission planning completo, incident workflow, ruoli, test più estesi, OpenAPI, audit e gestione concorrenza.        |
| **Release 5 – Data at Scale**         | Telemetria simulata, NoSQL/time series o data platform, ingestion, aggregazioni e analytics.                        |
| **Release 6 – Security & Resilience** | OAuth2/JWT, hardening, OWASP, segreti, backup/restore, rate limit dove utile, audit maturo.                         |
| **Release 7 – Cloud & DevOps**        | Docker, CI/CD, staging cloud, monitoring, logging; IaC e orchestrazione come evoluzione.                            |
| **Release 8 – Intelligent AETHER**    | Una o più funzioni AI con human-in-the-loop, metriche di qualità e chiari limiti di sicurezza.                      |
| **Release 9 – Thesis Edition**        | Stabilizzazione, documentazione, demo, dataset realistico, architettura finale, retrospettiva e presentazione tesi. |

# 16. Deliverable richiesti al team

| **ID**   | **Deliverable**                                                                    |
|----------|------------------------------------------------------------------------------------|
| **D-01** | Glossario di dominio e domande aperte al cliente.                                  |
| **D-02** | Diagramma E-R e motivazione delle cardinalità.                                     |
| **D-03** | Schema logico relazionale, normalizzazione e data dictionary.                      |
| **D-04** | DDL completo, constraints, migration script e seed data.                           |
| **D-05** | Set di query SQL significative e report richiesti.                                 |
| **D-06** | Diagramma architetturale e ADR per le decisioni tecniche principali.               |
| **D-07** | Backend Spring Boot con test e documentazione API.                                 |
| **D-08** | Frontend Angular integrato al backend.                                             |
| **D-09** | Piano e risultati dei test: unit, integration, API ed end-to-end dove applicabile. |
| **D-10** | Threat model semplificato e security checklist.                                    |
| **D-11** | Pipeline CI/CD e descrizione degli ambienti.                                       |
| **D-12** | Deployment cloud riproducibile e runbook operativo.                                |
| **D-13** | Pipeline/dataset Big Data con almeno un caso di analytics.                         |
| **D-14** | Eventuale modulo AI documentato con dati, prompt/modello, limiti e valutazione.    |
| **D-15** | Manuale utente essenziale, manuale tecnico e presentazione finale di tesi.         |

## 16.1 Cosa il cliente NON consegna

- Il diagramma E-R.
- Il numero di tabelle o la struttura delle chiavi.
- Le classi Java e i package.
- Gli endpoint REST già progettati.
- La struttura dei componenti Angular.
- La scelta finale di cloud, database specifico, messaging o strumenti Big Data.
- La soluzione delle query o gli script completi.

# 17. Criteri di accettazione

- Il sistema è avviabile seguendo esclusivamente la documentazione del repository.
- Lo schema dati può essere creato da zero tramite migration/script versionati.
- Esiste un dataset demo sufficiente a dimostrare i casi d’uso principali.
- Le principali regole di business non possono essere aggirate chiamando direttamente le API.
- Gli endpoint espongono errori coerenti e validano i dati ricevuti.
- Il frontend non contiene credenziali o segreti e gestisce correttamente gli stati di caricamento/errore.
- I flussi critici sono coperti da test automatici significativi.
- Il team sa spiegare il modello dati e le scelte architetturali senza limitarsi a mostrare il codice.
- La demo finale include almeno un percorso completo end-to-end e un caso di errore/violazione di regola.
- Il deployment di tesi è raggiungibile o riproducibile in un ambiente documentato.

# 18. Organizzazione del lavoro

AFC richiede un modello di lavoro iterativo. Il team dovrà evitare di “finire tutto il database” prima di verificare i casi d’uso o di costruire grandi quantità di frontend senza API stabili. Ogni release deve produrre un incremento dimostrabile.

## 18.1 Processo suggerito

1\. Backlog con epiche, user story, criteri di accettazione e priorità.
2\. Sprint brevi con planning, sviluppo, review e retrospettiva.
3\. Pull request/review del codice o meccanismo equivalente.
4\. Issue tracciate per bug, debito tecnico e miglioramenti.
5\. Definition of Done comune: codice, test, documentazione minima e demo.

## 18.2 Ruoli di progetto simulati

- Product Owner / referente del cliente (docente).
- Tech Lead a rotazione.
- Database/Data owner.
- Backend developer.
- Frontend developer.
- QA/Test owner.
- DevOps/Security owner nelle fasi avanzate.

# 19. Dataset narrativo iniziale

Per le prime demo, il cliente suggerisce di costruire dati realistici attorno ai seguenti elementi. I nomi sono volutamente narrativi: il team deve trasformarli in dati coerenti con il proprio modello.

| **Area**         | **Esempi iniziali**                                                                                                                             |
|------------------|-------------------------------------------------------------------------------------------------------------------------------------------------|
| **Colonie**      | Ares Prime (principale), Valles Research Outpost (scientifica), Elysium Relay (logistica/comunicazioni).                                        |
| **Habitat**      | Habitat residenziali, serre, laboratorio geologico, centro medico, officina rover, energy hub, water recycling, communication dome.             |
| **Equipaggio**   | Almeno 30 persone con competenze sovrapposte, certificazioni con scadenze diverse e alcuni periodi di indisponibilità.                          |
| **Missioni**     | Esplorazione canyon, riparazione antenna, recupero rover, raccolta campioni, trasferimento materiali, ispezione pannelli, missione di soccorso. |
| **Asset**        | Rover, droni, generatori, batterie, filtri CO2, moduli di riciclo, antenne, strumenti scientifici.                                              |
| **Risorse**      | Acqua, ossigeno, razioni, metano, batterie, filtri, guarnizioni, kit EVA, reagenti, pezzi di ricambio.                                          |
| **Incidenti**    | Caduta pressione, guasto pompa, rover immobilizzato, sensore incoerente, perdita comunicazione, consumo anomalo di energia.                     |
| **Telemetria**   | Temperature interne/esterne, pressione, O2, CO2, radiazione, energia prodotta/consumata, livello serbatoi, stato batterie.                      |
| **Scienza**      | Campioni di regolite e ghiaccio, colture sperimentali, test materiali, analisi atmosferiche.                                                    |
| **Rifornimenti** | Cargo da Terra con ETA lungo, trasferimenti urgenti tra colonie e consegne parziali.                                                            |

## 19.1 Scenari di test obbligatori

1\. Tentare di assegnare a una missione un astronauta già impegnato nello stesso intervallo.
2\. Tentare di approvare una missione con una certificazione obbligatoria scaduta.
3\. Registrare un consumo che porterebbe la giacenza sotto zero.
4\. Ricevere una spedizione con più risorse e verificare che l’operazione sia atomica.
5\. Mettere un rover fuori servizio e verificare che non venga proposto come disponibile.
6\. Aprire un incidente critico da un alert di telemetria e seguirlo fino alla chiusura.
7\. Trasferire un campione tra due laboratori mantenendo l’intera catena di custodia.
8\. Produrre un report che confronti consumi e incidenti tra due colonie su un periodo.
9\. Individuare persone con competenze richieste che non abbiano missioni sovrapposte.
10\. Ricostruire tramite audit una modifica sensibile effettuata da un utente.

# 20. Estensioni opzionali e tesi finale

Il progetto è intenzionalmente aperto. Dopo il completamento del core, ogni team può specializzarlo scegliendo una o più estensioni, purché non comprometta la qualità delle funzioni già realizzate.

- Mappa interattiva della colonia con asset, missioni e incidenti.
- WebSocket/SSE per alert e telemetria quasi real-time.
- Digital twin semplificato di habitat e sistemi tecnici.
- Sistema di pianificazione turni e reperibilità.
- Event sourcing limitato a uno specifico dominio, come audit avanzato o telemetria.
- Kafka o altra piattaforma event-driven per sensori e integrazioni.
- Data lake/lakehouse didattico per telemetria storica.
- Anomaly detection su consumi o sensori.
- RAG su manuali di manutenzione e procedure operative.
- Multi-agent simulation con un agente per logistica, maintenance e mission control, sempre con human approval.
- Progressive Web App o modalità offline per alcune checklist operative.
- Infrastructure as Code e orchestrazione Kubernetes.
- Chaos/failure simulation e dashboard SRE.
- SSO/OAuth2 con Identity Provider esterno.
- Generazione automatica di report di missione con AI e fonti tracciabili.

## 20.1 Obiettivo della tesi

La tesi non dovrà essere presentata come “un sito con CRUD”, ma come la storia tecnica di un prodotto evoluto per iterazioni. Lo studente/team dovrà mostrare come requisiti iniziali sono diventati modello dati, codice, interfacce, test, infrastruttura e funzionalità data/AI; dovrà inoltre discutere errori, refactoring, trade-off e decisioni cambiate durante il percorso.

# Consegna iniziale al team – Sprint 0

Prima di scrivere codice, AFC richiede al team di produrre e presentare i seguenti artefatti. Questa è la prima attività ufficiale del progetto:

1\. Glossario con almeno 25 termini del dominio.
2\. Elenco di almeno 15 domande da porre al cliente per chiarire requisiti ambigui.
3\. Mappa degli stakeholder e matrice ruoli/funzionalità preliminare.
4\. 10–15 user story prioritarie con criteri di accettazione.
5\. Diagramma E-R preliminare con cardinalità e motivazioni.
6\. Prima proposta di schema relazionale normalizzato fino alla 3NF, ove applicabile.
7\. Individuazione di almeno 5 operazioni che richiedono una transazione ACID.
8\. Individuazione di almeno 5 query/report che richiederanno JOIN, aggregazioni o subquery.
9\. Backlog della Release 1 con stima relativa della complessità.
10\. Presentazione di 10 minuti al “cliente” con rischi, dubbi e scelte iniziali.

> *Fine del capitolato iniziale. Le richieste successive del cliente potranno modificare priorità e introdurre nuovi requisiti: il prodotto deve quindi essere progettato per evolvere.*
