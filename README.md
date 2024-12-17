# Black Duck Binary Analysis on Kubernetes

You can deploy Black Duck Binary Analysis on a Kubernetes cluster by using the Helm package manager.

## Changes

### 2024.12.0
* Bump containers to new 2024.12.0 versions.
* Switches postgresql container from bitnami/postgresql to docker.io/library/postgres image.

### 2024.9.2
* Bump worker container to 2024.9.2

### 2024.9.1
* Bump frontend container to 2024.9.1
* Fix missing log bucket configuration from configmap.

### 2024.9.0
* Added support for prometheus metrics for collecting scan counts and average time spent on various scan tests.

### 2024.6.1
* Bump worker container for 2024.6.1.

### 2024.6.0
* Bump containers to new 2024.6.0 versions.
* Upgrade service containers.
* Added support for storing and fetching scan specific log files. This needs to be enabled using `worker.scanSpecificLogging.enabled`.

### 2024.3.1
* Bump containers to new 2024.3.1 versions.

### 2024.3.0
* Bump containers to new 2024.3.0 versions.

### 2023.12.5
* Fixed client secret permissions when mTLS was in use for external services to be more strict.

### 2023.12.4
* Bump worker image to 2023.12.3.
* Worker now honors '.Values.worker.resources' for fine grained resource requests and limits.
* fluentd is now reloaded with config changes.

### 2023.12.3
* Include `secrets-rabbitmq.yaml` for external rabbitmq secrets.
* Set http proxy configuration also as lower case environment variables to fix compatibility with AWS tooling.

### 2023.12.2
* s3Region is now properly propagated to all containers using S3.
* Added support for installing BDBA using images from Ironbank.
* Removed bitnami memcached helm chart and replaced it with internal `memcached.yaml`. Also memcached container
  is replaced with official Docker memcached container.
* pgupgrader can now be disabled using `pgupgrader.enabled=false`.
* All containers now honor imagePullSecrets.

### 2023.12.1
* Fixed updater health check that could cause it to timeout during first install.

### 2023.12.0
* Added support for external rabbitmq and external memcached with optional mTLS.
* Added support for `frontend.extraEnv` and `worker.extraEnv` to pass additional environment variables
  for application containers.

### 2023.9.0 -> 2023.9.1
* Updated container versions
* Added support for `frontend.web.forcedHttpsUrls` to force absolute internal urls to be sent over https. This allows running BDBA behind TLS-terminating L4 load balancer.

### 2023.6.1 -> 2023.9.0
* Postgresql that is included in BDBA is upgraded to PostgreSQL 15. Please read upgrading guidance after changelog, as there are required steps involved.
* Added `frontend.web.csrfTrustedOrigins` to override CSRF validations.
* Added `tasks.concurrency` to control concurrency of BDBA post processing tasks (default 3)
* Added `tasks.replicas` to allow increasing BDBA post processing tasks replicas.
* Added 'frontend.disableEc2Metadata' to disable use of EC2 metadata service.

### 2023.6.0 -> 2023.6.1
* Update BDBA worker to 2023.6.1.

### 2023.3.1 -> 2023.6.0
* Updated both BDBA frontend and worker to 2023.3.1 releases.
* Updated postgresql, rabbitmq and memcached images.

### 2023.3.0 -> 2023.3.1
* Updated both BDBA frontend and worker to 2023.3.1 releases.

### 2022.12.1 -> 2023.3.0
* Updated BDBA to 2023.3.0.
* Updated postgresql, rabbitmq and memcached images.
* Improved documentation with airgapped installations in this file.

### 2022.12.0 -> 2022.12.1
* Fixes configmap for vacuumDays

### 2022.9.3 -> 2022.12.0
* Updated postgresql, rabbitmq and memcached images
* Added `frontend.web.vacuumDays` variable to specify days when DB is vacuumed.

### 2022.9.2 -> 2022.9.3
* Worker update to 2022.9.2
  * Replaces OpenSSL 3.x with OpenSSL 1.1.x, resolving CVE-2022-3602 and CVE-2022-3786.

### 2022.9.1 -> 2022.9.2
* Frontend update to 2022.9.1
  * More aggressive garbage collection to prevent OOM situations caused by frequent calls to /api/product/.

### 2022.9.0 -> 2022.9.1
* Worker update to 2022.9.1
  * Fixes scanning regressions with Windows installers

