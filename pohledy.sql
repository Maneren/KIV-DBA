-- zobrazení papírů všech her
CREATE OR REPLACE VIEW papir AS
WITH r AS (
  SELECT LEVEL AS cislo_radku
  FROM dual
  CONNECT BY LEVEL <= (SELECT max(vyska_papiru) FROM hra)
)

SELECT
  h.id_hry,
  r.cislo_radku,
  radek_papiru(h.id_hry, r.cislo_radku) AS radek
FROM hra h
CROSS JOIN r
WHERE r.cislo_radku <= h.vyska_papiru
ORDER BY h.id_hry, r.cislo_radku;
