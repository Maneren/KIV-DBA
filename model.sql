-- Číselník stavů her
CREATE TABLE stav (
  id_stavu NUMBER PRIMARY KEY,
  nazev VARCHAR2(50) NOT NULL UNIQUE
);

-- Parametry systému
CREATE TABLE omezeni (
  nazev VARCHAR2(50) PRIMARY KEY,
  minimalni NUMBER NOT NULL,
  maximalni NUMBER NOT NULL,
  CONSTRAINT chk_omezeni_rozsah CHECK (minimalni <= maximalni)
);

-- Registrovaní hráči
CREATE TABLE hrac (
  id_hrace NUMBER PRIMARY KEY,
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
  id_hry NUMBER PRIMARY KEY,
  sirka_papiru NUMBER NOT NULL,
  vyska_papiru NUMBER NOT NULL,
  delka_vitezne_rady NUMBER NOT NULL,
  id_zacin_hrace NUMBER NOT NULL,
  id_druheho_hrace NUMBER NOT NULL,
  zacin_hrac_znak CHAR(1) NOT NULL,
  druhy_hrac_znak CHAR(1) NOT NULL,
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
  CONSTRAINT chk_hra_rozdilne_znaky CHECK (zacin_hrac_znak != druhy_hrac_znak),
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
  id_tahu NUMBER PRIMARY KEY,
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
