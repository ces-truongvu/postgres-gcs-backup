FROM postgres:14-alpine

RUN apk add --update \
  bash \
  curl \
  py-pip \
  py-cffi \
  && pip install --upgrade pip \
  && apk add --virtual build-deps \
  gcc \
  libffi-dev \
  linux-headers \
  musl-dev \
  openssl-dev \
  && pip install gsutil \
  && apk del build-deps \
  && rm -rf /var/cache/apk/*

ADD . /postgres-gcs-backup

WORKDIR /postgres-gcs-backup

RUN chmod +x /postgres-gcs-backup/backup.sh

ENTRYPOINT ["/postgres-gcs-backup/backup.sh"]
