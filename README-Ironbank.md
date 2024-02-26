# BDBA on Ironbank

BDBA images are also available in Ironbank.

`values-ironbank.yaml` contains configuration files needed for for Installing BDBA
using Ironbank containers. Ironbank installation uses the service images (rabbitmq, postgresql, memcached and minio) hosted in Ironbank repository.

## Caveats

Currently there are following caveats when using Ironbank images.

* Only standard Kubernetes logging is supported. Application level logging is not supported.
* Rabbitmq health checks depend on curl, but curl has been removed from RabbitMQ
  Ironbank image. Therefore Rabbitmq healthchecks must be disabled.
* Rabbitmq helm chart does not honor .Values.imagePullSecrets, but requires
  `.Values.rabbitmq.global.imagePullSecrets` value to pull from Ironbank.
* Postgresql updater is not supported, so updating major postgresql versions without
  admistrative manual actions is not supported.
* Postgresql image uses Docker postgresql image instead of Bitnami variant. Volumes between
  stock postgresql and bitnami images are incompatible, meaning image variant can not
  be changed after initialization.

It is recommended to use external postgresql and external rabbitmq with BDBA helm chart.
Please consult `README.md` how to do so.

### Installation

Ironbank configuration can be used by just adding values-ironbank.yaml for helm chart. Example:

```
$ helm upgrade bdba-ironbank . --install --namespace ironbank --debug -f values.yaml -f values-ironbank.yaml -f ../../configs/values-bdba.yaml
```
