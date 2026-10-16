-- ============================================================
-- AETHER - Mars Operations Platform
-- Script SQL (PostgreSQL) - SCHEMA UNIFICATO
--
-- Base: 04_AETHER_schema.sql (progetto, da 02_AETHER_Progettazione_Database.docx)
-- Integrato con le funzionalita' presenti in AETHER_MASTER_DATABASE_POSTGRESQL.sql
-- (schema di riferimento del docente) ma assenti nella nostra versione.
-- Le tabelle/colonne aggiunte sono raggruppate in fondo, nella sezione
-- "INTEGRAZIONI DA CONFRONTO CON LO SCHEMA DEL DOCENTE" cosi' da poter
-- individuare a colpo d'occhio cosa e' stato aggiunto rispetto all'originale.
--
-- Come usarlo: eseguire questo file su un database vuoto
-- (es. con psql -f schema.sql oppure da uno strumento come DBeaver/pgAdmin).
-- ============================================================
BEGIN;
CREATE SCHEMA IF NOT EXISTS aether;
SET search_path TO aether, public;
CREATE EXTENSION IF NOT EXISTS btree_gist;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

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

CREATE TABLE turni_astronauti (
    id_turno BIGSERIAL PRIMARY KEY,
    id_astronauta BIGINT NOT NULL REFERENCES astronauti(id_astronauta) ON DELETE RESTRICT,
    id_colonia INT NOT NULL REFERENCES colonie(id_colonia) ON DELETE RESTRICT,
    data_inizio TIMESTAMPTZ NOT NULL,
    data_fine TIMESTAMPTZ NOT NULL CHECK (data_fine > data_inizio),
    tipo_turno VARCHAR(30) NOT NULL,
    stato VARCHAR(20) NOT NULL DEFAULT 'PIANIFICATO'
        CHECK (stato IN ('PIANIFICATO','CONFERMATO','COMPLETATO','ANNULLATO'))
);

ALTER TABLE turni_astronauti ADD CONSTRAINT ex_turni_no_sovrapposizione
EXCLUDE USING gist (
    id_astronauta WITH =,
    tstzrange(data_inizio, data_fine, '[)') WITH &&
) WHERE (stato IN ('PIANIFICATO','CONFERMATO'));

CREATE TABLE obiettivi_missione (
    id_obiettivo BIGSERIAL PRIMARY KEY,
    id_missione BIGINT NOT NULL REFERENCES missioni(id_missione) ON DELETE CASCADE,
    numero_sequenza SMALLINT NOT NULL,
    descrizione TEXT NOT NULL,
    priorita VARCHAR(20) NOT NULL DEFAULT 'MEDIA' CHECK (priorita IN ('BASSA','MEDIA','ALTA','CRITICA')),
    stato VARCHAR(20) NOT NULL DEFAULT 'DA_FARE'
        CHECK (stato IN ('DA_FARE','IN_CORSO','COMPLETATO','FALLITO','ANNULLATO')),
    note_completamento TEXT,
    UNIQUE (id_missione, numero_sequenza)
);

CREATE TABLE fasi_missione (
    id_fase BIGSERIAL PRIMARY KEY,
    id_missione BIGINT NOT NULL REFERENCES missioni(id_missione) ON DELETE CASCADE,
    numero_sequenza SMALLINT NOT NULL,
    nome VARCHAR(150) NOT NULL,
    descrizione TEXT,
    data_inizio_prevista TIMESTAMPTZ,
    data_fine_prevista TIMESTAMPTZ,
    data_inizio_effettiva TIMESTAMPTZ,
    data_fine_effettiva TIMESTAMPTZ,
    stato VARCHAR(20) NOT NULL DEFAULT 'PIANIFICATA'
        CHECK (stato IN ('PIANIFICATA','IN_CORSO','COMPLETATA','SALTATA','ANNULLATA')),
    UNIQUE (id_missione, numero_sequenza)
);
-- I task possono ora essere raggruppati per fase (colonna opzionale, non rompe i dati esistenti)
ALTER TABLE task_missione ADD COLUMN id_fase BIGINT REFERENCES fasi_missione(id_fase) ON DELETE SET NULL;

CREATE TABLE rischi_missione (
    id_rischio BIGSERIAL PRIMARY KEY,
    id_missione BIGINT NOT NULL REFERENCES missioni(id_missione) ON DELETE CASCADE,
    titolo VARCHAR(180) NOT NULL,
    descrizione TEXT,
    probabilita SMALLINT NOT NULL CHECK (probabilita BETWEEN 1 AND 5),
    impatto SMALLINT NOT NULL CHECK (impatto BETWEEN 1 AND 5),
    mitigazione TEXT,
    id_responsabile BIGINT REFERENCES astronauti(id_astronauta) ON DELETE RESTRICT,
    stato VARCHAR(20) NOT NULL DEFAULT 'APERTO' CHECK (stato IN ('APERTO','MITIGATO','ACCETTATO','CHIUSO'))
);

