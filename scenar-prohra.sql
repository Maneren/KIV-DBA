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
values (:v_id_hry, 1, 5, 3, 9);
select radek from papir where id_hry = :v_id_hry order by cislo_radku;

insert into tah (id_hry, id_hrace, pozice_x, pozice_y, poradi_tahu)
values (:v_id_hry, 2, 5, 2, 10);
select radek from papir where id_hry = :v_id_hry order by cislo_radku;

select * from vyhry_zacinajici;
select * from hra order by id_hry;
select * from hrac order by id_hrace;
