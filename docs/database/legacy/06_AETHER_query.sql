-- ============================================================
-- AETHER - Mars Operations Platform
-- Query di esempio, da provare dopo aver caricato
-- 04_AETHER_schema.sql e 05_AETHER_seed.sql
--
-- Sono raggruppate per tipo (come richiesto dal capitolato, punto 8.3):
-- filtri/ordinamenti, JOIN, aggregazioni, subquery/EXISTS,
-- query di anomalia, transazioni di esempio.
-- ============================================================


-- ------------------------------------------------------------
-- 1. RICERCA CON FILTRI E ORDINAMENTO
-- ------------------------------------------------------------

-- 1.1 Astronauti in servizio nella colonia Ares Prime, in ordine alfabetico
SELECT a.matricola, a.nome, a.cognome, a.mansione, a.stato_servizio
FROM astronauti a
JOIN colonie c ON c.id_colonia = a.id_colonia
WHERE c.codice = 'ARES-1'
  AND a.stato_servizio = 'IN_SERVIZIO'
ORDER BY a.cognome, a.nome;

-- 1.2 Asset filtrati per colonia, stato e criticita' (come richiesto da COL-007)
SELECT ast.codice, ast.nome, t.nome AS tipo, ast.stato, ast.criticita
FROM asset_tecnici ast
JOIN tipi_asset t ON t.id_tipo_asset = ast.id_tipo_asset
JOIN colonie c ON c.id_colonia = ast.id_colonia
WHERE c.codice = 'ELY-1'
  AND ast.criticita IN ('ALTA', 'VITALE')
ORDER BY ast.stato, ast.nome;


-- ------------------------------------------------------------
-- 2. JOIN FRA PIU' TABELLE (comprese le relazioni N:N)
-- ------------------------------------------------------------

-- 2.1 Elenco missioni con nome colonia e tipologia (JOIN semplice x2)
SELECT m.codice, m.obiettivo, c.nome AS colonia, tm.nome AS tipologia, m.stato, m.priorita
FROM missioni m
JOIN colonie c ON c.id_colonia = m.id_colonia
JOIN tipologie_missione tm ON tm.id_tipologia = m.id_tipologia
ORDER BY m.data_inizio_prevista;

-- 2.2 Equipaggio di ogni missione, con nome/cognome e ruolo (JOIN su tabella ponte N:N)
SELECT m.codice AS missione, a.nome, a.cognome, em.ruolo
FROM equipaggio_missione em
JOIN missioni m ON m.id_missione = em.id_missione
JOIN astronauti a ON a.id_astronauta = em.id_astronauta
ORDER BY m.codice, em.ruolo;

-- 2.3 Dettaglio di un ticket: asset, colonia dell'asset, chi lo ha segnalato, tecnici assegnati
SELECT tk.codice AS ticket, ast.nome AS asset, col.nome AS colonia,
       u.username AS segnalato_da, a.nome || ' ' || a.cognome AS tecnico
FROM ticket_guasto tk
JOIN asset_tecnici ast ON ast.id_asset = tk.id_asset
JOIN colonie col ON col.id_colonia = ast.id_colonia
JOIN utenti u ON u.id_user = tk.id_segnalatore
LEFT JOIN tecnici_ticket tt ON tt.id_ticket = tk.id_ticket
LEFT JOIN astronauti a ON a.id_astronauta = tt.id_tecnico
ORDER BY tk.codice;
-- nota: LEFT JOIN perche' un ticket appena aperto puo' non avere ancora un tecnico assegnato


-- ------------------------------------------------------------
-- 3. AGGREGAZIONI (GROUP BY / HAVING)
-- ------------------------------------------------------------

-- 3.1 Numero di missioni per colonia e per stato
SELECT c.nome AS colonia, m.stato, COUNT(*) AS numero_missioni
FROM missioni m
JOIN colonie c ON c.id_colonia = m.id_colonia
GROUP BY c.nome, m.stato
ORDER BY c.nome, m.stato;

