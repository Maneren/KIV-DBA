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
