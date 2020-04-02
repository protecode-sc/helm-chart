# Black Duck Binary Analysis Helm chart

This chart bootstraps Black Duck Binary Analysis deployment on a Kubernetes cluster
using the Helm package manager.

## Prerequisites

Before starting, you will need:

  * A Kubernetes cluster with:
    * storageClass that allows persistent volumes configured.
    * NGINX Ingress Controller.
    * The cluster should have enough memory, preferably at least 16 gigabytes.
      A good entry level deployment, for example, would be two n1-standard
      nodes on GCP.
  * Helm 3

## Download chart dependencies

To download the chart dependencies, which include **postgresql**, **minio**, **memcached**, and **rabbitmq**:

```console
$ helm dependency update
Hang tight while we grab the latest from your chart repositories...
...Successfully got an update from the "stable" chart repository
Update Complete. ⎈Happy Helming!⎈
Saving 4 charts
Downloading postgresql from repo https://kubernetes-charts.storage.googleapis.com/
Downloading minio from repo https://kubernetes-charts.storage.googleapis.com/
Downloading memcached from repo https://kubernetes-charts.storage.googleapis.com/
Downloading rabbitmq from repo https://kubernetes-charts.storage.googleapis.com/
Deleting outdated charts
```

## Installing the chart

To install the chart with the release name `testing`:

```console
$ helm upgrade testing . --install --namespace bdba
Release "testing" does not exist. Installing it now.
NAME: testing
LAST DEPLOYED: Sun Feb 16 10:50:15 2020
NAMESPACE: bdba
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
1. Get the application URL by running these commands:
```


## Configuration

This section shows an example of how you can configure a Black Duck Binary Analysis instance. It's split into multiple
sections for clarity.

### Secrets for services

Black Duck Binary Analysis Helm chart uses PostgreSQL. Secrets for other services are automatically provisioned,
but for PostgreSQL you need to enter the password manually.


#### PostgreSQL secrets

If you use a bundled PostgreSQL database, it is recommended to configure a password
for PostgreSQL. During the initial installation, a PostgreSQL database is created with that specific
password, and you cannot change it afterward.

You can configure a password either with the `--set postgresql.postgresqlPassword="PASSWORD"` parameter or by using
existing secrets. To create a random password and use that, do the following before installing:

```console
$ kubectl create secret generic bdba-postgresql-secret -n NAMESPACE --from-literal=postgresql-password=<12 randon characters>
secret/bdba-postgresql-secret created
```

Next, add the created secret to Helm

`--set global.postgresql.existingSecret="bdba-postgresql-secret"`

This ensures that the PostgreSQL secret survives upgrades.

#### Summary

Parameter                                  | Description                                           | Default
------------------------------------------ | ----------------------------------------------------- | -----------------
`postgresql.postgresqlPassword`            | Password for PostgreSQL.                              | "CHANGEME"
`global.postgresql.existingSecret`         | Existing secret name that holds `postgresql-password`.| nil

### Storage

Black Duck Binary Analysis requires storage. It can support either existing PVC claims or automatically
provision volumes if `storageClass` is provided.

Parameter                              | Description                          | Default
-------------------------------------- | ------------------------------------ | -----------------------
`postgresql.persistence.storageClass`  | storageClass for PostgreSQL.         | ""
`postgresql.persistence.size`          | Size of PostgreSQL claim.            | 300Gi
`postgresql.persistence.existingClaim` | Existing claim to use for PostgreSQL.| ""
`minio.persistence.storageClass`       | storageClass for MinIO.              | ""
`minio.persistence.size`               | Size of MinIO claim.                 | 300Gi
`minio.persistence.existingClaim`      | Existing claim to use for MinIO.     | ""
`rabbitmq.persistence.storageClass`    | storageClass for RabbitMQ.           | ""
`rabbitmq.persistence.size`            | Size of RabbitMQ claim.              | 8Gi
`rabbitmq.persistence.existingClaim`   | Existing claim to use for RabbitMQ.  | ""

### Licensing

To access the data that Black Duck Binary Analysis needs a username and password for the licensing server are required.
Without these, the installation will not function.

Parameter                     | Description                      | Default
----------------------------- | -------------------------------- |------------------------
`frontend.licensing.username` | Username for licensing server.   | ""
`frontend.licensing.password` | Password for licensing server.   | ""
`frontend.licensing.upstream` | Upstream server for data updates.| "https://protecode-sc.com"

### RabbitMQ configuration

RabbitMQ requires to know the cluster's domain name. If it is not `cluster.local`,
you need to provide it.

Parameter                                 | Description                 | Default
----------------------------------------- | --------------------------- | ----------------
`rabbitmq.rabbitmq.clustering.k8s_domain` | Internal k8s cluster domain.| cluster.local

### Web frontend configuration

Generic configuration options for customization of frontend behavior.

