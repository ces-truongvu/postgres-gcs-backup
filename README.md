# postgres-gcs-backup

This project aims to provide a simple way to perform a PostgreSQL server/db backup using `pg_dump` and to upload it to Google Cloud Storage. It was greatly inspired from [`takemetour/docker-postgres-gcs-backup`](https://github.com/takemetour/docker-postgres-gcs-backup).

We provide a kubernetes support thanks to the helm chart located in the `chart` folder of this repository.

### Docker image

You can pull the public image from Docker Hub:

    docker pull diogopms/postgres-gcs-backup:latest

### Configuration

The following table lists the configurable parameters you can set up.

| Environment Variable     | Required | Default        | Description                                                                          |
| ------------------------ | -------- | -------------- | ------------------------------------------------------------------------------------ |
| `JOB_NAME`               | No       | `default-name` | Job name                                                                             |
| `BACKUP_DIR`             | No       | `/tmp`         | The path where the `pg_dump` result will be temporarily stored.                      |
| `BOTO_CONFIG_PATH`       | No       | `/root/.boto`  | The path where `gsutil` will search for the boto configuration file.                 |
| `GCS_BUCKET`             | Yes      |                | The bucket you want to upload the backup archive to.                                 |
| `GCS_KEY_FILE_PATH`      | Yes      |                | The location where the GCS serviceaccount key file will be mounted.                  |
| `POSTGRES_HOST`          | No       | `localhost`    | The PostgreSQL server host.                                                          |
| `POSTGRES_PORT`          | No       | `5432`         | The PostgreSQL port.                                                                 |
| `POSTGRES_DB`            | No       |                | The database to backup. By default, a backup of all the databases will be performed. |
| `POSTGRES_USER`          | No       |                | The PostgreSQL user if any.                                                          |
| `POSTGRES_PASSWORD`      | No       |                | The PostgreSQL password if any.                                                      |
| `MATTERMOST_ALERTS`      | No       |                | `true` if you want to send Slack alerts in case of failure.                          |
| `MATTERMOST_WEBHOOK_URL` | No       |                | The Incoming WebHook URL to use to send the alerts.                                  |

You can set all of these variables within your `values.yaml` file under the `env` dict key.

### Usage

#### Run locally

You can run the script locally:

    cd /path/to/postgres-gcs-backup
    chmod +x backup.sh
    GCS_BUCKET=<gs://bucket_name> \
    ./backup.sh

Please note that you can set any environment variable described in the previous section! As an example, to enable the Slack alerts on failure:

    MATTERMOST_ALERTS=true \
    MATTERMOST_WEBHOOK_URL=<webhook_url> \
    GCS_BUCKET=<gs://bucket_name> \
    ./backup.sh

#### Run within Kubernetes

##### Installing the Chart

To install the chart with the release name my-release within you Kubernetes cluster:

    $ helm install --name my-release chart/postgres-gcs-backup

The command deploys the chart on the Kubernetes cluster in the default namespace. The configuration section lists the parameters that can be configured during installation.

##### Uninstalling the Chart

To uninstall/delete the my-release deployment:

    $ helm delete my-release

The command removes all the Kubernetes components associated with the chart and deletes the release.

##### Bundle the Chart

Bundle chart to use for another purpose like Terraform

```sh
CHART_NAME=postgres-gcs-backup
CHART_VERSION=0.1.8

cd postgres-gcs-backup/chart

helm package $CHART_NAME --version "$CHART_VERSION"

helm repo index
```

After commit change to your repository, so now you are able to use this chart in your Terraform code. For instance:

```ts
provider "helm" {
  alias = "my_postgres_auto_backup"

  ...
}
resource "helm_release" "postgres_auto_backup" {
  provider   = helm.my_postgres_auto_backup
  repository = "https://raw.githubusercontent.com/ces-truongvu/postgres-gcs-backup/master/chart"
  name       = "release_name"
  chart      = "postgres-gcs-backup"

  set {
    name  = "env.POSTGRES_HOST"
    value = var.postgres_hostname
  }

  set {
    name  = "env.POSTGRES_DB"
    value = var.postgres_db
  }
}
```

### Authenticate with GCS

#### Using the gcloud CLI

If you are running the script locally, the easiest solution is to sign in to the google account associated with your Google Cloud Storage data:

    gcloud init --console-only

More information on how to setup gsutil locally [here](https://cloud.google.com/storage/docs/gsutil_install).

#### Using a service account within Kubernetes

You can create a [service account](https://cloud.google.com/iam/docs/creating-managing-service-accounts) with the required roles to write to GCS attached.

To use the resulting JSON key file within Kubernetes you can create a secret from it by running the following command:

      kubectl create secret generic postgres-gcs-backup \
      --from-file=credentials.json=/path/to/your/key.json

Then you will need to specify this secret name via the `--set secretName=<your_secret_name>` argument to the `helm install` command or by specifying it directly in your `values.yaml` file (by default, the secret name is set to `postgres-gcs-backup`). The key file will be mounted by default under `/secrets/gcp/credentials.json` and the `GCS_KEY_FILE_PATH` variable should point to it.
