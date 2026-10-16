-- ============================================================
-- AETHER - Mars Operations Platform
-- Dati di esempio (seed) per demo e test
--
-- Da eseguire DOPO 04_AETHER_schema.sql, su un database vuoto.
-- Le tabelle vengono riempite nello stesso ordine in cui sono
-- state create (cosi' le FK trovano sempre la riga a cui puntano).
-- ============================================================
SET search_path TO aether, public;

-- ------------------------------------------------------------
-- Cataloghi di base
-- ------------------------------------------------------------
INSERT INTO tipi_asset (codice, nome, criticita_di_default) VALUES
('GEN', 'Generatore', 'VITALE'),
('ROV', 'Rover', 'ALTA'),
('SER', 'Serra', 'MEDIA'),
('ANT', 'Antenna', 'ALTA'),
('DRO', 'Drone', 'BASSA');

INSERT INTO categorie_risorsa (nome) VALUES
('ACQUA'), ('OSSIGENO'), ('CIBO'), ('CARBURANTE'), ('RICAMBI');

INSERT INTO unita_misura (codice, descrizione, simbolo, tipo_grandezza) VALUES
('KG', 'Chilogrammi', 'kg', 'MASSA'),
('L', 'Litri', 'L', 'VOLUME'),
('PZ', 'Pezzi', 'pz', 'CONTEGGIO'),
('M3', 'Metri cubi', 'm³', 'VOLUME'),
('C', 'Gradi Celsius', '°C', 'TEMPERATURA'),
('HPA', 'Ettopascal', 'hPa', 'PRESSIONE'),
('PPM', 'Parti per milione', 'ppm', 'CONCENTRAZIONE');

INSERT INTO tipi_misurazione (nome, id_unita_misura_attesa) VALUES
('TEMPERATURA', 5),
('PRESSIONE', 6),
('OSSIGENO', 7),
('CO2', 7);

-- ------------------------------------------------------------
-- Colonie e astronauti
-- (id_responsabile si aggiorna alla fine: la FK e' circolare)
-- ------------------------------------------------------------
INSERT INTO colonie (codice, nome, area, latitudine, longitudine, stato_operativo, capacita_massima, ultima_modifica) VALUES
('ARES-1', 'Ares Prime', 'Acidalia Planitia', 18.500000, -22.000000, 'ATTIVA', 20, now()),
('VRO-1', 'Valles Research Outpost', 'Valles Marineris', -13.900000, -59.200000, 'ATTIVA', 12, now()),
('ELY-1', 'Elysium Relay', 'Elysium Planitia', 25.000000, 150.000000, 'ATTIVA', 8, now());

INSERT INTO astronauti (matricola, nome, cognome, data_di_nascita, mansione, id_colonia, stato_servizio, ultima_modifica) VALUES
('AST-001', 'Marco', 'Ferrari', '1988-04-12', 'Mission Commander', 1, 'IN_SERVIZIO', now()),
('AST-002', 'Elena', 'Conti', '1990-09-03', 'Pilota', 1, 'IN_SERVIZIO', now()),
('AST-003', 'Luca', 'Bianchi', '1985-01-20', 'Tecnico Manutenzione', 1, 'IN_SERVIZIO', now()),
('AST-004', 'Sara', 'Greco', '1992-11-15', 'Scienziata', 2, 'IN_SERVIZIO', now()),
('AST-005', 'Davide', 'Romano', '1987-06-30', 'Comandante Base', 2, 'IN_SERVIZIO', now()),
('AST-006', 'Giulia', 'Marino', '1993-02-08', 'Logista', 2, 'IN_TRANSITO', now()),
('AST-007', 'Paolo', 'Rizzo', '1986-07-19', 'Comandante Base', 3, 'IN_SERVIZIO', now()),
('AST-008', 'Anna', 'Colombo', '1991-12-01', 'Pilota Rover', 3, 'IN_SERVIZIO', now()),
('AST-009', 'Franco', 'Villa', '1984-03-25', 'Ingegnere', 1, 'RIENTRATO', now()),
('AST-010', 'Chiara', 'Fontana', '1994-05-17', 'Biologa', 2, 'IN_SERVIZIO', now());

UPDATE colonie SET id_responsabile = 1 WHERE codice = 'ARES-1';
UPDATE colonie SET id_responsabile = 5 WHERE codice = 'VRO-1';
UPDATE colonie SET id_responsabile = 7 WHERE codice = 'ELY-1';

-- ------------------------------------------------------------
-- Utenti, ruoli, permessi, sessioni
-- ------------------------------------------------------------
INSERT INTO utenti (email, username, password_hash, stato, id_astronauta, ultima_modifica) VALUES
('marco.ferrari@aether.mars', 'mferrari', '$2b$12$hashsimulato0000000000000000000000000000000000000001', 'ATTIVO', 1, now()),
('elena.conti@aether.mars', 'econti', '$2b$12$hashsimulato0000000000000000000000000000000000000002', 'ATTIVO', 2, now()),
('sara.greco@aether.mars', 'sgreco', '$2b$12$hashsimulato0000000000000000000000000000000000000003', 'ATTIVO', 4, now()),
('paolo.rizzo@aether.mars', 'prizzo', '$2b$12$hashsimulato0000000000000000000000000000000000000004', 'ATTIVO', 7, now()),
('admin@aether.mars', 'admin', '$2b$12$hashsimulato0000000000000000000000000000000000000005', 'ATTIVO', NULL, now());

INSERT INTO parametri_sistema (chiave, valore, tipo_dato, descrizione, ultima_modifica, modificato_da) VALUES
('ALERT_ESCALATION_MINUTI', '30', 'INT', 'Minuti prima che un alert non gestito faccia escalation', now(), 5),
('SESSIONE_DURATA_ORE', '8', 'INT', 'Durata di default di una sessione utente', now(), 5);

INSERT INTO ruoli (nome, descrizione) VALUES
('ADMIN', 'Amministratore di piattaforma'),
('MISSION_CONTROLLER', 'Pianifica e controlla le missioni'),
('COLONY_COMMANDER', 'Responsabile operativo di una colonia'),
('CREW', 'Membro di equipaggio');

INSERT INTO ruoli_utenti (id_utente, id_ruolo, assegnato_da) VALUES
(1, 3, 5), -- Marco: Colony Commander
(2, 2, 5), -- Elena: Mission Controller
(3, 4, 5), -- Sara: Crew
(4, 3, 5), -- Paolo: Colony Commander
(5, 1, 5); -- admin: Admin

INSERT INTO accessi_falliti (email_tentata, indirizzo_ip, motivo) VALUES
('sconosciuto@aether.mars', '10.0.0.15', 'Utente inesistente'),
('marco.ferrari@aether.mars', '10.0.0.22', 'Password errata');

INSERT INTO permessi (codice, descrizione) VALUES
('MISSIONE_APPROVA', 'Puo approvare una missione'),
('INCIDENTE_CHIUDI_CRITICO', 'Puo chiudere un incidente critico'),
('INVENTARIO_RETTIFICA', 'Puo registrare una rettifica di magazzino'),
('RUOLO_GESTISCI', 'Puo assegnare ruoli e permessi');

INSERT INTO ruoli_permessi (id_ruolo, id_permesso) VALUES
(1,1), (1,2), (1,3), (1,4),  -- ADMIN: tutti
(3,1), (3,2),                -- COLONY_COMMANDER
(2,1);                       -- MISSION_CONTROLLER

INSERT INTO sessioni (id_utente, token_hash, scade_il, indirizzo_ip, user_agent) VALUES
(1, 'tokenhash_sessione_0000000000000000000000000000000001', now() + INTERVAL '8 hours', '10.0.0.22', 'AetherApp/1.0'),
(2, 'tokenhash_sessione_0000000000000000000000000000000002', now() + INTERVAL '8 hours', '10.0.0.31', 'AetherApp/1.0');

-- ------------------------------------------------------------
-- Habitat e asset tecnici
-- ------------------------------------------------------------
INSERT INTO habitat (id_colonia, nome, funzione, capacita, stato, ultima_modifica) VALUES
(1, 'Alloggi Ares Prime', 'RESIDENZIALE', 20, 'OPERATIVO', now()),
(1, 'Serra Ares Prime', 'SERRA', NULL, 'OPERATIVO', now()),
(1, 'Officina Rover Ares Prime', 'OFFICINA', NULL, 'OPERATIVO', now()),
(2, 'Laboratorio Geologico Valles', 'LABORATORIO', NULL, 'OPERATIVO', now()),
(2, 'Centro Medico Valles', 'MEDICO', NULL, 'OPERATIVO', now()),
(3, 'Energy Hub Elysium', 'ENERGIA', NULL, 'OPERATIVO', now()),
(3, 'Water Recycling Elysium', 'RICICLO_ACQUA', NULL, 'OPERATIVO', now()),
(3, 'Communication Dome Elysium', 'COMUNICAZIONI', NULL, 'OPERATIVO', now());

INSERT INTO asset_tecnici (codice, id_colonia, id_habitat, nome, id_tipo_asset, criticita, stato, ultima_modifica) VALUES
('AST-GEN-01', 1, NULL, 'Generatore principale Ares', 1, 'VITALE', 'OPERATIVO', now()),
('AST-ROV-01', 1, 3, 'Rover Pathfinder', 2, 'ALTA', 'OPERATIVO', now()),
('AST-ROV-02', 3, NULL, 'Rover Voyager', 2, 'ALTA', 'MANUTENZIONE', now()),
('AST-SER-01', 1, 2, 'Modulo serra idroponica', 3, 'MEDIA', 'OPERATIVO', now()),
('AST-ANT-01', 3, 8, 'Antenna relay principale', 4, 'ALTA', 'OUT_OF_SERVICE', now()),
('AST-GEN-02', 3, 6, 'Generatore Elysium', 1, 'VITALE', 'OPERATIVO', now()),
('AST-DRO-01', 2, NULL, 'Drone da rilievo', 5, 'BASSA', 'OPERATIVO', now());

INSERT INTO storico_asset (id_asset, tipo_evento, descrizione, vecchio_stato, nuovo_stato, registrato_da) VALUES
(5, 'CAMBIO_STATO', 'Antenna fuori uso dopo perdita di segnale', 'OPERATIVO', 'OUT_OF_SERVICE', 4),
(3, 'CAMBIO_STATO', 'Rover in manutenzione programmata', 'OPERATIVO', 'MANUTENZIONE', 4);

INSERT INTO responsabili_asset (id_asset, id_responsabile, ruolo, valido_dal) VALUES
(1, 3, 'TITOLARE', '2026-01-01'),
(6, 7, 'TITOLARE', '2026-01-01');

-- ------------------------------------------------------------
-- Competenze e certificazioni
-- ------------------------------------------------------------
INSERT INTO competenze (nome, categoria) VALUES
('GUIDA_ROVER', 'OPERATIVA'), ('EVA', 'OPERATIVA'), ('SALDATURA', 'TECNICA'),
('MICROBIOLOGIA', 'SCIENTIFICA'), ('PRIMO_SOCCORSO', 'MEDICA'), ('GEOLOGIA', 'SCIENTIFICA');

INSERT INTO competenze_astronauti (id_competenza, id_astronauta, livello, data_di_valutazione) VALUES
(2, 1, 3, '2026-01-15'),
(1, 2, 5, '2026-01-15'),
(1, 8, 4, '2026-02-10'),
(3, 3, 4, '2026-01-20'),
(4, 4, 5, '2026-01-20'),
(5, 5, 5, '2026-01-20'),
(6, 10, 4, '2026-02-01');

INSERT INTO certificazioni (nome_certificazione, ente_emittente, validita_mesi) VALUES
('EVA Certification', 'AFC Training Division', 24),
('Medical Certification', 'AFC Medical Board', 12),
('Pilot Certification', 'AFC Flight Ops', 36);

INSERT INTO certificazioni_astronauti (id_astronauta, id_certificazione, data_rilascio, data_scadenza, codice_documento) VALUES
(1, 1, '2025-01-10', '2027-01-10', 'DOC-EVA-001'),
(2, 3, '2024-03-01', '2027-03-01', 'DOC-PIL-002'),
(5, 2, '2025-09-01', '2026-10-01', 'DOC-MED-005'),  -- in scadenza a breve
(8, 3, '2023-01-01', '2026-08-01', 'DOC-PIL-008');  -- gia' scaduta

INSERT INTO indisponibilita (id_astronauta, data_inizio, data_fine, tipo, note) VALUES
(6, '2026-09-10', '2026-09-20', 'VIAGGIO', 'Trasferimento da Terra'),
(9, '2026-06-01', '2026-08-01', 'RIENTRO', 'Fine incarico su Marte');

-- ------------------------------------------------------------
-- Missioni
-- ------------------------------------------------------------
INSERT INTO tipologie_missione (nome, richiede_approvazione) VALUES
('ESPLORAZIONE', FALSE), ('MANUTENZIONE', FALSE), ('LOGISTICA', FALSE),
('SCIENZA', FALSE), ('SOCCORSO', TRUE);

INSERT INTO missioni (codice, obiettivo, descrizione, id_colonia, id_tipologia, data_inizio_prevista, data_fine_prevista, priorita, rischio, stato, id_responsabile, approvato_da, data_approvazione, ultima_modifica) VALUES
('MIS-001', 'Esplorazione Canyon Valles', 'Rilievo geologico del canyon adiacente alla base', 2, 1, '2026-10-01 08:00+00', '2026-10-03 18:00+00', 'ALTA', 'MEDIO', 'PLANNED', 4, NULL, NULL, now()),
('MIS-002', 'Riparazione Antenna Elysium', 'Ripristino dell''antenna relay fuori servizio', 3, 2, '2026-09-18 09:00+00', '2026-09-18 17:00+00', 'CRITICA', 'ALTO', 'APPROVED', 7, 5, now(), now()),
('MIS-003', 'Recupero Rover Bloccato', 'Recupero del rover Voyager immobilizzato', 3, 2, '2026-08-01 08:00+00', '2026-08-01 20:00+00', 'ALTA', 'MEDIO', 'COMPLETED', 8, 4, '2026-07-30 10:00+00', now()),
('MIS-004', 'Raccolta Campioni Regolite', 'Campionamento scientifico nell''area circostante', 2, 4, '2026-09-05 08:00+00', '2026-09-12 18:00+00', 'MEDIA', 'BASSO', 'IN_PROGRESS', 10, NULL, NULL, now()),
('MIS-005', 'Missione di Soccorso Equipaggio', 'Piano di soccorso in caso di emergenza EVA', 1, 5, '2026-11-01 08:00+00', '2026-11-01 20:00+00', 'CRITICA', 'ALTO', 'DRAFT', 1, NULL, NULL, now());

INSERT INTO task_missione (id_missione, numero, obiettivo, stato, data_inizio, data_fine, id_responsabile, ultima_modifica) VALUES
(1, 1, 'Preparazione equipaggiamento EVA', 'COMPLETATO', '2026-09-20 08:00+00', '2026-09-20 10:00+00', 10, now()),
(1, 2, 'Attraversamento e rilievo canyon', 'DA_FARE', NULL, NULL, 4, now()),
(3, 1, 'Localizzazione rover e recupero', 'COMPLETATO', '2026-08-01 08:00+00', '2026-08-01 14:00+00', 8, now());

INSERT INTO requisiti_missione (id_missione, id_competenza, livello_minimo, id_tipo_asset, quantita) VALUES
(1, 2, 3, NULL, 1),          -- richiede competenza EVA livello >= 3
(1, NULL, NULL, 5, 1),       -- richiede 1 drone
(2, NULL, NULL, 4, 1);       -- richiede 1 antenna (di scorta)

INSERT INTO equipaggio_missione (id_missione, id_astronauta, ruolo) VALUES
(1, 4, 'COMANDANTE'),
(1, 10, 'SCIENZIATO'),
(3, 8, 'COMANDANTE'),
(3, 3, 'TECNICO'),
(4, 10, 'COMANDANTE');

INSERT INTO asset_missione (id_missione, id_asset, ruolo_impiego) VALUES
(1, 7, 'RILIEVO'),
(3, 2, 'TRASPORTO');

INSERT INTO consuntivo_missione (id_missione, esito, data_inizio_effettiva, data_fine_effettiva, note, redatto_da) VALUES
(3, 'SUCCESSO', '2026-08-01 08:10+00', '2026-08-01 19:30+00', 'Rover recuperato senza danni, batteria sostituita sul posto.', 4);

INSERT INTO storico_missioni (id_missione, campo_modificato, valore_precedente, valore_nuovo, motivazione, modificato_da) VALUES
(3, 'STATO', 'IN_PROGRESS', 'COMPLETED', 'Missione conclusa con successo', 4);

-- ------------------------------------------------------------
-- Magazzino e rifornimenti
-- ------------------------------------------------------------
INSERT INTO catalogo_risorse (codice, nome, id_categoria_risorsa, id_unita_misura, gestione_lotti, attivo, ultima_modifica) VALUES
('RES-ACQUA', 'Acqua potabile', 1, 2, FALSE, TRUE, now()),
('RES-O2', 'Ossigeno', 2, 4, FALSE, TRUE, now()),
('RES-RAZIONI', 'Razioni alimentari', 3, 3, TRUE, TRUE, now()),
('RES-METANO', 'Metano (propellente)', 4, 2, FALSE, TRUE, now()),
('RES-FILTRI-CO2', 'Filtri CO2', 5, 3, TRUE, TRUE, now()),
('RES-PEZZI', 'Pezzi di ricambio generici', 5, 3, TRUE, TRUE, now());

INSERT INTO lotti (id_risorsa, codice_lotto, provenienza, data_scadenza) VALUES
(3, 'RAZ-2026-01', 'Terra', '2027-03-01'),
(5, 'FLT-2026-05', 'Terra', '2028-01-01'),
(6, 'PEZ-2026-02', 'Produzione locale', NULL),
(1, 'CONV', 'Produzione locale (riciclo)', NULL),
(2, 'CONV', 'Produzione locale (elettrolisi)', NULL),
(4, 'CONV', 'Terra', NULL);

INSERT INTO soglie_risorse (id_habitat, id_risorsa, soglia_minima, ultima_modifica) VALUES
(1, 1, 500, now()),
(1, 2, 200, now()),
(6, 4, 100, now()),
(4, 3, 50, now());

INSERT INTO giacenza_lotti (id_habitat, id_risorsa, id_lotto, quantita_disponibile, ultima_modifica) VALUES
(1, 1, 4, 300, now()),   -- sotto la soglia di 500
(1, 2, 5, 250, now()),   -- sopra la soglia di 200
(6, 4, 6, 80, now()),    -- sotto la soglia di 100
(4, 3, 1, 120, now());   -- sopra la soglia di 50

INSERT INTO spedizioni (codice, origine_tipo, id_colonia_origine, id_colonia_dest, id_asset_veicolo, stato, data_partenza, data_arrivo_prevista, data_arrivo_effettiva) VALUES
('SPD-001', 'TERRA', NULL, 2, NULL, 'RICEVUTA', '2026-07-01 00:00+00', '2026-08-15 00:00+00', '2026-08-14 22:00+00'),
('SPD-002', 'COLONIA', 3, 1, 2, 'IN_TRANSITO', '2026-09-14 06:00+00', '2026-09-16 06:00+00', NULL);

INSERT INTO carico_spedizione (id_spedizione, id_risorsa, id_lotto, quantita_trasportata, quantita_ricevuta) VALUES
(1, 3, 1, 200, 200),
(1, 5, 2, 50, 48);  -- arrivate 2 unita' in meno di quelle spedite

-- ------------------------------------------------------------
-- Telemetria
-- ------------------------------------------------------------
INSERT INTO sensori (codice, id_habitat, id_tipo_misurazione, id_unita_misura, soglia_min, soglia_max) VALUES
('SEN-TEMP-01', 1, 1, 5, -10, 30),
('SEN-PRESS-01', 1, 2, 6, 950, 1050),
('SEN-CO2-01', 1, 4, 7, 300, 1000),
('SEN-TEMP-02', 6, 1, 5, -20, 25);

INSERT INTO misurazioni (id_sensore, data_registrazione, valore, qualita) VALUES
(1, '2026-09-14 00:00+00', 21.5, 'VALIDA'),
(1, '2026-09-14 06:00+00', 20.8, 'VALIDA'),
(1, '2026-09-14 12:00+00', 22.1, 'VALIDA'),
(1, '2026-09-14 18:00+00', -12.4, 'VALIDA'),
(1, '2026-09-15 00:00+00', 21.0, 'VALIDA'),
(2, '2026-09-14 00:00+00', 1001.2, 'VALIDA'),
(2, '2026-09-14 06:00+00', 998.7, 'VALIDA'),
(2, '2026-09-14 12:00+00', 1005.4, 'VALIDA'),
(3, '2026-09-14 00:00+00', 420.0, 'VALIDA'),
(3, '2026-09-14 06:00+00', 610.0, 'VALIDA'),
(3, '2026-09-14 12:00+00', 1200.0, 'SOSPETTA'),
(3, '2026-09-14 18:00+00', 450.0, 'VALIDA'),
(4, '2026-09-14 00:00+00', 18.0, 'VALIDA'),
(4, '2026-09-14 12:00+00', 19.2, 'VALIDA');

INSERT INTO eventi_anomali (id_sensore, data_misura, valore_rilevato, soglia_violata, tipo_anomalia, descrizione) VALUES
(3, '2026-09-14 12:00+00', 1200.0, 1000, 'SOPRA_SOGLIA', 'Picco di CO2 in Alloggi Ares Prime'),
(1, '2026-09-14 18:00+00', -12.4, -10, 'SOTTO_SOGLIA', 'Temperatura sotto soglia minima');

INSERT INTO alert (id_evento, origine, id_colonia, titolo, severita, stato, data_apertura) VALUES
(1, 'TELEMETRIA', 1, 'CO2 sopra soglia in Alloggi Ares Prime', 'ALTA', 'APERTO', now()),
(2, 'TELEMETRIA', 1, 'Temperatura sotto soglia in Alloggi Ares Prime', 'MEDIA', 'PRESO_IN_CARICO', now() - INTERVAL '2 hours');

INSERT INTO alert (origine, id_colonia, titolo, severita, stato, data_apertura) VALUES
('MAGAZZINO', 1, 'Scorta acqua sotto soglia in Alloggi Ares Prime', 'ALTA', 'APERTO', now());

INSERT INTO alert (origine, id_colonia, titolo, severita, stato, data_apertura, data_chiusura, chiuso_da) VALUES
('INCIDENTE', 3, 'Escalation guasto antenna Elysium', 'CRITICA', 'CHIUSO', now() - INTERVAL '1 day', now() - INTERVAL '20 hours', 4);

-- ------------------------------------------------------------
-- Manutenzione
-- ------------------------------------------------------------
INSERT INTO piano_manutenzione (id_asset, titolo, descrizione, tipo_intervallo, valore_intervallo, ultima_data, prossima_data, ultima_modifica) VALUES
(2, 'Controllo periodico rover Pathfinder', 'Ispezione motori e ruote', 'TEMPO', 90, '2026-06-20', '2026-09-18', now()),
(6, 'Manutenzione generatore Elysium', 'Controllo filtri e livelli', 'UTILIZZO', 500, '2026-05-01', NULL, now());

INSERT INTO ticket_guasto (codice, id_asset, id_piano, sintomo, severita, stato, id_segnalatore, id_alert, aperto_il) VALUES
('TCK-001', 5, NULL, 'Antenna non risponde ai comandi', 'CRITICA', 'APERTO', 4, 4, now() - INTERVAL '1 day'),
('TCK-002', 3, NULL, 'Rumore anomalo dal motore', 'MEDIA', 'IN_LAVORAZIONE', 1, NULL, now() - INTERVAL '3 days'),
('TCK-003', 2, 1, 'Controllo di routine programmato', 'BASSA', 'CHIUSO', 1, NULL, now() - INTERVAL '10 days');

UPDATE ticket_guasto SET chiuso_il = now() - INTERVAL '9 days', note_risoluzione = 'Nessuna anomalia riscontrata'
WHERE codice = 'TCK-003';

INSERT INTO tecnici_ticket (id_ticket, id_tecnico, ore_lavorate) VALUES
(1, 7, NULL),
(2, 3, 4.5),
(3, 3, 1.0);

INSERT INTO movimenti_risorse (id_risorsa, id_lotto, id_habitat, tipo_movimento, quantita, causale, id_spedizione, id_missione, id_ticket, registrato_da) VALUES
(3, 1, 4, 'CARICO', 200, 'Ricezione spedizione SPD-001', 1, NULL, NULL, 5),
(5, 2, 4, 'CARICO', 48, 'Ricezione spedizione SPD-001 (parziale)', 1, NULL, NULL, 5),
(1, 4, 1, 'SCARICO', -50, 'Consumo giornaliero equipaggio', NULL, NULL, NULL, 1),
(4, 6, 6, 'SCARICO', -20, 'Rifornimento generatore Elysium', NULL, NULL, NULL, 4),
(6, 3, 3, 'SCARICO', -5, 'Ricambi usati per manutenzione rover', NULL, NULL, 2, 3);

-- ------------------------------------------------------------
-- Incidenti
-- ------------------------------------------------------------
INSERT INTO incidenti (codice, id_colonia, id_missione, id_habitat, id_asset, titolo, descrizione, severita, stato, riportato_da) VALUES
('INC-001', 1, NULL, 1, NULL, 'Caduta di pressione in Alloggi Ares Prime', 'Rilevata una caduta di pressione temporanea nel modulo residenziale.', 'ALTA', 'IN_GESTIONE', 1),
('INC-002', 3, 2, NULL, 5, 'Guasto antenna di comunicazione', 'Perdita totale di segnale dall''antenna relay principale.', 'CRITICA', 'APERTO', 4);

INSERT INTO incidenti (codice, id_colonia, id_missione, id_habitat, id_asset, titolo, descrizione, severita, stato, causa_radice, riportato_da, chiuso_il, chiuso_da, motivazione_chiusura) VALUES
('INC-003', 3, 3, NULL, 3, 'Rover immobilizzato durante il recupero', 'Il rover Voyager si e'' bloccato per un guasto alla batteria.', 'MEDIA', 'CHIUSO', 'Batteria scarica per basse temperature notturne', 4, now() - INTERVAL '40 days', 4, 'Risolto sul posto, batteria sostituita, nessun danno permanente.');

INSERT INTO persone_incidente (id_incidente, id_astronauta, ruolo_nell_evento) VALUES
(1, 1, 'COINVOLTO'),
(3, 8, 'PRIMO_INTERVENTO'),
(3, 3, 'COINVOLTO');

INSERT INTO timeline_incidente (id_incidente, tipo_evento, descrizione, data_evento, registrato_da) VALUES
(1, 'SEGNALAZIONE', 'Sensore di pressione ha rilevato un calo anomalo', now() - INTERVAL '3 hours', 1),
(1, 'PRESA_IN_CARICO', 'Tecnico inviato per ispezione', now() - INTERVAL '2 hours', 1),
(3, 'SEGNALAZIONE', 'Rover non risponde ai comandi remoti', '2026-08-01 09:00+00', 4),
(3, 'AZIONE', 'Squadra di soccorso inviata sul posto', '2026-08-01 10:30+00', 4),
(3, 'CHIUSURA', 'Batteria sostituita, rover di nuovo operativo', '2026-08-01 19:00+00', 4);

-- ------------------------------------------------------------
-- Scienza
-- ------------------------------------------------------------
INSERT INTO laboratori (id_habitat, nome, specializzazione, ultima_modifica) VALUES
(4, 'Laboratorio Geologia', 'GEOLOGIA', now()),
(4, 'Laboratorio Biologia', 'BIOLOGIA', now()),
(4, 'Laboratorio Materiali', 'MATERIALI', now());

INSERT INTO esperimenti (codice, id_laboratorio, id_responsabile, titolo, descrizione, protocollo, stato, ultima_modifica) VALUES
('EXP-001', 1, 10, 'Analisi regolite del canyon', 'Studio della composizione minerale dei campioni raccolti', 'Protocollo standard AFC-GEO-01', 'IN_CORSO', now()),
('EXP-002', 2, 4, 'Coltura microbica marziana', 'Verifica sopravvivenza di colture in ambiente controllato', 'Protocollo AFC-BIO-04', 'PIANIFICATO', now()),
('EXP-003', 3, 4, 'Test resistenza materiali', 'Verifica resistenza di nuovi materiali da costruzione al freddo estremo', 'Protocollo AFC-MAT-02', 'CONCLUSO', now());

INSERT INTO attrezzature_esperimento (id_esperimento, id_asset, note) VALUES
(1, 7, 'Drone usato per i rilievi fotografici del sito');

INSERT INTO campioni (codice, tipo, descrizione_origine, id_missione_raccolta, collezionato_il, id_laboratorio_corrente, stato, ultima_modifica) VALUES
('CAM-001', 'Regolite', 'Raccolto durante la missione MIS-001', 1, '2026-09-20 11:00+00', 1, 'IN_ANALISI', now()),
('CAM-002', 'Ghiaccio', 'Campione da carotaggio superficiale', NULL, '2026-09-10 09:00+00', NULL, 'IN_TRANSITO', now()),
('CAM-003', 'Coltura', 'Coltura sperimentale in laboratorio', NULL, '2026-08-15 09:00+00', 2, 'IN_ARCHIVIO', now());

INSERT INTO trasferimenti_campione (id_campione, id_lab_partenza, id_lab_destinazione, trasferito_da) VALUES
(1, NULL, 1, 3);

INSERT INTO campioni_esperimenti (id_campione, id_esperimento) VALUES
(1, 1),
(3, 2);

INSERT INTO risultati_esperimento (id_esperimento, descrizione, stato_validazione, validato_da, ultima_modifica) VALUES
(3, 'Materiale idoneo: resistenza confermata fino a -80 C', 'VALIDATO', 5, now());

-- ------------------------------------------------------------
-- Notifiche e audit
-- ------------------------------------------------------------
INSERT INTO destinatari_alert (id_alert, id_utente, notificato_il, visionato_il) VALUES
(1, 1, now(), NULL),                          -- non ancora vista: utile per test escalation
(4, 4, now() - INTERVAL '1 day', now() - INTERVAL '22 hours');

INSERT INTO notifiche (id_utente, tipo_oggetto, id_oggetto, testo) VALUES
(4, 'MISSIONE', 1, 'Sei stato assegnato alla missione MIS-001'),
(4, 'TICKET', 1, 'Nuovo ticket critico aperto su AST-ANT-01');

INSERT INTO audit_log (id_utente, entita, id_entita, azione, motivazione) VALUES
(5, 'INCIDENTI', '3', 'UPDATE', 'Chiusura incidente con motivazione'),
(1, 'MISSIONI', '2', 'APPROVE', 'Missione critica approvata dopo verifica requisiti');
