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
  INNER JOIN stav s ON h.id_stavu = s.id_stavu
  WHERE h.id_hry = p_id_hry;

  IF v_stav != 'rozehraná' THEN
    raise_application_error(
      -20011, 'Nelze provést tah ve hře, která již skončila'
    );
  END IF;

  IF p_id_hrace NOT IN (v_id_zacin, v_id_druhy) THEN
    raise_application_error(-20012, 'Hráč nehraje v dané hře');
  END IF;

  IF p_pozice_x < 1
  OR p_pozice_x > v_sirka
  OR p_pozice_y < 1
  OR p_pozice_y > v_vyska THEN
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
    SELECT
      id_hrace,
      poradi_tahu
    INTO v_posledni_hrac, v_posledni_poradi
    FROM (
      SELECT * FROM tah
      WHERE id_hry = p_id_hry
      ORDER BY poradi_tahu DESC
    )
    WHERE ROWNUM = 1;

    IF v_posledni_hrac = v_id_zacin THEN
      v_ocekavany_hrac := v_id_druhy;
    ELSE
      v_ocekavany_hrac := v_id_zacin;
    END IF;

    v_ocekavane_poradi := v_posledni_poradi + 1;
  END IF;

  IF p_id_hrace != v_ocekavany_hrac THEN
    raise_application_error(
      -20015, 'Hráči se musí pravidelně střídat po jednom tahu'
    );
  END IF;

  IF p_poradi_tahu != v_ocekavane_poradi THEN
    raise_application_error(-20016, 'Neplatné pořadí tahu');
  END IF;

  EXCEPTION
    WHEN no_data_found THEN
      raise_application_error(-20010, 'Zadaná hra neexistuje');
END;
/
