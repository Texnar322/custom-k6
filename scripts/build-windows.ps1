$ErrorActionPreference = "Stop"
$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
Set-Location $Root

$Config = @{}
Get-Content "config/versions.env" | ForEach-Object {
    $Line = $_.Trim()
    if ($Line -and -not $Line.StartsWith("#")) {
        $Parts = $Line -split "=", 2
        $Config[$Parts[0].Trim()] = $Parts[1].Trim()
    }
}

$env:CGO_ENABLED = "0"
$env:GOOS = "windows"
$env:GOARCH = "amd64"

go install "go.k6.io/xk6/cmd/xk6@$($Config.XK6_VERSION)"
if ($LASTEXITCODE -ne 0) { throw "Could not install xk6" }
$env:PATH = "$(go env GOPATH)\bin;$env:PATH"

New-Item -ItemType Directory -Force -Path "dist" | Out-Null
xk6 build --k6-version $Config.K6_VERSION `
  --with "github.com/grafana/xk6-kafka@$($Config.KAFKA_VERSION)" `
  --with "github.com/grafana/xk6-sql@$($Config.SQL_VERSION)" `
  --with "github.com/grafana/xk6-sql-driver-mysql@$($Config.SQL_MYSQL_VERSION)" `
  --with "github.com/grafana/xk6-sql-driver-postgres@$($Config.SQL_POSTGRES_VERSION)" `
  --with "github.com/grafana/xk6-redis@$($Config.REDIS_VERSION)" `
  --with "github.com/grafana/xk6-mqtt@$($Config.MQTT_VERSION)" `
  --with "github.com/grafana/xk6-faker@$($Config.FAKER_VERSION)" `
  --output "dist/k6.exe"
if ($LASTEXITCODE -ne 0) { throw "xk6 build failed" }

& "dist/k6.exe" version
if ($LASTEXITCODE -ne 0) { throw "Custom k6 failed to start" }
& "dist/k6.exe" run "examples/smoke.js"
if ($LASTEXITCODE -ne 0) { throw "Extension smoke test failed" }

Compress-Archive -Path "dist/k6.exe" -DestinationPath "dist/custom-k6_$($Config.K6_VERSION)_windows_amd64.zip" -Force
