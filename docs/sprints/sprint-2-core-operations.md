<!-- Generated from the original Word document with pandoc; edit this Markdown, it is now the source of truth. -->

**PROJECT AETHER**

**SPRINT 2 – STUDENT MISSION PACK**

*Core Operations: regole di business, integrazione, transazioni e qualità*

| **Prodotto**    | AETHER – Mars Operations Platform                             |
|-----------------|---------------------------------------------------------------|
| **Ciclo**       | Sprint 2 – CORE OPERATIONS • 5 giorni                         |
| **Destinatari** | Studenti / Development Teams                                  |
| **Metodo**      | Scrum • GitHub Projects • GitHub Flow • PR • Code Review • CI |

**Sprint Goal: collegare i domini AETHER e rendere affidabili le principali regole di business.**

# 1. Missione dello Sprint

> **Sprint Goal**
>
> Mission Control può collegare persone, missioni, mezzi, risorse e incidenti mantenendo coerenti le principali regole operative.

Sprint 2 non è una gara a creare endpoint. Il valore sta nel far collaborare i domini e nell’impedire stati impossibili. La regola è: un dato non è corretto perché “la schermata sembra giusta”; deve restare corretto nel database e nel backend anche con input errati.

# 2. Come scegliere lo Sprint Backlog

- Guardate la velocity reale dello Sprint 1.
- Controllate la Definition of Ready.
- Stimate con 1,2,3,5,8.
- Scegliete un carico sostenibile; le Story stretch non sono obbligatorie.
- Primary + Buddy su ogni Story; WIP massimo consigliato 2.

# 3. Backlog candidato per squad

| **Squad** | **Core**            | **Stretch** | **Punti indicativi** |
|-----------|---------------------|-------------|----------------------|
| ARES      | ARES-102 + ARES-104 | ARES-105    | 5 + 5 (+5)           |
| PHOENIX   | PHX-202 + PHX-203   | PHX-204     | 5 + 8 (+5)           |
| TITAN     | TIT-302 + TIT-304   | TIT-303     | 5 + 5 (+8)           |
| ORION     | ORI-402 + ORI-403   | ORI-405     | 5 + 8 (+5)           |
| HELIOS    | HEL-503 + HEL-505   | HEL-502     | 5 + 5 (+3)           |

Le stime sono un punto di partenza: il team può cambiarle durante il Planning motivando la scelta.

# 4. Squad ARES

## ARES-102 – Dettaglio base e capacità \[5 SP indicativi\]

> **User Story**
>
> Come Mission Control voglio conoscere capacità e occupazione di una base per valutarne la disponibilità operativa.

**Acceptance Criteria**

- Dettaglio base recuperabile per identificativo/codice.
- Capacità massima disponibile e numero membri attualmente assegnati.
- Il conteggio deriva dai dati persistiti, non da valori hardcoded.
- Base inesistente produce 404/errore coerente.
- L’interfaccia evidenzia almeno il rapporto occupazione/capacità.

**Domande che il team deve risolvere**

- Da quale relazione deriva l’occupazione?
- Cosa succede se una base non ha membri?
- Il dato capacità può essere NULL?

## ARES-104 – Assegnazione membro a una base \[5 SP indicativi\]

> **User Story**
>
> Come responsabile equipaggi voglio assegnare un membro a una base senza superarne la capacità.

**Acceptance Criteria**

- Membro e base devono esistere.
- Un membro INACTIVE non è assegnabile.
- L’assegnazione non può portare la base oltre la capacità.
- Riassegnazione gestita senza creare duplicazioni.
- Conflitti restituiscono un errore di business comprensibile.

**Domande che il team deve risolvere**

- Come gestite trasferimento e riassegnazione?
- Dove applicate il controllo di capacità?
- Qual è il comportamento per un membro INACTIVE?

## ARES-105 – Competenze e certificazioni \[5 SP indicativi\]

> **User Story**
>
> Come planner voglio conoscere le certificazioni dei membri per preparare le future assegnazioni alle missioni.

**Acceptance Criteria**

- Relazione molti-a-molti membro-certificazione modellata correttamente.
- Data conseguimento e data scadenza rappresentabili.
- Certificazioni consultabili dal profilo.
- Non è ancora obbligatorio bloccare assegnazioni di missione in base alle certificazioni.

**Domande che il team deve risolvere**

- Dove vive la data di scadenza nella relazione?
- Come modellate N:M?
- Come evitate duplicati della stessa certificazione per lo stesso membro?

# 4. Squad PHOENIX

## PHX-202 – Workflow stato missione \[5 SP indicativi\]

> **User Story**
>
> Come operatore voglio far avanzare una missione nel suo ciclo di vita senza consentire transizioni incoerenti.

**Acceptance Criteria**

