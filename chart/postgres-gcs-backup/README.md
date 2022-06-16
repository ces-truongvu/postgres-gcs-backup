# Package Helm chart

Run the following command below:

```sh
CHART_NAME=postgres-gcs-backup

CHART_VERSION=0.1.1

CHART_VERSION=0.1.2

helm package $CHART_NAME --version "$CHART_VERSION"

helm repo index .

# the push the package to git repo
```