### 2022.6.0 -> 2022.9.0
* minio and updater initContainer now honor resource requests and limits from values.yaml.
* Increased healthcheck timeouts and retries of background workers.
* API now has default connection limit of 8 per IP. You can change it with `ingress.apiConnLimit`.
* `frontend.web.rootUrl` is now automatically inferred from ingress if not explicitly specified.

### 2022.3.0 -> 2022.6.0
* httpProxy configuration value sets also HTTPS proxy.

### 2021.12.1 -> 2022.3.0

* Added support for KEDA autoscaler.
* Added configures ingress.class parameter to specify Ingress class.
* Fixed fluentd container to honor disabling security contexts.
* Removed default memory limits from postgresql container to prevent abrupt termination
  with large transactions on large nodes.

### 2021.12.0 -> 2021.12.1

* Initial Openshift support.

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

### 2021.03 -> 2021.06

* Changed Ingress networking API to networking.k8s.io/v1beta1.
* Pods are now run with readOnlyRootFilesystem, improving security
* Proper `emptyDir:` is now specified for temporary spaces
* Updated rabbitmq, postgresql and memcached images
* Added instructions for populating the database in airgapped deployment
* `frontend.web.rootUrl` is now used for SSO endpoints as well, instead of guessing from HTTP request.

## Upgrading to 2023.9.0

BDBA helm chart 2023.9.0 upgrades internal PostgreSQL to 15. If you are using external postgresql, you can
ignore this.

There is an init container that performs the
volume upgrade automatically. However, for the volume upgrade process to work properly, application containers
need to be shut down so postgresql can shut down gracefully. First figure out `NAMESPACE` and `PREFIX`. 

`NAMESPACE` is the Kubernetes instance where BDBA is deployed. `PREFIX` is the release label that BDBA pods have.
You can get this for example by invoking `kubeget get deployment -n $NAMESPACE`.

Then invoke:

```
export PREFIX=<bdba-release-prefix>
export NAMESPACE=<bdba-namespace>

for deployment in "$PREFIX-bdba-beat" "$PREFIX-bdba-tasks" "$PREFIX-bdba-tasks-long" "$PREFIX-bdba-updater" "$PREFIX-bdba-webapp"; do
    kubectl delete deployment "$deployment" -n "$NAMESPACE"
done
```

before upgrading BDBA. 

After this, you can upgrade BDBA as usual.

### Recovering from unclean shutdown

Failing to stop application containers using database will likely result in database volume that is not shut down cleanly
and volume upgrader container will fail. Recovering from this situation requires deleting existing postgresql statefulset
and rolling back to 2023.6.0 release.

## Requirements

BDBA should run on fine on any public cloud provider supporting Kubernetes. Nodes should have 7 gigabytes of memory at minimum, and preferably there should be 3 nodes. Examples of minimum suitable nodes are

  * AWS: m5.large
  * Azure: Standard_DS2_v2 (See notes below)
  * GCP: n2-standard-2

BDBA also has been tested on local Kubernetes deployment deployed with kubespray.

Supported Kubernetes versions are 1.19 and later.

### Cluster Configuration Notes

Some Kubernetes clusters are configured with "Quaranteed QOS", which essentially means that resource limits behave like resource requests.
With "Queranteed QOS" pods won't be scheduled if nodes are not able to satisfy both CPU and memory limits.
In those cases the minimum resource requirements are higher. This helm chart does not specify hard limits for PostgreSQL, RabbitMQ and Minio due to them
being essential services and having them terminated by exceeding resource limits would be catastrophic. As a rule of thumb, the cluster should have at least

* 6 cores for BDBA pods
* 4 cores for PostgreSQL, Minio, Rabbitmq and Memcached.

Also a cluster may specify default "LimitRanges" to override limits in case limits are not specified for pod. In this case, resources should be
adjusted accordingly in values.yaml. Running PostgreSQL in this kind of setup would be dangerous and it is recommended to use PostgreSQL that
is not running inside the cluster if this is the case.

### Azure Notes

In Azure, if monitoring addons are enabled with `--enable-addons monitoring`,
Standard_DS2_v2 instances do not have enough free memory available for BDBA.

If monitoring is needed, minimum instance size is Standard_DS3_v2. In that
case node count can be decreased to 2.