- Almeno DRAFT→PLANNED e PLANNED→APPROVED implementate.
- Transizioni illegali rifiutate dal backend.
- La transizione non dipende da valori arbitrari del frontend.
- Missione inesistente produce 404.
- La scelta del workflow è documentata.

**Domande che il team deve risolvere**

- Quali transizioni sono ammesse?
- Chi decide lo stato: client o server?
- Come rappresentate una transizione illegale?

## PHX-203 – Assegnazione equipaggio alla missione \[8 SP indicativi\]

> **User Story**
>
> Come planner voglio comporre l’equipaggio di una missione per prepararla all’esecuzione.

**Acceptance Criteria**

- Missione e membro devono esistere.
- Membro INACTIVE non assegnabile.
- Lo stesso membro non può essere duplicato nella stessa missione.
- È registrabile il ruolo operativo nella missione.
- Le assegnazioni sono recuperabili nel dettaglio missione.

**Domande che il team deve risolvere**

- Come impedite duplicati?
- Qual è il ruolo del membro nella missione?
- Come recuperate equipaggio + dati persona senza duplicare anagrafiche?

## PHX-204 – Comandante della missione \[5 SP indicativi\]

> **User Story**
>
> Come Mission Control voglio designare un solo comandante tra i membri dell’equipaggio.

**Acceptance Criteria**

- Il comandante deve appartenere all’equipaggio della missione.
- Massimo un comandante attivo per missione.
- Cambio comandante gestito in modo coerente.
- Vincolo garantito server-side.

**Domande che il team deve risolvere**

- Come garantite un solo comandante?
- Il comandante è un membro o un’entità distinta?
- Cosa succede cambiando comandante?

# 4. Squad TITAN

## TIT-302 – Aggiornamento stato veicolo \[5 SP indicativi\]

> **User Story**
>
> Come tecnico voglio modificare lo stato operativo di un veicolo affinché Mission Control conosca la sua reale disponibilità.

**Acceptance Criteria**

- Stati ammessi controllati.
- Aggiornamento persistito.
- Transizioni palesemente impossibili possono essere rifiutate o motivate.
- UI aggiorna il dato senza necessità di modifica manuale del DB.

**Domande che il team deve risolvere**

- Quali stati ammettete?
- Tutte le transizioni sono sensate?
- Come reagisce la UI a un errore di dominio?

## TIT-304 – Apertura manutenzione \[5 SP indicativi\]

> **User Story**
>
> Come tecnico voglio aprire un intervento di manutenzione su un veicolo per impedirne l’uso quando non sicuro.

**Acceptance Criteria**

- Veicolo esistente obbligatorio.
- Descrizione problema, priorità e timestamp apertura.
- Stato intervento iniziale OPEN.
- Il team definisce se e come lo stato del mezzo cambia automaticamente.
- Intervento recuperabile nello storico del veicolo.

**Domande che il team deve risolvere**

- Lo stato del mezzo cambia all’apertura?
- Come conservate lo storico?
- Quali dati rendono utile una manutenzione?

## TIT-303 – Assegnazione veicolo a missione \[8 SP indicativi\]

> **User Story**
>
> Come planner voglio assegnare un mezzo disponibile a una missione evitando conflitti operativi.

**Acceptance Criteria**

- Missione e veicolo devono esistere.
- Mezzo in MAINTENANCE o OUT_OF_SERVICE non assegnabile.
- Lo stesso mezzo non può risultare contemporaneamente assegnato a due missioni incompatibili.
- La regola è garantita dal backend/DB, non soltanto dalla UI.
- Caso di conflitto verificabile con un test.

**Domande che il team deve risolvere**

- Come definite “disponibile”?
- Come impedite doppia assegnazione?
- Quale test negativo dimostra davvero la regola?

# 4. Squad ORION

## ORI-402 – Stock per base \[5 SP indicativi\]

> **User Story**
>
> Come logistica voglio conoscere la quantità di ciascuna risorsa presente in ogni base.

**Acceptance Criteria**

- Una sola posizione stock per coppia base-risorsa.
- Quantità mai negativa.
- Elenco stock filtrabile almeno per base.
- Sono supportate più unità tramite il catalogo risorse, senza duplicarne il significato nello stock.

**Domande che il team deve risolvere**

- Dove sta l’unità di misura?
- Come garantite unicità base-risorsa?
- Come rappresentate stock zero?

## ORI-403 – Movimenti di carico e scarico \[8 SP indicativi\]

> **User Story**
>
> Come magazziniere voglio registrare movimenti che aggiornano lo stock mantenendo saldo e storico coerenti.

**Acceptance Criteria**

- Movimento identifica base, risorsa, tipo, quantità e timestamp.
- Quantità del movimento positiva.
- Uno scarico non può portare il saldo sotto zero.
- Registrazione movimento e aggiornamento saldo avvengono nella stessa transazione.
- In caso di errore nessun aggiornamento parziale resta persistito.

