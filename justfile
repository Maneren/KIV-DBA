down:
    podman compose down

up:
    podman compose up

restart:
    podman compose restart

clean:
    podman container rm -f $(podman compose ps -q)

init: (run "vytvor.sql")
destroy: (run "destrukce.sql")

setup: (run "setup.sql")

run file:
    cat < {{ file }} | podman compose exec oracle sqlplus -S oldman/1234@localhost  