CREATE TABLE approvazioni_missione (
    id_approvazione BIGSERIAL PRIMARY KEY,
    id_missione BIGINT NOT NULL REFERENCES missioni(id_missione) ON DELETE CASCADE,
    tipo_approvazione VARCHAR(30) NOT NULL
        CHECK (tipo_approvazione IN ('OPERATIVA','SICUREZZA','SCIENTIFICA','LOGISTICA','COMANDO')),
    richiesta_da BIGINT NOT NULL REFERENCES utenti(id_user) ON DELETE RESTRICT,
    richiesta_il TIMESTAMPTZ NOT NULL DEFAULT now(),
    decisione VARCHAR(20) NOT NULL DEFAULT 'IN_ATTESA'
        CHECK (decisione IN ('IN_ATTESA','APPROVATA','RESPINTA','ANNULLATA')),
    decisa_da BIGINT REFERENCES utenti(id_user) ON DELETE RESTRICT,
    decisa_il TIMESTAMPTZ,
    note VARCHAR(255),
    CHECK (decisa_da IS NULL OR decisa_da <> richiesta_da)
);

-- --- 3. Fabbisogno/allocazione di risorse consumabili per missione ---------
-- (requisiti_missione copriva solo competenze/certificazioni/asset, non le risorse)
CREATE TABLE requisiti_risorse_missione (
    id_requisito BIGSERIAL PRIMARY KEY,
    id_missione BIGINT NOT NULL REFERENCES missioni(id_missione) ON DELETE CASCADE,
    id_risorsa INT NOT NULL REFERENCES catalogo_risorse(id_risorsa) ON DELETE RESTRICT,
    quantita_richiesta DECIMAL(14,3) NOT NULL CHECK (quantita_richiesta > 0),
    obbligatorio BOOLEAN NOT NULL DEFAULT TRUE,
    UNIQUE (id_missione, id_risorsa)
);

CREATE TABLE allocazioni_risorse_missione (
    id_allocazione BIGSERIAL PRIMARY KEY,
    id_requisito BIGINT NOT NULL REFERENCES requisiti_risorse_missione(id_requisito) ON DELETE RESTRICT,
    id_habitat INT NOT NULL,
    id_risorsa INT NOT NULL,
    id_lotto BIGINT NOT NULL,
    quantita_allocata DECIMAL(14,3) NOT NULL CHECK (quantita_allocata > 0),
    stato VARCHAR(20) NOT NULL DEFAULT 'RISERVATA'
        CHECK (stato IN ('RISERVATA','CONSUMATA','RESTITUITA','ANNULLATA')),
    allocata_il TIMESTAMPTZ NOT NULL DEFAULT now(),
    rilasciata_il TIMESTAMPTZ,
    FOREIGN KEY (id_habitat, id_risorsa, id_lotto)
        REFERENCES giacenza_lotti(id_habitat, id_risorsa, id_lotto) ON DELETE RESTRICT
);

-- --- 4. Telemetria: range attesi e regole di soglia configurabili ----------
ALTER TABLE tipi_misurazione ADD COLUMN valore_atteso_min DECIMAL(24,10);
ALTER TABLE tipi_misurazione ADD COLUMN valore_atteso_max DECIMAL(24,10);
ALTER TABLE tipi_misurazione ADD CONSTRAINT ck_tipo_misurazione_range
    CHECK (valore_atteso_min IS NULL OR valore_atteso_max IS NULL OR valore_atteso_max >= valore_atteso_min);

-- Regole di soglia riusabili (per singolo sensore o per intero tipo di misurazione),
-- con severita' e persistenza: nella nostra versione la soglia era solo
-- soglia_min/soglia_max fissa sul singolo sensore.
CREATE TABLE regole_soglia (
    id_regola BIGSERIAL PRIMARY KEY,
    id_sensore BIGINT REFERENCES sensori(id_sensore) ON DELETE RESTRICT,
    id_tipo_misurazione INT REFERENCES tipi_misurazione(id_tipo_misurazione) ON DELETE RESTRICT,
    nome_regola VARCHAR(150) NOT NULL,
    valore_minimo DECIMAL(24,10),
    valore_massimo DECIMAL(24,10),
    severita VARCHAR(20) NOT NULL CHECK (severita IN ('INFO','BASSA','MEDIA','ALTA','CRITICA')),
    persistenza_secondi INT NOT NULL DEFAULT 0 CHECK (persistenza_secondi >= 0),
    attiva BOOLEAN NOT NULL DEFAULT TRUE,
    data_creazione TIMESTAMPTZ NOT NULL DEFAULT now(),
    CHECK ((id_sensore IS NOT NULL AND id_tipo_misurazione IS NULL)
        OR (id_sensore IS NULL AND id_tipo_misurazione IS NOT NULL)),
    CHECK (valore_minimo IS NOT NULL OR valore_massimo IS NOT NULL),
    CHECK (valore_minimo IS NULL OR valore_massimo IS NULL OR valore_massimo >= valore_minimo)
);

