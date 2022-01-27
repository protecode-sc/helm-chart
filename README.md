# Black Duck Binary Analysis on Kubernetes

You can deploy Black Duck Binary Analysis on a Kubernetes cluster either by using the synopsysctl CLI
(command-line interface) or by using the Helm package manager.

## Changes

### 2021.12.0 -> 2021.12.1

* Initial Openshift support

### 2021.9.0 -> 2021.12.0

* Minio is now optional, and there is support for native S3 support or any other
  S3 compatible object storage. See below for more information.
* Helm chart no longer depends on helm.min.io -chart, which was deprecated and archived. Supplied
  minio installation is bare bones, and if you require more advanced minio features,
  use official chart and use minio as external S3 compatible object storage.

### 2021.06 -> 2021.9.0

* Added support for Kubernetes v1.22 and higher
* Added possibility to specify storageClass for scanner work space instead of
  using ephemeral storage.
* Added requests and limits for containers that were missing them.

### 2016.03 -> 2021.06

* Changed Ingress networking API to networking.k8s.io/v1beta1.
* Pods are now run with readOnlyRootFilesystem, improving security
* Proper `emptyDir:` is now specified for temporary spaces
* Updated rabbitmq, postgresql and memcached images
* Added instructions for populating the database in airgapped deployment
* `frontend.web.rootUrl` is now used for SSO endpoints as well, instead of guessing from HTTP request.

## Requirements

BDBA should run on fine on any public cloud provider supporting Kubernetes. Nodes should have 7 gigabytes of memory at minimum, and preferably there should be 3 nodes. Examples of minimum suitable nodes are

  * AWS: m5.large
  * Azure: Standard_DS2_v2 (See notes below)
  * GCP: n2-standard-2

BDBA also has been tested on local Kubernetes deployment deployed with kubespray.

Supported Kubernetes versions are 1.19 and later.

### Azure Notes

In Azure, if monitoring addons are enabled with `--enable-addons monitoring`, 
Standard_DS2_v2 instances do not have enough free memory available for BDBA.

If monitoring is needed, minimum instance size is Standard_DS3_v2. In that
case node count can be decreased to 2.

## Deploying Black Duck Binary Analysis using the synopsysctl

The following steps describe a high-level overview of the steps required to install BDBA in a Kubernetes cluster.

