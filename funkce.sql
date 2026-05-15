-- Funkce pro zobrazení řádku papíru
CREATE OR REPLACE FUNCTION radek_papiru(
  p_id_hry NUMBER,
  p_cislo_radku NUMBER
) RETURN VARCHAR2
IS
  v_radek VARCHAR2(100) := '';
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
          v_znak := ' ';
    END;

    v_radek := v_radek || v_znak;

  END LOOP;

  RETURN v_radek;
END;
/
