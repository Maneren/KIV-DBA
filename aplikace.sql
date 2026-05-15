CREATE SEQUENCE seq_stav;
CREATE SEQUENCE seq_omezeni;
CREATE SEQUENCE seq_hrac;
CREATE SEQUENCE seq_hra;
CREATE SEQUENCE seq_tah;

-- Číselník stavů her
CREATE TABLE stav (
  id_stavu NUMBER DEFAULT seq_stav.NEXTVAL PRIMARY KEY,
  nazev VARCHAR2(50) NOT NULL UNIQUE
);

-- Parametry systému
CREATE TABLE omezeni (
  id_omezeni NUMBER DEFAULT seq_omezeni.NEXTVAL PRIMARY KEY,
  nazev VARCHAR2(50) UNIQUE NOT NULL,
  minimalni NUMBER NOT NULL,
  maximalni NUMBER NOT NULL,
  CONSTRAINT chk_omezeni_rozsah CHECK (minimalni <= maximalni)
);

-- Registrovaní hráči
CREATE TABLE hrac (
  id_hrace NUMBER DEFAULT seq_hrac.NEXTVAL PRIMARY KEY,
  jmeno VARCHAR2(32) NOT NULL UNIQUE,
  vyhry_zacinajici NUMBER DEFAULT 0 NOT NULL,
  prohry_zacinajici NUMBER DEFAULT 0 NOT NULL,
  remizy_zacinajici NUMBER DEFAULT 0 NOT NULL,
  vyhry_druhy NUMBER DEFAULT 0 NOT NULL,
  prohry_druhy NUMBER DEFAULT 0 NOT NULL,
  remizy_druhy NUMBER DEFAULT 0 NOT NULL,
  CONSTRAINT chk_statistiky_nezaporne CHECK (
    vyhry_zacinajici >= 0
    AND prohry_zacinajici >= 0
    AND remizy_zacinajici >= 0
    AND vyhry_druhy >= 0
    AND prohry_druhy >= 0
    AND remizy_druhy >= 0
  )
);

-- Hry
CREATE TABLE hra (
  id_hry NUMBER DEFAULT seq_hra.NEXTVAL PRIMARY KEY,
  sirka_papiru NUMBER NOT NULL,
  vyska_papiru NUMBER NOT NULL,
  delka_vitezne_rady NUMBER NOT NULL,
  id_zacin_hrace NUMBER NOT NULL,
  id_druheho_hrace NUMBER NOT NULL,
  id_stavu NUMBER NOT NULL,
  cas_zacin_hrace NUMBER DEFAULT 0,
  cas_druheho_hrace NUMBER DEFAULT 0,
  datum_vytvoreni TIMESTAMP DEFAULT current_timestamp NOT NULL,
  CONSTRAINT fk_hra_zacin_hrac FOREIGN KEY (id_zacin_hrace) REFERENCES hrac (
    id_hrace
  ),
  CONSTRAINT fk_hra_druhy_hrac FOREIGN KEY (id_druheho_hrace) REFERENCES hrac (
    id_hrace
  ),
  CONSTRAINT fk_hra_stav FOREIGN KEY (id_stavu) REFERENCES stav (id_stavu),
  CONSTRAINT chk_hra_rozdilni_hraci CHECK (id_zacin_hrace != id_druheho_hrace),
  CONSTRAINT chk_hra_rozmer_papiru CHECK (
    sirka_papiru > 0 AND vyska_papiru > 0
  ),
  CONSTRAINT chk_hra_delka_vitezne_rady CHECK (delka_vitezne_rady > 0),
  CONSTRAINT chk_hra_cas_nezaporny CHECK (
    cas_zacin_hrace >= 0 AND cas_druheho_hrace >= 0
  )
);

-- Tahy ve hrách
CREATE TABLE tah (
  id_tahu NUMBER DEFAULT seq_tah.NEXTVAL PRIMARY KEY,
  id_hry NUMBER NOT NULL,
  id_hrace NUMBER NOT NULL,
  pozice_x NUMBER NOT NULL,
  pozice_y NUMBER NOT NULL,
  casova_znacka TIMESTAMP DEFAULT current_timestamp NOT NULL,
  poradi_tahu NUMBER NOT NULL,
  CONSTRAINT fk_tah_hra FOREIGN KEY (id_hry) REFERENCES hra (id_hry),
  CONSTRAINT fk_tah_hrac FOREIGN KEY (id_hrace) REFERENCES hrac (id_hrace),
  CONSTRAINT chk_tah_pozice CHECK (pozice_x > 0 AND pozice_y > 0),
  CONSTRAINT chk_tah_poradi CHECK (poradi_tahu > 0),
  CONSTRAINT uk_tah_pozice UNIQUE (id_hry, pozice_x, pozice_y),
  CONSTRAINT uk_tah_poradi UNIQUE (id_hry, poradi_tahu)
);

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
  SELECT sirka_papiru
  INTO v_sirka
  FROM hra
  WHERE id_hry = p_id_hry;

  FOR x IN 1..v_sirka LOOP
    BEGIN
      SELECT
        CASE
          WHEN t.id_hrace = h.id_zacin_hrace THEN 'X'
          ELSE 'O'
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
-- zobrazení papírů všech her
CREATE OR REPLACE VIEW papir AS
SELECT
  h.id_hry,
  r.cislo_radku,
  radek_papiru(h.id_hry, r.cislo_radku) AS radek
