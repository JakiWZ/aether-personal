-- ============================================================
-- AETHER - Mars Operations Platform
-- Script SQL (PostgreSQL) generato dal documento
-- 02_AETHER_Progettazione_Database.docx
--
-- Come usarlo: eseguire questo file su un database vuoto
-- (es. con psql -f schema.sql oppure da uno strumento come DBeaver/pgAdmin).
-- ============================================================

CREATE TABLE tipi_asset (
    id_tipo_asset SERIAL PRIMARY KEY,
    codice VARCHAR(30) NOT NULL,
    nome VARCHAR(100) NOT NULL,
    criticita_di_default VARCHAR(20) CHECK (criticita_di_default IN ('BASSA','MEDIA','ALTA','VITALE')),
    UNIQUE (codice)
);

CREATE TABLE categorie_risorsa (
    id_categoria_risorsa SERIAL PRIMARY KEY,
    nome VARCHAR(50) NOT NULL,
    richiede_lotti_di_default BOOLEAN NOT NULL DEFAULT FALSE,
    UNIQUE (nome)
);

CREATE TABLE unita_misura (
    id_unita_misura SERIAL PRIMARY KEY,
    codice VARCHAR(10) NOT NULL,
    descrizione VARCHAR(50) NOT NULL,
    UNIQUE (codice)
);

CREATE TABLE tipi_misurazione (
    id_tipo_misurazione SERIAL PRIMARY KEY,
    nome VARCHAR(50) NOT NULL,
    id_unita_misura_attesa INT REFERENCES unita_misura(id_unita_misura) ON DELETE RESTRICT,
    UNIQUE (nome)
);

CREATE TABLE colonie (
    id_colonia SERIAL PRIMARY KEY,
    codice VARCHAR(10) NOT NULL,
    nome VARCHAR(100) NOT NULL,
    area VARCHAR(100),
    latitudine DECIMAL(9,6) CHECK (latitudine BETWEEN -90 AND 90),
    longitudine DECIMAL(9,6) CHECK (longitudine BETWEEN -180 AND 180),
    stato_operativo VARCHAR(20) NOT NULL CHECK (stato_operativo IN ('IN_COSTRUZIONE','ATTIVA','SOSPESA','DISMESSA')),
    id_responsabile BIGINT,
    capacita_massima INT CHECK (capacita_massima >= 0),
    data_creazione TIMESTAMPTZ NOT NULL DEFAULT now(),
    ultima_modifica TIMESTAMPTZ NOT NULL,
    cancellato BOOLEAN NOT NULL DEFAULT FALSE,
    UNIQUE (codice)
);

CREATE TABLE astronauti (
    id_astronauta BIGSERIAL PRIMARY KEY,
    matricola VARCHAR(20) NOT NULL,
    nome VARCHAR(60) NOT NULL,
    cognome VARCHAR(60) NOT NULL,
    data_di_nascita DATE,
    mansione VARCHAR(50) NOT NULL,
    id_colonia INT REFERENCES colonie(id_colonia) ON DELETE RESTRICT,
    stato_servizio VARCHAR(20) NOT NULL CHECK (stato_servizio IN ('IN_SERVIZIO','IN_TRANSITO','RIENTRATO')),
    data_creazione TIMESTAMPTZ NOT NULL DEFAULT now(),
    ultima_modifica TIMESTAMPTZ NOT NULL,
    cancellato BOOLEAN NOT NULL DEFAULT FALSE,
    UNIQUE (matricola)
);

CREATE TABLE utenti (
    id_user BIGSERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL,
    username VARCHAR(50) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    stato VARCHAR(20) NOT NULL CHECK (stato IN ('ATTIVO','SOSPESO','DISABILITATO')),
    id_astronauta BIGINT REFERENCES astronauti(id_astronauta) ON DELETE RESTRICT,
    utente_cancellato BOOLEAN NOT NULL DEFAULT FALSE,
    data_creazione TIMESTAMPTZ NOT NULL DEFAULT now(),
    ultima_modifica TIMESTAMPTZ NOT NULL,
    UNIQUE (email),
    UNIQUE (username),
    UNIQUE (id_astronauta)
);

CREATE TABLE parametri_sistema (
    chiave VARCHAR(100) NOT NULL,
    valore VARCHAR(255) NOT NULL,
    tipo_dato VARCHAR(20) NOT NULL CHECK (tipo_dato IN ('INT','DECIMAL','BOOLEAN','STRING','DURATA')),
    descrizione VARCHAR(255),
    ultima_modifica TIMESTAMPTZ NOT NULL,
    modificato_da BIGINT REFERENCES utenti(id_user) ON DELETE RESTRICT,
    PRIMARY KEY (chiave)
);

CREATE TABLE ruoli (
    id_ruolo SERIAL PRIMARY KEY,
    nome VARCHAR(50) NOT NULL,
    descrizione VARCHAR(255),
    UNIQUE (nome)
);