Also, Azure can conflict with some S3/minio operations. This can be resolved
by settings `frontend.disableEc2Metadata` as `true`.

## Deploying Black Duck Binary Analysis Using the Helm Package Manager

This chart bootstraps Black Duck Binary Analysis deployment on a Kubernetes cluster
using the Helm package manager.

### Prerequisites

Before starting, you will need:

  * A Kubernetes cluster with:
    * storageClass that allows persistent volumes configured.
    * NGINX Ingress Controller (not needed with OpenShift)
    * The cluster should have enough memory, preferably at least 16 gigabytes.
      A good entry level deployment, for example, would be two n1-standard
      nodes on GCP.
  * Helm 3

### Install Synopsys Repo

``` console
$ helm repo add blackduck https://repo.blackduck.com/artifactory/sig-cloudnative/
```

### Install the Chart

To install the chart with the release name `testing`:

```console
$ helm upgrade testing blackduck/bdba --install --namespace bdba
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

#### Secrets for Services

Black Duck Binary Analysis Helm chart uses PostgreSQL. Secrets for other services are automatically provisioned,
but for PostgreSQL you need to enter the password manually.

##### PostgreSQL Secrets

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

#### Alternative Object Storages

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

To access the data that Black Duck Binary Analysis needs a username and password for the licensing server are required. These are credentials needed for accessing onprem updates from Black Duck Community.
Without these, automatic data updates will not function. In case you are operating airgapped installation,
you can omit these.

Parameter                     | Description                      | Default
----------------------------- | -------------------------------- |------------------------
`frontend.licensing.username` | Username for licensing server.   | ""
`frontend.licensing.password` | Password for licensing server.   | ""
`frontend.licensing.upstream` | Upstream server for data updates.| "https://bdba.blackduck.com"

#### RabbitMQ Configuration

RabbitMQ requires to know the cluster's domain name. If it is not `cluster.local`,
you need to provide it.

Parameter                                 | Description                 | Default
----------------------------------------- | --------------------------- | ----------------
`rabbitmq.rabbitmq.clustering.k8s_domain` | Internal k8s cluster domain.| cluster.local

#### Web Frontend Configuration

Generic configuration options for customization of frontend behavior.

Parameter                         | Description                             | Default
--------------------------------- | --------------------------------------- |------------------------
`frontend.web.secretKey`          | Secret key for web application.         | 50 random characters
`frontend.web.sessionCookieAge`   | Session cookie age.                     | "1209600"
`frontend.web.replicas`           | Number of frontend instances.           | 1
`frontend.web.hideLicenses`       | Hide licensing information from scan.   | false
`frontend.web.offlineMode`        | Do not make network request to internet | false
`frontend.web.admin`              | Administrator user's email address.     | "admin@bdba.local"
`frontend.web.erroradmin`         | Error report email receiver.            | ""
`frontend.web.rootURL`            | Root URL of web service for emails.     | ""
`frontend.web.vacuumDays`         | Days when to force vacuum the db.       | "sunday"
`frontend.web.csrfTrustedOrigins` | Trusted origins for CSRF check          | ""
`frontend.web.forcedHttpsUrls`    | Force internal absolute URLs to https   | false

`frontend.web.rootURL` is only necessary if it differs from `ingress.host` and `ingress.tls` values.
By default, URL of the BDBA service is inferred from values specified for Ingress.

`frontend.web.vacuumDays` accepts days in quite liberal crontab-format. Examples are
`sunday`, to vacuum only on sunday, `mon,wed,fri,sun` to vacuum on monday, wednesday, friday and sunday
and `mon-sun` to vacuum daily.

`frontend.web.csrfTrustedOrigins` allows specifying list of trusted origins for unsafe requests.
This is needed for example when TLS is not terminated in BDBA Ingress, but there is application load
balancer terminating TLS.

`frontend.web.forcedHttpsUrls` allows forcing all internal absolute URL links to be https. This is required
if BDBA is running behind a load balancer that does not send X-Forwarded-Proto -header.

#### SMTP Configuration

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
`frontend.ldap.searchOptReferrals`   | Follow LDAP referrals.                  | "true"
`frontend.ldap.userEmailMatch`       | Try also email when finding local user. | "false"

To setup root certificate for LDAP, issues:

```console
$ kubectl create secret generic bdba-ldap-root --from-file=~/root-ca/ca.pem
secret/bdba-ldap-root created
```

To use this as the root certificate, add `--set frontend.ldap.rootCASecret=bdba-ldap-root` to the Helm command line.

#### Monitoring

BDBA webapp can expose several prometheus gauges via `/metrics` endpoint. 

Parameter                                 | Description                                   | Default
----------------------------------------- | --------------------------------------------- | ------- 
`frontend.metrics.enabled`                | Enable monitoring endpoint in web application | false
`frontend.metrics.serviceMonitor.enabled` | Deploy ServiceMonitor object for prometheus   | false

Monitoring is disabled by default. To enable monitoring, you need to have prometheus inside the cluster.
Even if monitoring is enabled, BDBA rejects metrics requests coming thru ingress unless authentication
for monitoring is enabled.

There is included grafana dashboard in `contrib/bdba-metrics-grafana.json` which can be added to
`kube-prometheus-stack` deployment using kubectl. For example:

```console
$ kubectl create configmap bdba-dashboard -n <prometheus-namespace> --file=contrib/bdba-metrics-grafana.json -o yaml --dry-run|kubectl apply -f -
$ kubectl label configmap bdba-dashboard -n <prometheus-namespace> grafana_dashboard=1
```

#### Logging

Black Duck Binary Analysis uses Fluentd to centrally log. Relevant application pods are joined by
a Fluent Bit sidecar.

Parameter                             | Description                                      | Default
------------------------------------- | ------------------------------------------------ | ---------------
`frontend.applicationLogging.enabled` | Enable application logging for webapp pods.      | true
`worker.applicationLogging.enabled`   | Enable application logging for worker pods.      | true
`worker.scanSpecificLogging.enabled`  | Enable scan specific logging in worker pods.     | false
`logRetention`                        | Days to keep the application logs (0 to disable) | 30

`worker.scanSpecificLogging.enabled` enables scan-specific logging in worker. After scan has been completed,
it uploads the logs into object storage so they can be downloaded for troubleshooting. 

#### Cloud provider -specific settings

Some cloud providers (e.g. Azure) may interfere by providing instance metadata at the
same endpoint as AWS, and cause object storage operations to fail. Usage of instance metadata
can be disabled.

Parameter                     | Description                              | Default
----------------------------- | ---------------------------------------- | --------------
`frontend.disableEc2Metadata` | Disables user of EC2 metadata service    | false


#### Worker Scaling

Parameter             | Description                                                     | Default
--------------------- | ----------------------------------------------------------------|------------------------
`worker.replicas`                      | Number of scanner instances.                   | 1
`worker.concurrency`                   | Number of concurrent scanners in scanner pods. | 1
`worker.storageClass`                  | storageClass for worker's work space.          | ""

If `worker.storageClass` is left empty, scanners will be deployed as Kubernetes
Deployment and use ephemeral storage for work space.

However, if nodes have limited ephemeral storage available (that is, nodes contain
small root disks), `worker.storageClass` allows reserving work space for
scanners from persistent volumes. This also makes the workers run as Kubernetes
StatefulSets. Each worker pod reserves it's own workspace from persistent volume.

It is recommended to keep `worker.concurrency` as 1 to isolate scanners from each other and
to more efficiently use cluster resources. 

#### Worker Autoscaling

Parameter                              | Description                                    | Default
-------------------------------------- | -----------------------------------------------|----------
`worker.keda.enabled`                  | Use KEDA autoscaler (requires KEDA in cluster) | false
`worker.keda.minReplicaCount`          | Minimum number of workers to scale down to     | 1
`worker.keda.maxReplicaCount`          | Maximum number of workers to scale up to       | 10
`worker.keda.queueLength`              | # of jobs required to be in queue to scale up  | 2
`worker.terminationGracePeriodSeconds` | Termination grace period of worker             | 21600

To use worker autoscaling, KEDA (https://keda.sh) is required to be installed in cluster.
See KEDA's deployment instructions how to deploy KEDA.

Use `worker.keda.maxReplicaCount` to specify maximum number of workers to scale up to.

`worker.keda.queueLength` specifies the length of job queue before scaling up. By default, BDBA starts
scaling up when there are two jobs waiting in the queue. If you have lots of small scans, higher value
would work better, but if you have mostly large scans, `1` would trigger new worker immediately for new scan.

`worker.terminationGracePeriodSeconds` is required for scaling down. As KEDA starts to scale down when there
are no jobs in the queue by sending termination signal to workers, BDBA workers receiving the signal will stop
accepting new scan jobs but finishing their current scans. If scan does not finish in
`worker.terminationGracePeriodSeconds` it will be forcefully killed and fail. If scans fail abruptly when
downscaling, increasing this value will help.

#### Networking and Security

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

Possible values for `postgresqlSslMode` are specified in https://www.postgresql.org/docs/15/libpq-ssl.html.

#### External RabbitMQ

BDBA supports external RabbitMQ with mutual TLS encryption. It also works with RabbitMQ-as-a-service offerings
such as Amazon MQ. 

*IMPORTANT!*: It is mandatory that RabbitMQ is configured with larger than default consumer timeout. Some BDBA 
tasks are longer than RabbitMQ defaults allow and the recommended value for them is `86400000`. Without this value,
BDBA containers will experience unscheduled restarts and in some cases prematurely killed jobs.
To set this value, add `consumer_timeout = 86400000` in `/etc/rabbitmq/rabbitmq.conf` if rabbitmq is running
as a systemd service. With other deployment models, consult the documentation on how to do this.

The configuration values are:

Parameter                | Description                                      | Default
------------------------ | ------------------------------------------------ | --------------------
`rabbitmq.enabled`       | Enable internal RabbitMQ                         | true
`brokerUrl`              | URL for broker                                   | ""
`brokerTls`              | Enable TLS                                       | false
`brokerRootCASecretName` | Kubernetes secret for root certificate           | ""
`brokerClientSecretName` | Kubernetes secret name for client authentication | ""

`rabbitmq.enabled` needs to be set as `false` to enable external RabbitMQ.

`brokerUrl` is the connection string for RabbitMQ service. It is in the form of `amqp://<user>:<password>@<host>:<port>/<vhost>`.

