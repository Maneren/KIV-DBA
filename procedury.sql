-- Procedura zabrání vytvoření neplatné hry
CREATE OR REPLACE PROCEDURE zabran_hre(
  p_pocet_radku NUMBER,
  p_pocet_sloupcu NUMBER,
  p_delka_vitezne_rady NUMBER,
  p_id_zacin_hrace NUMBER,
  p_id_druheho_hrace NUMBER
)
IS
  v_kod NUMBER;
BEGIN
  v_kod := spatny_parametr(
    p_pocet_radku,
    p_pocet_sloupcu,
    p_delka_vitezne_rady
  );

  IF v_kod = 1 THEN
    raise_application_error(-20001, 'Příliš malý počet řádků na papíru');
  ELSIF v_kod = 2 THEN
    raise_application_error(-20002, 'Příliš velký počet řádků na papíru');
  ELSIF v_kod = 3 THEN
    raise_application_error(-20003, 'Příliš malý počet sloupců na papíru');
  ELSIF v_kod = 4 THEN
    raise_application_error(-20004, 'Příliš velký počet sloupců na papíru');
  ELSIF v_kod = 5 THEN
    raise_application_error(-20005, 'Příliš malý počet znaků ve vítězné řadě');
  ELSIF v_kod = 6 THEN
    raise_application_error(-20006, 'Příliš velký počet znaků ve vítězné řadě');
  ELSIF v_kod = 7 THEN
    raise_application_error(-20007, 'Vítězná řada je delší než šířka papíru');
  ELSIF v_kod = 8 THEN
    raise_application_error(-20008, 'Vítězná řada je delší než výška papíru');
  END IF;

  IF p_id_zacin_hrace = p_id_druheho_hrace THEN
    raise_application_error(-20009, 'Hru musí hrát dva různí hráči');
  END IF;
END;
/
show errors;

-- Procedura zabrání neplatnému tahu
CREATE OR REPLACE PROCEDURE zabran_tahu(
  p_id_hry NUMBER,
  p_id_hrace NUMBER,
  p_pozice_x NUMBER,
  p_pozice_y NUMBER,
  p_poradi_tahu NUMBER
)
IS
  v_sirka NUMBER;
  v_vyska NUMBER;
  v_id_zacin NUMBER;
  v_id_druhy NUMBER;
  v_stav VARCHAR2(50);
  v_pocet NUMBER;
  v_posledni_hrac NUMBER;
  v_posledni_poradi NUMBER;
  v_ocekavany_hrac NUMBER;
  v_ocekavane_poradi NUMBER;
BEGIN
  SELECT
    h.sirka_papiru,
    h.vyska_papiru,
    h.id_zacin_hrace,
    h.id_druheho_hrace,
    s.nazev
  INTO v_sirka, v_vyska, v_id_zacin, v_id_druhy, v_stav
  FROM hra h
  INNER JOIN stav s ON s.id_stavu = h.id_stavu
  WHERE h.id_hry = p_id_hry;

  IF v_stav != 'rozehraná' THEN
    raise_application_error(-20011, 'Nelze provést tah ve hře, která již skončila');
  END IF;

  IF p_id_hrace NOT IN (v_id_zacin, v_id_druhy) THEN
    raise_application_error(-20012, 'Hráč nehraje v dané hře');
  END IF;

  IF p_pozice_x < 1 OR p_pozice_x > v_sirka OR p_pozice_y < 1 OR p_pozice_y > v_vyska THEN
    raise_application_error(-20013, 'Tah je mimo papír');
  END IF;

  SELECT count(*)
  INTO v_pocet
  FROM tah t
  WHERE
    t.id_hry = p_id_hry
    AND t.pozice_x = p_pozice_x
    AND t.pozice_y = p_pozice_y;

  IF v_pocet > 0 THEN
    raise_application_error(-20014, 'Na zadané pozici už je značka');
  END IF;

  SELECT count(*)
  INTO v_pocet
  FROM tah t
  WHERE t.id_hry = p_id_hry;

  IF v_pocet = 0 THEN
    v_ocekavany_hrac := v_id_zacin;
    v_ocekavane_poradi := 1;
  ELSE
    SELECT t.id_hrace, t.poradi_tahu
    INTO v_posledni_hrac, v_posledni_poradi
    FROM tah t
    WHERE
      t.id_hry = p_id_hry
      AND t.poradi_tahu = (
        SELECT max(t2.poradi_tahu)
        FROM tah t2
        WHERE t2.id_hry = p_id_hry
      );

    IF v_posledni_hrac = v_id_zacin THEN
      v_ocekavany_hrac := v_id_druhy;
    ELSE
      v_ocekavany_hrac := v_id_zacin;
    END IF;

    v_ocekavane_poradi := v_posledni_poradi + 1;
  END IF;

  IF p_id_hrace != v_ocekavany_hrac THEN
    raise_application_error(-20015, 'Hráči se musí pravidelně střídat po jednom tahu');
  END IF;

  IF p_poradi_tahu != v_ocekavane_poradi THEN
    raise_application_error(-20016, 'Neplatné pořadí tahu');
  END IF;

