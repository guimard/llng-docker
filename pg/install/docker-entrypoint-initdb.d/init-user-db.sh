#!/bin/bash
set -e

DATABASE=${PG_DATABASE:-lemonldapng}
USER=${PG_USER:-lemonldap}
PASSWORD=${PG_PASSWORD:-lemonldap}
TABLE=${PG_TABLE:-lmConfig}

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
	CREATE USER $USER PASSWORD '$PASSWORD';
	CREATE DATABASE $DATABASE;
EOSQL
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$DATABASE" <<-EOSQL
	CREATE TABLE $TABLE (
		cfgNum integer not null primary key,
		data text
	);
	GRANT ALL PRIVILEGES ON TABLE $TABLE TO $USER;
EOSQL
