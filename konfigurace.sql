-- Sekvence pro automatické generování ID
CREATE SEQUENCE seq_stav START WITH 1;
CREATE SEQUENCE seq_hrac START WITH 1;
CREATE SEQUENCE seq_hra START WITH 1;
CREATE SEQUENCE seq_tah START WITH 1;

-- Stavy her
INSERT INTO stav (id_stavu, nazev) VALUES (seq_stav.nextval, 'rozehraná');
INSERT INTO stav (id_stavu, nazev) VALUES (seq_stav.nextval, 'vítězství');
INSERT INTO stav (id_stavu, nazev) VALUES (seq_stav.nextval, 'prohra');
INSERT INTO stav (id_stavu, nazev) VALUES (seq_stav.nextval, 'remíza');

-- Omezení parametrů
INSERT INTO omezeni (nazev, minimalni, maximalni) VALUES ('šířka', 5, 20);
INSERT INTO omezeni (nazev, minimalni, maximalni) VALUES ('výška', 5, 20);
INSERT INTO omezeni (nazev, minimalni, maximalni) VALUES ('délka', 5, 15);

-- Vytvoření hráčů
INSERT INTO hrac (id_hrace, jmeno) VALUES (seq_hrac.nextval, 'Petr');
INSERT INTO hrac (id_hrace, jmeno) VALUES (seq_hrac.nextval, 'Jana');
INSERT INTO hrac (id_hrace, jmeno) VALUES (seq_hrac.nextval, 'Honza');
