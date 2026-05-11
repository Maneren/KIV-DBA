-- zobrazení papírů všech her
CREATE OR REPLACE VIEW papir AS
SELECT
  h.id_hry,
  r.cislo_radku,
  radek_papiru(h.id_hry, r.cislo_radku) AS radek
FROM hra h
CROSS APPLY (
  SELECT LEVEL AS cislo_radku
  FROM dual
  CONNECT BY LEVEL <= h.vyska_papiru
) r
ORDER BY h.id_hry, r.cislo_radku;

-- zobrazení her, které skončily výhrou začínajícího hráče
CREATE OR REPLACE VIEW vyhry_zacinajici AS
WITH hra_data AS (
  SELECT
    h.id_hry,
    h.sirka_papiru,
    h.vyska_papiru,
    h.delka_vitezne_rady,
    hz.jmeno AS jmeno_zacin_hrace,
    hd.jmeno AS jmeno_druheho_hrace,
    hz.jmeno AS jmeno_hrace_ktery_zacikal,
    h.zacin_hrac_znak AS znak_zacin_hrace,
    h.druhy_hrac_znak AS znak_druheho_hrace,
    h.cas_zacin_hrace,
    h.cas_druheho_hrace
  FROM hra h
  INNER JOIN hrac hz ON h.id_zacin_hrace = hz.id_hrace
  INNER JOIN hrac hd ON h.id_druheho_hrace = hd.id_hrace
  INNER JOIN stav s ON h.id_stavu = s.id_stavu
  WHERE s.nazev = 'vítězství'
),
pocty_tahu AS (
  SELECT
    id_hry,
    count(*) AS pocet_tahu
  FROM tah
  GROUP BY id_hry
)
SELECT
  hd.id_hry,
  hd.sirka_papiru,
  hd.vyska_papiru,
  hd.delka_vitezne_rady,
  hd.jmeno_zacin_hrace,
  hd.jmeno_druheho_hrace,
  hd.jmeno_hrace_ktery_zacikal,
  hd.znak_zacin_hrace,
  hd.znak_druheho_hrace,
  pt.pocet_tahu,
  (hd.cas_zacin_hrace + hd.cas_druheho_hrace) AS celkovy_cas_hry
FROM hra_data hd
INNER JOIN pocty_tahu pt ON hd.id_hry = pt.id_hry;

-- zobrazení her, které skončily remízou
CREATE OR REPLACE VIEW remizy AS
SELECT
  h.id_hry,
  h.sirka_papiru,
  h.vyska_papiru,
  h.delka_vitezne_rady,
  hz.jmeno AS jmeno_zacin_hrace,
  hd.jmeno AS jmeno_druheho_hrace,
  hz.jmeno AS jmeno_hrace_ktery_zacikal,
  h.zacin_hrac_znak AS znak_zacin_hrace,
  h.druhy_hrac_znak AS znak_druheho_hrace,
  (h.cas_zacin_hrace + h.cas_druheho_hrace) AS celkovy_cas_hry,
  (
    SELECT count(*) FROM tah t
    WHERE t.id_hry = h.id_hry
  ) AS pocet_tahu
FROM hra h
INNER JOIN hrac hz ON h.id_zacin_hrace = hz.id_hrace
INNER JOIN hrac hd ON h.id_druheho_hrace = hd.id_hrace
INNER JOIN stav s ON h.id_stavu = s.id_stavu
WHERE s.nazev = 'remíza';

-- zobrazení her, které skončily prohrou začínajícího hráče
CREATE OR REPLACE VIEW prohry_zacinajici AS
SELECT
  h.id_hry,
  h.sirka_papiru,
  h.vyska_papiru,
  h.delka_vitezne_rady,
  hz.jmeno AS jmeno_zacin_hrace,
  hd.jmeno AS jmeno_druheho_hrace,
  hz.jmeno AS jmeno_hrace_ktery_zacikal,
  h.zacin_hrac_znak AS znak_zacin_hrace,
  h.druhy_hrac_znak AS znak_druheho_hrace,
  (h.cas_zacin_hrace + h.cas_druheho_hrace) AS celkovy_cas_hry,
  (
    SELECT count(*) FROM tah t
    WHERE t.id_hry = h.id_hry
  ) AS pocet_tahu
FROM hra h
INNER JOIN hrac hz ON h.id_zacin_hrace = hz.id_hrace
INNER JOIN hrac hd ON h.id_druheho_hrace = hd.id_hrace
INNER JOIN stav s ON h.id_stavu = s.id_stavu
WHERE s.nazev = 'prohra';
