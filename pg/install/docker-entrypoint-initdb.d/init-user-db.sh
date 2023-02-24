#!/bin/sh
set -e

DATABASE=${PG_DATABASE:-lemonldapng}
USER=${PG_USER:-lemonldap}
PASSWORD=${PG_PASSWORD:-lemonldap}
TABLE=${PG_TABLE:-lmConfig}
PTABLE=${PG_PERSISTENT_SESSIONS_TABLE:-sessions}

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
	CREATE UNLOGGED TABLE $PTABLE (
		id varchar(64) not null primary key,
		a_session text
	);
	GRANT ALL PRIVILEGES ON TABLE $PTABLE TO $USER;
EOSQL

if test -e /llng-conf/conf.json; then
	SERIALIZED=`perl -MJSON -e '$/=undef;
		open F, "/llng-conf/conf.json" or die $!;
		$a=JSON::from_json(<F>);
		$a->{cfgNum}=1;
		$a=JSON::to_json($a);
		$a=~s/'\''/'\'\''/g;
		$a =~ s/\\\\/\\\\\\\\/g;
		print $a;'`
	echo "set val '$SERIALIZED'" >&2
	psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$DATABASE" <<-EOSQL
	\\set val '$SERIALIZED'
	INSERT INTO $TABLE (cfgNum, data) VALUES (1, :'val');
	SELECT * FROM $TABLE;
	\\unset val
EOSQL
fi
