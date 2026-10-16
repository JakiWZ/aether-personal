-- ============================================================
-- AETHER - Mars Operations Platform
-- Script SQL (PostgreSQL) di SEED / DATI DI TEST
-- Da eseguire DOPO aver applicato 04_AETHER_schema.sql
-- (es. psql -f 04_AETHER_schema.sql poi psql -f 05_AETHER_seed_data.sql)
--
-- Obiettivo: fornire dati coerenti e sufficienti a sviluppare e
-- dimostrare il prodotto, rispettando i vincoli (PK/FK/CHECK/UNIQUE)
-- definiti nello schema.
--
-- Criteri soddisfatti:
--  - Almeno 3 basi (colonie)                 -> 4 colonie
--  - Almeno 15 membri equipaggio (astronauti) -> 20 astronauti
--  - Missioni in stati differenti             -> tutti e 7 gli stati
--  - Veicoli e risorse presenti                -> asset_tecnici, catalogo_risorse, lotti, giacenza
--  - Casi utili per query e test negativi      -> vedi commenti "TEST" nel testo
-- ============================================================

BEGIN;

-- ============================================================
-- 1. tipi_asset
-- ============================================================
INSERT INTO tipi_asset (id_tipo_asset, codice, nome, criticita_di_default) VALUES
(1, 'VEICOLO_ROVER',        'Rover di superficie',        'ALTA'),
(2, 'VEICOLO_LANDER',       'Lander / Navetta',            'VITALE'),
(3, 'GENERATORE_ENERGIA',   'Generatore di energia',       'VITALE'),
(4, 'SISTEMA_SUPPORTO_VITA','Sistema di supporto vitale',  'VITALE'),
(5, 'STAZIONE_METEO',       'Stazione meteorologica',      'MEDIA'),
(6, 'ROBOT_PERFORAZIONE',   'Robot di perforazione',       'ALTA'),
(7, 'STRUMENTO_LABORATORIO','Strumento da laboratorio',    'MEDIA'),
(8, 'SISTEMA_COMUNICAZIONE','Sistema di comunicazione',    'ALTA'),
(9, 'DRONE_RICOGNIZIONE',   'Drone da ricognizione',       'BASSA');

-- ============================================================
-- 2. categorie_risorsa
-- ============================================================
INSERT INTO categorie_risorsa (id_categoria_risorsa, nome, richiede_lotti_di_default) VALUES
(1, 'Alimentari',                 TRUE),
(2, 'Acqua e Ossigeno',           FALSE),
(3, 'Propellente',                FALSE),
(4, 'Ricambi Tecnici',            FALSE),
(5, 'Farmaci',                    TRUE),
(6, 'Materiali da Costruzione',   FALSE);

-- ============================================================
-- 3. unita_misura
-- ============================================================
INSERT INTO unita_misura (id_unita_misura, codice, descrizione) VALUES
(1, 'KG',  'Chilogrammi'),
(2, 'L',   'Litri'),
(3, 'M3',  'Metri cubi'),
(4, 'PZ',  'Pezzi'),
(5, 'PA',  'Pascal'),
(6, 'C',   'Gradi Celsius'),
(7, 'PPM', 'Parti per milione'),
(8, 'PCT', 'Percentuale');

-- ============================================================
-- 4. tipi_misurazione
-- ============================================================
INSERT INTO tipi_misurazione (id_tipo_misurazione, nome, id_unita_misura_attesa) VALUES
(1, 'Pressione Atmosferica',   5),
(2, 'Temperatura',             6),
(3, 'Concentrazione CO2',      7),
(4, 'Umidita Relativa',        8),
(5, 'Livello Ossigeno',        8);

-- ============================================================
-- 5. colonie
-- (id_responsabile impostato dopo la creazione degli astronauti,
--  a causa della dipendenza circolare colonie <-> astronauti)
-- ============================================================
INSERT INTO colonie
(id_colonia, codice, nome, area, latitudine, longitudine, stato_operativo, id_responsabile, capacita_massima, data_creazione, ultima_modifica, cancellato) VALUES
(1, 'NOVA1', 'Nova Ares',       'Acidalia Planitia',   46.700000,  -22.450000, 'ATTIVA',         NULL, 120, '2025-03-01 08:00:00+00', '2026-09-01 08:00:00+00', FALSE),
(2, 'OLY02', 'Olympus Base',    'Tharsis',              18.650000, -133.800000,'ATTIVA',         NULL,  90, '2025-05-10 08:00:00+00', '2026-09-01 08:00:00+00', FALSE),
(3, 'TAU03', 'Tau Outpost',     'Valles Marineris',    -13.900000,  -59.200000, 'IN_COSTRUZIONE', NULL,  40, '2026-04-01 08:00:00+00', '2026-09-10 08:00:00+00', FALSE),
(4, 'HELL04','Hellas Station',  'Hellas Planitia',     -42.400000,   70.500000, 'SOSPESA',        NULL,  60, '2025-01-15 08:00:00+00', '2026-07-01 08:00:00+00', FALSE);

-- ============================================================
-- 6. astronauti (>= 15 richiesti -> 20 astronauti su 4 colonie)
-- ============================================================
INSERT INTO astronauti
(id_astronauta, matricola, nome, cognome, data_di_nascita, mansione, id_colonia, stato_servizio, data_creazione, ultima_modifica, cancellato) VALUES
(1,  'AST-001', 'Marco',       'Rossi',      '1985-04-12', 'Comandante', 1, 'IN_SERVIZIO', '2025-03-01 08:00:00+00', '2026-09-01 08:00:00+00', FALSE),
(2,  'AST-002', 'Elena',       'Bianchi',    '1988-09-03', 'Ingegnere',  1, 'IN_SERVIZIO', '2025-03-01 08:00:00+00', '2026-09-01 08:00:00+00', FALSE),
(3,  'AST-003', 'Luca',        'Ferrari',    '1990-01-22', 'Pilota',     1, 'IN_SERVIZIO', '2025-03-01 08:00:00+00', '2026-09-01 08:00:00+00', FALSE),
(4,  'AST-004', 'Giulia',      'Romano',     '1987-06-15', 'Medico',     1, 'IN_SERVIZIO', '2025-03-01 08:00:00+00', '2026-09-01 08:00:00+00', FALSE),
(5,  'AST-005', 'Davide',      'Colombo',    '1983-11-30', 'Geologo',    1, 'IN_TRANSITO', '2025-03-01 08:00:00+00', '2026-09-01 08:00:00+00', FALSE),
(6,  'AST-006', 'Sara',        'Greco',      '1991-02-18', 'Biologo',    2, 'IN_SERVIZIO', '2025-05-10 08:00:00+00', '2026-09-01 08:00:00+00', FALSE),
(7,  'AST-007', 'Andrea',      'Bruno',      '1986-07-09', 'Comandante', 2, 'IN_SERVIZIO', '2025-05-10 08:00:00+00', '2026-09-01 08:00:00+00', FALSE),
(8,  'AST-008', 'Chiara',      'Gallo',      '1989-12-25', 'Tecnico',    2, 'IN_SERVIZIO', '2025-05-10 08:00:00+00', '2026-09-01 08:00:00+00', FALSE),
(9,  'AST-009', 'Matteo',      'Conti',      '1984-03-14', 'Ingegnere',  2, 'IN_SERVIZIO', '2025-05-10 08:00:00+00', '2026-09-01 08:00:00+00', FALSE),
(10, 'AST-010', 'Federica',    'Marino',     '1992-05-07', 'Chimico',    2, 'RIENTRATO',   '2025-05-10 08:00:00+00', '2026-08-01 08:00:00+00', FALSE),
(11, 'AST-011', 'Simone',      'Ricci',      '1988-08-19', 'Comandante', 3, 'IN_SERVIZIO', '2026-04-01 08:00:00+00', '2026-09-10 08:00:00+00', FALSE),
(12, 'AST-012', 'Valentina',   'Costa',      '1990-10-02', 'Pilota',     3, 'IN_TRANSITO', '2026-04-01 08:00:00+00', '2026-09-10 08:00:00+00', FALSE),
(13, 'AST-013', 'Alessandro',  'Fontana',    '1985-01-27', 'Tecnico',    3, 'IN_SERVIZIO', '2026-04-01 08:00:00+00', '2026-09-10 08:00:00+00', FALSE),
(14, 'AST-014', 'Martina',     'Serra',      '1993-04-11', 'Medico',     3, 'IN_SERVIZIO', '2026-04-01 08:00:00+00', '2026-09-10 08:00:00+00', FALSE),
(15, 'AST-015', 'Paolo',       'Moretti',    '1982-09-23', 'Geologo',    1, 'IN_SERVIZIO', '2025-03-01 08:00:00+00', '2026-09-01 08:00:00+00', FALSE),
(16, 'AST-016', 'Francesca',   'Rizzo',      '1991-06-30', 'Biologo',    1, 'IN_SERVIZIO', '2025-03-01 08:00:00+00', '2026-09-01 08:00:00+00', FALSE),
(17, 'AST-017', 'Roberto',     'Lombardi',   '1987-12-05', 'Ingegnere',  4, 'RIENTRATO',   '2025-01-15 08:00:00+00', '2026-07-01 08:00:00+00', FALSE),
(18, 'AST-018', 'Silvia',      'Barbieri',   '1989-03-17', 'Comandante', 4, 'IN_SERVIZIO', '2025-01-15 08:00:00+00', '2026-07-01 08:00:00+00', FALSE),
(19, 'AST-019', 'Giorgio',     'Villa',      '1984-11-11', 'Tecnico',    2, 'IN_SERVIZIO', '2025-05-10 08:00:00+00', '2026-09-01 08:00:00+00', FALSE),
(20, 'AST-020', 'Anna',        'Fabbri',     '1990-07-08', 'Pilota',     3, 'IN_SERVIZIO', '2026-04-01 08:00:00+00', '2026-09-10 08:00:00+00', FALSE);

