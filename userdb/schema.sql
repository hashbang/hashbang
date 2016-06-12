-- -*- mode: sql; product: postgres -*-

-- hosts table
CREATE TABLE "hosts" (
  "id" serial PRIMARY KEY,
  "name" text UNIQUE NOT NULL,
  "data" jsonb -- extra data added in the stats answer
               -- conforms to the host_data.yaml schema
)


-- data for NSS' passwd
-- there is an implicit primary group for each user
CREATE SEQUENCE user_id MINVALUE 4000 MAXVALUE 2147483647 NO CYCLE;

CREATE DOMAIN username_t varchar(31) CHECK (
  VALUE ~ '^[a-z][a-z0-9]+$'
);

CREATE TABLE "passwd" (
  "uid" integer PRIMARY KEY MINVALUE 1000 DEFAULT nextval('user_id'),
  "name" username_t UNIQUE NOT NULL,
  "host" integer NOT NULL REFERENCES hosts (id),
  "homedir" text NOT NULL,
  "data" jsonb  -- conforms to the user_data.yaml schema
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