EXCEPTION
  WHEN no_data_found THEN
    raise_application_error(-20010, 'Zadaná hra neexistuje');
END;
/
show errors;

-- Procedura spočítá herní čas po dokončení hry
CREATE OR REPLACE PROCEDURE konec_hry(
  p_id_hry NUMBER
)
IS
  v_id_zacin NUMBER;
  v_id_druhy NUMBER;
BEGIN
  SELECT h.id_zacin_hrace, h.id_druheho_hrace
  INTO v_id_zacin, v_id_druhy
  FROM hra h
  WHERE h.id_hry = p_id_hry;

  UPDATE hra h
  SET
    h.cas_zacin_hrace = herni_cas(p_id_hry, v_id_zacin),
    h.cas_druheho_hrace = herni_cas(p_id_hry, v_id_druhy)
  WHERE h.id_hry = p_id_hry;

EXCEPTION
  WHEN no_data_found THEN
    raise_application_error(-20010, 'Zadaná hra neexistuje');
END;
/
show errors;

-- Procedura aktualizuje statistiky hráčů po dokončení hry
CREATE OR REPLACE PROCEDURE statistiky(
  p_id_hry NUMBER
)
IS
  v_id_zacin NUMBER;
  v_id_druhy NUMBER;
  v_stav VARCHAR2(50);
BEGIN
  SELECT
    h.id_zacin_hrace,
    h.id_druheho_hrace,
    s.nazev
  INTO v_id_zacin, v_id_druhy, v_stav
  FROM hra h
  INNER JOIN stav s ON s.id_stavu = h.id_stavu
  WHERE h.id_hry = p_id_hry;

  IF v_stav = 'vítězství' THEN
    UPDATE hrac
    SET vyhry_zacinajici = vyhry_zacinajici + 1
    WHERE id_hrace = v_id_zacin;

    UPDATE hrac
    SET prohry_druhy = prohry_druhy + 1
    WHERE id_hrace = v_id_druhy;
  ELSIF v_stav = 'prohra' THEN
    UPDATE hrac
    SET prohry_zacinajici = prohry_zacinajici + 1
    WHERE id_hrace = v_id_zacin;

    UPDATE hrac
    SET vyhry_druhy = vyhry_druhy + 1
    WHERE id_hrace = v_id_druhy;
  ELSIF v_stav = 'remíza' THEN
    UPDATE hrac
    SET remizy_zacinajici = remizy_zacinajici + 1
    WHERE id_hrace = v_id_zacin;

    UPDATE hrac
    SET remizy_druhy = remizy_druhy + 1
    WHERE id_hrace = v_id_druhy;
  END IF;

EXCEPTION
  WHEN no_data_found THEN
    raise_application_error(-20010, 'Zadaná hra neexistuje');
END;
/
show errors;
