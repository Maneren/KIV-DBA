set serveroutput on
set linesize 220
set pagesize 1000

variable v_id_hry number
variable v_id_stav number

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
    zacin_hrac_znak,
    druhy_hrac_znak,
    id_stavu
  ) values (
    5,
    5,
    5,
    1,
    2,
    'X',
    'O',
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

-- tah po konci hry
-- insert into tah (id_hry, id_hrace, pozice_x, pozice_y, poradi_tahu)
-- values (:v_id_hry, 2, 5, 2, 10);
-- select radek from papir where id_hry = :v_id_hry order by cislo_radku;

select * from vyhry_zacinajici;
select * from hra order by id_hry;
select * from hrac order by id_hrace;