1. Ensure that you fulfill the [prerequisites](https://synopsys.atlassian.net/wiki/spaces/BDLM/pages/417234960/Prerequisites+for+BDBA) to install BDBA.
2. Create and configure the [Kubernetes cluster](https://synopsys.atlassian.net/wiki/spaces/BDLM/pages/414089277/Preparing+the+Environment), and prepare your environment to install BDBA.
3. Download [synopsysctl](https://synopsys.atlassian.net/wiki/spaces/BDLM/pages/417234971/Getting+Started+with+Synopsysctl+CLI) and install BDBA.

## Deploying Black Duck Binary Analysis using the Helm package manager

This chart bootstraps Black Duck Binary Analysis deployment on a Kubernetes cluster
using the Helm package manager.

### Prerequisites

Before starting, you will need:

  * A Kubernetes cluster with:
    * storageClass that allows persistent volumes configured.
    * NGINX Ingress Controller.
    * The cluster should have enough memory, preferably at least 16 gigabytes.
      A good entry level deployment, for example, would be two n1-standard
      nodes on GCP.
  * Helm 3

### Download chart dependencies

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

### Installing the chart

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


### Configuration

This section shows an example of how you can configure a Black Duck Binary Analysis instance. It's split into multiple
sections for clarity.

#### Secrets for services

Black Duck Binary Analysis Helm chart uses PostgreSQL. Secrets for other services are automatically provisioned,
but for PostgreSQL you need to enter the password manually.

##### PostgreSQL secrets

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

##### Summary

Parameter                                  | Description                                           | Default
------------------------------------------ | ----------------------------------------------------- | -----------------
`postgresql.postgresqlPassword`            | Password for PostgreSQL.                              | "CHANGEME"
`global.postgresql.existingSecret`         | Existing secret name that holds `postgresql-password`.| nil

#### Storage

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

#### Alternative object storages

Black Duck Binary Analysis by default uses minio for storing data to persistent
volumes. However, Minio can be replaced with any S3-compatible object storage,
including native S3 from AWS.

Parameter                   | Description                     | Default
--------------------------- | ------------------------------- | ---------------
`minio.enabled`             | Use bundled minio.              | true
`frontend.internalBucket`   | Bucket for BDBAs internal use.  | "bdba-internal"
`frontend.uploadBucket`     | Bucket for storing uploads.     | "bdba-uploads"
`fluentd.logsBucket`        | Bucket for storing logs.        | "bdba-logs"
`s3Endpoint`                | S3 endpoint.                    | ""
`s3AccessKeyId`             | S3 Access Key Id.               | ""
`s3SecretAccessKey`         | S3 Secret Access Key.           | ""
`s3Region`                  | S3 Region.                      | ""

To use alternative object storage, minio needs to be disabled. 

If using native S3, you need to consider the following:

* Bucket names need to be unique (globally).
* S3 Region is needed.
* To grant permissions, you can either all role for Kubernetes nodes that BDBA,
  or create AWS user that that can access the buckets and use `s3AccessKeyId`
  and `s3SecretAccessKey` parameters. BDBA is able to use Instance Metadata
  Service, and access keys are optional if IDMS is available.

For other object storage options (like external Minio), `s3Endpoint`,
`s3AccessKeyId` and `s3SecretAccessKey` are needed.

#### Licensing

To access the data that Black Duck Binary Analysis needs a username and password for the licensing server are required. These are credentials needed for accessing onprem updates from Synopsys Community.
Without these, automatic data updates will not function. In case you are operating airgapped installation,
you can omit these.

Parameter                     | Description                      | Default
----------------------------- | -------------------------------- |------------------------
`frontend.licensing.username` | Username for licensing server.   | ""
`frontend.licensing.password` | Password for licensing server.   | ""
`frontend.licensing.upstream` | Upstream server for data updates.| "https://protecode-sc.com"

#### RabbitMQ configuration

RabbitMQ requires to know the cluster's domain name. If it is not `cluster.local`,
you need to provide it.

Parameter                                 | Description                 | Default
----------------------------------------- | --------------------------- | ----------------
`rabbitmq.rabbitmq.clustering.k8s_domain` | Internal k8s cluster domain.| cluster.local

#### Web frontend configuration

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

#### SMTP configuration

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

#### LDAP Authentication

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

#### Logging

Black Duck Binary Analysis uses Fluentd to centrally log. Relevant application pods are joined by
a Fluent Bit sidecar.

Parameter                     | Description                                      | Default
----------------------------- | ------------------------------------------------ | ---------------
`frontend.applicationLogging` | Enable application logging for webapp pods.      | true
`worker.applicationLogging`   | Enable application logging for worker pods.      | true
`logRetention`                | Days to keep the application logs (0 to disable) | 30

#### Worker scaling

Parameter             | Description                                   | Default
--------------------- | ----------------------------------------------|------------------------
`worker.replicas`     | Number of scanner instances.                  | 1
`worker.concurrency`  | Number of concurrent scanners in scanner pods.| 1
`worker.storageClass` | storageClass for worker's work space.         | ""

If `worker.storageClass` is left empty, scanners will be deployed as Kubernetes
Deployment and use ephemeral storage for work space. 

However, if nodes have limited ephemeral storage available (that is, nodes contain
small root disks), `worker.storageClass` allows reserving work space for
scanners from persistent volumes. This also makes the workers run as Kubernetes
StatefulSets. Each worker pod reserves it's own workspace from persistent volume.

#### Networking and security

Parameter       | Description                   | Default
--------------- | ----------------------------- | -----------------------
`rootCASecret`  | Kubernetes secret for root CA.| ""
`httpProxy`     | Proxy URL.                    | nil
`httpNoProxy`   | No proxy list.                | nil

#### External PostgreSQL

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

#### Ingress

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

#### Configuring

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

#### Examples

Examples, with inline documentation, are provided in the `examples` directory.

### Secrets

Key material can be saved to Kubernetes using kubectl. To set up additional root certificates,
you can set them as Kubernetes secrets. PEM encoding is assumed.

```console
$ kubectl create secret generic bdba-root --from-file=~/root-ca/ca.pem
secret/bdba-root created
```

To use this as the root certificate, add `--set rootCASecret=bdba-root` to the Helm command line.

### Migration from an existing appliance

To migrate data from an existing VM-based appliance, backup API of the appliance
can be used to perform data acquisition.

#### Acquiring backup

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

##### BDBA < 2021.12.0

BDBA before 2021.12.0 wrapped the pgdump inside tarball. If backup is taken
from BDBA before 2021.12.0, this step is necessary. If it is 2021.12.0 or later,
this step can be omitted.

Extract it backup file if it is made by BDBA before 2021.12.0:

```console
$ tar xvf backup.pgdump
x database.pgdump
```

#### Stopping services accessing the database

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


#### Preparing the database for pg_restore

Before Black Duck Binary Analysis database can be restored, it is required to clean up tables found in the
database.

##### Internal postgresql

Kubectl into the database container and run:

```console
$ kubectl exec -it -n dev hayrynen1-postgresql-0 bash
```

In the PostgreSQL pod, enter the interactive PostgreSQL shell and execute:

```console
$ psql -h localhost -U <database-username> -W -d <database-name>
```

##### Hosted PostgreSQL

With hosted PostgreSQL, like AWS RDS, you can access the database by launching
a pod that can access the database.

```console
kubectl run -it --env="PGPASSWORD=<database-password>" --rm --image=postgres --restart=Never --command=true psqlshell -- psql -h <database-host> -U <database-username>
```

#### DB Shell

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

#### Overwriting the database with a backup

Copy the database dump to the PostgreSQL pod.

```console
$ kubectl cp database.pgdump dev/NS-postgresql-0:/tmp
```

Next, restore the database. In the PostgreSQL pod, execute:

```console
$ pg_restore -c -C -Fc -h localhost -U <database-username> -d <database-name> -n public -O </tmp/database.pgdump
```

##### Restoring the database on hosted PostgreSQL

When using hosted PostgreSQL, database can be restored by piping the database dump to pg_restore.

```console
kubectl run -i --env="PGPASSWORD=<database-password>" --rm --image=postgres --restart=Never --command=true psqlshell -- pg_restore -h <database-host> -U <database-username> --verbose -j 1 -Fc -n public -O -d <database-name> <database.pgdump
```

#### Restoring the services

Next, restore the services:

```console
$ kubectl scale --replicas=1 deployment/NAME-bdba-tasks
$ kubectl scale --replicas=1 deployment/NAME-bdba-tasks-long
$ kubectl scale --replicas=1 deployment/NAME-bdba-updater
$ kubectl scale --replicas=N deployment/NAME-bdba-webapp
```

Now, you should be all set.

### Openshift

Since Openshift is incompatible with security contexts specified in helm charts, security contexts need to be disabled and have openshift manage them.

To disable security context declarations in helm charts, add the following to helm command line or your values.yaml.

```
--set postgresql.securityContext.enabled=false \
--set rabbitmq.securityContext.enabled=false \
--set minio.securityContext.enabled=false
--set frontend.securityContext.enabled=false \
--set worker.securityContext.enabled=false \
--set memcached.securityContext.enabled=false
```

### Airgapped installation

BDBA Kubernetes can operate in airgapped mode. However, it needs manual work to be kept up-to-date.

#### Populating database

By default, when BDBA is given licensing username and password, it is able to fetch
data updates from https://protecode-sc.com/. However, when installation is airgapped, this
option is not possible. However, it is still possible to manually populate the internal
vulnerability database and keep it up-to-date.

To populate the database, you can download dataset from `https://protecode-sc.com/updates/vulndata/`.
This requires the same credential that are used for Synopsys community. You will receive "vulndata.tar.xz"
which is roughly 500MB.

This can be brought to airgapped network, and inserted into running BDBA kubernetes deployment by
uploading it to

`http(s)://<ingress-host-name>/api/bootstrap/`, for example using curl:

```
$ curl -T vulndata.tar.xz -u admin:<adminpw> https://<bdba-k8s-ingress>/api/bootstrap/
```

#### Keeping database up-to-date

Similarly, to keep database up-to-date, you can download data from
`https://protecode-sc.com/updates/`. It will return `appcheck-dataupdate-YYYYMMDD-hhmmss.dat`.

To update database, push it to `http(s)://<ingress-host-name>/api/nvd/`, for example using curl:

```
$ curl -T appcheck-dataupdate-20210601-145434.dat -u admin:<adminpw> https://<bdba-k8s-ingress>/api/nvd/
```