**Domande che il team deve risolvere**

- Che differenza c’è tra movimento e saldo?
- Cosa deve succedere se lo scarico fallisce?
- Quale parte deve essere transazionale?

## ORI-405 – Soglia minima di sicurezza \[5 SP indicativi\]

> **User Story**
>
> Come responsabile base voglio definire una soglia minima per sapere quando una risorsa diventa critica.

**Acceptance Criteria**

- Soglia configurabile per coppia base-risorsa.
- Soglia non negativa.
- Una risorsa senza soglia rimane valida.
- È possibile identificare se lo stock corrente è sotto soglia.

**Domande che il team deve risolvere**

- Soglia e quantità sono la stessa informazione?
- Una soglia può mancare?
- Come trovate le risorse critiche?

# 4. Squad HELIOS

## HEL-503 – Assegnazione responder \[5 SP indicativi\]

> **User Story**
>
> Come coordinatore voglio assegnare personale alla gestione di un incidente per distribuire le responsabilità.

**Acceptance Criteria**

- Incidente e membro devono esistere.
- Membro INACTIVE non assegnabile.
- Più responder possibili per incidente.
- Nessuna assegnazione duplicata.
- Responder visibili nel dettaglio incidente.

**Domande che il team deve risolvere**

- Una persona può essere responder di più incidenti?
- Come impedite duplicati?
- Come visualizzate i responder senza duplicare anagrafiche?

## HEL-505 – Chiusura incidente \[5 SP indicativi\]

> **User Story**
>
> Come responsabile sicurezza voglio chiudere un incidente registrandone la risoluzione.

**Acceptance Criteria**

- Solo incidenti non già chiusi possono essere chiusi.
- Risoluzione obbligatoria.
- Timestamp di chiusura deciso dal backend.
- Stato finale coerente e persistito.
- Una seconda chiusura viene rifiutata in modo comprensibile.

**Domande che il team deve risolvere**

- Quale informazione è obbligatoria per chiudere?
- Chi genera il timestamp?
- Cosa succede chiudendo due volte?

## HEL-502 – Filtro e classificazione severità \[3 SP indicativi\]

> **User Story**
>
> Come Mission Control voglio filtrare gli incidenti per severità per concentrarmi su quelli più urgenti.

**Acceptance Criteria**

- Severità controllata secondo il vocabolario condiviso.
- Filtro per severità disponibile.
- Valore di filtro non valido gestito.
- Ordinamento o priorità visiva coerente con la severità.

**Domande che il team deve risolvere**

- Qual è l’ordine delle severità?
- Il filtro viene validato?
- Come viene mostrato un elenco senza risultati?

# 5. Dependency Contract

Prima di modificare dati/API usati da altre squad, aprite o aggiornate la relativa Issue e fate un breve contract sync. Per ogni dipendenza annotate:

- producer (chi espone il dato/servizio);
- consumer;
- identificativo e formato;
- endpoint o tabella/interfaccia coinvolta;
- cosa è stabile e cosa può cambiare;
- chi deve essere avvisato prima del merge.

# 6. Regole tecniche obbligatorie

- Niente push diretto su main.
- Ogni Story/bug significativo parte da una Issue.
- PR revisionata da almeno una persona diversa dall’autore.
- I vincoli di business importanti vivono nel backend/DB, non solo nella UI.
- I dati non si “aggiustano” manualmente nel DB per far funzionare la demo.
- Testate almeno un caso negativo per Story.
- Le operazioni che aggiornano più dati coerenti devono essere considerate come unità transazionali.
- Riducete le PR: review di cambiamenti piccoli è parte del lavoro, non burocrazia.

# 7. Mini-check ACID

| **A**          | **C**                    | **I**                   | **D**                          |
|----------------|--------------------------|-------------------------|--------------------------------|
| Atomicity      | Consistency              | Isolation               | Durability                     |
| Tutto o niente | Invarianti sempre valide | Concorrenza controllata | Commit che sopravvive ai crash |

Durante lo Sprint provate a identificare almeno una vostra operazione che dipende da ciascuno dei quattro principi.

# 8. Sprint Review – cosa portare

- Software integrato su main.
- Issue e PR collegate.
- Un happy path e almeno un caso negativo.
- Query/DB reali: niente mock usati per nascondere integrazioni mancanti.
- Spiegazione di una regola di business e di dove viene garantita.
- Un problema incontrato e la decisione presa dal team.

# 9. Quando una Story non è Done

> **Niente “90% Done”**
>
> Se manca review, test, merge, Acceptance Criterion o integrazione necessaria, la Story non è Done. Torna nel backlog/Sprint successivo con il suo stato reale. La trasparenza vale più di una board tutta verde.
