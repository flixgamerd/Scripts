#!/usr/bin/env zsh
# pgcreate.zsh — PostgreSQL database provisioning script
# Usage: ./pgcreate.zsh --db <n> [options]

setopt errexit nounset pipefail

# ─── colours ──────────────────────────────────────────────────────────────────
autoload -U colors && colors
info()    { print -P "%F{cyan}[INFO]%f  $*" }
success() { print -P "%F{green}[OK]%f    $*" }
warn()    { print -P "%F{yellow}[WARN]%f  $*" >&2 }
die()     { print -P "%F{red}[ERROR]%f $*" >&2; exit 1 }

# ─── defaults ─────────────────────────────────────────────────────────────────
DB_NAME=""
DB_USER=""
DB_HOST="localhost"
DB_PORT="5432"
PG_SUPERUSER="postgres"
SCHEMA_FILE=""
NO_USER=false
DRY_RUN=false
CREATE_USER=true
DROP_MODE=false
DROP_ROLE=false

# ─── argument parsing ─────────────────────────────────────────────────────────
while (( $# )); do
  case $1 in
    --db)        DB_NAME=$2;      shift 2 ;;
    --user)      DB_USER=$2;      shift 2 ;;
    --host)      DB_HOST=$2;      shift 2 ;;
    --port)      DB_PORT=$2;      shift 2 ;;
    --superuser) PG_SUPERUSER=$2; shift 2 ;;
    --schema)    SCHEMA_FILE=$2;  shift 2 ;;
    --no-user)   NO_USER=true;    shift   ;;
    --dry-run)   DRY_RUN=true;    shift   ;;
    --drop)      DROP_MODE=true;  shift   ;;
    --drop-role) DROP_ROLE=true;  shift   ;;
    --help|-h)
      print "Usage: $0 --db <n> [--user <user>]"
      print "          [--host <host>] [--port <port>] [--superuser <role>]"
      print "          [--schema <file.sql>] [--no-user] [--dry-run]"
      print "          [--drop] [--drop-role]"
      print ""
      print "  --drop        Drop the database (termina conexões activas primeiro)"
      print "  --drop-role   Drop também o role associado (usar com --drop)"
      exit 0
      ;;
    *) die "Unknown option: $1" ;;
  esac
done

# ─── validation ───────────────────────────────────────────────────────────────
[[ -z $DB_NAME ]] && die "--db <n> is required."

if $NO_USER; then
  CREATE_USER=false
else
  [[ -z $DB_USER ]] && DB_USER=$DB_NAME
fi

if [[ -n $SCHEMA_FILE && ! -f $SCHEMA_FILE ]]; then
  die "Schema file not found: $SCHEMA_FILE"
fi

# ─── psql runner ──────────────────────────────────────────────────────────────
run_sql() {
  local sql=$1
  local dbname=${2:-postgres}

  if $DRY_RUN; then
    print -P "%F{magenta}[DRY-RUN]%f $sql"
    return 0
  fi

  psql \
    --host="$DB_HOST" \
    --port="$DB_PORT" \
    --username="$PG_SUPERUSER" \
    --dbname="$dbname" \
    --tuples-only \
    --no-align \
    --command="$sql" 2>&1
}

run_file() {
  local file=$1
  local dbname=$2

  if $DRY_RUN; then
    print -P "%F{magenta}[DRY-RUN]%f \\i $file (on database $dbname)"
    return 0
  fi

  psql \
    --host="$DB_HOST" \
    --port="$DB_PORT" \
    --username="$PG_SUPERUSER" \
    --dbname="$dbname" \
    --file="$file"
}

# ─── connectivity check ───────────────────────────────────────────────────────
if ! $DRY_RUN; then
  info "Testing connection to $DB_HOST:$DB_PORT as $PG_SUPERUSER..."
  if ! psql \
        --host="$DB_HOST" --port="$DB_PORT" \
        --username="$PG_SUPERUSER" --dbname="postgres" \
        --command="\q" &>/dev/null; then
    die "Cannot connect to PostgreSQL at $DB_HOST:$DB_PORT as $PG_SUPERUSER."
  fi
  success "Connection established."
fi

