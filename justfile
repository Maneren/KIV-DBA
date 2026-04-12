down:
    podman compose down

up:
    podman compose up

restart:
    podman compose restart

clean:
    podman container rm -f $(podman compose ps -q)

init:
    podman compose exec oracle sqlplus -S oldman/1234@localhost < vytvor.sql

destroy:
    podman compose exec oracle sqlplus -S oldman/1234@localhost < destrukce.sql

setup:
    podman compose exec oracle sqlplus -S sysdba/1234@localhost < setup.sql