-- Chiusura della dipendenza circolare colonie <-> astronauti
UPDATE colonie SET id_responsabile = 1  WHERE id_colonia = 1;
UPDATE colonie SET id_responsabile = 7  WHERE id_colonia = 2;
UPDATE colonie SET id_responsabile = 11 WHERE id_colonia = 3;
UPDATE colonie SET id_responsabile = 18 WHERE id_colonia = 4;

-- ============================================================
-- 7. utenti
-- (16 = admin di sistema senza astronauta; 15 astronauti + admin;
--  utente 16 collegato ad astronauta RIENTRATO e DISABILITATO -> TEST negativo)
-- ============================================================
INSERT INTO utenti
(id_user, email, username, password_hash, stato, id_astronauta, utente_cancellato, data_creazione, ultima_modifica) VALUES
(1,  'marco.rossi@aether.mars',      'mrossi',    '$2b$12$seedHASHmrossi000000000000000000000000000001', 'ATTIVO',      1,  FALSE, '2025-03-01 08:05:00+00', '2026-09-01 08:05:00+00'),
(2,  'elena.bianchi@aether.mars',    'ebianchi',  '$2b$12$seedHASHebianchi0000000000000000000000000002', 'ATTIVO',      2,  FALSE, '2025-03-01 08:05:00+00', '2026-09-01 08:05:00+00'),
(3,  'luca.ferrari@aether.mars',     'lferrari',  '$2b$12$seedHASHlferrari0000000000000000000000000003', 'ATTIVO',      3,  FALSE, '2025-03-01 08:05:00+00', '2026-09-01 08:05:00+00'),
(4,  'giulia.romano@aether.mars',    'gromano',   '$2b$12$seedHASHgromano00000000000000000000000000004', 'ATTIVO',      4,  FALSE, '2025-03-01 08:05:00+00', '2026-09-01 08:05:00+00'),
(5,  'davide.colombo@aether.mars',   'dcolombo',  '$2b$12$seedHASHdcolombo0000000000000000000000000005', 'ATTIVO',      5,  FALSE, '2025-03-01 08:05:00+00', '2026-09-01 08:05:00+00'),
(6,  'sara.greco@aether.mars',       'sgreco',    '$2b$12$seedHASHsgreco000000000000000000000000000006', 'ATTIVO',      6,  FALSE, '2025-05-10 08:05:00+00', '2026-09-01 08:05:00+00'),
(7,  'andrea.bruno@aether.mars',     'abruno',    '$2b$12$seedHASHabruno000000000000000000000000000007', 'ATTIVO',      7,  FALSE, '2025-05-10 08:05:00+00', '2026-09-01 08:05:00+00'),
(8,  'chiara.gallo@aether.mars',     'cgallo',    '$2b$12$seedHASHcgallo000000000000000000000000000008', 'ATTIVO',      8,  FALSE, '2025-05-10 08:05:00+00', '2026-09-01 08:05:00+00'),
(9,  'matteo.conti@aether.mars',     'mconti',    '$2b$12$seedHASHmconti000000000000000000000000000009', 'ATTIVO',      9,  FALSE, '2025-05-10 08:05:00+00', '2026-09-01 08:05:00+00'),
(10, 'federica.marino@aether.mars',  'fmarino',   '$2b$12$seedHASHfmarino00000000000000000000000000010', 'SOSPESO',     10, FALSE, '2025-05-10 08:05:00+00', '2026-08-01 08:05:00+00'),
(11, 'simone.ricci@aether.mars',     'sricci',    '$2b$12$seedHASHsricci000000000000000000000000000011', 'ATTIVO',      11, FALSE, '2026-04-01 08:05:00+00', '2026-09-10 08:05:00+00'),
(12, 'valentina.costa@aether.mars',  'vcosta',    '$2b$12$seedHASHvcosta000000000000000000000000000012', 'ATTIVO',      12, FALSE, '2026-04-01 08:05:00+00', '2026-09-10 08:05:00+00'),
(13, 'alessandro.fontana@aether.mars','afontana', '$2b$12$seedHASHafontana0000000000000000000000000013', 'ATTIVO',      13, FALSE, '2026-04-01 08:05:00+00', '2026-09-10 08:05:00+00'),
(14, 'martina.serra@aether.mars',    'mserra',    '$2b$12$seedHASHmserra000000000000000000000000000014', 'ATTIVO',      14, FALSE, '2026-04-01 08:05:00+00', '2026-09-10 08:05:00+00'),
(15, 'admin.sistema@aether.mars',    'admin',     '$2b$12$seedHASHadmin0000000000000000000000000000015', 'ATTIVO',      NULL, FALSE, '2025-01-01 08:00:00+00', '2026-09-01 08:00:00+00'),
(16, 'roberto.lombardi@aether.mars', 'rlombardi', '$2b$12$seedHASHrlombardi000000000000000000000000016', 'DISABILITATO',17, FALSE, '2025-01-15 08:05:00+00', '2026-07-01 08:05:00+00'),
(17, 'silvia.barbieri@aether.mars',  'sbarbieri', '$2b$12$seedHASHsbarbieri000000000000000000000000017', 'ATTIVO',      18, FALSE, '2025-01-15 08:05:00+00', '2026-07-01 08:05:00+00');
-- TEST: utente 10 SOSPESO e utente 16 DISABILITATO (entrambi legati ad astronauti non IN_SERVIZIO)

-- ============================================================
-- 8. parametri_sistema
-- ============================================================
INSERT INTO parametri_sistema (chiave, valore, tipo_dato, descrizione, ultima_modifica, modificato_da) VALUES
('SOGLIA_ALERT_OSSIGENO_MIN', '19.5',  'DECIMAL', 'Soglia minima percentuale ossigeno prima di generare alert',        '2026-01-10 09:00:00+00', 15),
('INTERVALLO_BACKUP_ORE',     '24',    'INT',     'Intervallo in ore tra un backup di sistema e il successivo',        '2026-01-10 09:00:00+00', 15),
('MODALITA_MANUTENZIONE',     'false', 'BOOLEAN', 'Flag che indica se la piattaforma e in modalita manutenzione',      '2026-02-01 09:00:00+00', 15),
('NOME_PIATTAFORMA',          'AETHER','STRING',  'Nome visualizzato della piattaforma',                                '2025-01-01 09:00:00+00', 15),
('TIMEOUT_SESSIONE',          'PT30M', 'DURATA',  'Durata massima di inattivita prima della scadenza della sessione',  '2025-01-01 09:00:00+00', 15);

-- ============================================================
-- 9. ruoli
-- ============================================================
INSERT INTO ruoli (id_ruolo, nome, descrizione) VALUES
(1, 'ADMIN',                 'Amministratore di sistema con accesso completo'),
(2, 'COMANDANTE',             'Responsabile di colonia o missione'),
(3, 'OPERATORE',              'Operatore generico con permessi limitati'),
(4, 'SCIENZIATO',             'Personale scientifico e di ricerca'),
(5, 'TECNICO_MANUTENZIONE',   'Personale tecnico per manutenzione asset');

-- ============================================================
-- 10. ruoli_utenti
-- ============================================================
INSERT INTO ruoli_utenti (id_utente, id_ruolo, assegnato_il, assegnato_da) VALUES
(15, 1, '2025-01-01 08:10:00+00', NULL),
(1,  2, '2025-03-01 08:10:00+00', 15),
(7,  2, '2025-05-10 08:10:00+00', 15),
(11, 2, '2026-04-01 08:10:00+00', 15),
(17, 2, '2025-01-15 08:10:00+00', 15),
(2,  5, '2025-03-01 08:10:00+00', 15),
(9,  5, '2025-05-10 08:10:00+00', 15),
(13, 5, '2026-04-01 08:10:00+00', 15),
(8,  5, '2025-05-10 08:10:00+00', 15),
(16, 5, '2025-01-15 08:10:00+00', 15),
(6,  4, '2025-05-10 08:10:00+00', 15),
(4,  4, '2025-03-01 08:10:00+00', 15),
(5,  4, '2025-03-01 08:10:00+00', 15),
(14, 4, '2026-04-01 08:10:00+00', 15),
(3,  3, '2025-03-01 08:10:00+00', 15),
(12, 3, '2026-04-01 08:10:00+00', 15),
(10, 3, '2025-05-10 08:10:00+00', 15);

-- ============================================================
-- 11. accessi_falliti
-- ============================================================
INSERT INTO accessi_falliti (id_tentativo, email_tentata, indirizzo_ip, data_tentativo, motivo) VALUES
(1, 'hacker@unknown.com',            '203.0.113.5',  '2026-09-14 03:12:00+00', 'PASSWORD_ERRATA'),
(2, 'federica.marino@aether.mars',   '10.0.2.15',    '2026-09-10 14:22:00+00', 'ACCOUNT_SOSPESO'),
(3, 'admin.sistema@aether.mars',     '198.51.100.9', '2026-09-15 22:47:00+00', 'PASSWORD_ERRATA'),
(4, 'roberto.lombardi@aether.mars',  '198.51.100.9', '2026-09-15 22:48:00+00', 'ACCOUNT_DISABILITATO');
-- TEST: tentativi su account sospesi/disabilitati e utente inesistente

-- ============================================================
-- 12. permessi
-- ============================================================
INSERT INTO permessi (id_permesso, codice, descrizione) VALUES
(1, 'MISSIONI_CREATE',  'Creare nuove missioni'),
(2, 'MISSIONI_APPROVE', 'Approvare missioni pianificate'),
(3, 'RISORSE_MANAGE',   'Gestire catalogo risorse e magazzino'),
(4, 'UTENTI_MANAGE',    'Gestire utenti e ruoli'),
(5, 'ASSET_MANAGE',     'Gestire asset tecnici e manutenzioni'),
(6, 'INCIDENTI_MANAGE', 'Gestire incidenti e relative azioni'),
(7, 'REPORT_VIEW',      'Visualizzare report e dashboard');

