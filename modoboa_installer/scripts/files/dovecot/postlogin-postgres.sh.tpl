#!/bin/sh
# Postlogin script - updates last_login timestamp in Modoboa
# Supports both local (Unix socket) and external (TCP) PostgreSQL

PATH="/usr/bin:/usr/local/bin:/bin"

# Database connection parameters (substituted from installer config)
export PGHOST="%dbhost"
export PGPORT="%dbport"
export PGUSER="%modoboa_dbuser"
export PGDATABASE="%modoboa_dbname"
export PGPASSWORD="%modoboa_dbpassword"

# Update last login time (ignore errors to not block mail delivery)
psql -c "UPDATE core_user SET last_login=now() WHERE username='$USER'" > /dev/null 2>&1 || true

exec "$@"
