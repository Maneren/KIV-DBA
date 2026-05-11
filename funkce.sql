-- Funkce pro zobrazení řádku papíru
CREATE OR REPLACE FUNCTION radek_papiru(
  p_id_hry NUMBER,
  p_cislo_radku NUMBER
) RETURN VARCHAR2
IS
  v_radek VARCHAR2(1000) := '';
  v_sirka NUMBER;
  v_znak CHAR(1);
  v_zacin_znak CHAR(1);
  v_druhy_znak CHAR(1);
BEGIN
  SELECT
    sirka_papiru,
    zacin_hrac_znak,
    druhy_hrac_znak
  INTO v_sirka, v_zacin_znak, v_druhy_znak
  FROM hra
  WHERE id_hry = p_id_hry;

  FOR x IN 1..v_sirka LOOP
    BEGIN
      SELECT
        CASE
          WHEN t.id_hrace = h.id_zacin_hrace THEN h.zacin_hrac_znak
          ELSE h.druhy_hrac_znak
        END
      INTO v_znak
      FROM tah t
      INNER JOIN hra h ON t.id_hry = h.id_hry
      WHERE
        t.id_hry = p_id_hry
        AND t.pozice_x = x
        AND t.pozice_y = p_cislo_radku;
      EXCEPTION
        WHEN no_data_found THEN
          v_znak := '.';
    END;

    v_radek := v_radek || v_znak;

    IF x < v_sirka THEN v_radek := v_radek || ' '; END IF;
  END LOOP;

  RETURN v_radek;
END;
/

-- Funkce pro výpočet celkového herního času hráče v jedné hře
CREATE OR REPLACE FUNCTION herni_cas(
  p_id_hry NUMBER,
  p_id_hrace NUMBER
) RETURN NUMBER
IS
  v_herni_cas NUMBER;
BEGIN
  SELECT
    coalesce(
      sum(
        -- timestamp difference -> seconds as float (with milliseconds
        -- precision)
        -- ref: https://stackoverflow.com/questions/17413096/
        -- how-to-find-difference-b-w-timestamp-format-values-in-oracle/17413839
        extract(
          DAY FROM (tah.casova_znacka - pred.casova_znacka) * 86400 * 1000
        ) / 1000
      ),
      0
    )
  INTO v_herni_cas
  FROM tah
  INNER JOIN tah pred
    ON
      tah.id_hry = pred.id_hry AND pred.poradi_tahu = tah.poradi_tahu - 1
  WHERE
    tah.id_hry = p_id_hry
    AND tah.id_hrace = p_id_hrace
    AND pred.id_hrace IS NOT NULL
    AND pred.id_hrace != p_id_hrace;

  RETURN v_herni_cas;
END;
/

-- Funkce vrací TRUE, pokud už není možné udělat další tah
CREATE OR REPLACE FUNCTION remiza(
  p_id_hry NUMBER
) RETURN BOOLEAN
IS
  v_celkem_policek NUMBER;
  v_plno NUMBER;
BEGIN
  SELECT h.sirka_papiru * h.vyska_papiru
  INTO v_celkem_policek
  FROM hra h
  WHERE h.id_hry = p_id_hry;

  SELECT count(*)
  INTO v_plno
  FROM tah t
  WHERE t.id_hry = p_id_hry;

  RETURN v_plno >= v_celkem_policek;
END;
/

-- Funkce vrací TRUE, pokud poslední tah právě hrajícího hráče vytvořil výhru
CREATE OR REPLACE FUNCTION vyhra(
  p_id_hry NUMBER
) RETURN BOOLEAN
IS
  v_id_hrace NUMBER;
  v_x NUMBER;
  v_y NUMBER;
  v_delka NUMBER;

  FUNCTION pocet_ve_smeru(
    p_dx NUMBER,
    p_dy NUMBER
  ) RETURN NUMBER
  IS
    v_krok NUMBER := 1;
    v_existuje NUMBER;
  BEGIN
    LOOP
      SELECT count(*)
      INTO v_existuje
      FROM tah t
      WHERE
        t.id_hry = p_id_hry
        AND t.id_hrace = v_id_hrace
        AND t.pozice_x = v_x + p_dx * v_krok
        AND t.pozice_y = v_y + p_dy * v_krok
        AND ROWNUM = 1;

      EXIT WHEN v_existuje = 0;
      v_krok := v_krok + 1;
    END LOOP;

    RETURN v_krok - 1;
  END;
BEGIN
  SELECT
    id_hrace,
    pozice_x,
    pozice_y
  INTO v_id_hrace, v_x, v_y
  FROM (
    SELECT * FROM tah
    WHERE id_hry = p_id_hry
    ORDER BY poradi_tahu DESC
  )
  WHERE ROWNUM = 1;

  SELECT h.delka_vitezne_rady
  INTO v_delka
  FROM hra h
  WHERE h.id_hry = p_id_hry;

  FOR d IN (
    SELECT
      1 AS dx,
      0 AS dy
    FROM dual
    UNION ALL
    SELECT
      0 AS dx,
      1 AS dy
    FROM dual
    UNION ALL
    SELECT
      1 AS dx,
      1 AS dy
    FROM dual
    UNION ALL
    SELECT
      1 AS dx,
      -1 AS dy
    FROM dual
  ) LOOP
    IF 1
    + pocet_ve_smeru(d.dx, d.dy)
    + pocet_ve_smeru(-d.dx, -d.dy) >= v_delka THEN
      RETURN TRUE;
    END IF;
  END LOOP;

  RETURN FALSE;

  EXCEPTION
    WHEN no_data_found THEN
      RETURN FALSE;
END;
/

-- Funkce vrací kód chyby parametrů při zakládání hry
CREATE OR REPLACE FUNCTION spatny_parametr(
  p_pocet_radku NUMBER,
  p_pocet_sloupcu NUMBER,
  p_delka_vitezne_rady NUMBER
) RETURN NUMBER
IS
  v_min_radku NUMBER;
  v_max_radku NUMBER;
  v_min_sloupcu NUMBER;
  v_max_sloupcu NUMBER;
  v_min_delky NUMBER;
  v_max_delky NUMBER;
BEGIN
  SELECT
    o.minimalni,
    o.maximalni
  INTO v_min_sloupcu, v_max_sloupcu
  FROM omezeni o
  WHERE o.nazev = 'šířka';

  SELECT
    o.minimalni,
    o.maximalni
  INTO v_min_radku, v_max_radku
  FROM omezeni o
  WHERE o.nazev = 'výška';

  SELECT
    o.minimalni,
    o.maximalni
  INTO v_min_delky, v_max_delky
  FROM omezeni o
  WHERE o.nazev = 'délka';

  IF p_pocet_radku < v_min_radku THEN
    RETURN 1;
  END IF;

  IF p_pocet_radku > v_max_radku THEN
    RETURN 2;
  END IF;

  IF p_pocet_sloupcu < v_min_sloupcu THEN
    RETURN 3;
  END IF;

  IF p_pocet_sloupcu > v_max_sloupcu THEN
    RETURN 4;
  END IF;

  IF p_delka_vitezne_rady < v_min_delky THEN
    RETURN 5;
  END IF;

  IF p_delka_vitezne_rady > v_max_delky THEN
    RETURN 6;
  END IF;

  IF p_delka_vitezne_rady > p_pocet_sloupcu THEN
    RETURN 7;
  END IF;

  IF p_delka_vitezne_rady > p_pocet_radku THEN
    RETURN 8;
  END IF;

  RETURN 0;
END;
/
