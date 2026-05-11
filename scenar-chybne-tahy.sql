set serveroutput on
set linesize 300
set pagesize 1000

variable v_id_hry number
variable v_id_stav number

begin
  select id_stavu
  into :v_id_stav
  from stav
  where nazev = 'rozehraná';

  insert into hra (
    id_hry,
    sirka_papiru,
    vyska_papiru,
    delka_vitezne_rady,
    id_zacin_hrace,
    id_druheho_hrace,
    zacin_hrac_znak,
    druhy_hrac_znak,
    id_stavu
  ) values (
    seq_hra.nextval,
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

begin
  insert into tah (id_tahu, id_hry, id_hrace, pozice_x, pozice_y, poradi_tahu)
  values (seq_tah.nextval, 9999, 1, 1, 1, 1);
exception
  when others then
    dbms_output.put_line('Neexistujici hra: ' || sqlerrm);
end;
/
begin
  insert into tah (id_tahu, id_hry, id_hrace, pozice_x, pozice_y, poradi_tahu)
  values (seq_tah.nextval, :v_id_hry, 3, 1, 1, 1);
exception
  when others then
    dbms_output.put_line('Hrac mimo hru: ' || sqlerrm);
end;
/
insert into tah (id_tahu, id_hry, id_hrace, pozice_x, pozice_y, poradi_tahu)
values (seq_tah.nextval, :v_id_hry, 1, 1, 1, 1);
select cislo_radku, radek from papir where id_hry = :v_id_hry order by cislo_radku;

begin
  insert into tah (id_tahu, id_hry, id_hrace, pozice_x, pozice_y, poradi_tahu)
  values (seq_tah.nextval, :v_id_hry, 1, 2, 1, 2);
exception
  when others then
    dbms_output.put_line('Spatny hrac na tahu: ' || sqlerrm);
end;
/
begin
  insert into tah (id_tahu, id_hry, id_hrace, pozice_x, pozice_y, poradi_tahu)
  values (seq_tah.nextval, :v_id_hry, 2, 2, 2, 3);
exception
  when others then
    dbms_output.put_line('Spatne poradi tahu: ' || sqlerrm);
end;
/
insert into tah (id_tahu, id_hry, id_hrace, pozice_x, pozice_y, poradi_tahu)
values (seq_tah.nextval, :v_id_hry, 2, 1, 2, 2);
select cislo_radku, radek from papir where id_hry = :v_id_hry order by cislo_radku;

begin
  insert into tah (id_tahu, id_hry, id_hrace, pozice_x, pozice_y, poradi_tahu)
  values (seq_tah.nextval, :v_id_hry, 1, 1, 2, 3);
exception
  when others then
    dbms_output.put_line('Obsazena pozice: ' || sqlerrm);
end;
/
insert into tah (id_tahu, id_hry, id_hrace, pozice_x, pozice_y, poradi_tahu)
values (seq_tah.nextval, :v_id_hry, 1, 2, 1, 3);
select cislo_radku, radek from papir where id_hry = :v_id_hry order by cislo_radku;

begin
  insert into tah (id_tahu, id_hry, id_hrace, pozice_x, pozice_y, poradi_tahu)
  values (seq_tah.nextval, :v_id_hry, 2, 6, 1, 4);
exception
  when others then
    dbms_output.put_line('Tah mimo papir: ' || sqlerrm);
end;
/
insert into tah (id_tahu, id_hry, id_hrace, pozice_x, pozice_y, poradi_tahu)
values (seq_tah.nextval, :v_id_hry, 2, 2, 2, 4);
select cislo_radku, radek from papir where id_hry = :v_id_hry order by cislo_radku;

insert into tah (id_tahu, id_hry, id_hrace, pozice_x, pozice_y, poradi_tahu)
values (seq_tah.nextval, :v_id_hry, 1, 3, 1, 5);
select cislo_radku, radek from papir where id_hry = :v_id_hry order by cislo_radku;

insert into tah (id_tahu, id_hry, id_hrace, pozice_x, pozice_y, poradi_tahu)
values (seq_tah.nextval, :v_id_hry, 2, 3, 2, 6);
select cislo_radku, radek from papir where id_hry = :v_id_hry order by cislo_radku;

insert into tah (id_tahu, id_hry, id_hrace, pozice_x, pozice_y, poradi_tahu)
values (seq_tah.nextval, :v_id_hry, 1, 4, 1, 7);
select cislo_radku, radek from papir where id_hry = :v_id_hry order by cislo_radku;

insert into tah (id_tahu, id_hry, id_hrace, pozice_x, pozice_y, poradi_tahu)
values (seq_tah.nextval, :v_id_hry, 2, 4, 2, 8);
select cislo_radku, radek from papir where id_hry = :v_id_hry order by cislo_radku;

insert into tah (id_tahu, id_hry, id_hrace, pozice_x, pozice_y, poradi_tahu)
values (seq_tah.nextval, :v_id_hry, 1, 5, 1, 9);
select cislo_radku, radek from papir where id_hry = :v_id_hry order by cislo_radku;

begin
  insert into tah (id_tahu, id_hry, id_hrace, pozice_x, pozice_y, poradi_tahu)
  values (seq_tah.nextval, :v_id_hry, 2, 5, 2, 10);
exception
  when others then
    dbms_output.put_line('Tah po konci hry: ' || sqlerrm);
end;
/
select * from vyhry_zacinajici;
select * from hra order by id_hry;
select * from hrac order by id_hrace;