-- ============================================================
-- 13. ruoli_permessi
-- ============================================================
INSERT INTO ruoli_permessi (id_ruolo, id_permesso) VALUES
(1,1),(1,2),(1,3),(1,4),(1,5),(1,6),(1,7),
(2,1),(2,2),(2,7),
(3,7),
(4,7),
(5,5),(5,7);

-- ============================================================
-- 14. sessioni
-- ============================================================
INSERT INTO sessioni (id_sessione, id_utente, token_hash, creata_il, scade_il, revocata_il, indirizzo_ip, user_agent) VALUES
(1, 1,  'tok-hash-mrossi-001', '2026-09-15 07:00:00+00', '2026-09-15 07:30:00+00', NULL,                     '10.0.1.5',  'AetherApp/1.4 (HabitatTerminal)'),
(2, 15, 'tok-hash-admin-002',  '2026-09-16 06:00:00+00', '2026-09-16 06:30:00+00', NULL,                     '10.0.0.2',  'AetherApp/1.4 (ControlRoom)'),
(3, 9,  'tok-hash-mconti-003', '2026-09-14 09:00:00+00', '2026-09-14 09:30:00+00', '2026-09-14 09:12:00+00', '10.0.2.9',  'AetherApp/1.3 (FieldTablet)'),
(4, 1,  'tok-hash-mrossi-004', '2026-08-01 07:00:00+00', '2026-08-01 07:30:00+00', NULL,                     '10.0.1.5',  'AetherApp/1.2 (HabitatTerminal)');
-- TEST: sessione 1 attiva ma "scade_il" nel passato rispetto ad ora corrente -> sessione scaduta;
--       sessione 3 revocata manualmente; sessione 4 vecchia/scaduta

-- ============================================================
-- 15. habitat
-- ============================================================
INSERT INTO habitat (id_habitat, id_colonia, id_habitat_padre, nome, funzione, capacita, stato, data_creazione, ultima_modifica, cancellato) VALUES
(1,  1, NULL, 'Modulo Centrale Nova-1',           'COMANDO',      50, 'OPERATIVO',    '2025-03-01 08:00:00+00', '2026-09-01 08:00:00+00', FALSE),
(2,  1, 1,    'Ala Residenziale A',               'ALLOGGIO',     30, 'OPERATIVO',    '2025-03-05 08:00:00+00', '2026-09-01 08:00:00+00', FALSE),
(3,  1, 1,    'Serra Idroponica Nova-1',          'AGRICOLTURA',  10, 'OPERATIVO',    '2025-03-10 08:00:00+00', '2026-09-12 08:00:00+00', FALSE),
(4,  1, 1,    'Laboratorio Scientifico Nova-1',   'RICERCA',      15, 'MANUTENZIONE', '2025-03-15 08:00:00+00', '2026-09-01 08:00:00+00', FALSE),
(5,  2, NULL, 'Modulo Centrale Olympus',          'COMANDO',      40, 'OPERATIVO',    '2025-05-10 08:00:00+00', '2026-09-01 08:00:00+00', FALSE),
(6,  2, 5,    'Ala Residenziale Olympus',         'ALLOGGIO',     25, 'OPERATIVO',    '2025-05-15 08:00:00+00', '2026-09-01 08:00:00+00', FALSE),
(7,  2, 5,    'Officina Meccanica Olympus',       'MANUTENZIONE', 12, 'OPERATIVO',    '2025-05-20 08:00:00+00', '2026-09-01 08:00:00+00', FALSE),
(8,  3, NULL, 'Modulo Provvisorio Tau',           'COMANDO',      20, 'OPERATIVO',    '2026-04-01 08:00:00+00', '2026-09-10 08:00:00+00', FALSE),
(9,  3, 8,    'Deposito Materiali Tau',           'STOCCAGGIO',   15, 'OPERATIVO',    '2026-04-05 08:00:00+00', '2026-09-10 08:00:00+00', FALSE),
(10, 4, NULL, 'Modulo Centrale Hellas',           'COMANDO',      30, 'FUORI_SERVIZIO','2025-01-15 08:00:00+00','2026-07-01 08:00:00+00', FALSE);
-- TEST: habitat 10 FUORI_SERVIZIO poiche' la colonia Hellas e' SOSPESA

-- ============================================================
-- 16. asset_tecnici (veicoli e altri asset)
-- ============================================================
INSERT INTO asset_tecnici (id_asset, codice, id_colonia, id_habitat, nome, id_tipo_asset, criticita, stato, data_creazione, ultima_modifica, cancellato) VALUES
(1,  'ROV-001', 1, NULL, 'Rover Pathfinder II',            1, 'ALTA',   'OPERATIVO',      '2025-03-01 08:00:00+00', '2026-09-01 08:00:00+00', FALSE),
(2,  'LAN-001', 1, NULL, 'Lander Ares-1',                  2, 'VITALE', 'OPERATIVO',      '2025-03-01 08:00:00+00', '2026-09-01 08:00:00+00', FALSE),
(3,  'GEN-001', 1, 1,    'Generatore Nucleare Nova-1',     3, 'VITALE', 'OPERATIVO',      '2025-03-01 08:00:00+00', '2026-09-14 08:00:00+00', FALSE),
(4,  'SSV-001', 1, 2,    'Sistema Supporto Vitale Ala-A',  4, 'VITALE', 'OPERATIVO',      '2025-03-01 08:00:00+00', '2026-09-15 08:00:00+00', FALSE),
(5,  'MET-001', 1, NULL, 'Stazione Meteo Nova-1',          5, 'MEDIA',  'OPERATIVO',      '2025-03-01 08:00:00+00', '2026-09-01 08:00:00+00', FALSE),
(6,  'ROV-002', 2, NULL, 'Rover Explorer III',             1, 'ALTA',   'MANUTENZIONE',   '2025-05-10 08:00:00+00', '2026-09-10 08:00:00+00', FALSE),
(7,  'GEN-002', 2, 5,    'Generatore Solare Olympus',      3, 'VITALE', 'OPERATIVO',      '2025-05-10 08:00:00+00', '2026-09-01 08:00:00+00', FALSE),
(8,  'PER-001', 2, NULL, 'Robot Perforazione Olympus',     6, 'ALTA',   'OPERATIVO',      '2025-05-10 08:00:00+00', '2026-09-01 08:00:00+00', FALSE),
(9,  'COM-001', 2, 5,    'Antenna Comunicazione Olympus',  8, 'ALTA',   'OUT_OF_SERVICE', '2025-05-10 08:00:00+00', '2026-09-14 08:00:00+00', FALSE),
(10, 'LAN-002', 3, NULL, 'Lander Cargo Tau',               2, 'VITALE', 'OPERATIVO',      '2026-04-01 08:00:00+00', '2026-09-10 08:00:00+00', FALSE),
(11, 'DRN-001', 3, NULL, 'Drone Ricognizione Tau-1',       9, 'BASSA',  'OPERATIVO',      '2026-04-01 08:00:00+00', '2026-09-15 08:00:00+00', FALSE),
(12, 'GEN-003', 4, 10,   'Generatore Hellas',              3, 'VITALE', 'DISMESSO',       '2025-01-15 08:00:00+00', '2026-07-01 08:00:00+00', FALSE),
(13, 'STR-001', 1, 4,    'Spettrometro da Laboratorio',    7, 'MEDIA',  'OPERATIVO',      '2025-03-15 08:00:00+00', '2026-09-01 08:00:00+00', FALSE);
-- TEST: asset 9 OUT_OF_SERVICE (comunicazione compromessa) e asset 12 DISMESSO in colonia sospesa

-- ============================================================
-- 17. storico_asset
-- ============================================================
INSERT INTO storico_asset (id_storico, id_asset, tipo_evento, data_evento, descrizione, vecchio_stato, nuovo_stato, registrato_da) VALUES
(1, 6,  'CAMBIO_STATO',       '2026-09-10 09:00:00+00', 'Rumore anomalo al motore ruota anteriore, messo in manutenzione', 'OPERATIVO', 'MANUTENZIONE',   8),
(2, 9,  'CAMBIO_STATO',       '2026-09-14 12:00:00+00', 'Perdita completa del segnale, antenna fuori servizio',            'OPERATIVO', 'OUT_OF_SERVICE', 9),
(3, 12, 'CAMBIO_STATO',       '2026-07-01 10:00:00+00', 'Generatore dismesso a seguito della sospensione della colonia',   'OPERATIVO', 'DISMESSO',        15),
(4, 3,  'MANUTENZIONE_ESEGUITA','2026-08-20 10:00:00+00','Ispezione periodica generatore nucleare completata',            'OPERATIVO', 'OPERATIVO',       2);

-- ============================================================
-- 18. responsabili_asset
-- ============================================================
INSERT INTO responsabili_asset (id_asset, id_responsabile, ruolo, valido_dal, valido_al) VALUES
(1,  3,  'TITOLARE',  '2025-03-01', NULL),
(3,  2,  'TITOLARE',  '2025-03-01', NULL),
(4,  2,  'SOSTITUTO', '2025-03-01', NULL),
(6,  9,  'TITOLARE',  '2025-05-10', NULL),
(9,  9,  'TITOLARE',  '2025-05-10', NULL),
(11, 20, 'TITOLARE',  '2026-04-01', NULL);