NOTE! The `brokerUrl` parameter does not support the amqps suffix. To use amqps (amqp over TLS), specify the port `5671` in the connection
string and set `brokerTls` as true.

##### Root Certificate

In case TLS is in use for RabbitMQ, you need to specify `brokerRootCASecretName` which points to a secret that contains
the root certificate that RabbitMQ uses unless the RabbitMQ server certificate is signed by a known trusted Certificate Authority.

To populate the CA secret, run:
```console
$ kubectl create secret -n bdba generic rabbitmq-ca --from-file=ca.pem
```

Note that the filename MUST be ca.pem. In this case, `brokerRootCASecretName` would be `rabbitmq-ca`.

##### mTLS Client Authentication

If the RabbitMQ server requires mTLS client authentication, you can pass the client certificate in the `brokerClientSecretName` secret.

To populate the client certificate and the key, run:
```console
$ kubectl create secret tls -n dev rabbitmq-client-cert --key="client-key.pem" --cert="client.pem"
```

In this case, `brokerClientSecretName` would be `rabbitmq-client-cert`.

#### External memcached
BDBA uses memcached for certain locks and caches. Usage of external memcached is supported. It also works with
memcached-as-a-service offerings such as Amazon ElastiCache. The memcached instance can be very lightweight.

The configuration values are:

Parameter                      | Description                                      | Default
------------------------------ | ------------------------------------------------ | --------------------
`memcached.enabled`            | Enable internal memcached                        | true
`memcachedHostPort`            | Host:port pair of memcached service              | ""
`memcachedTls`                 | Enable TLS for memcached                         | false
`memcachedRootCASecretName`    | Kubernetes secret for root certificate           | ""
`memcachedTlsClientSecretName` | Kubernetes secret name for client authentication | ""

`memcached.enabled` needs to be set as `false` to enable external memcached.

`memcachedHostPort` is the <host>:<port> pair for the memcached service, for example `memcached:11211`.

##### Root Certificate

In case TLS is in use for memcached, you need to specify `memcachedRootCASecretName` which points to a secret that contains
the root certificate that memcached uses, unless the memcached server certificate is signed by a known trusted Certificate Authority.

To populate the CA secret, run:
```
$ kubectl create secret -n bdba generic memcached-ca --from-file=ca.pem
```

Note that the filename MUST be ca.pem. In this case, `memcachedRootCASecretName` would be `memcached-ca`.

##### mTLS Client Authentication

If the memcached server requires mTLS client authentication, you can pass the client certificate in the `memcachedClientSecretName` secret.

To populate the client certificate and the key, run:
```
$ kubectl create secret tls -n dev memcached-client-cert --key="client-key.pem" --cert="client.pem"
```