CREATE TABLE ruoli_utenti (
    id_utente BIGINT NOT NULL REFERENCES utenti(id_user) ON DELETE RESTRICT,
    id_ruolo INT NOT NULL REFERENCES ruoli(id_ruolo) ON DELETE RESTRICT,
    assegnato_il TIMESTAMPTZ NOT NULL DEFAULT now(),
    assegnato_da BIGINT REFERENCES utenti(id_user) ON DELETE RESTRICT,
    PRIMARY KEY (id_utente, id_ruolo)
);

CREATE TABLE accessi_falliti (
    id_tentativo BIGSERIAL PRIMARY KEY,
    email_tentata VARCHAR(255) NOT NULL,
    indirizzo_ip VARCHAR(45),
    data_tentativo TIMESTAMPTZ NOT NULL DEFAULT now(),
    motivo VARCHAR(50) NOT NULL
);

CREATE TABLE permessi (
    id_permesso SERIAL PRIMARY KEY,
    codice VARCHAR(50) NOT NULL,
    descrizione VARCHAR(255) NOT NULL,
    UNIQUE (codice)
);

CREATE TABLE ruoli_permessi (
    id_ruolo INT NOT NULL REFERENCES ruoli(id_ruolo) ON DELETE RESTRICT,
    id_permesso INT NOT NULL REFERENCES permessi(id_permesso) ON DELETE RESTRICT,
    PRIMARY KEY (id_ruolo, id_permesso)
);

CREATE TABLE sessioni (
    id_sessione BIGSERIAL PRIMARY KEY,
    id_utente BIGINT NOT NULL REFERENCES utenti(id_user) ON DELETE CASCADE,
    token_hash VARCHAR(255) NOT NULL,
    creata_il TIMESTAMPTZ NOT NULL DEFAULT now(),
    scade_il TIMESTAMPTZ NOT NULL CHECK (scade_il > creata_il),
    revocata_il TIMESTAMPTZ,
    indirizzo_ip VARCHAR(45),
    user_agent VARCHAR(255),
    UNIQUE (token_hash)
);

