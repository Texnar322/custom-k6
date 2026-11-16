#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

# shellcheck disable=SC1091
source config/versions.env

export CGO_ENABLED=0
export GOOS=linux
export GOARCH=amd64

go install "go.k6.io/xk6/cmd/xk6@${XK6_VERSION}"
export PATH="$(go env GOPATH)/bin:$PATH"

mkdir -p dist
xk6 build --k6-version "$K6_VERSION" \
  --with "github.com/grafana/xk6-kafka@${KAFKA_VERSION}" \
  --with "github.com/grafana/xk6-sql@${SQL_VERSION}" \
  --with "github.com/grafana/xk6-sql-driver-mysql@${SQL_MYSQL_VERSION}" \
  --with "github.com/grafana/xk6-sql-driver-postgres@${SQL_POSTGRES_VERSION}" \
  --with "github.com/grafana/xk6-redis@${REDIS_VERSION}" \
  --with "github.com/grafana/xk6-mqtt@${MQTT_VERSION}" \
  --with "github.com/grafana/xk6-faker@${FAKER_VERSION}" \
  --output dist/k6

./dist/k6 version
./dist/k6 run examples/smoke.js

tar -C dist -czf "dist/custom-k6_${K6_VERSION}_linux_amd64.tar.gz" k6
