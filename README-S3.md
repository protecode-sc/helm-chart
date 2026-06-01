# Configuring Amazon S3 as Object Storage

By default, BDBA uses an in-cluster object storage service (VersityGW or MinIO).
This document covers switching to Amazon S3 and the required IAM permissions.

## Buckets

BDBA uses three buckets, configured independently:

| `values.yaml` key | Default name | Purpose |
|---|---|---|
| `frontend.uploadBucket` | `bdba-uploads` | Uploaded binaries and analysis results |
| `frontend.internalBucket` | `bdba-internal` | Internal state and signature data |
| `fluentd.logsBucket` | `bdba-logs` | Application log archives |

Create all three buckets before installing the chart. 


## Helm values

To use Amazon S3, disable the in-cluster storage and point the application at your buckets
and region:

```yaml
minio:
  enabled: false

versitygw:
  enabled: false

s3Region: "eu-west-1"   # required; no default
s3Endpoint: ""          # leave empty for native AWS S3

frontend:
  uploadBucket: "my-bdba-uploads"
  internalBucket: "my-bdba-internal"

fluentd:
  logsBucket: "my-bdba-logs"
```

## Authentication

### Option A — IRSA (recommended on EKS)

Bind an IAM role to the pod's Kubernetes service account using EKS Pod Identity or
the older IRSA annotation. No static credentials are stored in the cluster.