CREATE TABLE habitat (
    id_habitat SERIAL PRIMARY KEY,
    id_colonia INT NOT NULL REFERENCES colonie(id_colonia) ON DELETE RESTRICT,
    id_habitat_padre INT REFERENCES habitat(id_habitat) ON DELETE RESTRICT,
    nome VARCHAR(100) NOT NULL,
    funzione VARCHAR(50) NOT NULL,
    capacita INT CHECK (capacita >= 0),
    stato VARCHAR(20) NOT NULL CHECK (stato IN ('OPERATIVO','MANUTENZIONE','FUORI_SERVIZIO')),
    data_creazione TIMESTAMPTZ NOT NULL DEFAULT now(),
    ultima_modifica TIMESTAMPTZ NOT NULL,
    cancellato BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE asset_tecnici (
    id_asset BIGSERIAL PRIMARY KEY,
    codice VARCHAR(20) NOT NULL,
    id_colonia INT NOT NULL REFERENCES colonie(id_colonia) ON DELETE RESTRICT,
    id_habitat INT REFERENCES habitat(id_habitat) ON DELETE SET NULL,
    nome VARCHAR(100) NOT NULL,
    id_tipo_asset INT NOT NULL REFERENCES tipi_asset(id_tipo_asset) ON DELETE RESTRICT,
    criticita VARCHAR(20) NOT NULL CHECK (criticita IN ('BASSA','MEDIA','ALTA','VITALE')),
    stato VARCHAR(20) NOT NULL CHECK (stato IN ('OPERATIVO','MANUTENZIONE','OUT_OF_SERVICE','DISMESSO')),
    data_creazione TIMESTAMPTZ NOT NULL DEFAULT now(),
    ultima_modifica TIMESTAMPTZ NOT NULL,
    cancellato BOOLEAN NOT NULL DEFAULT FALSE,
    UNIQUE (codice)
);

CREATE TABLE storico_asset (
    id_storico BIGSERIAL PRIMARY KEY,
    id_asset BIGINT NOT NULL REFERENCES asset_tecnici(id_asset) ON DELETE RESTRICT,
    tipo_evento VARCHAR(50) NOT NULL,
    data_evento TIMESTAMPTZ NOT NULL DEFAULT now(),
    descrizione TEXT,
    vecchio_stato VARCHAR(20),
    nuovo_stato VARCHAR(20),
    registrato_da BIGINT REFERENCES utenti(id_user) ON DELETE RESTRICT
);

CREATE TABLE responsabili_asset (
    id_asset BIGINT NOT NULL REFERENCES asset_tecnici(id_asset) ON DELETE RESTRICT,
    id_responsabile BIGINT NOT NULL REFERENCES astronauti(id_astronauta) ON DELETE RESTRICT,
    ruolo VARCHAR(30) NOT NULL CHECK (ruolo IN ('TITOLARE','SOSTITUTO')),
    valido_dal DATE NOT NULL,
    valido_al DATE CHECK (valido_al >= valido_dal),
    PRIMARY KEY (id_asset, id_responsabile, ruolo)
);

CREATE TABLE competenze (
    id_competenza SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    categoria VARCHAR(50),
    UNIQUE (nome)
);

CREATE TABLE competenze_astronauti (
    id_competenza INT NOT NULL REFERENCES competenze(id_competenza) ON DELETE RESTRICT,
    id_astronauta BIGINT NOT NULL REFERENCES astronauti(id_astronauta) ON DELETE RESTRICT,
    livello SMALLINT NOT NULL CHECK (livello BETWEEN 1 AND 5),
    data_di_valutazione DATE NOT NULL,
    data_scadenza DATE CHECK (data_scadenza > data_di_valutazione),
    PRIMARY KEY (id_competenza, id_astronauta)
);

CREATE TABLE certificazioni (
    id_certificazione SERIAL PRIMARY KEY,
    nome_certificazione VARCHAR(100) NOT NULL,
    ente_emittente VARCHAR(100) NOT NULL,
    validita_mesi SMALLINT CHECK (validita_mesi > 0)
);

CREATE TABLE certificazioni_astronauti (
    id_astronauta BIGINT NOT NULL REFERENCES astronauti(id_astronauta) ON DELETE RESTRICT,
    id_certificazione INT NOT NULL REFERENCES certificazioni(id_certificazione) ON DELETE RESTRICT,
    data_rilascio DATE NOT NULL,
    data_scadenza DATE CHECK (data_scadenza > data_rilascio),
    codice_documento VARCHAR(50),
    PRIMARY KEY (id_astronauta, id_certificazione, data_rilascio)
);

CREATE TABLE indisponibilita (
    id_indisponibilita BIGSERIAL PRIMARY KEY,
    id_astronauta BIGINT NOT NULL REFERENCES astronauti(id_astronauta) ON DELETE RESTRICT,
    data_inizio TIMESTAMPTZ NOT NULL,
    data_fine TIMESTAMPTZ NOT NULL CHECK (data_fine > data_inizio),
    tipo VARCHAR(30) NOT NULL,
    note VARCHAR(255)
);

CREATE TABLE tipologie_missione (
    id_tipologia SERIAL PRIMARY KEY,
    nome VARCHAR(50) NOT NULL,
    richiede_approvazione BOOLEAN NOT NULL DEFAULT FALSE,
    UNIQUE (nome)
);

CREATE TABLE missioni (
    id_missione BIGSERIAL PRIMARY KEY,
    codice VARCHAR(20) NOT NULL,
    obiettivo VARCHAR(255) NOT NULL,
    descrizione TEXT,
    id_colonia INT NOT NULL REFERENCES colonie(id_colonia) ON DELETE RESTRICT,
    id_tipologia INT NOT NULL REFERENCES tipologie_missione(id_tipologia) ON DELETE RESTRICT,
    data_inizio_prevista TIMESTAMPTZ NOT NULL,
    data_fine_prevista TIMESTAMPTZ NOT NULL CHECK (data_fine_prevista > data_inizio_prevista),
    priorita VARCHAR(20) NOT NULL CHECK (priorita IN ('BASSA','MEDIA','ALTA','CRITICA')),
    rischio VARCHAR(20) NOT NULL CHECK (rischio IN ('BASSO','MEDIO','ALTO')),
    stato VARCHAR(20) NOT NULL CHECK (stato IN ('DRAFT','PLANNED','APPROVED','IN_PROGRESS','SUSPENDED','COMPLETED','CANCELLED')),
    id_responsabile BIGINT NOT NULL REFERENCES astronauti(id_astronauta) ON DELETE RESTRICT,
    approvato_da BIGINT REFERENCES utenti(id_user) ON DELETE RESTRICT,
    data_approvazione TIMESTAMPTZ,
    data_creazione TIMESTAMPTZ NOT NULL DEFAULT now(),
    ultima_modifica TIMESTAMPTZ NOT NULL,
    UNIQUE (codice)
);

CREATE TABLE task_missione (
    id_task BIGSERIAL PRIMARY KEY,
    id_missione BIGINT NOT NULL REFERENCES missioni(id_missione) ON DELETE CASCADE,
    numero SMALLINT NOT NULL,
    obiettivo VARCHAR(255) NOT NULL,
    stato VARCHAR(20) NOT NULL CHECK (stato IN ('DA_FARE','IN_CORSO','COMPLETATO','ANNULLATO')),
    data_inizio TIMESTAMPTZ,
    data_fine TIMESTAMPTZ CHECK (data_fine >= data_inizio),
    id_responsabile BIGINT REFERENCES astronauti(id_astronauta) ON DELETE RESTRICT,
    data_creazione TIMESTAMPTZ NOT NULL DEFAULT now(),
    ultima_modifica TIMESTAMPTZ NOT NULL,
    UNIQUE (id_missione, numero)
);

CREATE TABLE requisiti_missione (
    id_requisito BIGSERIAL PRIMARY KEY,
    id_missione BIGINT NOT NULL REFERENCES missioni(id_missione) ON DELETE CASCADE,
    id_competenza INT REFERENCES competenze(id_competenza) ON DELETE RESTRICT,
    livello_minimo SMALLINT CHECK (livello_minimo BETWEEN 1 AND 5),
    id_certificazione INT REFERENCES certificazioni(id_certificazione) ON DELETE RESTRICT,
    id_tipo_asset INT REFERENCES tipi_asset(id_tipo_asset) ON DELETE RESTRICT,
    quantita SMALLINT NOT NULL DEFAULT 1 CHECK (quantita > 0),
    note VARCHAR(255)
);

CREATE TABLE equipaggio_missione (
    id_missione BIGINT NOT NULL REFERENCES missioni(id_missione) ON DELETE RESTRICT,
    id_astronauta BIGINT NOT NULL REFERENCES astronauti(id_astronauta) ON DELETE RESTRICT,
    ruolo VARCHAR(50) NOT NULL,
    assegnato_il TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (id_missione, id_astronauta)
);

CREATE TABLE asset_missione (
    id_missione BIGINT NOT NULL REFERENCES missioni(id_missione) ON DELETE RESTRICT,
    id_asset BIGINT NOT NULL REFERENCES asset_tecnici(id_asset) ON DELETE RESTRICT,
    ruolo_impiego VARCHAR(50),
    assegnato_il TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (id_missione, id_asset)
);

CREATE TABLE consuntivo_missione (
    id_missione BIGINT NOT NULL REFERENCES missioni(id_missione) ON DELETE RESTRICT,
    esito VARCHAR(20) NOT NULL CHECK (esito IN ('SUCCESSO','SUCCESSO_PARZIALE','FALLIMENTO','ABORTITA')),
    data_inizio_effettiva TIMESTAMPTZ NOT NULL,
    data_fine_effettiva TIMESTAMPTZ NOT NULL CHECK (data_fine_effettiva > data_inizio_effettiva),
    note TEXT,
    redatto_da BIGINT NOT NULL REFERENCES utenti(id_user) ON DELETE RESTRICT,
    data_chiusura TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (id_missione)
);

CREATE TABLE storico_missioni (
    id_storico BIGSERIAL PRIMARY KEY,
    id_missione BIGINT NOT NULL REFERENCES missioni(id_missione) ON DELETE RESTRICT,
    campo_modificato VARCHAR(50) NOT NULL,
    valore_precedente VARCHAR(255),
    valore_nuovo VARCHAR(255),
    motivazione VARCHAR(255),
    data_modifica TIMESTAMPTZ NOT NULL DEFAULT now(),
    modificato_da BIGINT NOT NULL REFERENCES utenti(id_user) ON DELETE RESTRICT
);

CREATE TABLE catalogo_risorse (
    id_risorsa SERIAL PRIMARY KEY,
    codice VARCHAR(20) NOT NULL,
    nome VARCHAR(100) NOT NULL,
    id_categoria_risorsa INT NOT NULL REFERENCES categorie_risorsa(id_categoria_risorsa) ON DELETE RESTRICT,
    id_unita_misura INT NOT NULL REFERENCES unita_misura(id_unita_misura) ON DELETE RESTRICT,
    gestione_lotti BOOLEAN NOT NULL DEFAULT FALSE,
    attivo BOOLEAN NOT NULL DEFAULT TRUE,
    descrizione VARCHAR(255),
    data_creazione TIMESTAMPTZ NOT NULL DEFAULT now(),
    ultima_modifica TIMESTAMPTZ NOT NULL,
    UNIQUE (codice)
);

CREATE TABLE lotti (
    id_lotto BIGSERIAL PRIMARY KEY,
    id_risorsa INT NOT NULL REFERENCES catalogo_risorse(id_risorsa) ON DELETE RESTRICT,
    codice_lotto VARCHAR(50) NOT NULL,
    provenienza VARCHAR(100),
    data_scadenza DATE,
    data_produzione DATE,
    UNIQUE (id_risorsa, codice_lotto)
);

CREATE TABLE soglie_risorse (
    id_habitat INT NOT NULL REFERENCES habitat(id_habitat) ON DELETE RESTRICT,
    id_risorsa INT NOT NULL REFERENCES catalogo_risorse(id_risorsa) ON DELETE RESTRICT,
    soglia_minima DECIMAL(14,3) NOT NULL DEFAULT 0 CHECK (soglia_minima >= 0),
    ultima_modifica TIMESTAMPTZ NOT NULL,
    PRIMARY KEY (id_habitat, id_risorsa)
);

CREATE TABLE giacenza_lotti (
    id_habitat INT NOT NULL REFERENCES habitat(id_habitat) ON DELETE RESTRICT,
    id_risorsa INT NOT NULL REFERENCES catalogo_risorse(id_risorsa) ON DELETE RESTRICT,
    id_lotto BIGINT NOT NULL REFERENCES lotti(id_lotto) ON DELETE RESTRICT,
    quantita_disponibile DECIMAL(14,3) NOT NULL CHECK (quantita_disponibile >= 0),
    ultima_modifica TIMESTAMPTZ NOT NULL,
    PRIMARY KEY (id_habitat, id_risorsa, id_lotto)
);

CREATE TABLE sensori (
    id_sensore BIGSERIAL PRIMARY KEY,
    codice VARCHAR(30) NOT NULL,
    id_asset BIGINT REFERENCES asset_tecnici(id_asset) ON DELETE RESTRICT,
    id_habitat INT REFERENCES habitat(id_habitat) ON DELETE RESTRICT,
    id_colonia INT REFERENCES colonie(id_colonia) ON DELETE RESTRICT,
    id_tipo_misurazione INT NOT NULL REFERENCES tipi_misurazione(id_tipo_misurazione) ON DELETE RESTRICT,
    id_unita_misura INT NOT NULL REFERENCES unita_misura(id_unita_misura) ON DELETE RESTRICT,
    soglia_min DECIMAL(12,4),
    soglia_max DECIMAL(12,4) CHECK (soglia_max > soglia_min),
    attivo BOOLEAN NOT NULL DEFAULT TRUE,
    UNIQUE (codice)
);

CREATE TABLE eventi_anomali (
    id_evento BIGSERIAL PRIMARY KEY,
    id_sensore BIGINT NOT NULL REFERENCES sensori(id_sensore) ON DELETE RESTRICT,
    data_misura TIMESTAMPTZ NOT NULL,
    valore_rilevato DECIMAL(12,4) NOT NULL,
    soglia_violata DECIMAL(12,4),
    tipo_anomalia VARCHAR(30) NOT NULL CHECK (tipo_anomalia IN ('SOTTO_SOGLIA','SOPRA_SOGLIA','ASSENZA_DATO','REGOLA')),
    descrizione VARCHAR(255),
    data_registrazione TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE alert (
    id_alert BIGSERIAL PRIMARY KEY,
    id_evento BIGINT REFERENCES eventi_anomali(id_evento) ON DELETE RESTRICT,
    origine VARCHAR(30) NOT NULL CHECK (origine IN ('TELEMETRIA','MAGAZZINO','INCIDENTE','MANUALE')),
    id_colonia INT NOT NULL REFERENCES colonie(id_colonia) ON DELETE RESTRICT,
    titolo VARCHAR(150) NOT NULL,
    severita VARCHAR(20) NOT NULL CHECK (severita IN ('INFO','BASSA','MEDIA','ALTA','CRITICA')),
    stato VARCHAR(20) NOT NULL CHECK (stato IN ('APERTO','PRESO_IN_CARICO','ESCALATO','CHIUSO')),
    livello_escalation SMALLINT NOT NULL DEFAULT 0 CHECK (livello_escalation >= 0),
    scadenza_presa_carico TIMESTAMPTZ,
    data_apertura TIMESTAMPTZ NOT NULL DEFAULT now(),
    data_chiusura TIMESTAMPTZ CHECK (data_chiusura >= data_apertura),
    chiuso_da BIGINT REFERENCES utenti(id_user) ON DELETE RESTRICT
);

CREATE TABLE piano_manutenzione (
    id_piano BIGSERIAL PRIMARY KEY,
    id_asset BIGINT NOT NULL REFERENCES asset_tecnici(id_asset) ON DELETE RESTRICT,
    titolo VARCHAR(100) NOT NULL,
    descrizione TEXT,
    tipo_intervallo VARCHAR(20) NOT NULL CHECK (tipo_intervallo IN ('TEMPO','UTILIZZO')),
    valore_intervallo INT NOT NULL CHECK (valore_intervallo > 0),
    ultima_data DATE,
    prossima_data DATE,
    attivo BOOLEAN NOT NULL DEFAULT TRUE,
    data_creazione TIMESTAMPTZ NOT NULL DEFAULT now(),
    ultima_modifica TIMESTAMPTZ NOT NULL
);

CREATE TABLE ticket_guasto (
    id_ticket BIGSERIAL PRIMARY KEY,
    codice VARCHAR(20) NOT NULL,
    id_asset BIGINT NOT NULL REFERENCES asset_tecnici(id_asset) ON DELETE RESTRICT,
    id_piano BIGINT REFERENCES piano_manutenzione(id_piano) ON DELETE RESTRICT,
    sintomo VARCHAR(255) NOT NULL,
    severita VARCHAR(20) NOT NULL CHECK (severita IN ('BASSA','MEDIA','ALTA','CRITICA')),
    stato VARCHAR(20) NOT NULL CHECK (stato IN ('APERTO','PRESO_IN_CARICO','IN_LAVORAZIONE','IN_ATTESA','RISOLTO','CHIUSO')),
    id_segnalatore BIGINT NOT NULL REFERENCES utenti(id_user) ON DELETE RESTRICT,
    id_alert BIGINT REFERENCES alert(id_alert) ON DELETE RESTRICT,
    aperto_il TIMESTAMPTZ NOT NULL DEFAULT now(),
    chiuso_il TIMESTAMPTZ CHECK (chiuso_il >= aperto_il),
    note_risoluzione TEXT,
    UNIQUE (codice)
);

CREATE TABLE spedizioni (
    id_spedizione BIGSERIAL PRIMARY KEY,
    codice VARCHAR(20) NOT NULL,
    origine_tipo VARCHAR(20) NOT NULL CHECK (origine_tipo IN ('TERRA','COLONIA')),
    id_colonia_origine INT REFERENCES colonie(id_colonia) ON DELETE RESTRICT,
    id_colonia_dest INT NOT NULL REFERENCES colonie(id_colonia) ON DELETE RESTRICT,
    id_asset_veicolo BIGINT REFERENCES asset_tecnici(id_asset) ON DELETE RESTRICT,
    stato VARCHAR(20) NOT NULL CHECK (stato IN ('PIANIFICATA','IN_TRANSITO','ARRIVATA','RICEVUTA','ANNULLATA')),
    data_partenza TIMESTAMPTZ,
    data_arrivo_prevista TIMESTAMPTZ,
    data_arrivo_effettiva TIMESTAMPTZ,
    UNIQUE (codice)
);

CREATE TABLE movimenti_risorse (
    id_movimento BIGSERIAL PRIMARY KEY,
    id_risorsa INT NOT NULL REFERENCES catalogo_risorse(id_risorsa) ON DELETE RESTRICT,
    id_lotto BIGINT REFERENCES lotti(id_lotto) ON DELETE RESTRICT,
    id_habitat INT NOT NULL REFERENCES habitat(id_habitat) ON DELETE RESTRICT,
    tipo_movimento VARCHAR(20) NOT NULL CHECK (tipo_movimento IN ('CARICO','SCARICO','TRASFERIMENTO','CONSUMO','RETTIFICA')),
    quantita DECIMAL(14,3) NOT NULL CHECK (quantita <> 0),
    causale VARCHAR(255) NOT NULL,
    id_trasferimento BIGINT,
    id_spedizione BIGINT REFERENCES spedizioni(id_spedizione) ON DELETE RESTRICT,
    id_missione BIGINT REFERENCES missioni(id_missione) ON DELETE RESTRICT,
    id_ticket BIGINT REFERENCES ticket_guasto(id_ticket) ON DELETE RESTRICT,
    data_movimento TIMESTAMPTZ NOT NULL DEFAULT now(),
    registrato_da BIGINT NOT NULL REFERENCES utenti(id_user) ON DELETE RESTRICT
);

CREATE TABLE carico_spedizione (
    id_spedizione BIGINT NOT NULL REFERENCES spedizioni(id_spedizione) ON DELETE CASCADE,
    id_risorsa INT NOT NULL REFERENCES catalogo_risorse(id_risorsa) ON DELETE RESTRICT,
    id_lotto BIGINT NOT NULL REFERENCES lotti(id_lotto) ON DELETE RESTRICT,
    quantita_trasportata DECIMAL(14,3) NOT NULL CHECK (quantita_trasportata > 0),
    quantita_ricevuta DECIMAL(14,3) CHECK (quantita_ricevuta >= 0),
    PRIMARY KEY (id_spedizione, id_risorsa, id_lotto)
);

CREATE TABLE tecnici_ticket (
    id_ticket BIGINT NOT NULL REFERENCES ticket_guasto(id_ticket) ON DELETE CASCADE,
    id_tecnico BIGINT NOT NULL REFERENCES astronauti(id_astronauta) ON DELETE RESTRICT,
    assegnato_il TIMESTAMPTZ NOT NULL DEFAULT now(),
    ore_lavorate DECIMAL(6,2) CHECK (ore_lavorate >= 0),
    PRIMARY KEY (id_ticket, id_tecnico)
);

CREATE TABLE incidenti (
    id_incidente BIGSERIAL PRIMARY KEY,
    codice VARCHAR(20) NOT NULL,
    id_colonia INT NOT NULL REFERENCES colonie(id_colonia) ON DELETE RESTRICT,
    id_missione BIGINT REFERENCES missioni(id_missione) ON DELETE RESTRICT,
    id_habitat INT REFERENCES habitat(id_habitat) ON DELETE RESTRICT,
    id_asset BIGINT REFERENCES asset_tecnici(id_asset) ON DELETE RESTRICT,
    titolo VARCHAR(150) NOT NULL,
    descrizione TEXT NOT NULL,
    severita VARCHAR(20) NOT NULL CHECK (severita IN ('BASSA','MEDIA','ALTA','CRITICA')),
    stato VARCHAR(20) NOT NULL CHECK (stato IN ('APERTO','IN_ANALISI','IN_GESTIONE','RISOLTO','CHIUSO')),
    causa_radice TEXT,
    azioni_correttive TEXT,
    azioni_preventive TEXT,
    riportato_il TIMESTAMPTZ NOT NULL DEFAULT now(),
    riportato_da BIGINT NOT NULL REFERENCES utenti(id_user) ON DELETE RESTRICT,
    chiuso_il TIMESTAMPTZ,
    chiuso_da BIGINT REFERENCES utenti(id_user) ON DELETE RESTRICT,
    motivazione_chiusura VARCHAR(255),
    UNIQUE (codice)
);

CREATE TABLE persone_incidente (
    id_incidente BIGINT NOT NULL REFERENCES incidenti(id_incidente) ON DELETE CASCADE,
    id_astronauta BIGINT NOT NULL REFERENCES astronauti(id_astronauta) ON DELETE RESTRICT,
    ruolo_nell_evento VARCHAR(30) NOT NULL CHECK (ruolo_nell_evento IN ('COINVOLTO','TESTIMONE','PRIMO_INTERVENTO')),
    PRIMARY KEY (id_incidente, id_astronauta)
);

CREATE TABLE timeline_incidente (
    id_evento BIGSERIAL PRIMARY KEY,
    id_incidente BIGINT NOT NULL REFERENCES incidenti(id_incidente) ON DELETE RESTRICT,
    tipo_evento VARCHAR(30) NOT NULL CHECK (tipo_evento IN ('SEGNALAZIONE','PRESA_IN_CARICO','ESCALATION','AZIONE','NOTA','CHIUSURA')),
    descrizione TEXT NOT NULL,
    data_evento TIMESTAMPTZ NOT NULL DEFAULT now(),
    registrato_da BIGINT NOT NULL REFERENCES utenti(id_user) ON DELETE RESTRICT
);

CREATE TABLE laboratori (
    id_laboratorio SERIAL PRIMARY KEY,
    id_habitat INT NOT NULL REFERENCES habitat(id_habitat) ON DELETE RESTRICT,
    nome VARCHAR(100) NOT NULL,
    specializzazione VARCHAR(50),
    data_creazione TIMESTAMPTZ NOT NULL DEFAULT now(),
    ultima_modifica TIMESTAMPTZ NOT NULL
);

CREATE TABLE esperimenti (
    id_esperimento BIGSERIAL PRIMARY KEY,
    codice VARCHAR(20) NOT NULL,
    id_laboratorio INT NOT NULL REFERENCES laboratori(id_laboratorio) ON DELETE RESTRICT,
    id_responsabile BIGINT NOT NULL REFERENCES astronauti(id_astronauta) ON DELETE RESTRICT,
    titolo VARCHAR(150) NOT NULL,
    descrizione TEXT,
    protocollo TEXT,
    stato VARCHAR(20) NOT NULL CHECK (stato IN ('PIANIFICATO','IN_CORSO','SOSPESO','CONCLUSO','ANNULLATO')),
    data_creazione TIMESTAMPTZ NOT NULL DEFAULT now(),
    ultima_modifica TIMESTAMPTZ NOT NULL,
    UNIQUE (codice)
);

CREATE TABLE attrezzature_esperimento (
    id_esperimento BIGINT NOT NULL REFERENCES esperimenti(id_esperimento) ON DELETE CASCADE,
    id_asset BIGINT NOT NULL REFERENCES asset_tecnici(id_asset) ON DELETE RESTRICT,
    note VARCHAR(255),
    PRIMARY KEY (id_esperimento, id_asset)
);

CREATE TABLE campioni (
    id_campione BIGSERIAL PRIMARY KEY,
    codice VARCHAR(30) NOT NULL,
    tipo VARCHAR(50) NOT NULL,
    descrizione_origine VARCHAR(255),
    id_missione_raccolta BIGINT REFERENCES missioni(id_missione) ON DELETE RESTRICT,
    collezionato_il TIMESTAMPTZ NOT NULL,
    id_laboratorio_corrente INT REFERENCES laboratori(id_laboratorio) ON DELETE RESTRICT,
    stato VARCHAR(20) NOT NULL CHECK (stato IN ('IN_TRANSITO','IN_ARCHIVIO','IN_ANALISI','CONSUMATO','SMALTITO')),
    data_creazione TIMESTAMPTZ NOT NULL DEFAULT now(),
    ultima_modifica TIMESTAMPTZ NOT NULL,
    UNIQUE (codice)
);

CREATE TABLE trasferimenti_campione (
    id_trasferimento BIGSERIAL PRIMARY KEY,
    id_campione BIGINT NOT NULL REFERENCES campioni(id_campione) ON DELETE RESTRICT,
    id_lab_partenza INT REFERENCES laboratori(id_laboratorio) ON DELETE RESTRICT,
    id_lab_destinazione INT NOT NULL CHECK (id_lab_destinazione <> id_lab_partenza) REFERENCES laboratori(id_laboratorio) ON DELETE RESTRICT,
    trasferito_il TIMESTAMPTZ NOT NULL DEFAULT now(),
    trasferito_da BIGINT NOT NULL REFERENCES utenti(id_user) ON DELETE RESTRICT,
    id_asset_veicolo BIGINT REFERENCES asset_tecnici(id_asset) ON DELETE RESTRICT
);

CREATE TABLE campioni_esperimenti (
    id_campione BIGINT NOT NULL REFERENCES campioni(id_campione) ON DELETE RESTRICT,
    id_esperimento BIGINT NOT NULL REFERENCES esperimenti(id_esperimento) ON DELETE RESTRICT,
    associato_il TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (id_campione, id_esperimento)
);

CREATE TABLE risultati_esperimento (
    id_risultato BIGSERIAL PRIMARY KEY,
    id_esperimento BIGINT NOT NULL REFERENCES esperimenti(id_esperimento) ON DELETE RESTRICT,
    descrizione TEXT NOT NULL,
    metadati JSONB,
    uri_allegato VARCHAR(500),
    stato_validazione VARCHAR(20) NOT NULL CHECK (stato_validazione IN ('BOZZA','IN_REVISIONE','VALIDATO','RESPINTO')),
    validato_da BIGINT REFERENCES utenti(id_user) ON DELETE RESTRICT,
    data_creazione TIMESTAMPTZ NOT NULL DEFAULT now(),
    ultima_modifica TIMESTAMPTZ NOT NULL
);

CREATE TABLE misurazioni (
    id_sensore BIGINT NOT NULL REFERENCES sensori(id_sensore) ON DELETE RESTRICT,
    data_registrazione TIMESTAMPTZ NOT NULL,
    valore DECIMAL(12,4) NOT NULL,
    qualita VARCHAR(20) NOT NULL CHECK (qualita IN ('VALIDA','SOSPETTA','NON_VALIDA')),
    PRIMARY KEY (id_sensore, data_registrazione)
);

CREATE TABLE destinatari_alert (
    id_alert BIGINT NOT NULL REFERENCES alert(id_alert) ON DELETE RESTRICT,
    id_utente BIGINT NOT NULL REFERENCES utenti(id_user) ON DELETE RESTRICT,
    notificato_il TIMESTAMPTZ NOT NULL DEFAULT now(),
    visionato_il TIMESTAMPTZ CHECK (visionato_il >= notificato_il),
    PRIMARY KEY (id_alert, id_utente)
);

CREATE TABLE notifiche (
    id_notifica BIGSERIAL PRIMARY KEY,
    id_utente BIGINT NOT NULL REFERENCES utenti(id_user) ON DELETE CASCADE,
    tipo_oggetto VARCHAR(30),
    id_oggetto BIGINT,
    testo VARCHAR(500) NOT NULL,
    data_invio TIMESTAMPTZ NOT NULL DEFAULT now(),
    letta_il TIMESTAMPTZ
);

CREATE TABLE audit_log (
    id_audit BIGSERIAL PRIMARY KEY,
    id_utente BIGINT NOT NULL REFERENCES utenti(id_user) ON DELETE RESTRICT,
    entita VARCHAR(50) NOT NULL,
    id_entita VARCHAR(50) NOT NULL,
    azione VARCHAR(20) NOT NULL CHECK (azione IN ('CREATE','UPDATE','DELETE','APPROVE','LOGIN','EXPORT')),
    valore_precedente JSONB,
    valore_nuovo JSONB,
    motivazione VARCHAR(255),
    indirizzo_ip VARCHAR(45),
    data_azione TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- COLONIE e ASTRONAUTI si referenziano a vicenda (la colonia ha un
-- responsabile che e' un astronauta; l'astronauta e' assegnato a una colonia).
-- Per crearle entrambe serve aggiungere questo collegamento DOPO le due tabelle:
ALTER TABLE colonie ADD CONSTRAINT fk_colonie_responsabile
    FOREIGN KEY (id_responsabile) REFERENCES astronauti(id_astronauta) ON DELETE RESTRICT;

-- Alcune regole in piu', non esprimibili con un semplice CHECK di colonna:

-- Al massimo un comandante per missione
CREATE UNIQUE INDEX ux_equipaggio_comandante ON equipaggio_missione (id_missione)
    WHERE ruolo = 'COMANDANTE';

-- Vista con i soli movimenti di consumo (usata per i report)
CREATE VIEW registro_consumi AS
SELECT m.id_movimento, m.id_risorsa, ABS(m.quantita) AS quantita_consumata,
       h.id_colonia, m.id_missione, m.data_movimento
FROM movimenti_risorse m
JOIN habitat h ON h.id_habitat = m.id_habitat
WHERE m.tipo_movimento = 'CONSUMO';
