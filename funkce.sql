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
  -- Získání informací o hře
  SELECT
    sirka_papiru,
    zacin_hrac_znak,
    druhy_hrac_znak
  INTO v_sirka, v_zacin_znak, v_druhy_znak
  FROM hra
  WHERE id_hry = p_id_hry;

  FOR i IN 1..v_sirka LOOP
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
        AND t.pozice_x = i
        AND t.pozice_y = p_cislo_radku;
      EXCEPTION
        WHEN no_data_found THEN
          v_znak := '.';
    END;

    v_radek := v_radek || v_znak;

    IF i < v_sirka THEN v_radek := v_radek || ' '; END IF;
  END LOOP;

  RETURN v_radek;
END;
/
show errors;

-- Funkce pro výpočet celkového herního času hráče v jedné hře
CREATE OR REPLACE FUNCTION herni_cas(
  p_id_hry NUMBER,
  p_id_hrace NUMBER
) RETURN NUMBER
IS
  v_cas NUMBER := 0;
BEGIN
  SELECT
    coalesce(
      sum(
        (cast(x.casova_znacka AS DATE) - cast(x.predchozi_cas AS DATE)) * 86400
      ),
      0
    )
  INTO v_cas
  FROM (
    SELECT
      t.id_hrace,
      t.casova_znacka,
      lag(t.id_hrace) OVER (ORDER BY t.poradi_tahu) AS predchozi_hrac,
      lag(t.casova_znacka) OVER (ORDER BY t.poradi_tahu) AS predchozi_cas
    FROM tah t
    WHERE t.id_hry = p_id_hry
  ) x
  WHERE
    x.id_hrace = p_id_hrace
    AND x.predchozi_cas IS NOT NULL
    AND x.predchozi_hrac IS NOT NULL
    AND x.predchozi_hrac != p_id_hrace;

  RETURN v_cas;
END;
/
show errors;

-- Funkce vrací TRUE, pokud už není možné udělat další tah
CREATE OR REPLACE FUNCTION remiza(
  p_id_hry NUMBER
) RETURN BOOLEAN
IS
  v_sirka NUMBER;
  v_vyska NUMBER;
  v_pocet_tahu NUMBER;
BEGIN
  SELECT
    h.sirka_papiru,
    h.vyska_papiru
  INTO v_sirka, v_vyska
  FROM hra h
  WHERE h.id_hry = p_id_hry;

  SELECT count(*)
  INTO v_pocet_tahu
  FROM tah t
  WHERE t.id_hry = p_id_hry;

  RETURN v_pocet_tahu >= (v_sirka * v_vyska);
END;
/
show errors;

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
        AND t.pozice_y = v_y + p_dy * v_krok;

      EXIT WHEN v_existuje = 0;
      v_krok := v_krok + 1;
    END LOOP;

    RETURN v_krok - 1;
  END;
BEGIN
  SELECT
    t.id_hrace,
    t.pozice_x,
    t.pozice_y
  INTO v_id_hrace, v_x, v_y
  FROM tah t
  WHERE
    t.id_hry = p_id_hry
    AND t.poradi_tahu = (
      SELECT max(t2.poradi_tahu)
      FROM tah t2
      WHERE t2.id_hry = p_id_hry
    );

  SELECT h.delka_vitezne_rady
  INTO v_delka
  FROM hra h
  WHERE h.id_hry = p_id_hry;

  IF 1 + pocet_ve_smeru(1, 0) + pocet_ve_smeru(-1, 0) >= v_delka THEN
    RETURN TRUE;
  END IF;

  IF 1 + pocet_ve_smeru(0, 1) + pocet_ve_smeru(0, -1) >= v_delka THEN
    RETURN TRUE;
  END IF;

  IF 1 + pocet_ve_smeru(1, 1) + pocet_ve_smeru(-1, -1) >= v_delka THEN
    RETURN TRUE;
  END IF;

  IF 1 + pocet_ve_smeru(1, -1) + pocet_ve_smeru(-1, 1) >= v_delka THEN
    RETURN TRUE;
  END IF;

  RETURN FALSE;

  EXCEPTION
    WHEN no_data_found THEN
      RETURN FALSE;
END;
/
show errors;


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
show errors;