-- ============================================================
-- 19. competenze
-- ============================================================
INSERT INTO competenze (id_competenza, nome, categoria) VALUES
(1, 'Pilotaggio Rover',        'OPERATIVA'),
(2, 'Manutenzione Elettrica',  'TECNICA'),
(3, 'Primo Soccorso',          'MEDICA'),
(4, 'Biologia Molecolare',     'SCIENTIFICA'),
(5, 'Geologia Planetaria',     'SCIENTIFICA'),
(6, 'Chimica Analitica',       'SCIENTIFICA'),
(7, 'Gestione Crisi',          'LEADERSHIP');

-- ============================================================
-- 20. competenze_astronauti
-- ============================================================
INSERT INTO competenze_astronauti (id_competenza, id_astronauta, livello, data_di_valutazione, data_scadenza) VALUES
(1, 3,  4, '2024-01-10', NULL),
(2, 2,  5, '2023-11-05', '2026-11-05'),
(3, 3,  3, '2022-05-01', '2025-05-01'),  -- TEST: competenza scaduta (valida fino al 2025, oggi siamo nel 2026)
(3, 4,  4, '2024-02-20', NULL),
(4, 6,  5, '2023-08-15', NULL),
(2, 9,  4, '2024-03-01', '2027-03-01'),
(5, 15, 5, '2022-01-01', NULL),
(6, 10, 3, '2021-06-01', '2024-06-01'), -- TEST: competenza scaduta di astronauta gia' RIENTRATO
(7, 1,  4, '2023-01-01', NULL);

-- ============================================================
-- 21. certificazioni
-- ============================================================
INSERT INTO certificazioni (id_certificazione, nome_certificazione, ente_emittente, validita_mesi) VALUES
(1, 'EVA Certification',              'ESA',                              24),
(2, 'Reattore Nucleare Portatile',    'NASA',                             36),
(3, 'Primo Soccorso Avanzato',        'Croce Rossa Interplanetaria',      12),
(4, 'Pilota Lander',                  'ESA',                              24);

-- ============================================================
-- 22. certificazioni_astronauti
-- ============================================================
INSERT INTO certificazioni_astronauti (id_astronauta, id_certificazione, data_rilascio, data_scadenza, codice_documento) VALUES
(1,  1, '2024-01-15', '2026-01-15', 'DOC-EVA-001'),  -- TEST: certificazione SCADUTA, astronauta ancora IN_SERVIZIO
(2,  2, '2024-06-01', '2027-06-01', 'DOC-REACT-002'),
(3,  4, '2023-09-01', '2025-09-01', 'DOC-PIL-003'),  -- TEST: certificazione SCADUTA (pilota lander)
(4,  3, '2024-04-10', '2025-04-10', 'DOC-PS-004'),   -- TEST: certificazione SCADUTA (primo soccorso medico)
(11, 1, '2025-01-01', '2027-01-01', 'DOC-EVA-005'),
(20, 4, '2025-03-01', '2027-03-01', 'DOC-PIL-006');

-- ============================================================
-- 23. indisponibilita
-- ============================================================
INSERT INTO indisponibilita (id_indisponibilita, id_astronauta, data_inizio, data_fine, tipo, note) VALUES
(1, 5,  '2026-09-01 00:00:00+00', '2026-09-20 00:00:00+00', 'TRASFERIMENTO',   'In transito verso Nova Ares'),
(2, 10, '2026-08-01 00:00:00+00', '2026-12-01 00:00:00+00', 'CONGEDO_MEDICO',  'Rientrato sulla Terra per accertamenti medici'),
(3, 12, '2026-09-10 00:00:00+00', '2026-09-25 00:00:00+00', 'MISSIONE_ESTERNA','In transito per missione esplorativa'),
(4, 17, '2026-07-01 00:00:00+00', '2027-07-01 00:00:00+00', 'CONGEDO_LUNGO',   'Rientrato definitivamente in seguito a sospensione colonia');

-- ============================================================
-- 24. tipologie_missione
-- ============================================================
INSERT INTO tipologie_missione (id_tipologia, nome, richiede_approvazione) VALUES
(1, 'Esplorazione Superficie', TRUE),
(2, 'Manutenzione Asset',      FALSE),
(3, 'Ricerca Scientifica',     TRUE),
(4, 'Rifornimento',            FALSE),
(5, 'Emergenza',               FALSE);

-- ============================================================
-- 25. missioni (tutti gli stati previsti dal CHECK sono rappresentati)
-- ============================================================
INSERT INTO missioni
(id_missione, codice, obiettivo, descrizione, id_colonia, id_tipologia, data_inizio_prevista, data_fine_prevista, priorita, rischio, stato, id_responsabile, approvato_da, data_approvazione, data_creazione, ultima_modifica) VALUES
(1, 'MIS-001', 'Rilievo geologico Cratere Gale',            'Campagna di rilevamento e raccolta campioni rocciosi.',       1, 1, '2026-06-01 06:00:00+00', '2026-06-10 06:00:00+00', 'ALTA',     'MEDIO', 'COMPLETED',  15, 15, '2026-05-25 10:00:00+00', '2026-05-20 08:00:00+00', '2026-06-11 08:00:00+00'),
(2, 'MIS-002', 'Manutenzione Generatore Olympus',           'Manutenzione programmata del generatore solare.',              2, 2, '2026-09-10 06:00:00+00', '2026-09-18 06:00:00+00', 'CRITICA',  'ALTO',  'IN_PROGRESS',9, NULL, NULL,                     '2026-09-05 08:00:00+00', '2026-09-15 08:00:00+00'),
(3, 'MIS-003', 'Studio campioni biologici Tau',             'Analisi di campioni raccolti nell area di Valles Marineris.',  3, 3, '2026-10-01 06:00:00+00', '2026-10-15 06:00:00+00', 'MEDIA',    'BASSO', 'PLANNED',    11, NULL, NULL,                    '2026-09-01 08:00:00+00', '2026-09-01 08:00:00+00'),
(4, 'MIS-004', 'Rifornimento Hellas Station',                'Consegna materiali di sussistenza alla colonia sospesa.',      4, 4, '2026-08-01 06:00:00+00', '2026-08-10 06:00:00+00', 'ALTA',     'MEDIO', 'SUSPENDED',  18, NULL, NULL,                    '2026-07-20 08:00:00+00', '2026-07-25 08:00:00+00'),
(5, 'MIS-005', 'Espansione Serra Idroponica',                'Progetto di ampliamento della capacita produttiva della serra.', 1, 1, '2026-11-01 06:00:00+00', '2026-11-20 06:00:00+00', 'BASSA',    'BASSO', 'DRAFT',      16, NULL, NULL,                    '2026-09-14 08:00:00+00', '2026-09-14 08:00:00+00'),
(6, 'MIS-006', 'Missione esplorativa Valles Marineris',      'Esplorazione approfondita del canyon con rover e drone.',      3, 1, '2026-09-25 06:00:00+00', '2026-10-05 06:00:00+00', 'ALTA',     'ALTO',  'APPROVED',   11, 15, '2026-09-14 09:00:00+00', '2026-09-05 08:00:00+00', '2026-09-14 09:00:00+00'),
(7, 'MIS-007', 'Test drone ricognizione avanzato',           'Sperimentazione del nuovo drone in ambiente ostile.',          3, 3, '2026-07-01 06:00:00+00', '2026-07-05 06:00:00+00', 'MEDIA',    'MEDIO', 'CANCELLED',  11, NULL, NULL,                    '2026-06-20 08:00:00+00', '2026-07-02 08:00:00+00'),
(8, 'MIS-008', 'Emergenza guasto supporto vitale',           'Intervento di emergenza per guasto al sistema di supporto vitale.', 1, 5, '2026-09-15 05:00:00+00', '2026-09-16 05:00:00+00', 'CRITICA', 'ALTO',  'IN_PROGRESS',2, NULL, NULL,                    '2026-09-15 05:10:00+00', '2026-09-15 09:00:00+00');
-- Le 8 missioni sopra rappresentano tutti e 7 gli stati previsti dal CHECK su "stato"

-- ============================================================
-- 26. task_missione
-- ============================================================
INSERT INTO task_missione (id_task, id_missione, numero, obiettivo, stato, data_inizio, data_fine, id_responsabile, data_creazione, ultima_modifica) VALUES
(1, 1, 1, 'Raccolta campioni rocciosi',       'COMPLETATO', '2026-06-01 06:00:00+00', '2026-06-05 06:00:00+00', 15, '2026-05-20 08:00:00+00', '2026-06-05 08:00:00+00'),
(2, 1, 2, 'Analisi preliminare in loco',      'COMPLETATO', '2026-06-05 06:00:00+00', '2026-06-09 06:00:00+00', 15, '2026-05-20 08:00:00+00', '2026-06-09 08:00:00+00'),
(3, 2, 1, 'Ispezione pannelli solari',        'COMPLETATO', '2026-09-10 06:00:00+00', '2026-09-11 06:00:00+00', 9,  '2026-09-05 08:00:00+00', '2026-09-11 08:00:00+00'),
(4, 2, 2, 'Sostituzione batteria di accumulo','IN_CORSO',   '2026-09-12 06:00:00+00', NULL,                      9,  '2026-09-05 08:00:00+00', '2026-09-15 08:00:00+00'),
(5, 8, 1, 'Isolamento del guasto',            'COMPLETATO', '2026-09-15 05:00:00+00', '2026-09-15 06:00:00+00', 2,  '2026-09-15 05:10:00+00', '2026-09-15 06:00:00+00'),
(6, 8, 2, 'Riparazione sistema supporto vitale','IN_CORSO', '2026-09-15 06:00:00+00', NULL,                      2,  '2026-09-15 05:10:00+00', '2026-09-15 09:00:00+00');

