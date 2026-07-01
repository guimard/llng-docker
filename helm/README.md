# lemonldap

A Helm chart for LemonLDAP::NG (manager, portal and maintenance cronjob)

![Version: 2.21.4](https://img.shields.io/badge/Version-2.21.4-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 2.21.4-4](https://img.shields.io/badge/AppVersion-2.21.4--4-informational?style=flat-square)

## Source Code

- <https://github.com/guimard/llng-docker>
- <https://lemonldap-ng.org>

## Prerequisites

- Kubernetes 1.22+
- Helm 3.2.0+

## Requirements

Kubernetes: `>=1.22`

| Repository            | Name    | Version |
| --------------------- | ------- | ------- |
| file://charts/commons | commons | 1.0.0   |

The `commons` library chart is vendored under `charts/`, so no external Helm
repository is required to build or install this chart.

## Installing/Upgrading the Chart

Clone the repository and install the chart from its local path with the release
name `my-release`:

```
helm upgrade --install my-release ./helm
```

> **Tip**: Use the `helm diff` plugin to preview what a helm upgrade would change.

## Uninstalling the Chart

To uninstall/delete the `my-release` deployment:

```
helm delete my-release
```

## Values

| Key                                   | Type   | Default                                                     | Description                                                                                                                |
| ------------------------------------- | ------ | ----------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| nameOverride                          | string | `""`                                                        |                                                                                                                            |
| fullnameOverride                      | string | `""`                                                        |                                                                                                                            |
| global.image.pullSecrets              | list   | `[]`                                                        | Global registry pull secrets                                                                                               |
| manager.enabled                       | bool   | `false`                                                     |                                                                                                                            |
| manager.image.registry                | string | `"docker.io"`                                               | Image registry                                                                                                             |
| manager.image.repository              | string | `"yadd/lemonldap-ng-manager"`                               | Image repository                                                                                                           |
| manager.image.tag                     | string | `"2.21.4-4-no-s6"`                                          | Image tag (immutable tags are recommended)                                                                                 |
| manager.image.digest                  | string | `""`                                                        | Image digest in SHA. If set, will override the tag                                                                         |
| manager.image.pullPolicy              | string | `"IfNotPresent"`                                            | Defaults to `Always` if image tag is `latest`, else set to `IfNotPresent`                                                  |
| manager.image.pullSecrets             | list   | `[]`                                                        | Optional - Specify an array of imagePullSecrets                                                                            |
| manager.diagnosticMode                | object | `{"args":["infinity"],"command":["sleep"],"enabled":false}` | Debug mode - Sleep pod                                                                                                     |
| manager.replicaCount                  | int    | `1`                                                         |                                                                                                                            |
| manager.readinessProbe                | string | `nil`                                                       | Configuration for Readiness Probes                                                                                         |
| manager.livenessProbe                 | string | `nil`                                                       | Configuration for Liveness Probes                                                                                          |
| manager.affinity                      | object | `{}`                                                        | Affinity for pod assignment                                                                                                |
| manager.resources.limits              | object | `{"cpu":"250m","memory":"500Mi"}`                           | Resources limits for the container                                                                                         |
| manager.resources.requests            | object | `{"cpu":"50m","memory":"100Mi"}`                            | Requested resources for the container                                                                                      |
| portal.image.registry                 | string | `"docker.io"`                                               | Image registry                                                                                                             |
| portal.image.repository               | string | `"yadd/lemonldap-ng-portal"`                                | Image repository                                                                                                           |
| portal.image.tag                      | string | `"2.21.4-4-no-s6-hiperf"`                                   | Image tag (immutable tags are recommended)                                                                                 |
| portal.image.digest                   | string | `""`                                                        | Image digest in SHA. If set, will override the tag                                                                         |
| portal.image.pullPolicy               | string | `"IfNotPresent"`                                            | Defaults to `Always` if image tag is `latest`, else set to `IfNotPresent`                                                  |
| portal.image.pullSecrets              | list   | `[]`                                                        | Optional - Specify an array of imagePullSecrets                                                                            |
| portal.replicaCount                   | int    | `1`                                                         |                                                                                                                            |
| portal.diagnosticMode.enabled         | bool   | `false`                                                     |                                                                                                                            |
| portal.readinessProbe                 | string | `nil`                                                       | Configuration for Readiness Probes                                                                                         |
| portal.livenessProbe                  | string | `nil`                                                       | Configuration for Liveness Probes                                                                                          |
| portal.affinity                       | object | `{}`                                                        | Affinity for pod assignment                                                                                                |
| portal.resources.limits               | object | `{"cpu":"250m","memory":"500Mi"}`                           | Resources limits for the container                                                                                         |
| portal.resources.requests             | object | `{"cpu":"50m","memory":"100Mi"}`                            | Requested resources for the container                                                                                      |
| cronjob.enabled                       | bool   | `true`                                                      |                                                                                                                            |
| cronjob.schedule                      | string | `"0 */3 * * *"`                                             | Cron schedule for the maintenance job                                                                                      |
| cronjob.concurrencyPolicy             | string | `"Forbid"`                                                  | Do not start a new Job while the previous one is still running                                                             |
| cronjob.successfulJobsHistoryLimit    | int    | `1`                                                         | Number of successful finished Jobs to keep                                                                                 |
| cronjob.failedJobsHistoryLimit        | int    | `1`                                                         | Number of failed finished Jobs to keep                                                                                     |
| cronjob.ttl                           | int    | `21600`                                                     | Seconds after which a finished Job is deleted                                                                              |
| cronjob.image.registry                | string | `"docker.io"`                                               | Image registry                                                                                                             |
| cronjob.image.repository              | string | `"yadd/lemonldap-ng-cron-task"`                             | Image repository                                                                                                           |
| cronjob.image.tag                     | string | `"2.21.4-4-no-s6"`                                          | Image tag (immutable tags are recommended)                                                                                 |
| cronjob.image.digest                  | string | `""`                                                        | Image digest in SHA. If set, will override the tag                                                                         |
| cronjob.image.pullPolicy              | string | `"IfNotPresent"`                                            | Defaults to `Always` if image tag is `latest`, else set to `IfNotPresent`                                                  |
| cronjob.image.pullSecrets             | list   | `[]`                                                        | Optional - Specify an array of imagePullSecrets                                                                            |
| cronjob.resources.limits              | object | `{"cpu":"250m","memory":"500Mi"}`                           | Resources limits for the container                                                                                         |
| cronjob.resources.requests            | object | `{"cpu":"50m","memory":"100Mi"}`                            | Requested resources for the container                                                                                      |
| config.logoutRedirection              | string | `""`                                                        | Logout Redirection URL - Empty value by default to not modify LemonLDAP behavior                                           |
| config.domain.root                    | string | `"example.com"`                                             | Root Domain                                                                                                                |
| config.domain.portal                  | string | `"auth.example.com"`                                        | Portal URL - Used as Ingress if enabled                                                                                    |
| config.domain.manager                 | string | `"manager.example.com"`                                     | Manager URL - Used as Ingress if enabled                                                                                   |
| config.portal.serverName              | string | `nil`                                                       |                                                                                                                            |
| config.manager.protection             | string | `"manager"`                                                 | Manager protection rule. Supported values: `authenticate`, `manager`, a custom rule, or `none`                             |
| config.log.level                      | string | `"info"`                                                    | Possible values: debug, info, notice, warn, error                                                                          |
| config.log.logger                     | string | `"syslog"`                                                  | Possible values: stderr, syslog                                                                                            |
| config.log.userLogger                 | string | `"syslog"`                                                  | Possible values: stderr, syslog                                                                                            |
| config.cron.handler.enabled           | bool   | `false`                                                     | Enable session purge cron task (handler)                                                                                   |
| config.cron.portal.enabled            | bool   | `false`                                                     | Enable session purge cron task (portal)                                                                                    |
| config.postgres.enabled               | bool   | `false`                                                     | Enable Postgres as LemonLDAP backend database                                                                              |
| config.postgres.host                  | string | `"postgresql"`                                              |                                                                                                                            |
| config.postgres.port                  | int    | `5432`                                                      |                                                                                                                            |
| config.postgres.sslMode               | string | `"prefer"`                                                  |                                                                                                                            |
| config.postgres.dbName                | string | `"lemonldapng"`                                             |                                                                                                                            |
| config.postgres.username              | string | `"lemonldap"`                                               |                                                                                                                            |
| config.postgres.password              | string | `"change-me"`                                               |                                                                                                                            |
| config.postgres.admin                 | object | `{"dbName":"","password":"","username":""}`                 | Admin credentials for the init-job to create the LemonLDAP DB user and schema                                              |
| config.postgres.initJob.enabled       | bool   | `true`                                                      | Built-in schema init-job (pre-install hook). Set to false when the database/user already exist (e.g. a managed PostgreSQL) |
| config.proxy.forwardedBy              | string | `"0.0.0.0/0"`                                               | Trusted proxy range for the forwarded header                                                                               |
| config.proxy.forwardedHeader          | string | `"X-Remote-IP"`                                             | Header carrying the client IP                                                                                              |
| config.externalFileConfig             | object | `{}`                                                        | Override the default lmConf.json                                                                                           |
| ingress.enabled                       | bool   | `false`                                                     | Set to true to enable ingress record generation                                                                            |
| ingress.ingressClassName              | string | `"nginx"`                                                   | IngressClass used to implement the Ingress                                                                                 |
| ingress.annotations                   | object | `{}`                                                        | Annotations for the Ingress resource. Use cert-manager annotations to enable certificate autogeneration.                   |
| ingress.tls.enabled                   | bool   | `false`                                                     | Enable TLS for ingress                                                                                                     |
| ingress.manager.enabled               | bool   | `false`                                                     | Manager ingress config                                                                                                     |
| ingress.manager.annotations           | object | `{}`                                                        | Annotations for the Manager Ingress resource                                                                               |
| ingress.imapAutoDiscovery.enabled     | bool   | `false`                                                     | Enable the IMAP Auto Discovery Ingress                                                                                     |
| ingress.imapAutoDiscovery.host        | string | `"autodiscover.example.com"`                                | IMAP Auto Discovery host                                                                                                   |
| ingress.imapAutoDiscovery.annotations | object | `{}`                                                        | Annotations for the IMAP Auto Discovery Ingress resource                                                                   |
| ingress.portal.host                   | string | `""`                                                        | Override the default portal domain URL                                                                                     |