Parameter                       | Description                             | Default
------------------------------- | --------------------------------------- |------------------------
`frontend.web.secretKey`        | Secret key for web application.         | 50 random characters
`frontend.web.sessionCookieAge` | Session cookie age.                     | "1209600"
`frontend.web.replicas`         | Number of frontend instances.           | 1
`frontend.web.hideLicenses`     | Hide licensing information from scan.   | false
`frontend.web.offlineMode`      | Do not make network request to internet | false
`frontend.web.admin`            | Administrator user's email address.     | "admin@bdba.local"
`frontend.web.erroradmin`       | Error report email receiver.            | ""
`frontend.web.rootURL`          | Root URL of web service for emails.     | "http://bdba.local"

### SMTP configuration

Black Duck Binary Analysis can send emails, for example, to invite new users or to send vulnerability
notifications.

Parameter                     | Description                                       | Default
----------------------------- | ------------------------------------------------- | -----------------------
`frontend.email.enabled`      | Enable sending email.                             | false
`frontend.email.smtpHost`     | Email SMTP host.                                  | ""
`frontend.email.smtpPort`     | Email SMTP port.                                  | "25"
`frontend.email.smtpUser`     | Email SMTP hostname.                              | ""
`frontend.email.smtpPassword` | Email SMTP password.                              | ""
`frontend.email.from`         | Sender of email.                                  | "noreply@protecode-sc.local"
`frontend.email.security`     | Email security mode. "none", "ssl", or "starttls".| "none"
`frontend.email.verify`       | Verify email certificate.                         | "false"

### LDAP Authentication

Black Duck Binary Analysis can authenticate against LDAP servers.

Parameter                            | Description                             | Default
------------------------------------ | ----------------------------------------|------------------------
`frontend.ldap.enabled`              | Enable LDAP authentication.             | false
`frontend.ldap.serverUri`            | LDAP server URI.                        | ""
`frontend.ldap.userDNTemplate`       | LDAP DN template for user.              | ""
`frontend.ldap.bindAsAuthenticating` | Bind as authenticating user.            | "true"
`frontend.ldap.bindDN`               | LDAP bind DN (generic bind, optional).  | nil
`frontend.ldap.bindPassword`         | LDAP bind password (generic bind).      | nil
`frontend.ldap.startTLS`             | User STARTTLS for securing LDAP.        | "false"
`frontend.ldap.verify`               | Verify LDAP server certificate.         | "false"
`frontend.ldap.rootCASecret`         | Secret for LDAP root certificate.       | nil
`frontend.ldap.requireGroup`         | LDAP group required for access.         | nil
`frontend.ldap.userSearch`           | LDAP user search DN template.           | nil
`frontend.ldap.userSearchScope`      | LDAP user search scope.                 | nil
`frontend.ldap.groupSearch`          | LDAP group search DN template.          | nil
`frontend.ldap.groupSearchScope`     | LDAP group search scope.                | nil
`frontend.ldap.nestedSearch`         | User nested group search.               | "false"

To setup root certificate for LDAP, issues:

```console
$ kubectl create secret generic bdba-ldap-root --from-file=~/root-ca/ca.pem
secret/bdba-ldap-root created
```

To use this as the root certificate, add `--set frontend.ldap.rootCASecret=bdba-ldap-root` to the Helm command line.

### Logging

Black Duck Binary Analysis uses Fluentd to centrally log. Relevant application pods are joined by
a Fluent Bit sidecar.

Parameter                     | Description                                | Default
----------------------------- | ------------------------------------------ | ---------------
`frontend.applicationLogging` | Enable application logging for webapp pods.| true
`worker.applicationLogging`   | Enable application logging for worker pods.| true

### Worker scaling

Parameter            | Description                                   | Default
-------------------- | ----------------------------------------------|------------------------
`worker.replicas`    | Number of scanner instances.                  | 1
`worker.concurrency` | Number of concurrent scanners in scanner pods.| 1

### Networking and security

Parameter       | Description                   | Default
--------------- | ----------------------------- | -----------------------
`rootCASecret`  | Kubernetes secret for root CA.| ""
`httpProxy`     | Proxy URL.                    | nil
`httpNoProxy`   | No proxy list.                | nil

### External PostgreSQL

Black Duck Binary Analysis supports external PostgreSQL. Black Duck Binary Analysis is tested against PostgreSQL 9.6 and 11. There
are no specific version restrictions as long as it is 9.6 or newer.

To configure external PostgreSQL, the following parameters are supported. To omit
installing PostgreSQL and use external instead, specify:

 `--set postgresql.enabled=false`.

Parameter                              | Description                                | Default
-------------------------------------- | ------------------------------------------ | -------
`frontend.database.postgresqlHost`     | Hostname of external PostgreSQL.           | nil
`frontend.database.postgresqlPort`     | Port of external PostgreSQL.               | "5432"
`frontend.database.postgresqlDatabase` | Database name of external PostgreSQL.      | nil
`frontend.database.postgresqlUsername` | Username in external PostgreSQL.           | nil
`frontend.database.postgresqlPassword` | Password in external PostgreSQL.           | nil
`frontend.database.postgresqlSslMode`  | SSL mode for connecting.                   | nil
`frontend.database.clientSecretName`   | Name of TLS secret for client keypair.     | nil
`frontend.database.rootCASecretName`   | Name of generic secret for CA certificate. | nil

To inject a CA secret, use the following. rootCASecretName will be named `bdba-pgroot`.