FROM hra h
CROSS APPLY (
  SELECT LEVEL AS cislo_radku
  FROM dual
  CONNECT BY LEVEL <= h.vyska_papiru
) r
ORDER BY h.id_hry, r.cislo_radku;

-- zobrazení her, které skončily výhrou začínajícího hráče
CREATE OR REPLACE VIEW vyhry_zacinajici AS
WITH hra_data AS (
  SELECT
    h.id_hry,
    h.sirka_papiru,
    h.vyska_papiru,
    h.delka_vitezne_rady,
    hz.jmeno AS jmeno_zacin_hrace,
    hd.jmeno AS jmeno_druheho_hrace,
    hz.jmeno AS jmeno_hrace_ktery_zacikal,
    h.cas_zacin_hrace,
    h.cas_druheho_hrace
  FROM hra h
  INNER JOIN hrac hz ON h.id_zacin_hrace = hz.id_hrace
  INNER JOIN hrac hd ON h.id_druheho_hrace = hd.id_hrace
  INNER JOIN stav s ON h.id_stavu = s.id_stavu
  WHERE s.nazev = 'výhra'
),
pocty_tahu AS (
  SELECT
    id_hry,
    count(*) AS pocet_tahu
  FROM tah
  GROUP BY id_hry
)
SELECT
  hd.id_hry,
  hd.sirka_papiru,
  hd.vyska_papiru,
  hd.delka_vitezne_rady,
  hd.jmeno_zacin_hrace,
  hd.jmeno_druheho_hrace,
  hd.jmeno_hrace_ktery_zacikal,
  pt.pocet_tahu,
  (hd.cas_zacin_hrace + hd.cas_druheho_hrace) AS celkovy_cas_hry
FROM hra_data hd
INNER JOIN pocty_tahu pt ON hd.id_hry = pt.id_hry;

-- zobrazení her, které skončily remízou
CREATE OR REPLACE VIEW remizy AS
SELECT
  h.id_hry,
  h.sirka_papiru,
  h.vyska_papiru,
  h.delka_vitezne_rady,
  hz.jmeno AS jmeno_zacin_hrace,
  hd.jmeno AS jmeno_druheho_hrace,
  hz.jmeno AS jmeno_hrace_ktery_zacikal,
  (h.cas_zacin_hrace + h.cas_druheho_hrace) AS celkovy_cas_hry,
  (
    SELECT count(*) FROM tah t
    WHERE t.id_hry = h.id_hry
  ) AS pocet_tahu
FROM hra h
INNER JOIN hrac hz ON h.id_zacin_hrace = hz.id_hrace
INNER JOIN hrac hd ON h.id_druheho_hrace = hd.id_hrace
INNER JOIN stav s ON h.id_stavu = s.id_stavu
WHERE s.nazev = 'remíza';

-- zobrazení her, které skončily prohrou začínajícího hráče
CREATE OR REPLACE VIEW prohry_zacinajici AS
SELECT
  h.id_hry,
  h.sirka_papiru,
  h.vyska_papiru,
  h.delka_vitezne_rady,
  hz.jmeno AS jmeno_zacin_hrace,
  hd.jmeno AS jmeno_druheho_hrace,
  hz.jmeno AS jmeno_hrace_ktery_zacikal,
  (h.cas_zacin_hrace + h.cas_druheho_hrace) AS celkovy_cas_hry,
  (
    SELECT count(*) FROM tah t
    WHERE t.id_hry = h.id_hry
  ) AS pocet_tahu
FROM hra h
INNER JOIN hrac hz ON h.id_zacin_hrace = hz.id_hrace
INNER JOIN hrac hd ON h.id_druheho_hrace = hd.id_hrace
INNER JOIN stav s ON h.id_stavu = s.id_stavu
WHERE s.nazev = 'prohra';

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

INSERT INTO stav (nazev) VALUES ('rozehraná'),
('výhra'),
('prohra'),
('remíza');

INSERT INTO omezeni (nazev, minimalni, maximalni) VALUES ('šířka', 5, 20),
('výška', 5, 20),
('délka', 5, 15);

set serveroutput on
set linesize 220
set pagesize 1000

