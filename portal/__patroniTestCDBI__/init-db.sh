#!/bin/bash
set -e

# Création de l'utilisateur et de la base de données LemonLDAP::NG
psql -U postgres <<-EOSQL
    CREATE USER lemonldap PASSWORD 'lemonldap';
    CREATE DATABASE lemonldapng OWNER lemonldap;
EOSQL

# Création des tables dans la base lemonldapng
psql -U postgres -d lemonldapng <<-EOSQL
    CREATE TABLE lmConfig (
        cfgNum integer not null primary key,
        data text
    );
    GRANT ALL PRIVILEGES ON TABLE lmConfig TO lemonldap;

    CREATE TABLE psessions (
        id varchar(64) not null primary key,
        a_session jsonb
    );
    CREATE INDEX i_p__session_kind    ON psessions ((a_session ->> '_session_kind'));
    CREATE INDEX i_p__httpSessionType ON psessions ((a_session ->> '_httpSessionType'));
    CREATE INDEX i_p__session_uid     ON psessions ((a_session ->> '_session_uid'));
    CREATE INDEX i_p_ipAddr           ON psessions ((a_session ->> 'ipAddr'));
    CREATE INDEX i_p__whatToTrace     ON psessions ((a_session ->> '_whatToTrace'));
    GRANT ALL PRIVILEGES ON TABLE psessions TO lemonldap;

    CREATE UNLOGGED TABLE sessions (
        id varchar(64) not null primary key,
        a_session jsonb
    );
    CREATE INDEX i_s__whatToTrace     ON sessions ((a_session ->> '_whatToTrace'));
    CREATE INDEX i_s__session_kind    ON sessions ((a_session ->> '_session_kind'));
    CREATE INDEX i_s__utime           ON sessions ((cast (a_session ->> '_utime' as bigint)));
    CREATE INDEX i_s_ipAddr           ON sessions ((a_session ->> 'ipAddr'));
    CREATE INDEX i_s__httpSessionType ON sessions ((a_session ->> '_httpSessionType'));
    CREATE INDEX i_s_user             ON sessions ((a_session ->> 'user'));
    GRANT ALL PRIVILEGES ON TABLE sessions TO lemonldap;

    CREATE UNLOGGED TABLE samlsessions (
        id varchar(64) not null primary key,
        a_session jsonb
    );
    CREATE INDEX i_a__session_kind ON samlsessions ((a_session ->> '_session_kind'));
    CREATE INDEX i_a__utime        ON samlsessions ((cast(a_session ->> '_utime' as bigint)));
    CREATE INDEX i_a_ProxyID       ON samlsessions ((a_session ->> 'ProxyID'));
    CREATE INDEX i_a__nameID       ON samlsessions ((a_session ->> '_nameID'));
    CREATE INDEX i_a__assert_id    ON samlsessions ((a_session ->> '_assert_id'));
    CREATE INDEX i_a__art_id       ON samlsessions ((a_session ->> '_art_id'));
    CREATE INDEX i_a__saml_id      ON samlsessions ((a_session ->> '_saml_id'));
    GRANT ALL PRIVILEGES ON TABLE samlsessions TO lemonldap;

    CREATE UNLOGGED TABLE oidcsessions (
        id varchar(64) not null primary key,
        a_session jsonb
    );
    CREATE INDEX i_o__session_kind ON oidcsessions ((a_session ->> '_session_kind'));
    CREATE INDEX i_o__utime        ON oidcsessions ((cast(a_session ->> '_utime' as bigint)));
    GRANT ALL PRIVILEGES ON TABLE oidcsessions TO lemonldap;

    CREATE UNLOGGED TABLE cassessions (
        id varchar(64) not null primary key,
        a_session jsonb
    );
    CREATE INDEX i_c__session_kind ON cassessions ((a_session ->> '_session_kind'));
    CREATE INDEX i_c__utime        ON cassessions ((cast(a_session ->> '_utime' as bigint)));
    CREATE INDEX i_c__cas_id       ON cassessions ((a_session ->> '_cas_id'));
    CREATE INDEX i_c_pgtIou        ON cassessions ((a_session ->> 'pgtIou'));
    GRANT ALL PRIVILEGES ON TABLE cassessions TO lemonldap;
EOSQL
