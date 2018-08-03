#!/bin/bash

: ${PGSQL_IP:=*}

function init_pgsql_db {


su postgres -c '/usr/pgsql-10/bin/pg_ctl start -D /var/lib/pgsql/10/data'
su postgres <<'EOF'
psql --command "CREATE USER openattic WITH SUPERUSER PASSWORD 'openattic';"
createdb -O openattic openattic
EOF
su postgres -c '/usr/pgsql-10/bin/pg_ctl stop -D /var/lib/pgsql/10/data'

sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" \
       /var/lib/pgsql/10/data/postgresql.conf
echo "host all  all    0.0.0.0/0  md5" >> /var/lib/pgsql/10/data/pg_hba.conf
}

function start_pgsql_db {
  su postgres -c '/usr/pgsql-10/bin/pg_ctl start -D /var/lib/pgsql/10/data'

  PG_PID=`pgrep postgres | head -1`
  while [ -e /proc/${PG_PID} ]; do sleep 2;done
}

case "$1" in
  init_db)
    init_pgsql_db
    ;;
  start_db | *)
    start_pgsql_db
    ;;
esac