1. Create an IAM role with the policy described in the [IAM permissions](#iam-permissions)
   section below and configure its trust policy to allow the service account to assume it.

2. Annotate the service account via `values.yaml`:

```yaml
frontend:
  serviceAccount:
    create: true
    annotations:
      eks.amazonaws.com/role-arn: "arn:aws:iam::123456789012:role/bdba-s3-role"
```

3. If the cluster nodes themselves also have an instance profile that must not be used,
   disable EC2 metadata access:

```yaml
frontend:
  disableEc2Metadata: true
```

Leave `s3AccessKeyId` and `s3SecretAccessKey` empty — credentials are picked up
automatically from the pod's projected service account token.

### Option B — Pre-existing Secret (recommended for static credentials)

Create a Kubernetes Secret outside the chart and reference it by name. The chart will
not create or manage the Secret — useful with external secrets operators (ESO, Vault
Agent, Sealed Secrets, etc.).

```sh
kubectl create secret generic bdba-s3-credentials \
  --from-literal=AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE \
  --from-literal=AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
```

```yaml
s3ExistingSecret: "bdba-s3-credentials"
```

The secret must contain the keys `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`.
When `s3ExistingSecret` is set, `s3AccessKeyId` and `s3SecretAccessKey` are ignored.

### Option C — Inline static credentials

Pass credentials directly in `values.yaml`. The chart creates and manages the Secret.

```yaml
s3AccessKeyId: "AKIAIOSFODNN7EXAMPLE"
s3SecretAccessKey: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
```

Avoid this in production — credentials end up in Helm release history.

## IAM permissions

The policy below grants the minimum permissions required for the **frontend, tasks,
and fluentd** pods. The worker needs a subset of these; see the
[Worker IAM role](#worker-iam-role-optional) section.

Files larger than 16 MB are uploaded using S3 multipart upload, so the multipart
actions are required even if you do not expect large files — multipart is used
automatically based on file size.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "UploadBucket",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket",
        "s3:CreateMultipartUpload",
        "s3:UploadPart",
        "s3:CompleteMultipartUpload",
        "s3:AbortMultipartUpload"
      ],
      "Resource": [
        "arn:aws:s3:::my-bdba-uploads",
        "arn:aws:s3:::my-bdba-uploads/*"
      ]
    },
    {
      "Sid": "InternalBucket",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::my-bdba-internal",
        "arn:aws:s3:::my-bdba-internal/*"
      ]
    },
    {
      "Sid": "LogsBucket",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::my-bdba-logs",
        "arn:aws:s3:::my-bdba-logs/*"
      ]
    }
  ]
}
```

### Permission rationale

| Permission | Buckets | Reason |
|---|---|---|
| `s3:GetObject` | upload, internal, logs | Download binaries, read internal state, read log files for support bundles; also covers `HeadObject` used to check file existence |
| `s3:PutObject` | upload, internal, logs | Binary uploads, analysis results, internal state writes; fluentd writes structured log objects to the logs bucket |
| `s3:DeleteObject` | upload, internal, logs | Post-processing cleanup; log retention enforcement (`clean_k8s_logs`) |
| `s3:ListBucket` | upload, internal, logs | Log enumeration by prefix (`bucket.objects.filter`); `HeadBucket` checks in the `s3buckets` management command |
| `s3:CreateMultipartUpload` | upload | Multipart threshold is 16 MB — any upload over this size uses multipart |
| `s3:UploadPart` | upload | Multipart upload parts |
| `s3:CompleteMultipartUpload` | upload | Finalise multipart upload |
| `s3:AbortMultipartUpload` | upload | Clean up incomplete multipart uploads |

> `s3:ListBucket` must be granted on the bucket ARN (`arn:aws:s3:::bucket-name`),
> not the object ARN (`arn:aws:s3:::bucket-name/*`). The policy above handles this
> by listing both forms under `Resource` for each statement where it is needed.

## Worker IAM role (optional)

The worker accesses two buckets:

- **Upload bucket** — downloads the binary to scan (`s3:GetObject`) and uploads result
  bundles back (`s3:PutObject` + multipart)
- **Internal bucket** — reads signature files (`s3:GetObject`); the frontend embeds
  `s3://<internal-bucket>/worker-data/<file>` URLs in the scan job and the worker
  fetches them directly (in container mode `S3_SIGNATURE_BUCKET = S3_INTERNAL_BUCKET`)

It does not touch the logs bucket.

By default, the worker pod uses the same credentials as the frontend (injected via
the shared `bdba.s3env` template), so it inherits the full policy above. If you want
least-privilege isolation, give the worker its own IAM role with this smaller policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "WorkerUploadBucket",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:CreateMultipartUpload",
        "s3:UploadPart",
        "s3:CompleteMultipartUpload",
        "s3:AbortMultipartUpload"
      ],
      "Resource": [
        "arn:aws:s3:::my-bdba-uploads",
        "arn:aws:s3:::my-bdba-uploads/*"
      ]
    },
    {
      "Sid": "WorkerInternalBucket",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject"
      ],
      "Resource": [
        "arn:aws:s3:::my-bdba-internal/*"
      ]
    }
  ]
}
```

### Wiring dedicated service accounts

The chart creates dedicated service accounts for the worker and fluentd, mirroring
the `frontend.serviceAccount` pattern. Annotate each with its IAM role ARN:

```yaml
worker:
  serviceAccount:
    create: true
    annotations:
      eks.amazonaws.com/role-arn: "arn:aws:iam::123456789012:role/bdba-worker-s3-role"

fluentd:
  serviceAccount:
    create: true
    annotations:
      eks.amazonaws.com/role-arn: "arn:aws:iam::123456789012:role/bdba-fluentd-s3-role"
```

Fluentd only writes log objects to the logs bucket, so its IAM role can be
scoped to just `s3:PutObject`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "FluentdLogsBucket",
      "Effect": "Allow",
      "Action": [
        "s3:PutObject"
      ],
      "Resource": [
        "arn:aws:s3:::my-bdba-logs/*"
      ]
    }
  ]
}
```

The frontend role covers the read/delete side of the logs bucket used when bundling
support archives. Leave `s3AccessKeyId` and `s3SecretAccessKey` empty so the IRSA
token is used rather than static credentials.

### Initial bucket creation (optional)

If you want the `s3buckets` management command to create the buckets (rather than
pre-creating them outside the chart), also grant:

```json
{
  "Sid": "CreateBuckets",
  "Effect": "Allow",
  "Action": ["s3:CreateBucket"],
  "Resource": [
    "arn:aws:s3:::my-bdba-uploads",
    "arn:aws:s3:::my-bdba-internal",
    "arn:aws:s3:::my-bdba-logs"
  ]
}
```

This is not needed in normal operation once the buckets exist.

### Checking buckets exist

You can check that the application is able to access buckets using:

```sh
kubectl exec -it <frontend-pod> -- /srv/venv/appcheck-frontend/bin/python /srv/apps/appcheck-frontend/manage.py s3buckets --check
```