variable v_id_hry number
variable v_id_stav number

INSERT INTO hrac (jmeno) VALUES ('Petr'), ('Jana');

begin
  select id_stavu
  into :v_id_stav
  from stav
  where nazev = 'rozehraná';

  insert into hra (
    sirka_papiru,
    vyska_papiru,
    delka_vitezne_rady,
    id_zacin_hrace,
    id_druheho_hrace,
    id_stavu
  ) values (
    5,
    5,
    5,
    1,
    2,
    :v_id_stav
  );

  select seq_hra.currval into :v_id_hry from dual;
end;
/

insert into tah (id_hry, id_hrace, pozice_x, pozice_y, poradi_tahu)
values (:v_id_hry, 1, 1, 1, 1);
select radek from papir where id_hry = :v_id_hry order by cislo_radku;

insert into tah (id_hry, id_hrace, pozice_x, pozice_y, poradi_tahu)
values (:v_id_hry, 2, 1, 2, 2);
select radek from papir where id_hry = :v_id_hry order by cislo_radku;

insert into tah (id_hry, id_hrace, pozice_x, pozice_y, poradi_tahu)
values (:v_id_hry, 1, 2, 1, 3);
select radek from papir where id_hry = :v_id_hry order by cislo_radku;

insert into tah (id_hry, id_hrace, pozice_x, pozice_y, poradi_tahu)
values (:v_id_hry, 2, 2, 2, 4);
select radek from papir where id_hry = :v_id_hry order by cislo_radku;

insert into tah (id_hry, id_hrace, pozice_x, pozice_y, poradi_tahu)
values (:v_id_hry, 1, 3, 1, 5);
select radek from papir where id_hry = :v_id_hry order by cislo_radku;

insert into tah (id_hry, id_hrace, pozice_x, pozice_y, poradi_tahu)
values (:v_id_hry, 2, 3, 2, 6);
select radek from papir where id_hry = :v_id_hry order by cislo_radku;

insert into tah (id_hry, id_hrace, pozice_x, pozice_y, poradi_tahu)
values (:v_id_hry, 1, 4, 1, 7);
select radek from papir where id_hry = :v_id_hry order by cislo_radku;

insert into tah (id_hry, id_hrace, pozice_x, pozice_y, poradi_tahu)
values (:v_id_hry, 2, 4, 2, 8);
select radek from papir where id_hry = :v_id_hry order by cislo_radku;

insert into tah (id_hry, id_hrace, pozice_x, pozice_y, poradi_tahu)
values (:v_id_hry, 1, 5, 1, 9);
select radek from papir where id_hry = :v_id_hry order by cislo_radku;

select * from vyhry_zacinajici;
select * from hra order by id_hry;
select * from hrac order by id_hrace;

begin
  select id_stavu
  into :v_id_stav
  from stav
  where nazev = 'rozehraná';

  insert into hra (
    sirka_papiru,
    vyska_papiru,
    delka_vitezne_rady,
    id_zacin_hrace,
    id_druheho_hrace,
    id_stavu
  ) values (
    5,
    5,
    5,
    1,
    2,
    :v_id_stav
  );

  select seq_hra.currval into :v_id_hry from dual;
end;
/

insert into tah (id_hry, id_hrace, pozice_x, pozice_y, poradi_tahu)
values (:v_id_hry, 1, 1, 1, 1);
select radek from papir where id_hry = :v_id_hry order by cislo_radku;

insert into tah (id_hry, id_hrace, pozice_x, pozice_y, poradi_tahu)
values (:v_id_hry, 2, 1, 2, 2);
select radek from papir where id_hry = :v_id_hry order by cislo_radku;

insert into tah (id_hry, id_hrace, pozice_x, pozice_y, poradi_tahu)
values (:v_id_hry, 1, 2, 1, 3);
select radek from papir where id_hry = :v_id_hry order by cislo_radku;

insert into tah (id_hry, id_hrace, pozice_x, pozice_y, poradi_tahu)
values (:v_id_hry, 2, 2, 2, 4);
select radek from papir where id_hry = :v_id_hry order by cislo_radku;

insert into tah (id_hry, id_hrace, pozice_x, pozice_y, poradi_tahu)
values (:v_id_hry, 1, 3, 1, 5);
select radek from papir where id_hry = :v_id_hry order by cislo_radku;

insert into tah (id_hry, id_hrace, pozice_x, pozice_y, poradi_tahu)
values (:v_id_hry, 2, 3, 2, 6);
select radek from papir where id_hry = :v_id_hry order by cislo_radku;

insert into tah (id_hry, id_hrace, pozice_x, pozice_y, poradi_tahu)
values (:v_id_hry, 1, 4, 1, 7);
select radek from papir where id_hry = :v_id_hry order by cislo_radku;