# ══════════════════════════════════════════════════════════════════════════════
# ─── DROP MODE ────────────────────────────────────────────────────────────────
# ══════════════════════════════════════════════════════════════════════════════
if $DROP_MODE; then
  # confirmar
  if ! $DRY_RUN; then
    print -P "%F{yellow}[WARN]%f  Prestes a apagar o banco '$DB_NAME'. Confirmar? [s/N] " && read -r confirm
    [[ $confirm != [sS] ]] && die "Operação cancelada."
  fi

  info "Terminando conexões activas em '$DB_NAME'..."
  run_sql "SELECT pg_terminate_backend(pid)
           FROM pg_stat_activity
           WHERE datname = '$DB_NAME' AND pid <> pg_backend_pid();"

  info "Dropping database '$DB_NAME'..."
  run_sql "DROP DATABASE IF EXISTS \"$DB_NAME\";"
  success "Database '$DB_NAME' removido."

  if $DROP_ROLE; then
    info "Dropping role '$DB_USER'..."
    run_sql "DROP ROLE IF EXISTS \"$DB_USER\";"
    success "Role '$DB_USER' removido."
  fi

  print ""
  print -P "%F{yellow}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%f"
  print -P "%F{yellow}  Drop concluído%f"
  print -P "%F{yellow}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%f"
  print "  Database removido : $DB_NAME"
  $DROP_ROLE && print "  Role removido     : $DB_USER"
  print -P "%F{yellow}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%f"
  exit 0
fi

# ══════════════════════════════════════════════════════════════════════════════
# ─── CREATE MODE ──────────────────────────────────────────────────────────────
# ══════════════════════════════════════════════════════════════════════════════

# ─── check if database already exists ─────────────────────────────────────────
if ! $DRY_RUN; then
  local existing
  existing=$(psql \
    --host="$DB_HOST" --port="$DB_PORT" \
    --username="$PG_SUPERUSER" --dbname="postgres" \
    --tuples-only --no-align \
    --command="SELECT 1 FROM pg_database WHERE datname = '$DB_NAME';" 2>/dev/null)

  if [[ $existing == "1" ]]; then
    die "Database '$DB_NAME' already exists. Aborting."
  fi
fi

# ─── step 1: create role ──────────────────────────────────────────────────────
if $CREATE_USER; then
  info "Creating role '$DB_USER'..."

  run_sql "DO \$\$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '$DB_USER') THEN
    CREATE ROLE \"$DB_USER\" WITH LOGIN;
  ELSE
    RAISE NOTICE 'Role % already exists — skipping creation.', '$DB_USER';
  END IF;
END
\$\$;"

  success "Role '$DB_USER' ready."
fi

# ─── step 2: create database ──────────────────────────────────────────────────
info "Creating database '$DB_NAME'..."

if $CREATE_USER; then
  run_sql "CREATE DATABASE \"$DB_NAME\" OWNER \"$DB_USER\" ENCODING 'UTF8' LC_COLLATE 'C.UTF-8' LC_CTYPE 'C.UTF-8' TEMPLATE template0;"
else
  run_sql "CREATE DATABASE \"$DB_NAME\" ENCODING 'UTF8' LC_COLLATE 'C.UTF-8' LC_CTYPE 'C.UTF-8' TEMPLATE template0;"
fi

success "Database '$DB_NAME' created."

# ─── step 3: revoke default public access ─────────────────────────────────────
info "Hardening public schema permissions..."
run_sql "REVOKE ALL ON DATABASE \"$DB_NAME\" FROM PUBLIC;"
run_sql "REVOKE ALL ON SCHEMA public FROM PUBLIC;" "$DB_NAME"

if $CREATE_USER; then
  run_sql "GRANT ALL PRIVILEGES ON DATABASE \"$DB_NAME\" TO \"$DB_USER\";"
  run_sql "GRANT ALL ON SCHEMA public TO \"$DB_USER\";" "$DB_NAME"
fi

success "Permissions configured."

# ─── step 4: apply schema file ────────────────────────────────────────────────
if [[ -n $SCHEMA_FILE ]]; then
  info "Applying schema from '$SCHEMA_FILE'..."
  run_file "$SCHEMA_FILE" "$DB_NAME"
  success "Schema applied."
fi

# ─── summary ──────────────────────────────────────────────────────────────────
print ""
print -P "%F{green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%f"
print -P "%F{green}  Database provisioned successfully%f"
print -P "%F{green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%f"
print "  Database : $DB_NAME"
print "  Host     : $DB_HOST:$DB_PORT"

if $CREATE_USER; then
  print "  User     : $DB_USER"
  print ""
  print "  Connection string (URI):"
  print "  postgresql://$DB_USER@$DB_HOST:$DB_PORT/$DB_NAME"
  print ""
  print "  .env:"
  print "  DATABASE_URL=postgresql://$DB_USER@$DB_HOST:$DB_PORT/$DB_NAME"
else
  print ""
  print "  Connection string (URI):"
  print "  postgresql://$PG_SUPERUSER@$DB_HOST:$DB_PORT/$DB_NAME"
fi

print -P "%F{green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%f"
