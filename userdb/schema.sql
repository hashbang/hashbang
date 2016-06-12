-- -*- mode: sql; product: postgres -*-

-- hosts table
CREATE SEQUENCE host_id MINVALUE    0 MAXVALUE 2147483647 NO CYCLE;

CREATE TABLE "hosts" (
  "id" integer PRIMARY KEY MINVALUE 0 DEFAULT nextval('host_id'),
  "name" varchar(10) UNIQUE NOT NULL,
  "data" jsonb -- extra data added in the stats answer
)


-- data for NSS' passwd
-- there is an implicit primary group for each user
CREATE SEQUENCE user_id MINVALUE 4000 MAXVALUE 2147483647 NO CYCLE;

CREATE DOMAIN username_t varchar(64) CHECK (
  VALUE ~ '^[a-z][a-z0-9]+$'
);

CREATE TABLE "passwd" (
  "uid" integer PRIMARY KEY MINVALUE 1000 DEFAULT nextval('user_id'),
  "name" username_t UNIQUE NOT NULL,
  "host" integer NOT NULL REFERENCES hosts (id),
  "homedir" varchar(256) NOT NULL,
  "data" jsonb
);

-- auxiliary groups
CREATE TABLE "group" (
  "gid" integer PRIMARY KEY MAXVALUE 999,
  "name" username_t UNIQUE NOT NULL,
);

CREATE TABLE "aux_groups" (
  "uid" int4 NOT NULL REFERENCES passwd (uid) ON DELETE CASCADE,
  "gid" int4 NOT NULL REFERENCES group  (gid) ON DELETE CASCADE,
  PRIMARY KEY ("uid", "gid"),
);