-- ============================================================
-- 27. requisiti_missione
-- ============================================================
INSERT INTO requisiti_missione (id_requisito, id_missione, id_competenza, livello_minimo, id_certificazione, id_tipo_asset, quantita, note) VALUES
(1, 1, 5, 4, NULL, NULL, 1, 'Necessario un geologo esperto'),
(2, 2, 2, 3, NULL, 3,    1, 'Tecnico elettrico per il generatore'),
(3, 6, NULL, NULL, 1, 1, 2, 'Certificazione EVA per almeno due membri equipaggio');

-- ============================================================
-- 28. equipaggio_missione (al massimo un COMANDANTE per missione)
-- ============================================================
INSERT INTO equipaggio_missione (id_missione, id_astronauta, ruolo, assegnato_il) VALUES
(1, 15, 'RESPONSABILE_SCIENTIFICO', '2026-05-20 08:00:00+00'),
(1, 3,  'PILOTA',                   '2026-05-20 08:00:00+00'),
(2, 9,  'COMANDANTE',               '2026-09-05 08:00:00+00'),
(2, 8,  'TECNICO',                  '2026-09-05 08:00:00+00'),
(3, 11, 'COMANDANTE',               '2026-09-01 08:00:00+00'),
(3, 6,  'BIOLOGO',                  '2026-09-01 08:00:00+00'),
(6, 11, 'COMANDANTE',               '2026-09-05 08:00:00+00'),
(6, 20, 'PILOTA',                   '2026-09-05 08:00:00+00'),
(6, 13, 'TECNICO',                  '2026-09-05 08:00:00+00'),
(8, 2,  'COMANDANTE',               '2026-09-15 05:10:00+00'),
(8, 4,  'MEDICO',                   '2026-09-15 05:10:00+00');

-- ============================================================
-- 29. asset_missione
-- ============================================================
INSERT INTO asset_missione (id_missione, id_asset, ruolo_impiego, assegnato_il) VALUES
(1, 1,  'ROVER_PRINCIPALE',   '2026-05-20 08:00:00+00'),
(2, 7,  'IMPIANTO_TARGET',    '2026-09-05 08:00:00+00'),
(6, 10, 'TRASPORTO',          '2026-09-05 08:00:00+00'),
(6, 11, 'RICOGNIZIONE',       '2026-09-05 08:00:00+00'),
(8, 4,  'SISTEMA_IN_GUASTO',  '2026-09-15 05:10:00+00');

-- ============================================================
-- 30. consuntivo_missione (solo per missioni concluse/abortite)
-- ============================================================
INSERT INTO consuntivo_missione (id_missione, esito, data_inizio_effettiva, data_fine_effettiva, note, redatto_da, data_chiusura) VALUES
(1, 'SUCCESSO',  '2026-06-01 06:00:00+00', '2026-06-11 06:00:00+00', 'Obiettivi raggiunti, campioni consegnati al laboratorio geologia.', 15, '2026-06-11 09:00:00+00'),
(7, 'ABORTITA',  '2026-07-01 06:00:00+00', '2026-07-02 06:00:00+00', 'Missione annullata per malfunzionamento del drone di ricognizione.', 15, '2026-07-02 09:00:00+00');

-- ============================================================
-- 31. storico_missioni
-- ============================================================
INSERT INTO storico_missioni (id_storico, id_missione, campo_modificato, valore_precedente, valore_nuovo, motivazione, data_modifica, modificato_da) VALUES
(1, 2, 'stato', 'PLANNED',     'IN_PROGRESS', 'Avviati i lavori di manutenzione secondo programma',        '2026-09-10 06:00:00+00', 9),
(2, 4, 'stato', 'IN_PROGRESS', 'SUSPENDED',   'Sospesa a seguito della sospensione operativa della colonia Hellas', '2026-08-05 08:00:00+00', 15),
(3, 7, 'stato', 'IN_PROGRESS', 'CANCELLED',   'Annullata per malfunzionamento del drone',                  '2026-07-02 08:00:00+00', 11);