```console
$ kubectl create secret generic bdba-pgroot --from-file=ca.pem
secret/bdba-pgroot created
```

To inject a client keypair, use the following. clientSecretName will be named `bdba-pgclient`.

```console
$ kubectl create secret tls bdba-pgclient --key key.pem --cert cert.pem
secret/bdba-pgclient created
```

Possible values from postgresqlSslMode are specified in https://www.postgresql.org/docs/11/libpq-ssl.html.

### Ingress

Parameter                | Description                  | Default
------------------------ | ---------------------------- | --------------------
`ingress.enabled`        | Enable ingress.              | true
`ingress.host`           | Hostname for ingress.        | "bdba.local"
`ingress.tls.enabled`    | Enable TLS.                  | false
`ingress.tls.secretName` | TLS secret for certificate.  | bdba-tls

To create a TLS secret, invoke:

```console
$ kubectl create secret tls bdba-tls --key key.pem --cert cert.pem
secret/bdba-tls created
```

### Configuring

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`. For example:

```console
$ helm upgrade testing . --install \
   --set frontend.licensing.username="foo@example.com" \
   --set frontend.licensing.password="secret" .
```

Alternatively, a YAML file that specifies the values for the parameters can be provided while installing the chart. For example:

```console
$ helm upgrade testing . --install -f my-values.yaml
#
```

### Examples

Examples, with inline documentation, are provided in the `examples` directory.

## Secrets

Key material can be saved to Kubernetes using kubectl. To set up additional root certificates,
you can set them as Kubernetes secrets. PEM encoding is assumed.

```console
$ kubectl create secret generic bdba-root --from-file=~/root-ca/ca.pem
secret/bdba-root created
```

To use this as the root certificate, add `--set rootCASecret=bdba-root` to the Helm command line.

## Migration from an existing appliance

To migrate data from an existing VM-based appliance, backup API of the appliance
can be used to perform data acquisition.

### Acquiring backup

First, run:

```console
$ curl -X POST -u admin "https://<APPLIANCE>/api/backup/"
```

Next, Query until the backup is ready.

```console
$ curl -X POST -u admin "https://<APPLIANCE>/api/backup/"|jq
{
  "meta": {
    "code": 200
  },
  "backup": {
    "status": "R",
    "started": "2019-12-03T13:02:12",
    "completed": "2019-12-03T13:03:17",
    "location": "/api/backup/appliance-NNNNN.pgdump",
    "sha1sum": "684cd634b35d26dfeb1ab8c5e9b399619126c176"
  }
}

```

Once it is ready, get the "location" from the response and download the database dump.

```console
$ curl -o backup.pgdump.tar -u admin "http://<APPLIANCE>/api/backup/appliance-NNNNN.pgdump"
```

Backup is in fact a tar archive, containing just backup.pgdump. Extract it.

```console
$ tar xvf backup.pgdump
x database.pgdump
```

### Stopping services accessing the database

Next, you need to stop deployments that access the database. These deployments are:

  * NAME-bdba-tasks
  * NAME-bdba-tasks-long
  * NAME-bdba-updater
  * NAME-bdba-webapp

Invoke the following commands:

```console
$ kubectl scale --replicas=0 deployment/NAME-bdba-tasks
$ kubectl scale --replicas=0 deployment/NAME-bdba-tasks-long
$ kubectl scale --replicas=0 deployment/NAME-bdba-updater
$ kubectl scale --replicas=0 deployment/NAME-bdba-webapp
```

### Overwriting the database with a backup

Copy the database dump to the PostgreSQL pod.

```console
$ kubectl cp database.pgdump dev/NS-postgresql-0:/tmp
```

### Preparing the database for pg_restore

As Black Duck Binary Analysis populates the database, it is required to clean up tables found in the
database before it can be restored.

Kubectl into the database container and run:

```console
$ kubectl exec -it -n dev hayrynen1-postgresql-0 bash
```

In the PostgreSQL pod, enter the interactive PostgreSQL shell and execute:

```console
$ psql -h localhost -U <database-username> -W -d <database-name>
```

In the interactive db shell, run:

```sql
DO $$ DECLARE
    r RECORD;
BEGIN
    FOR r IN (SELECT tablename FROM pg_tables WHERE schemaname = 'public') LOOP
        EXECUTE 'DROP TABLE IF EXISTS ' || quote_ident(r.tablename) || ' CASCADE';
    END LOOP;
END $$;
```

This will empty the database, but authentication credentials are kept intact.

Exit the db shell with `^D` to proceed.

### Restoring the database

Next, restore the database. In the PostgreSQL pod, execute:

```console
$ pg_restore -c -C -Fc -h localhost -U <database-username> -d <database-name> -n public </tmp/database.pgdump
```

### Restoring the services

Next, restore the services:

```console
$ kubectl scale --replicas=1 deployment/NAME-bdba-tasks
$ kubectl scale --replicas=1 deployment/NAME-bdba-tasks-long
$ kubectl scale --replicas=1 deployment/NAME-bdba-updater
$ kubectl scale --replicas=N deployment/NAME-bdba-webapp
```

Now, you should be all set.
