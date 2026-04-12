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
);

-- Registrovaní hráči
CREATE TABLE hrac (
  id_hrace NUMBER PRIMARY KEY,
  jmeno VARCHAR2(100) NOT NULL UNIQUE,
  vyhry_zacinajici NUMBER DEFAULT 0 NOT NULL,
  prohry_zacinajici NUMBER DEFAULT 0 NOT NULL,
  remizy_zacinajici NUMBER DEFAULT 0 NOT NULL,
  vyhry_druhy NUMBER DEFAULT 0 NOT NULL,
  prohry_druhy NUMBER DEFAULT 0 NOT NULL,
  remizy_druhy NUMBER DEFAULT 0 NOT NULL,
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
);