-- --- 5. Alert: conferma presa in carico ed escalation storicizzate ---------
-- (destinatari_alert tracciava solo la notifica/visione, non la presa in carico o l'escalation)
CREATE TABLE conferme_alert (
    id_conferma BIGSERIAL PRIMARY KEY,
    id_alert BIGINT NOT NULL REFERENCES alert(id_alert) ON DELETE RESTRICT,
    id_utente BIGINT NOT NULL REFERENCES utenti(id_user) ON DELETE RESTRICT,
    confermato_il TIMESTAMPTZ NOT NULL DEFAULT now(),
    nota TEXT
);

CREATE TABLE escalation_alert (
    id_escalation BIGSERIAL PRIMARY KEY,
    id_alert BIGINT NOT NULL REFERENCES alert(id_alert) ON DELETE RESTRICT,
    livello_escalation INT NOT NULL CHECK (livello_escalation > 0),
    ruolo_destinatario VARCHAR(50) NOT NULL,
    escalato_il TIMESTAMPTZ NOT NULL DEFAULT now(),
    motivo TEXT NOT NULL
);

-- --- 6. Incidenti: azioni correttive tracciate singolarmente ---------------
-- (prima erano solo i campi testo azioni_correttive/azioni_preventive su incidenti)
CREATE TABLE azioni_correttive_incidente (
    id_azione BIGSERIAL PRIMARY KEY,
    id_incidente BIGINT NOT NULL REFERENCES incidenti(id_incidente) ON DELETE RESTRICT,
    descrizione TEXT NOT NULL,
    assegnata_a BIGINT REFERENCES astronauti(id_astronauta) ON DELETE RESTRICT,
    scadenza TIMESTAMPTZ,
    completata_il TIMESTAMPTZ,
    stato VARCHAR(20) NOT NULL DEFAULT 'APERTA'
        CHECK (stato IN ('APERTA','IN_CORSO','COMPLETATA','ANNULLATA'))
);

-- --- 7. Manutenzione: log dei singoli interventi eseguiti ------------------
-- (storico_asset registra i cambi di stato dell'asset, non il dettaglio di
-- ogni intervento di manutenzione con relativa durata)
CREATE TABLE interventi_manutenzione (
    id_intervento BIGSERIAL PRIMARY KEY,
    id_ticket BIGINT NOT NULL REFERENCES ticket_guasto(id_ticket) ON DELETE RESTRICT,
    id_tecnico BIGINT REFERENCES astronauti(id_astronauta) ON DELETE RESTRICT,
    descrizione TEXT NOT NULL,
    eseguito_il TIMESTAMPTZ NOT NULL DEFAULT now(),
    durata_minuti INT CHECK (durata_minuti >= 0),
    note TEXT
);

-- --- 8. Preferenze di notifica per utente/canale ---------------------------
CREATE TABLE preferenze_notifiche (
    id_utente BIGINT NOT NULL REFERENCES utenti(id_user) ON DELETE CASCADE,
    tipo_evento VARCHAR(60) NOT NULL,
    canale VARCHAR(20) NOT NULL CHECK (canale IN ('IN_APP','EMAIL','PUSH')),
    abilitato BOOLEAN NOT NULL DEFAULT TRUE,
    PRIMARY KEY (id_utente, tipo_evento, canale)
);
ALTER TABLE notifiche ADD COLUMN severita VARCHAR(20) NOT NULL DEFAULT 'INFO'
    CHECK (severita IN ('INFO','BASSA','MEDIA','ALTA','CRITICA'));

-- --- 9. Outbox degli eventi (per una futura integrazione a code/messaggistica) ---
-- Facoltativa: non necessaria per il solo uso del DB, ma presente nel master
-- come pattern per pubblicare in modo affidabile gli eventi di dominio.
CREATE TABLE eventi_outbox (
    id_evento UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tipo_aggregato VARCHAR(80) NOT NULL,
    id_aggregato VARCHAR(120) NOT NULL,
    tipo_evento VARCHAR(120) NOT NULL,
    payload JSONB NOT NULL,
    data_evento TIMESTAMPTZ NOT NULL DEFAULT now(),
    pubblicato_il TIMESTAMPTZ,
    tentativi INT NOT NULL DEFAULT 0 CHECK (tentativi >= 0),
    ultimo_errore TEXT
);

-- --- 10. Sicurezza account: contatori oltre al log di accessi_falliti -----
ALTER TABLE utenti ADD COLUMN tentativi_falliti INT NOT NULL DEFAULT 0 CHECK (tentativi_falliti >= 0);
ALTER TABLE utenti ADD COLUMN bloccato_fino TIMESTAMPTZ;
ALTER TABLE utenti ADD COLUMN ultimo_accesso TIMESTAMPTZ;

-- --- 11. Asset: dati identificativi/di utilizzo mancanti -------------------
ALTER TABLE asset_tecnici ADD COLUMN numero_seriale VARCHAR(120) UNIQUE;
ALTER TABLE asset_tecnici ADD COLUMN produttore VARCHAR(120);
ALTER TABLE asset_tecnici ADD COLUMN modello VARCHAR(120);
ALTER TABLE asset_tecnici ADD COLUMN ore_di_funzionamento DECIMAL(14,2) NOT NULL DEFAULT 0
    CHECK (ore_di_funzionamento >= 0);

-- --- 12. Risorse: criticita' e conservabilita' -----------------------------
ALTER TABLE catalogo_risorse ADD COLUMN critica BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE catalogo_risorse ADD COLUMN giorni_di_conservazione INT CHECK (giorni_di_conservazione > 0);

-- --- 13. Missioni: livello di sicurezza e motivo di annullamento -----------
ALTER TABLE missioni ADD COLUMN livello_sicurezza VARCHAR(20) NOT NULL DEFAULT 'STANDARD'
    CHECK (livello_sicurezza IN ('STANDARD','ELEVATO','ALTO_RISCHIO','CRITICO'));
ALTER TABLE missioni ADD COLUMN motivo_annullamento TEXT;

-- --- 14. Indici mancanti sulle foreign key piu' interrogate ----------------
CREATE INDEX ix_turni_astronauta ON turni_astronauti(id_astronauta);
CREATE INDEX ix_turni_colonia_date ON turni_astronauti(id_colonia, data_inizio, data_fine);
CREATE INDEX ix_obiettivi_missione ON obiettivi_missione(id_missione);
CREATE INDEX ix_fasi_missione ON fasi_missione(id_missione);
CREATE INDEX ix_task_fase ON task_missione(id_fase);
CREATE INDEX ix_rischi_missione ON rischi_missione(id_missione);
CREATE INDEX ix_approvazioni_missione ON approvazioni_missione(id_missione, decisione);
CREATE INDEX ix_requisiti_risorse_missione ON requisiti_risorse_missione(id_risorsa);
CREATE INDEX ix_allocazioni_requisito ON allocazioni_risorse_missione(id_requisito);
CREATE INDEX ix_regole_soglia_sensore ON regole_soglia(id_sensore);
CREATE INDEX ix_regole_soglia_tipo ON regole_soglia(id_tipo_misurazione);
CREATE INDEX ix_conferme_alert_alert ON conferme_alert(id_alert);
CREATE INDEX ix_escalation_alert_alert ON escalation_alert(id_alert);
CREATE INDEX ix_azioni_correttive_incidente ON azioni_correttive_incidente(id_incidente, stato);
CREATE INDEX ix_interventi_manutenzione_ticket ON interventi_manutenzione(id_ticket);
CREATE INDEX ix_asset_colonia_stato ON asset_tecnici(id_colonia, stato);
CREATE INDEX ix_sensori_colonia_stato ON sensori(id_colonia);
CREATE INDEX ix_missioni_stato_date ON missioni(stato, data_inizio_prevista, data_fine_prevista);
CREATE INDEX ix_ticket_asset_stato ON ticket_guasto(id_asset, stato);
CREATE INDEX ix_incidenti_colonia_stato ON incidenti(id_colonia, stato);
CREATE INDEX ix_movimenti_risorsa_data ON movimenti_risorse(id_risorsa, data_movimento DESC);
CREATE INDEX ix_notifiche_utente_stato ON notifiche(id_utente, letta_il);
CREATE INDEX ix_audit_entita ON audit_log(entita, id_entita, data_azione DESC);

-- ============================================================
-- FINE INTEGRAZIONI
-- ============================================================

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

COMMIT;