-- 3.2 Consumo totale di ogni risorsa, per colonia (JOIN + aggregazione su piu' domini)
SELECT col.nome AS colonia, cr.nome AS risorsa, SUM(-mr.quantita) AS totale_consumato
FROM movimenti_risorse mr
JOIN catalogo_risorse cr ON cr.id_risorsa = mr.id_risorsa
JOIN habitat h ON h.id_habitat = mr.id_habitat
JOIN colonie col ON col.id_colonia = h.id_colonia
WHERE mr.tipo_movimento IN ('SCARICO', 'CONSUMO')
GROUP BY col.nome, cr.nome
ORDER BY col.nome, totale_consumato DESC;

-- 3.3 Colonie con piu' di un incidente ancora aperto (GROUP BY + HAVING)
SELECT col.nome AS colonia, COUNT(*) AS incidenti_aperti
FROM incidenti i
JOIN colonie col ON col.id_colonia = i.id_colonia
WHERE i.stato <> 'CHIUSO'
GROUP BY col.nome
HAVING COUNT(*) >= 1
ORDER BY incidenti_aperti DESC;

-- 3.4 Per ogni astronauta, quante competenze possiede a livello alto (>= 4)
SELECT a.nome, a.cognome, COUNT(*) AS competenze_avanzate
FROM competenze_astronauti ca
JOIN astronauti a ON a.id_astronauta = ca.id_astronauta
WHERE ca.livello >= 4
GROUP BY a.nome, a.cognome
HAVING COUNT(*) >= 1
ORDER BY competenze_avanzate DESC;


-- ------------------------------------------------------------
-- 4. SUBQUERY / EXISTS / NOT EXISTS
-- ------------------------------------------------------------

-- 4.1 Astronauti senza nessuna certificazione registrata (NOT EXISTS)
SELECT a.matricola, a.nome, a.cognome
FROM astronauti a
WHERE NOT EXISTS (
    SELECT 1 FROM certificazioni_astronauti ca WHERE ca.id_astronauta = a.id_astronauta
);

-- 4.2 Missioni senza equipaggio ancora assegnato (NOT EXISTS)
SELECT m.codice, m.obiettivo, m.stato
FROM missioni m
WHERE NOT EXISTS (
    SELECT 1 FROM equipaggio_missione em WHERE em.id_missione = m.id_missione
);

-- 4.3 Astronauti disponibili in un certo intervallo (senza indisponibilita' ne' missioni sovrapposte)
-- corrisponde allo scenario di test 9 del capitolato
SELECT a.matricola, a.nome, a.cognome
FROM astronauti a
WHERE a.stato_servizio = 'IN_SERVIZIO'
  AND NOT EXISTS (
      SELECT 1 FROM indisponibilita ind
      WHERE ind.id_astronauta = a.id_astronauta
        AND (ind.data_inizio, ind.data_fine) OVERLAPS (TIMESTAMPTZ '2026-10-01', TIMESTAMPTZ '2026-10-03')
  )
  AND NOT EXISTS (
      SELECT 1
      FROM equipaggio_missione em
      JOIN missioni m2 ON m2.id_missione = em.id_missione
      WHERE em.id_astronauta = a.id_astronauta
        AND m2.stato IN ('APPROVED', 'IN_PROGRESS')
        AND (m2.data_inizio_prevista, m2.data_fine_prevista) OVERLAPS (TIMESTAMPTZ '2026-10-01', TIMESTAMPTZ '2026-10-03')
  );


-- ------------------------------------------------------------
-- 5. QUERY DI ANOMALIA (richieste esplicitamente dal punto 8.3)
-- ------------------------------------------------------------

-- 5.1 Risorse sotto la soglia minima, per habitat
SELECT h.nome AS habitat, cr.nome AS risorsa,
       COALESCE(SUM(gl.quantita_disponibile), 0) AS quantita_totale,
       sr.soglia_minima
FROM soglie_risorse sr
JOIN habitat h ON h.id_habitat = sr.id_habitat
JOIN catalogo_risorse cr ON cr.id_risorsa = sr.id_risorsa
LEFT JOIN giacenza_lotti gl ON gl.id_habitat = sr.id_habitat AND gl.id_risorsa = sr.id_risorsa
GROUP BY h.nome, cr.nome, sr.soglia_minima
HAVING COALESCE(SUM(gl.quantita_disponibile), 0) < sr.soglia_minima
ORDER BY h.nome;

-- 5.2 Certificazioni in scadenza nei prossimi 30 giorni
SELECT a.nome, a.cognome, c.nome_certificazione, ca.data_scadenza
FROM certificazioni_astronauti ca
JOIN astronauti a ON a.id_astronauta = ca.id_astronauta
JOIN certificazioni c ON c.id_certificazione = ca.id_certificazione
WHERE ca.data_scadenza IS NOT NULL
  AND ca.data_scadenza BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '30 days'
ORDER BY ca.data_scadenza;

-- 5.3 Asset con piu' di 1 ticket registrato (candidati a "troppi guasti")
SELECT ast.codice, ast.nome, COUNT(*) AS numero_ticket
FROM ticket_guasto tk
JOIN asset_tecnici ast ON ast.id_asset = tk.id_asset
GROUP BY ast.codice, ast.nome
HAVING COUNT(*) > 1
ORDER BY numero_ticket DESC;

-- 5.4 Missioni la cui competenza richiesta non e' coperta da nessun membro dell'equipaggio assegnato
SELECT m.codice, m.obiettivo, comp.nome AS competenza_mancante, rm.livello_minimo
FROM requisiti_missione rm
JOIN missioni m ON m.id_missione = rm.id_missione
JOIN competenze comp ON comp.id_competenza = rm.id_competenza
WHERE rm.id_competenza IS NOT NULL
  AND NOT EXISTS (
      SELECT 1
      FROM equipaggio_missione em
      JOIN competenze_astronauti ca ON ca.id_astronauta = em.id_astronauta
      WHERE em.id_missione = m.id_missione
        AND ca.id_competenza = rm.id_competenza
        AND ca.livello >= COALESCE(rm.livello_minimo, 1)
  );


-- ------------------------------------------------------------
-- 6. REPORT E CONFRONTI (scenario di test 8 del capitolato)
-- ------------------------------------------------------------

-- 6.1 Confronto fra colonie: consumi totali e incidenti nell'ultimo mese
SELECT col.nome AS colonia,
       COALESCE(consumi.totale, 0) AS consumo_totale,
       COALESCE(inc.numero, 0)     AS incidenti_ultimo_mese
FROM colonie col
LEFT JOIN (
    SELECT h.id_colonia, SUM(-mr.quantita) AS totale
    FROM movimenti_risorse mr
    JOIN habitat h ON h.id_habitat = mr.id_habitat
    WHERE mr.tipo_movimento IN ('SCARICO', 'CONSUMO')
      AND mr.data_movimento >= now() - INTERVAL '30 days'
    GROUP BY h.id_colonia
) consumi ON consumi.id_colonia = col.id_colonia
LEFT JOIN (
    SELECT id_colonia, COUNT(*) AS numero
    FROM incidenti
    WHERE riportato_il >= now() - INTERVAL '30 days'
    GROUP BY id_colonia
) inc ON inc.id_colonia = col.id_colonia
ORDER BY col.nome;

-- 6.2 Audit: ricostruire chi ha modificato cosa e quando (scenario di test 10)
SELECT al.data_azione, u.username, al.entita, al.id_entita, al.azione, al.motivazione
FROM audit_log al
JOIN utenti u ON u.id_user = al.id_utente
ORDER BY al.data_azione DESC;


-- ============================================================
-- 7. TRANSAZIONI DI ESEMPIO (operazioni multi-step "tutto o niente")
-- ============================================================

-- 7.1 Ricezione di una spedizione: aggiorna la giacenza e registra il movimento
--     insieme, cosi' se una delle due cose fallisce non resta nulla a meta'.
BEGIN;

    UPDATE giacenza_lotti
    SET quantita_disponibile = quantita_disponibile + 100,
        ultima_modifica = now()
    WHERE id_habitat = 4 AND id_risorsa = 3 AND id_lotto = 1;

    INSERT INTO movimenti_risorse
        (id_risorsa, id_lotto, id_habitat, tipo_movimento, quantita, causale, id_spedizione, registrato_da)
    VALUES
        (3, 1, 4, 'CARICO', 100, 'Ricezione rifornimento aggiuntivo', 1, 5);

COMMIT;

-- 7.2 Scarico di magazzino con controllo del saldo prima di procedere
--     (il CHECK quantita_disponibile >= 0 nello schema blocca comunque
--     il saldo negativo anche se qui dimenticassimo il controllo)
BEGIN;

    -- prima si controlla che ci sia abbastanza giacenza...
    -- SELECT quantita_disponibile FROM giacenza_lotti WHERE id_habitat=1 AND id_risorsa=1 AND id_lotto=4 FOR UPDATE;

    UPDATE giacenza_lotti
    SET quantita_disponibile = quantita_disponibile - 30,
        ultima_modifica = now()
    WHERE id_habitat = 1 AND id_risorsa = 1 AND id_lotto = 4;

    INSERT INTO movimenti_risorse
        (id_risorsa, id_lotto, id_habitat, tipo_movimento, quantita, causale, id_missione, registrato_da)
    VALUES
        (1, 4, 1, 'CONSUMO', -30, 'Consumo acqua per missione MIS-005', 5, 1);

COMMIT;
