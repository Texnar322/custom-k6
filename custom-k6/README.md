# custom-k6

Custom k6 distribution for load testing HTTP services, Apache Kafka, SQL databases, Redis and MQTT.

## Included versions

Versions are pinned in [`config/versions.env`](config/versions.env). The initial baseline is:

| Component | Version | Purpose |
|---|---:|---|
| k6 | `v1.8.2` | Core load-testing engine |
| xk6 | `v1.4.14` | Custom binary builder |
| Grafana xk6-kafka | `v0.1.0` | Apache Kafka; pure Go |
| xk6-sql | `v1.0.5` | SQL API |
| xk6-sql-driver-mysql | `v0.2.1` | MySQL driver |
| xk6-sql-driver-postgres | `v0.1.1` | PostgreSQL driver |
| xk6-redis | `v0.3.6` | Redis |
| xk6-mqtt | `v0.2.0` | MQTT |
| xk6-faker | `v0.4.4` | Test data generation |

The Kafka extension is the Grafana-owned pure-Go implementation. It avoids CGO and native `librdkafka` dependencies, which makes the same build approach practical for Windows and Linux. Its `v0.x` API is pre-1.0 and may change; check its compatibility and migration notes before upgrading it.

SQL drivers are separate extensions. This repository embeds MySQL and PostgreSQL drivers as common defaults. Add another driver module if your target database is different.

## Supported release artifacts

GitHub Actions builds:

- `custom-k6_v1.8.2_linux_amd64.tar.gz`
- `custom-k6_v1.8.2_windows_amd64.zip`
- `SHA256SUMS`

The binary inside the archives is named `k6` (Linux) or `k6.exe` (Windows).

## Build locally

Prerequisites: Git and the Go version in `.go-version`.

### Linux

```bash
sudo apt-get update
sudo apt-get install -y git
bash scripts/build-linux.sh
./dist/k6 version
./dist/k6 run examples/smoke.js
```

### Windows PowerShell

```powershell
# Install Git and the Go version specified in .go-version first.
Set-ExecutionPolicy -Scope Process Bypass
.\scripts\build-windows.ps1
.\dist\k6.exe version
.\dist\k6.exe run .\examples\smoke.js
```

The build scripts set `CGO_ENABLED=0`, pin all module versions and run a smoke test that imports every embedded extension.

## Publish to your GitHub account

1. Create an empty GitHub repository named `custom-k6` (do not add a README or license if you plan to push this directory as-is).
2. Download and extract this project archive.
3. In the extracted directory, run:

```bash
git init
git add .
git commit -m "Initial custom k6 distribution"
git branch -M main
git remote add origin https://github.com/<YOUR_GITHUB_USER>/custom-k6.git
git push -u origin main
```

4. Create and push a version tag:

```bash
git tag v0.1.0
git push origin v0.1.0
```

5. Open the repository's **Actions** tab. Wait until Linux and Windows jobs pass. The `publish` job creates a GitHub Release and attaches the two binaries plus checksums.
6. Download the matching archive from **Releases** on any machine. Verify it with `sha256sum -c SHA256SUMS` on Linux or `Get-FileHash` on Windows.

To publish a later build, update pinned versions only after testing, commit the changes, create a new tag such as `v0.1.1`, and push it.

## Test extension imports

```bash
k6 run examples/smoke.js
```

This checks that modules can be imported. It does not test connectivity or credentials for external services.

## Kafka TLS example

`examples/kafka/producer-tls.js` shows the TLS CA-only pattern using `kafka_ca.crt`:

```bash
# Linux/macOS
KAFKA_BROKERS="broker1.example:9093,broker2.example:9093" \
KAFKA_TOPIC="load-test-topic" \
KAFKA_CA_FILE="./certs/kafka_ca.crt" \
./k6 run examples/kafka/producer-tls.js
```

PowerShell:

```powershell
$env:KAFKA_BROKERS = "broker1.example:9093"
$env:KAFKA_TOPIC = "load-test-topic"
$env:KAFKA_CA_FILE = ".\certs\kafka_ca.crt"
.\k6.exe run .\examples\kafka\producer-tls.js
```

The CA certificate verifies the broker. This is not mTLS. If the Kafka cluster requires client-certificate authentication, configure the client certificate and private key according to the extension's current TLS API. Do not commit private keys, passwords, production certificates or credentials to Git. The repository ignores local certificate files by default.

## Updating versions

Edit `config/versions.env` and `.go-version` together. Run both build scripts or trigger the Actions workflow on a branch before creating a release tag. Keep the extension module paths and versions pinned; avoid `@latest` in release builds.

## Important notes

- The smoke test proves module loading, not that Kafka/SQL/Redis/MQTT services are reachable.
- The Kafka extension is pre-1.0; review upstream release notes before upgrading.
- k6 and the Grafana Kafka extension are AGPL-3.0. Review upstream licenses and your organization's redistribution obligations before distributing custom binaries.
- GitHub Releases are used for binaries; do not commit compiled executables to the Git repository.
- `k6` itself supports HTTP, browser, WebSocket and other built-in protocols without extra extensions.

## Upstream references

- [k6 extensions](https://grafana.com/docs/k6/latest/extensions/explore/)
- [xk6 build tool](https://github.com/grafana/xk6)
- [Grafana xk6-kafka](https://github.com/grafana/xk6-kafka)
- [xk6-sql](https://github.com/grafana/xk6-sql)
- [xk6-redis](https://github.com/grafana/xk6-redis)
- [xk6-mqtt](https://github.com/grafana/xk6-mqtt)
- [xk6-faker](https://github.com/grafana/xk6-faker)