In this case, the `memcachedClientSecretName` would be `memcached-client-cert`.

#### Ingress

Parameter                | Description                        | Default
------------------------ | ---------------------------------- | --------------------
`ingress.enabled`        | Enable ingress.                    | true
`ingress.host`           | Hostname for ingress.              | "bdba.local"
`ingress.tls.enabled`    | Enable TLS.                        | false
`ingress.tls.secretName` | TLS secret for certificate.        | bdba-tls
`ingress.apiConnLimit`   | Concurrent API connections per ip. | 8

To create a TLS secret, invoke:

```console
$ kubectl create secret tls bdba-tls --key key.pem --cert cert.pem
secret/bdba-tls created
```

#### Configuring

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`. For example:

```console
$ helm upgrade testing synopsys/bdba --install \
   --set frontend.licensing.username="foo@example.com" \
   --set frontend.licensing.password="secret" .
```

Alternatively, a YAML file that specifies the values for the parameters can be provided while installing the chart. For example:

```console
$ helm upgrade testing synopsys/bdba --install -f my-values.yaml
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

### Backing Up Database
To take backup of internal postgresql if external postgresql is not in use, you can use kubectl and pg_dump.

```
$ kubectl exec -it -n bdba bdba-postgresql-0 -- sh -c 'PGPASSWORD=$POSTGRES_PASSWORD pg_dump -Fc -d bdba -U bdba' >backup.pgdump
```

This will create `backup.pgdump` which is standard postgresql custom-format archive that can be restored using pg_restore.

### Migration from an Existing Appliance

To migrate data from an existing VM-based appliance, backup API of the appliance
can be used to perform data acquisition.

#### Acquiring Backup

First, run:

```console
$ curl -X POST -u admin "https://<APPLIANCE>/api/backup/"
```

Next, Query until the backup is ready.

```console
$ curl -u admin "https://<APPLIANCE>/api/backup/"|jq
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

#### Stopping Services Accessing the Database

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


#### Preparing the Database for pg_restore

Before Black Duck Binary Analysis database can be restored, it is required to clean up tables found in the
database.

##### Internal Postgresql

Kubectl into the database container and run:

```console
$ kubectl exec -it -n bdba bdba-postgresql-0 bash
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

#### Overwriting the Database with a Backup

Copy the database dump to the PostgreSQL pod.

```console
$ kubectl cp database.pgdump NS/<release>-postgresql-0:/tmp
```

Next, restore the database. In the PostgreSQL pod, execute:

```console
$ pg_restore -c -C -Fc -h localhost -U <database-username> -d <database-name> -n public -O </tmp/database.pgdump
```

##### Restoring the Database on Hosted PostgreSQL

When using hosted PostgreSQL, database can be restored by piping the database dump to pg_restore.

```console
kubectl run -i --env="PGPASSWORD=<database-password>" --rm --image=postgres --restart=Never --command=true psqlshell -- pg_restore -h <database-host> -U <database-username> --verbose -j 1 -Fc -n public -O -d <database-name> <database.pgdump
```

#### Restoring the Services

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
--set memcached.securityContext.enabled=false \
--set fluentd.securityContext.enabled=false
```

Because BDBA defaults to nginx Ingress class, you also need to specify Ingress class so Openshift can
create routes properly. To do this, use

```
$ kubectl get ingressclass
```

to figure out proper ingressclass and add the parameter for helm installation command.

```
--set ingress.class="<ingressclass>"
```

By default, this is "openshift-default". You can also use `--set ingress.class=""` to use the default as well.

### Airgapped Installation

BDBA Kubernetes can operate in airgapped mode. However, it needs manual work to be kept up-to-date.

#### Populating Database

By default, when BDBA is given licensing username and password, it is able to fetch
data updates from https://protecode-sc.com/. However, when installation is airgapped, this
option is not possible. However, it is still possible to manually populate the internal
vulnerability database and keep it up-to-date.

To populate the database, you can download dataset from `https://bdba.blackduck.com/updates/vulndata/`.
This requires the same credential that are used for Black Duck Community. You will receive "vulndata.tar.xz"
which is roughly 500MB.

