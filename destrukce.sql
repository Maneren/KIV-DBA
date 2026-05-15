-- Teardown skript: odstranění projektvých objektů
DECLARE
  PROCEDURE drop_if_exists(p_sql VARCHAR2) IS
  BEGIN
    EXECUTE IMMEDIATE p_sql;
    EXCEPTION
      WHEN OTHERS THEN
        IF sqlcode NOT IN (
          -4043, -- object does not exist
          -4080, -- trigger does not exist
          -942,  -- table or view does not exist
          -2289  -- sequence does not exist
        ) THEN
          RAISE;
        END IF;
  END;
BEGIN
  -- pohledy
  drop_if_exists('DROP VIEW prohry_zacinajici');
  drop_if_exists('DROP VIEW remizy');
  drop_if_exists('DROP VIEW vyhry_zacinajici');
  drop_if_exists('DROP VIEW papir');

  -- triggery
  drop_if_exists('DROP TRIGGER trg_tah_validace');

  -- procedury
  drop_if_exists('DROP PROCEDURE zabran_tahu');

  -- funkce
  drop_if_exists('DROP FUNCTION radek_papiru');

  -- tabulky
  drop_if_exists('DROP TABLE tah CASCADE CONSTRAINTS');
  drop_if_exists('DROP TABLE hra CASCADE CONSTRAINTS');
  drop_if_exists('DROP TABLE hrac CASCADE CONSTRAINTS');
  drop_if_exists('DROP TABLE omezeni CASCADE CONSTRAINTS');
  drop_if_exists('DROP TABLE stav CASCADE CONSTRAINTS');

  -- sekvence
  drop_if_exists('DROP SEQUENCE seq_tah');
  drop_if_exists('DROP SEQUENCE seq_hra');
  drop_if_exists('DROP SEQUENCE seq_hrac');
  drop_if_exists('DROP SEQUENCE seq_omezeni');
  drop_if_exists('DROP SEQUENCE seq_stav');
END;
/

COMMIT;