-- ============================================================
-- 32. catalogo_risorse
-- ============================================================
INSERT INTO catalogo_risorse (id_risorsa, codice, nome, id_categoria_risorsa, id_unita_misura, gestione_lotti, attivo, descrizione, data_creazione, ultima_modifica) VALUES
(1, 'OSS-001', 'Ossigeno liquido',                  2, 2, FALSE, TRUE,  'Ossigeno per respirazione e supporto vitale',        '2025-01-01 08:00:00+00', '2026-09-01 08:00:00+00'),
(2, 'ACQ-001', 'Acqua potabile',                    2, 2, FALSE, TRUE,  'Acqua potabile trattata e riciclata',                 '2025-01-01 08:00:00+00', '2026-09-01 08:00:00+00'),
(3, 'CIB-001', 'Razioni alimentari liofilizzate',   1, 1, TRUE,  TRUE,  'Razioni alimentari a lunga conservazione',            '2025-01-01 08:00:00+00', '2026-09-01 08:00:00+00'),
(4, 'PRO-001', 'Propellente ipergolico',            3, 2, FALSE, TRUE,  'Propellente per lander e veicoli di trasferimento',   '2025-01-01 08:00:00+00', '2026-09-01 08:00:00+00'),
(5, 'FAR-001', 'Kit farmaci base',                  5, 4, TRUE,  TRUE,  'Kit di farmaci essenziali per il presidio medico',    '2025-01-01 08:00:00+00', '2026-09-01 08:00:00+00'),
(6, 'RIC-001', 'Ricambi elettronici',               4, 4, FALSE, TRUE,  'Componenti di ricambio per apparati elettronici',     '2025-01-01 08:00:00+00', '2026-09-01 08:00:00+00'),
(7, 'MAT-001', 'Regolite compattata',                6, 1, FALSE, FALSE,'Materiale da costruzione, uso sospeso',               '2025-01-01 08:00:00+00', '2026-06-01 08:00:00+00');
-- TEST: risorsa 7 con attivo = FALSE (risorsa dismessa, non piu' movimentabile)

-- ============================================================
-- 33. lotti
-- ============================================================
INSERT INTO lotti (id_lotto, id_risorsa, codice_lotto, provenienza, data_scadenza, data_produzione) VALUES
(1, 3, 'LOT-CIB-2026-01', 'Terra - SpaceX Cargo 12',      '2027-06-01', '2026-01-15'),
(2, 3, 'LOT-CIB-2025-09', 'Terra - Cargo 10',              '2026-08-01', '2025-09-01'), -- TEST: lotto GIA' SCADUTO ma ancora in giacenza
(3, 5, 'LOT-FAR-2026-02', 'Terra - ESA Medical',           '2028-01-01', '2026-02-01'),
(4, 5, 'LOT-FAR-2024-05', 'Terra - ESA Medical',           '2026-05-01', '2024-05-01'), -- TEST: lotto farmaci SCADUTO
(5, 1, 'STOCK-OSS-GEN',   'Produzione locale - elettrolisi', NULL, NULL),
(6, 2, 'STOCK-ACQ-GEN',   'Produzione locale - riciclo',      NULL, NULL),
(7, 4, 'STOCK-PRO-GEN',   'Terra - Cargo 8',                   NULL, NULL),
(8, 6, 'STOCK-RIC-GEN',   'Terra - Cargo 9',                   NULL, NULL);

-- ============================================================
-- 34. soglie_risorse
-- ============================================================
INSERT INTO soglie_risorse (id_habitat, id_risorsa, soglia_minima, ultima_modifica) VALUES
(1, 1, 500,  '2026-01-01 08:00:00+00'),
(1, 2, 1000, '2026-01-01 08:00:00+00'),
(1, 3, 200,  '2026-01-01 08:00:00+00'),
(5, 1, 400,  '2026-01-01 08:00:00+00'),
(5, 2, 800,  '2026-01-01 08:00:00+00'),
(8, 2, 300,  '2026-04-01 08:00:00+00');

-- ============================================================
-- 35. giacenza_lotti
-- ============================================================
INSERT INTO giacenza_lotti (id_habitat, id_risorsa, id_lotto, quantita_disponibile, ultima_modifica) VALUES
(1, 1, 5, 450,  '2026-09-15 08:00:00+00'), -- TEST: sotto la soglia_minima (500) definita in soglie_risorse
(1, 2, 6, 1200, '2026-09-15 08:00:00+00'),
(1, 3, 1, 300,  '2026-09-15 08:00:00+00'),
(1, 3, 2, 50,   '2026-09-15 08:00:00+00'), -- TEST: giacenza residua di un lotto GIA' SCADUTO
(5, 1, 5, 600,  '2026-09-15 08:00:00+00'),
(5, 2, 6, 750,  '2026-09-15 08:00:00+00'), -- TEST: sotto la soglia_minima (800) definita in soglie_risorse
(8, 2, 6, 320,  '2026-09-10 08:00:00+00');

-- ============================================================
-- 36. sensori
-- ============================================================
INSERT INTO sensori (id_sensore, codice, id_asset, id_habitat, id_colonia, id_tipo_misurazione, id_unita_misura, soglia_min, soglia_max, attivo) VALUES
(1, 'SEN-001', 4,    2,    1, 1, 5, 95000, 105000, TRUE),
(2, 'SEN-002', 4,    2,    1, 4, 8, 30,    70,     TRUE),
(3, 'SEN-003', 3,    1,    1, 2, 6, -10,   60,     TRUE),
(4, 'SEN-004', 7,    5,    2, 2, 6, -10,   55,     TRUE),
(5, 'SEN-005', NULL, NULL, 3, 3, 7, 300,   1000,   TRUE);

-- ============================================================
-- 37. eventi_anomali
-- ============================================================
INSERT INTO eventi_anomali (id_evento, id_sensore, data_misura, valore_rilevato, soglia_violata, tipo_anomalia, descrizione, data_registrazione) VALUES
(1, 1, '2026-09-15 10:00:00+00', 106500, 105000, 'SOPRA_SOGLIA', 'Pressione anomala rilevata in Ala Residenziale A', '2026-09-15 10:01:00+00'),
(2, 3, '2026-09-14 22:30:00+00', 65,     60,     'SOPRA_SOGLIA', 'Surriscaldamento del generatore nucleare',          '2026-09-14 22:31:00+00'),
(3, 5, '2026-09-10 08:00:00+00', 1200,   1000,   'SOPRA_SOGLIA', 'Livello di CO2 elevato in area esterna a Tau',      '2026-09-10 08:01:00+00');

-- ============================================================
-- 38. alert
-- ============================================================
INSERT INTO alert (id_alert, id_evento, origine, id_colonia, titolo, severita, stato, livello_escalation, scadenza_presa_carico, data_apertura, data_chiusura, chiuso_da) VALUES
(1, 1,    'TELEMETRIA', 1, 'Anomalia di pressione - Ala Residenziale A',           'ALTA',   'APERTO',          1, '2026-09-15 12:00:00+00', '2026-09-15 10:01:00+00', NULL,                     NULL),
(2, 2,    'TELEMETRIA', 1, 'Surriscaldamento Generatore Nova-1',                    'CRITICA','PRESO_IN_CARICO',2, '2026-09-14 23:30:00+00', '2026-09-14 22:31:00+00', NULL,                     NULL),
(3, 3,    'TELEMETRIA', 3, 'CO2 elevato in zona esterna Tau',                       'MEDIA',  'CHIUSO',          0, '2026-09-10 12:00:00+00', '2026-09-10 08:01:00+00', '2026-09-11 09:00:00+00', 11),
(4, NULL, 'MAGAZZINO',  2, 'Scorta acqua sotto soglia minima - Olympus Base',       'MEDIA',  'APERTO',          0, '2026-09-17 08:00:00+00', '2026-09-15 08:00:00+00', NULL,                     NULL),
(5, NULL, 'INCIDENTE',  1, 'Alert generato da incidente di contaminazione lab.',    'ALTA',   'ESCALATO',        1, '2026-09-13 08:00:00+00', '2026-09-12 09:00:00+00', NULL,                     NULL);

-- ============================================================
-- 39. piano_manutenzione
-- ============================================================
INSERT INTO piano_manutenzione (id_piano, id_asset, titolo, descrizione, tipo_intervallo, valore_intervallo, ultima_data, prossima_data, attivo, data_creazione, ultima_modifica) VALUES
(1, 1, 'Manutenzione ordinaria Rover Pathfinder',   'Controllo periodico ruote, batterie e sistemi di guida.', 'TEMPO',    90,  '2026-07-01', '2026-09-29', TRUE, '2025-03-01 08:00:00+00', '2026-07-01 08:00:00+00'),
(2, 3, 'Ispezione Generatore Nucleare',              'Controllo periodico del reattore e degli scambiatori.',   'TEMPO',    30,  '2026-08-20', '2026-09-19', TRUE, '2025-03-01 08:00:00+00', '2026-08-20 08:00:00+00'),
(3, 7, 'Manutenzione Generatore Solare Olympus',     'Pulizia pannelli e controllo accumulatori ogni 500 ore.', 'UTILIZZO', 500, '2026-06-15', NULL,          TRUE, '2025-05-10 08:00:00+00', '2026-06-15 08:00:00+00'),
(4, 9, 'Sostituzione componenti antenna',            'Sostituzione periodica dei moduli di trasmissione.',      'TEMPO',    180, '2025-01-01', '2026-06-30', TRUE, '2025-05-10 08:00:00+00', '2025-01-01 08:00:00+00');
-- TEST: piano 4 con "prossima_data" gia' superata (manutenzione preventiva NON eseguita) -> antenna infatti OUT_OF_SERVICE

-- ============================================================
-- 40. ticket_guasto
-- ============================================================
INSERT INTO ticket_guasto (id_ticket, codice, id_asset, id_piano, sintomo, severita, stato, id_segnalatore, id_alert, aperto_il, chiuso_il, note_risoluzione) VALUES
(1, 'TCK-001', 9, 4,    'Perdita completa del segnale di comunicazione', 'CRITICA', 'APERTO',         9, NULL, '2026-09-14 12:30:00+00', NULL,                      NULL),
(2, 'TCK-002', 6, NULL, 'Rumore anomalo dal motore della ruota anteriore','MEDIA',  'IN_LAVORAZIONE', 8, NULL, '2026-09-10 09:10:00+00', NULL,                      NULL),
(3, 'TCK-003', 3, 2,    'Surriscaldamento rilevato dal sensore SEN-003', 'ALTA',   'PRESO_IN_CARICO', 2, 2,    '2026-09-14 22:40:00+00', NULL,                      NULL),
(4, 'TCK-004', 1, 1,    'Manutenzione programmata trimestrale',          'BASSA',  'CHIUSO',          3, NULL, '2026-07-01 08:00:00+00', '2026-07-05 10:00:00+00', 'Sostituiti i filtri dell aria e controllate le sospensioni.');
-- TEST: ticket 1 CRITICO ancora APERTO da piu' di un giorno -> caso utile per query di ticket urgenti non gestiti

-- ============================================================
-- 41. spedizioni
-- ============================================================
INSERT INTO spedizioni (id_spedizione, codice, origine_tipo, id_colonia_origine, id_colonia_dest, id_asset_veicolo, stato, data_partenza, data_arrivo_prevista, data_arrivo_effettiva) VALUES
(1, 'SPD-001', 'TERRA',   NULL, 1, NULL, 'RICEVUTA',   '2026-01-10 06:00:00+00', '2026-06-01 06:00:00+00', '2026-06-02 07:30:00+00'),
(2, 'SPD-002', 'COLONIA', 1,    3, 10,   'IN_TRANSITO','2026-09-14 06:00:00+00', '2026-09-16 06:00:00+00', NULL),
(3, 'SPD-003', 'TERRA',   NULL, 2, NULL, 'PIANIFICATA', NULL,                     '2026-11-01 06:00:00+00', NULL),
(4, 'SPD-004', 'COLONIA', 2,    4, NULL, 'ANNULLATA',   NULL,                     '2026-08-15 06:00:00+00', NULL);
-- TEST: spedizione 4 ANNULLATA verso la colonia sospesa Hellas

-- ============================================================
-- 42. carico_spedizione
-- ============================================================
INSERT INTO carico_spedizione (id_spedizione, id_risorsa, id_lotto, quantita_trasportata, quantita_ricevuta) VALUES
(1, 3, 1, 300, 300),
(1, 5, 3, 50,  50),
(2, 6, 8, 20,  NULL); -- TEST: spedizione ancora in transito, quantita_ricevuta non ancora nota

-- ============================================================
-- 43. tecnici_ticket
-- ============================================================
INSERT INTO tecnici_ticket (id_ticket, id_tecnico, assegnato_il, ore_lavorate) VALUES
(1, 9, '2026-09-14 12:35:00+00', 0),
(2, 8, '2026-09-10 09:15:00+00', 4.5),
(3, 2, '2026-09-14 22:45:00+00', 6.0),
(4, 3, '2026-07-01 08:10:00+00', 2.0);

-- ============================================================
-- 44. movimenti_risorse
-- ============================================================
INSERT INTO movimenti_risorse (id_movimento, id_risorsa, id_lotto, id_habitat, tipo_movimento, quantita, causale, id_trasferimento, id_spedizione, id_missione, id_ticket, data_movimento, registrato_da) VALUES
(1, 3, 1, 1, 'CARICO',  300,  'Ricezione spedizione SPD-001', NULL, 1,    NULL, NULL, '2026-06-02 08:00:00+00', 15),
(2, 3, 1, 1, 'CONSUMO', -15,  'Consumo giornaliero mensa',    NULL, NULL, NULL, NULL, '2026-09-14 20:00:00+00', 1),
(3, 1, 5, 1, 'CONSUMO', -50,  'Consumo respirazione equipaggio', NULL, NULL, NULL, NULL, '2026-09-14 20:00:00+00', 2),
(4, 4, 7, 1, 'SCARICO', -200, 'Rifornimento lander per missione MIS-006', NULL, NULL, 6, NULL, '2026-09-14 07:00:00+00', 3),
(5, 6, 8, 7, 'TRASFERIMENTO', -5, 'Ricambi utilizzati per riparazione generatore', NULL, NULL, NULL, 3, '2026-09-14 22:50:00+00', 2);

-- ============================================================
-- 45. incidenti
-- ============================================================
INSERT INTO incidenti (id_incidente, codice, id_colonia, id_missione, id_habitat, id_asset, titolo, descrizione, severita, stato, causa_radice, azioni_correttive, azioni_preventive, riportato_il, riportato_da, chiuso_il, chiuso_da, motivazione_chiusura) VALUES
(1, 'INC-001', 1, NULL, 3, NULL, 'Contaminazione batterica in serra idroponica', 'Rilevata presenza anomala di batteri nella coltura idroponica durante un controllo di routine.', 'ALTA', 'IN_GESTIONE', NULL, NULL, NULL, '2026-09-12 09:00:00+00', 6, NULL, NULL, NULL),
(2, 'INC-002', 2, 2, 7, 6, 'Incidente durante manutenzione rover',         'Piccolo incidente durante lo smontaggio della ruota anteriore del rover.',                          'MEDIA', 'CHIUSO',     'Errore nella procedura di sollevamento', 'Aggiornata la checklist di sicurezza per la manutenzione rover', 'Formazione aggiuntiva sul sollevamento in sicurezza', '2026-09-05 10:00:00+00', 8, '2026-09-08 09:00:00+00', 7, 'Risolto senza feriti, procedura aggiornata'),
(3, 'INC-003', 3, NULL, NULL, 11, 'Perdita di controllo temporanea del drone di ricognizione', 'Il drone ha perso il collegamento radio per alcuni minuti durante il volo esplorativo.', 'BASSA', 'APERTO', NULL, NULL, NULL, '2026-09-15 11:00:00+00', 11, NULL, NULL, NULL),
(4, 'INC-004', 1, 8, 2, 4, 'Guasto critico al sistema di supporto vitale',  'Guasto improvviso rilevato dai sensori ambientali, intervento di emergenza in corso.',              'CRITICA', 'APERTO', NULL, NULL, NULL, '2026-09-15 05:05:00+00', 2, NULL, NULL, NULL);
-- TEST: incidente 4 CRITICO ancora APERTO, collegato alla missione di emergenza MIS-008

-- ============================================================
-- 46. persone_incidente
-- ============================================================
INSERT INTO persone_incidente (id_incidente, id_astronauta, ruolo_nell_evento) VALUES
(1, 6,  'COINVOLTO'),
(1, 16, 'PRIMO_INTERVENTO'),
(2, 8,  'COINVOLTO'),
(2, 9,  'TESTIMONE'),
(4, 2,  'PRIMO_INTERVENTO'),
(4, 4,  'COINVOLTO');

-- ============================================================
-- 47. timeline_incidente
-- ============================================================
INSERT INTO timeline_incidente (id_evento, id_incidente, tipo_evento, descrizione, data_evento, registrato_da) VALUES
(1, 1, 'SEGNALAZIONE',   'Rilevata contaminazione durante un controllo di routine in serra.', '2026-09-12 09:00:00+00', 6),
(2, 1, 'PRESA_IN_CARICO','Il team scientifico ha preso in carico l''indagine.',                '2026-09-12 10:30:00+00', 6),
(3, 2, 'SEGNALAZIONE',   'Segnalato incidente durante la manutenzione del rover.',             '2026-09-05 10:00:00+00', 8),
(4, 2, 'CHIUSURA',       'Incidente chiuso dopo revisione della procedura di sicurezza.',      '2026-09-08 09:00:00+00', 7),
(5, 4, 'SEGNALAZIONE',   'Guasto critico rilevato dai sensori ambientali.',                     '2026-09-15 05:05:00+00', 2),
(6, 4, 'ESCALATION',     'Escalation immediata al comando colonia per gravita dell evento.',   '2026-09-15 05:07:00+00', 2);

-- ============================================================
-- 48. laboratori
-- ============================================================
INSERT INTO laboratori (id_laboratorio, id_habitat, nome, specializzazione, data_creazione, ultima_modifica) VALUES
(1, 4, 'Laboratorio Biologia Nova-1',   'BIOLOGIA', '2025-03-15 08:00:00+00', '2026-09-01 08:00:00+00'),
(2, 4, 'Laboratorio Geologia Nova-1',   'GEOLOGIA', '2025-03-15 08:00:00+00', '2026-09-01 08:00:00+00'),
(3, 7, 'Laboratorio Chimico Olympus',   'CHIMICA',  '2025-05-20 08:00:00+00', '2026-09-01 08:00:00+00');

-- ============================================================
-- 49. esperimenti
-- ============================================================
INSERT INTO esperimenti (id_esperimento, codice, id_laboratorio, id_responsabile, titolo, descrizione, protocollo, stato, data_creazione, ultima_modifica) VALUES
(1, 'EXP-001', 1, 16, 'Crescita batterica in gravita marziana',   'Studio della crescita di colture batteriche in condizioni di bassa gravita.', 'Protocollo standard ESA-BIO-04', 'IN_CORSO',   '2026-08-01 08:00:00+00', '2026-09-15 08:00:00+00'),
(2, 'EXP-002', 2, 15, 'Analisi composizione regolite',            'Analisi chimica e mineralogica dei campioni raccolti nel Cratere Gale.',       'Protocollo standard ESA-GEO-02', 'CONCLUSO',   '2026-06-01 08:00:00+00', '2026-06-20 08:00:00+00'),
(3, 'EXP-003', 3, 10, 'Sintesi di composti per la depurazione idrica','Sperimentazione di nuovi filtri chimici per la depurazione dell acqua.',    'Protocollo interno CHM-09',       'SOSPESO',    '2026-05-01 08:00:00+00', '2026-08-01 08:00:00+00'),
(4, 'EXP-004', 1, 6,  'Coltivazione idroponica avanzata',         'Ottimizzazione dei cicli di coltivazione per aumentare la resa alimentare.',   'Protocollo standard ESA-AGR-01', 'PIANIFICATO','2026-09-10 08:00:00+00', '2026-09-10 08:00:00+00');
-- TEST: esperimento 3 SOSPESO con responsabile (astronauta 10) gia' RIENTRATO sulla Terra

-- ============================================================
-- 50. attrezzature_esperimento
-- ============================================================
INSERT INTO attrezzature_esperimento (id_esperimento, id_asset, note) VALUES
(1, 13, 'Spettrometro utilizzato per l''analisi dei campioni biologici'),
(2, 13, 'Strumento condiviso con il laboratorio di geologia');

-- ============================================================
-- 51. campioni
-- ============================================================
INSERT INTO campioni (id_campione, codice, tipo, descrizione_origine, id_missione_raccolta, collezionato_il, id_laboratorio_corrente, stato, data_creazione, ultima_modifica) VALUES
(1, 'CAM-001', 'Roccia',             'Cratere Gale',              1,    '2026-06-05 10:00:00+00', 2, 'IN_ARCHIVIO', '2026-06-05 12:00:00+00', '2026-06-20 08:00:00+00'),
(2, 'CAM-002', 'Roccia sedimentaria','Cratere Gale',              1,    '2026-06-06 10:00:00+00', 2, 'IN_ANALISI',  '2026-06-06 12:00:00+00', '2026-06-06 12:00:00+00'),
(3, 'CAM-003', 'Coltura batterica',  'Serra Idroponica Nova-1',   NULL, '2026-08-20 09:00:00+00', 1, 'IN_ANALISI',  '2026-08-20 09:30:00+00', '2026-09-12 09:00:00+00'),
(4, 'CAM-004', 'Campione atmosferico','Tau Outpost',              NULL, '2026-07-15 08:00:00+00', 3, 'SMALTITO',    '2026-07-15 08:30:00+00', '2026-08-01 08:00:00+00');

-- ============================================================
-- 52. trasferimenti_campione
-- ============================================================
INSERT INTO trasferimenti_campione (id_trasferimento, id_campione, id_lab_partenza, id_lab_destinazione, trasferito_il, trasferito_da, id_asset_veicolo) VALUES
(1, 1, NULL, 2, '2026-06-05 12:00:00+00', 1,  1),
(2, 2, NULL, 2, '2026-06-06 12:00:00+00', 3,  1),
(3, 3, NULL, 1, '2026-08-20 09:30:00+00', 6,  NULL),
(4, 2, 2,    1, '2026-06-15 10:00:00+00', 15, NULL);

-- ============================================================
-- 53. campioni_esperimenti
-- ============================================================
INSERT INTO campioni_esperimenti (id_campione, id_esperimento, associato_il) VALUES
(1, 2, '2026-06-05 13:00:00+00'),
(2, 2, '2026-06-06 13:00:00+00'),
(3, 1, '2026-08-20 10:00:00+00'),
(3, 4, '2026-09-10 09:00:00+00');

-- ============================================================
-- 54. risultati_esperimento
-- ============================================================
INSERT INTO risultati_esperimento (id_risultato, id_esperimento, descrizione, metadati, uri_allegato, stato_validazione, validato_da, data_creazione, ultima_modifica) VALUES
(1, 2, 'Composizione ricca in ossidi di ferro, coerente con formazioni sedimentarie.', '{"fe2o3_pct": 18.2, "sio2_pct": 45.6}', 'aether://labs/geo/exp002/report1.pdf', 'VALIDATO',    15,   '2026-06-18 08:00:00+00', '2026-06-20 08:00:00+00'),
(2, 1, 'Crescita rilevata ma inferiore alle attese nelle prime due settimane.',        '{"colonie_batteriche": 42}',            NULL,                                    'IN_REVISIONE',NULL, '2026-09-10 08:00:00+00', '2026-09-10 08:00:00+00'),
(3, 1, 'Bozza preliminare dei risultati della prima settimana di osservazione.',        NULL,                                    NULL,                                    'BOZZA',       NULL, '2026-09-05 08:00:00+00', '2026-09-05 08:00:00+00');

-- ============================================================
-- 55. misurazioni
-- ============================================================
INSERT INTO misurazioni (id_sensore, data_registrazione, valore, qualita) VALUES
(1, '2026-09-15 10:00:00+00', 106500, 'SOSPETTA'),
(1, '2026-09-15 11:00:00+00', 99000,  'VALIDA'),
(2, '2026-09-15 09:00:00+00', 55,     'VALIDA'),
(3, '2026-09-14 22:30:00+00', 65,     'SOSPETTA'),
(3, '2026-09-15 00:00:00+00', 45,     'VALIDA'),
(4, '2026-09-15 08:00:00+00', 40,     'VALIDA'),
(5, '2026-09-10 08:00:00+00', 1200,   'SOSPETTA');

-- ============================================================
-- 56. destinatari_alert
-- ============================================================
INSERT INTO destinatari_alert (id_alert, id_utente, notificato_il, visionato_il) VALUES
(1, 1, '2026-09-15 10:02:00+00', NULL),
(1, 2, '2026-09-15 10:02:00+00', '2026-09-15 10:15:00+00'),
(2, 9, '2026-09-14 22:32:00+00', '2026-09-14 22:40:00+00'),
(2, 7, '2026-09-14 22:32:00+00', NULL),
(4, 8, '2026-09-15 08:01:00+00', NULL),
(5, 6, '2026-09-12 09:01:00+00', NULL);

-- ============================================================
-- 57. notifiche
-- ============================================================
INSERT INTO notifiche (id_notifica, id_utente, tipo_oggetto, id_oggetto, testo, data_invio, letta_il) VALUES
(1, 2,  'MISSIONE', 2, 'La missione MIS-002 e stata aggiornata: task "Sostituzione batteria" in corso.', '2026-09-12 08:00:00+00', '2026-09-12 09:00:00+00'),
(2, 2,  'ALERT',    2, 'Nuovo alert critico: Surriscaldamento Generatore Nova-1.',                        '2026-09-14 22:32:00+00', '2026-09-14 22:40:00+00'),
(3, 9,  'TICKET',   1, 'Il ticket TCK-001 richiede attenzione urgente.',                                  '2026-09-14 12:35:00+00', NULL),
(4, 15, 'SISTEMA',  NULL, 'Backup di sistema completato con successo.',                                   '2026-09-16 03:00:00+00', '2026-09-16 07:00:00+00');

-- ============================================================
-- 58. audit_log
-- ============================================================
INSERT INTO audit_log (id_audit, id_utente, entita, id_entita, azione, valore_precedente, valore_nuovo, motivazione, indirizzo_ip, data_azione) VALUES
(1, 15, 'missioni',     '2',  'UPDATE', '{"stato":"PLANNED"}',        '{"stato":"IN_PROGRESS"}', 'Avvio lavori di manutenzione programmati',       '10.0.0.2', '2026-09-10 06:05:00+00'),
(2, 1,  'astronauti',   '5',  'UPDATE', '{"stato_servizio":"IN_SERVIZIO"}', '{"stato_servizio":"IN_TRANSITO"}', 'Trasferimento verso Nova Ares', '10.0.1.5', '2026-09-01 07:00:00+00'),
(3, 15, 'utenti',       '10', 'UPDATE', '{"stato":"ATTIVO"}',         '{"stato":"SOSPESO"}',     'Sospensione account per assenza prolungata',      '10.0.0.2', '2026-08-01 08:05:00+00'),
(4, 9,  'asset_tecnici','9',  'UPDATE', '{"stato":"OPERATIVO"}',      '{"stato":"OUT_OF_SERVICE"}','Guasto totale rilevato sull antenna',           '10.0.2.9', '2026-09-14 12:00:00+00'),
(5, 15, 'ruoli_utenti', '1',  'CREATE', NULL,                          '{"id_utente":15,"id_ruolo":1}', 'Assegnazione ruolo iniziale amministratore', '10.0.0.2', '2025-01-01 08:10:00+00'),
(6, 1,  'utenti',       '1',  'LOGIN',  NULL,                          NULL,                       NULL,                                              '10.0.1.5', '2026-09-15 07:00:00+00');

COMMIT;

-- ============================================================
-- Allineamento delle sequenze (SERIAL/BIGSERIAL) ai valori
-- esplicitamente inseriti sopra, per evitare collisioni di
-- chiave primaria nei successivi INSERT applicativi.
-- ============================================================
SELECT setval(pg_get_serial_sequence('tipi_asset','id_tipo_asset'),                 (SELECT COALESCE(MAX(id_tipo_asset),1)                 FROM tipi_asset));
SELECT setval(pg_get_serial_sequence('categorie_risorsa','id_categoria_risorsa'),   (SELECT COALESCE(MAX(id_categoria_risorsa),1)           FROM categorie_risorsa));
SELECT setval(pg_get_serial_sequence('unita_misura','id_unita_misura'),             (SELECT COALESCE(MAX(id_unita_misura),1)                FROM unita_misura));
SELECT setval(pg_get_serial_sequence('tipi_misurazione','id_tipo_misurazione'),     (SELECT COALESCE(MAX(id_tipo_misurazione),1)            FROM tipi_misurazione));
SELECT setval(pg_get_serial_sequence('colonie','id_colonia'),                       (SELECT COALESCE(MAX(id_colonia),1)                     FROM colonie));
SELECT setval(pg_get_serial_sequence('astronauti','id_astronauta'),                 (SELECT COALESCE(MAX(id_astronauta),1)                  FROM astronauti));
SELECT setval(pg_get_serial_sequence('utenti','id_user'),                           (SELECT COALESCE(MAX(id_user),1)                        FROM utenti));
SELECT setval(pg_get_serial_sequence('ruoli','id_ruolo'),                           (SELECT COALESCE(MAX(id_ruolo),1)                       FROM ruoli));
SELECT setval(pg_get_serial_sequence('accessi_falliti','id_tentativo'),             (SELECT COALESCE(MAX(id_tentativo),1)                   FROM accessi_falliti));
SELECT setval(pg_get_serial_sequence('permessi','id_permesso'),                     (SELECT COALESCE(MAX(id_permesso),1)                    FROM permessi));
SELECT setval(pg_get_serial_sequence('sessioni','id_sessione'),                     (SELECT COALESCE(MAX(id_sessione),1)                    FROM sessioni));
SELECT setval(pg_get_serial_sequence('habitat','id_habitat'),                       (SELECT COALESCE(MAX(id_habitat),1)                     FROM habitat));
SELECT setval(pg_get_serial_sequence('asset_tecnici','id_asset'),                   (SELECT COALESCE(MAX(id_asset),1)                       FROM asset_tecnici));
SELECT setval(pg_get_serial_sequence('storico_asset','id_storico'),                 (SELECT COALESCE(MAX(id_storico),1)                     FROM storico_asset));
SELECT setval(pg_get_serial_sequence('competenze','id_competenza'),                 (SELECT COALESCE(MAX(id_competenza),1)                  FROM competenze));
SELECT setval(pg_get_serial_sequence('certificazioni','id_certificazione'),         (SELECT COALESCE(MAX(id_certificazione),1)              FROM certificazioni));
SELECT setval(pg_get_serial_sequence('indisponibilita','id_indisponibilita'),       (SELECT COALESCE(MAX(id_indisponibilita),1)             FROM indisponibilita));
SELECT setval(pg_get_serial_sequence('tipologie_missione','id_tipologia'),          (SELECT COALESCE(MAX(id_tipologia),1)                   FROM tipologie_missione));
SELECT setval(pg_get_serial_sequence('missioni','id_missione'),                     (SELECT COALESCE(MAX(id_missione),1)                    FROM missioni));
SELECT setval(pg_get_serial_sequence('task_missione','id_task'),                    (SELECT COALESCE(MAX(id_task),1)                        FROM task_missione));
SELECT setval(pg_get_serial_sequence('requisiti_missione','id_requisito'),          (SELECT COALESCE(MAX(id_requisito),1)                   FROM requisiti_missione));
SELECT setval(pg_get_serial_sequence('storico_missioni','id_storico'),              (SELECT COALESCE(MAX(id_storico),1)                     FROM storico_missioni));
SELECT setval(pg_get_serial_sequence('catalogo_risorse','id_risorsa'),              (SELECT COALESCE(MAX(id_risorsa),1)                     FROM catalogo_risorse));
SELECT setval(pg_get_serial_sequence('lotti','id_lotto'),                           (SELECT COALESCE(MAX(id_lotto),1)                       FROM lotti));
SELECT setval(pg_get_serial_sequence('sensori','id_sensore'),                       (SELECT COALESCE(MAX(id_sensore),1)                     FROM sensori));
SELECT setval(pg_get_serial_sequence('eventi_anomali','id_evento'),                 (SELECT COALESCE(MAX(id_evento),1)                      FROM eventi_anomali));
SELECT setval(pg_get_serial_sequence('alert','id_alert'),                           (SELECT COALESCE(MAX(id_alert),1)                       FROM alert));
SELECT setval(pg_get_serial_sequence('piano_manutenzione','id_piano'),              (SELECT COALESCE(MAX(id_piano),1)                       FROM piano_manutenzione));
SELECT setval(pg_get_serial_sequence('ticket_guasto','id_ticket'),                  (SELECT COALESCE(MAX(id_ticket),1)                      FROM ticket_guasto));
SELECT setval(pg_get_serial_sequence('spedizioni','id_spedizione'),                 (SELECT COALESCE(MAX(id_spedizione),1)                  FROM spedizioni));
SELECT setval(pg_get_serial_sequence('movimenti_risorse','id_movimento'),           (SELECT COALESCE(MAX(id_movimento),1)                   FROM movimenti_risorse));
SELECT setval(pg_get_serial_sequence('incidenti','id_incidente'),                   (SELECT COALESCE(MAX(id_incidente),1)                   FROM incidenti));
SELECT setval(pg_get_serial_sequence('timeline_incidente','id_evento'),             (SELECT COALESCE(MAX(id_evento),1)                      FROM timeline_incidente));
SELECT setval(pg_get_serial_sequence('laboratori','id_laboratorio'),                (SELECT COALESCE(MAX(id_laboratorio),1)                 FROM laboratori));
SELECT setval(pg_get_serial_sequence('esperimenti','id_esperimento'),               (SELECT COALESCE(MAX(id_esperimento),1)                 FROM esperimenti));
SELECT setval(pg_get_serial_sequence('campioni','id_campione'),                     (SELECT COALESCE(MAX(id_campione),1)                    FROM campioni));
SELECT setval(pg_get_serial_sequence('trasferimenti_campione','id_trasferimento'),  (SELECT COALESCE(MAX(id_trasferimento),1)               FROM trasferimenti_campione));
SELECT setval(pg_get_serial_sequence('risultati_esperimento','id_risultato'),       (SELECT COALESCE(MAX(id_risultato),1)                   FROM risultati_esperimento));
SELECT setval(pg_get_serial_sequence('notifiche','id_notifica'),                    (SELECT COALESCE(MAX(id_notifica),1)                    FROM notifiche));
SELECT setval(pg_get_serial_sequence('audit_log','id_audit'),                       (SELECT COALESCE(MAX(id_audit),1)                       FROM audit_log));