insert into tah (id_hry, id_hrace, pozice_x, pozice_y, poradi_tahu)
values (:v_id_hry, 2, 4, 2, 8);
select radek from papir where id_hry = :v_id_hry order by cislo_radku;

insert into tah (id_hry, id_hrace, pozice_x, pozice_y, poradi_tahu)
values (:v_id_hry, 1, 5, 3, 9);
select radek from papir where id_hry = :v_id_hry order by cislo_radku;

insert into tah (id_hry, id_hrace, pozice_x, pozice_y, poradi_tahu)
values (:v_id_hry, 2, 5, 2, 10);
select radek from papir where id_hry = :v_id_hry order by cislo_radku;

select * from vyhry_zacinajici;
select * from hra order by id_hry;
select * from hrac order by id_hrace;

begin
  select id_stavu
  into :v_id_stav
  from stav
  where nazev = 'rozehraná';

  insert into hra (
    sirka_papiru,
    vyska_papiru,
    delka_vitezne_rady,
    id_zacin_hrace,
    id_druheho_hrace,
    id_stavu
  ) values (
    5,
    5,
    5,
    1,
    2,
    :v_id_stav
  );

  select seq_hra.currval into :v_id_hry from dual;
end;
/

-- neexistující hra
insert into tah (id_hry, id_hrace, pozice_x, pozice_y, poradi_tahu)
values (9999, 1, 1, 1, 1);

-- nehrající hráč
insert into tah (id_hry, id_hrace, pozice_x, pozice_y, poradi_tahu)
values (:v_id_hry, 3, 1, 1, 1);

-- validní tah
insert into tah (id_hry, id_hrace, pozice_x, pozice_y, poradi_tahu)
values (:v_id_hry, 1, 1, 1, 1);
select radek from papir where id_hry = :v_id_hry order by cislo_radku;

-- hráč hraje podruhé v řadě
insert into tah (id_hry, id_hrace, pozice_x, pozice_y, poradi_tahu)
values (:v_id_hry, 1, 2, 1, 2);

-- špatné pořadí tahu
insert into tah (id_hry, id_hrace, pozice_x, pozice_y, poradi_tahu)
values (:v_id_hry, 2, 2, 2, 3);

insert into tah (id_hry, id_hrace, pozice_x, pozice_y, poradi_tahu)
values (:v_id_hry, 2, 1, 2, 2);
select radek from papir where id_hry = :v_id_hry order by cislo_radku;

-- tah na obsazenou pozici
insert into tah (id_hry, id_hrace, pozice_x, pozice_y, poradi_tahu)
values (:v_id_hry, 1, 1, 2, 3);

insert into tah (id_hry, id_hrace, pozice_x, pozice_y, poradi_tahu)
values (:v_id_hry, 1, 2, 1, 3);
select radek from papir where id_hry = :v_id_hry order by cislo_radku;

-- tah mimo papír
insert into tah (id_hry, id_hrace, pozice_x, pozice_y, poradi_tahu)
values (:v_id_hry, 2, 6, 1, 4);

insert into tah (id_hry, id_hrace, pozice_x, pozice_y, poradi_tahu)
values (:v_id_hry, 2, 2, 2, 4);
select radek from papir where id_hry = :v_id_hry order by cislo_radku;

insert into tah (id_hry, id_hrace, pozice_x, pozice_y, poradi_tahu)
values (:v_id_hry, 1, 3, 1, 5);
select radek from papir where id_hry = :v_id_hry order by cislo_radku;

insert into tah (id_hry, id_hrace, pozice_x, pozice_y, poradi_tahu)
values (:v_id_hry, 2, 3, 2, 6);
select radek from papir where id_hry = :v_id_hry order by cislo_radku;

insert into tah (id_hry, id_hrace, pozice_x, pozice_y, poradi_tahu)
values (:v_id_hry, 1, 4, 1, 7);
select radek from papir where id_hry = :v_id_hry order by cislo_radku;

insert into tah (id_hry, id_hrace, pozice_x, pozice_y, poradi_tahu)
values (:v_id_hry, 2, 4, 2, 8);
select radek from papir where id_hry = :v_id_hry order by cislo_radku;

insert into tah (id_hry, id_hrace, pozice_x, pozice_y, poradi_tahu)
values (:v_id_hry, 1, 5, 1, 9);
select radek from papir where id_hry = :v_id_hry order by cislo_radku;

-- tah po konci hry - konec hry není implementován
-- insert into tah (id_hry, id_hrace, pozice_x, pozice_y, poradi_tahu)
-- values (:v_id_hry, 2, 5, 2, 10);
-- select radek from papir where id_hry = :v_id_hry order by cislo_radku;

select * from vyhry_zacinajici;
select * from hra order by id_hry;
select * from hrac order by id_hrace;
