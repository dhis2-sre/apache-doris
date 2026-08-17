# Apache Doris with the PostgreSQL JDBC driver

Publishes [`dhis2/apache-doris`](https://hub.docker.com/r/dhis2/apache-doris), which is the upstream
[`apache/doris`](https://hub.docker.com/r/apache/doris) image with the PostgreSQL JDBC driver already
in place.

## Why

Doris reads an external PostgreSQL database through a JDBC catalog, and that needs the driver on both
the frontend and the backend. The image does not ship one, and the alternatives are worse than
deriving an image:

- A `ConfigMap` or `Secret` cannot carry it. The driver is 1.04 MiB and the limit is 1 MiB.
- The `DorisCluster` custom resource has no `initContainers`, and the init container it does support,
  `systemInitialization`, mounts no volumes, so it has nowhere to stage a file the Doris container
  can read.
- Doris can fetch a driver from a URL at catalog creation, which moves a download into the deploy
  path and makes it depend on a third party being up.

Baking it in keeps deploys offline-safe and pins the driver by checksum. This mirrors
[bitnami-postgresql-curl](https://github.com/dhis2-sre/bitnami-postgresql-curl), which exists for the
same reason.

## Tags

`<tier>-<doris version>-postgres`, for example `fe-2.1.11-postgres` and `be-2.1.11-postgres`, so a tag
names the image it derives from and what was added.

## Usage

The tier images go in the matching parts of a `DorisCluster`:

```yaml
spec:
  feSpec:
    image: dhis2/apache-doris:fe-2.1.11-postgres
  beSpec:
    image: dhis2/apache-doris:be-2.1.11-postgres
```

The driver lands in Doris's own `jdbc_drivers` directory under a stable name, so a catalog refers to
it by file name and the version stays in the image tag:

```sql
CREATE CATALOG dhis2 PROPERTIES (
    "type" = "jdbc",
    "user" = "dhis",
    "password" = "...",
    "jdbc_url" = "jdbc:postgresql://<host>:5432/dhis2",
    "driver_url" = "postgresql.jar",
    "driver_class" = "org.postgresql.Driver"
);
```

## Adding a version

Add it to `versions.yaml`, keeping the list in descending order. Every version is built for every
tier listed there. The driver version and its checksum live in the same file; changing one without
the other fails the build, which is the point.