This can be brought to airgapped network, and inserted into running BDBA kubernetes deployment by
uploading it to

`http(s)://<ingress-host-name>/api/bootstrap/`, for example using curl:

```
$ curl -T vulndata.tar.xz -u admin:<adminpw> https://<bdba-k8s-ingress>/api/bootstrap/
```

#### Populating Component Information

After each software update, also supplemental information about components should be populated into database.
This should be done also with first installation in addition to populating the database with vulnerability data.

To achieve this, download data from `https://bdba.blackduck.com/updates-v2/bootstrap/`. It will return
`bdba-onprem-data-bootstrap-YYYYMMDD-hhmmss.tar.zst`.

To update the database, push it to `http(s)://<ingress-host-name>/api/nvd/`, for example using curl:

```
$ curl -T bdba-onprem-data-bootstrap-YYYYMMDD-hhmmss.tar.zst -u admin:<adminpw> https://<bdba-k8s-ingress>/api/nvd/
```

#### Keeping the Database Up-To-Date

Similarly, to keep database up-to-date, you can download data from
`https://bdba.blackduck.com/updates-v2/`. It will return `bdba-onprem-data-update-YYYYMMDD-hhmmss.tar.zst`.

To update database, push it to `http(s)://<ingress-host-name>/api/nvd/`, for example using curl:

```
$ curl -T bdba-onprem-data-update-YYYYMMDD-hhmmss.tar.zst -u admin:<adminpw> https://<bdba-k8s-ingress>/api/nvd/
```

The difference with this file to bootstrap -variant is that it contains only delta of seven days and it is faster to apply.

### Upscaling

As BDBA has varied workloads by nature, there can be no absolute guidance for configuration for example for X scans / day
and how machines should be provisioned.

BDBA inherintly is an application that processes workloads using queues, stores data in PostgreSQL and provides a web interface.
In practice this means that all the components except PostgreSQL can be horizontally scaled and distributed among many hardware
instances. PostgreSQL is the only thing that scales only vertically.

Therefore, primary focus on scaling should be placed on PostgreSQL performance. Running PostgreSQL with enough memory and
fast disks is advisable. In larger deployments external PostgreSQL should be used.

In case of BDBA workloads getting stuck, increasing replicas help. Different symptons on slowness can be for example

* Web application is slow -> increase web application replicas with `frontend.web.replicas` parameter.
* Scan jobs stay in the queue for long time -> increase number of workers, either enabling keda or with `worker.replicas` parameter.
* Post processing jobs stay in the queue for long time -> increase post processing replicas with `tasks.replicas` parameter.

### Running without service account

By default, when BDBA is using embedded minio or rabbitmq, it creates the secrets from them is initialization job. This
job creates secrets for minio and rabbitmq, and stores them as Kubernetes secrets. This requires a service account.

If for some reason service accounts are not functioning in cluster or pods do not have access to use them,
you can disable the service account and create the secrets manually. 

Service account relevant parameters are

Parameter                        | Description                                     | Default
-------------------------------- | ----------------------------------------------- | ------------------
`frontend.serviceAccount.create` | Create the service account                      | true
`frontend.serviceAccount.name`   | Name of the service account                     | <autogenerated>
`frontend.createSecrets`         | Automatically create minio and rabbitmq secrets | true

To disable automatic secrets creation, set `frontend.createSecrets` as false.

Following secrets then need to be created manually

1) (If using embedded minio)
```
$ kubectl create secret generic -n namespace bdba-minio-secret \
  --from-literal=accesskey=<random string> --from-literal=secretkey=<random-string>
```

2) (If using embedded rabbitmq)
```
$ kubectl create secret generic -n <namespace> bdba-rabbitmq-password-secret \
  --from-literal=rabbitmq-password=<random string>

$ kubectl create secret generic -n <namespace> bdba-rabbitmq-broker-url \
  --from-literal=host=amqp://bdba:<password-set-above>@<release-name>-rabbitmq.<namespace>

$ kubectl create secret generic -n <namespace> bdba-rabbitmq-erlang-cookie-secret \
  --from-literal=rabbitmq-erlang-cookie=<random string>
```

