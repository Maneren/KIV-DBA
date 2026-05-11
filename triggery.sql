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


-- Trigger pro aktualizaci stavu hry, časů a statistik po tahu (compound trigger kvůli čtení z TAH ve vyhra)
CREATE OR REPLACE TRIGGER trg_tah_ukonceni_hry
FOR INSERT ON tah
COMPOUND TRIGGER

  -- key=id_hry, value=id_hrace (last mover in statement)
  TYPE t_game_set IS TABLE OF PLS_INTEGER INDEX BY PLS_INTEGER;
  g_games T_GAME_SET;

AFTER EACH ROW IS
BEGIN
g_games (:NEW.id_hry) := :NEW.id_hrace;
END AFTER EACH ROW;

AFTER STATEMENT IS
  v_id_zacin hra.id_zacin_hrace%TYPE;
  v_stav_id  stav.id_stavu%TYPE;
  k          PLS_INTEGER;
BEGIN
  k := g_games.first;
  WHILE k IS NOT NULL LOOP
    v_stav_id := NULL;

    IF vyhra(k) THEN
      SELECT h.id_zacin_hrace
      INTO v_id_zacin
      FROM hra h
      WHERE h.id_hry = k;

      IF g_games(k) = v_id_zacin THEN
        SELECT s.id_stavu INTO v_stav_id FROM stav s
        WHERE s.nazev = 'vítězství';
      ELSE
        SELECT s.id_stavu INTO v_stav_id FROM stav s
        WHERE s.nazev = 'prohra';
      END IF;

    ELSIF remiza(k) THEN
      SELECT s.id_stavu INTO v_stav_id FROM stav s
      WHERE s.nazev = 'remíza';
    END IF;

    IF v_stav_id IS NOT NULL THEN
      UPDATE hra
      SET id_stavu = v_stav_id
      WHERE id_hry = k;

      konec_hry(k);
      statistiky(k);
    END IF;

    k := g_games.NEXT(k);
  END LOOP;

  g_games.DELETE;
END AFTER STATEMENT;

END trg_tah_ukonceni_hry;
/
