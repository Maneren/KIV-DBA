-- Trigger pro hlídání parametrů nové hry a validaci hráčů
CREATE OR REPLACE TRIGGER trg_hra_validace
BEFORE INSERT OR UPDATE ON hra
FOR EACH ROW
BEGIN
  zabran_hre(
    :NEW.vyska_papiru,
    :NEW.sirka_papiru,
    :NEW.delka_vitezne_rady,
    :NEW.id_zacin_hrace,
    :NEW.id_druheho_hrace
  );
END;
/

-- Trigger pro hlídání pravidel při vkládání tahu
CREATE OR REPLACE TRIGGER trg_tah_validace
BEFORE INSERT ON tah
FOR EACH ROW
BEGIN
  zabran_tahu(
    :NEW.id_hry,
    :NEW.id_hrace,
    :NEW.pozice_x,
    :NEW.pozice_y,
    :NEW.poradi_tahu
  );
END;
/

-- Trigger pro aktualizaci stavu hry, časů a statistik po tahu
CREATE OR REPLACE TRIGGER trg_tah_ukonceni_hry
AFTER INSERT ON tah
FOR EACH ROW
DECLARE
  v_id_zacin NUMBER;
  v_id_stavu_vyhry NUMBER;
  v_id_stavu_prohry NUMBER;
  v_id_stavu_remiza NUMBER;
  v_konec_hry BOOLEAN := FALSE;
BEGIN
  SELECT h.id_zacin_hrace
  INTO v_id_zacin
  FROM hra h
  WHERE h.id_hry = :NEW.id_hry;

  IF vyhra(:NEW.id_hry) THEN
    SELECT s.id_stavu
    INTO v_id_stavu_vyhry
    FROM stav s
    WHERE s.nazev = 'vítězství';

    SELECT s.id_stavu
    INTO v_id_stavu_prohry
    FROM stav s
    WHERE s.nazev = 'prohra';

    IF :NEW.id_hrace = v_id_zacin THEN
      UPDATE hra
      SET id_stavu = v_id_stavu_vyhry
      WHERE id_hry = :NEW.id_hry;
    ELSE
      UPDATE hra
      SET id_stavu = v_id_stavu_prohry
      WHERE id_hry = :NEW.id_hry;
    END IF;

    v_konec_hry := TRUE;
  ELSIF remiza(:NEW.id_hry) THEN
    SELECT s.id_stavu
    INTO v_id_stavu_remiza
    FROM stav s
    WHERE s.nazev = 'remíza';

    UPDATE hra
    SET id_stavu = v_id_stavu_remiza
    WHERE id_hry = :NEW.id_hry;

    v_konec_hry := TRUE;
  END IF;

  IF v_konec_hry THEN
    konec_hry(:NEW.id_hry);
    statistiky(:NEW.id_hry);
  END IF;
END;
/
