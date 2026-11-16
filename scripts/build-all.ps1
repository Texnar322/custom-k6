
$ErrorActionPreference = "Stop"

# Корень репозитория
$Root = Split-Path -Parent $PSScriptRoot
$ConfigDir = Join-Path $Root "config"
$DistDir = Join-Path $Root "dist"

New-Item -ItemType Directory -Force -Path $DistDir | Out-Null

# Проверка инструментов
foreach ($Tool in @("go", "xk6")) {
    if (-not (Get-Command $Tool -ErrorAction SilentlyContinue)) {
        throw "Tool not found: $Tool. Install it and check PATH."
    }
}

Write-Host "Go version:"
go version

Write-Host "xk6 version:"
xk6 version

# Читаем versions.env
$Versions = @{}

Get-Content (Join-Path $ConfigDir "versions.env") | ForEach-Object {
    if ($_ -match '^\s*([A-Z0-9_]+)=(.+)$') {
        $Versions[$matches[1]] = $matches[2].Trim()
    }
}

$K6Version = $Versions["K6_VERSION"]

if (-not $K6Version) {
    throw "K6_VERSION not found in versions.env"
}

# Сопоставление модулей и переменных версий
$VersionMap = @{
    "xk6-kafka"              = "KAFKA_VERSION"
    "xk6-sql"                = "SQL_VERSION"
    "xk6-sql-driver-mysql"   = "SQL_MYSQL_VERSION"
    "xk6-sql-driver-postgres"= "SQL_POSTGRES_VERSION"
    "xk6-redis"              = "REDIS_VERSION"
    "xk6-mqtt"               = "MQTT_VERSION"
    "xk6-faker"              = "FAKER_VERSION"
}

# Формируем аргументы расширений
$WithArgs = @()

Get-Content (Join-Path $ConfigDir "extensions.txt") | ForEach-Object {
    $Module = $_.Trim()

    if (-not $Module -or $Module.StartsWith("#")) {
        return
    }

    $ModuleName = ($Module -split "/")[-1]
    $VersionKey = $VersionMap[$ModuleName]

    if (-not $VersionKey) {
        throw "Unknown extension: $Module"
    }

    $Version = $Versions[$VersionKey]

    if (-not $Version) {
        throw "Version $VersionKey not found in versions.env"
    }

    $WithArgs += @("--with", "$Module@$Version")

    Write-Host "Extension: $Module@$Version"
}

if ($WithArgs.Count -eq 0) {
    throw "No extensions configured"
}

# Кросс-компиляция без CGO
$env:CGO_ENABLED = "0"

function Build-K6 {
    param(
        [string]$OS,
        [string]$BinaryName
    )

    $Output = Join-Path $DistDir $BinaryName

    Write-Host ""
    Write-Host "==================================" -ForegroundColor Cyan
    Write-Host "Building $OS AMD64" -ForegroundColor Cyan
    Write-Host "==================================" -ForegroundColor Cyan

    $Xk6Args = @(
        "build",
        $K6Version,
        "--os", $OS,
        "--arch", "amd64",
        "--output", $Output
    ) + $WithArgs

    & xk6 --verbose @Xk6Args

    if ($LASTEXITCODE -ne 0) {
        throw "Build failed for $OS"
    }

    if (-not (Test-Path $Output)) {
        throw "Output binary not found: $Output"
    }

    Write-Host "Build successful: $Output" -ForegroundColor Green
}

# Linux AMD64
Build-K6 -OS "linux" -BinaryName "k6-linux-amd64"

# Windows AMD64
Build-K6 -OS "windows" -BinaryName "k6-windows-amd64.exe"

# Создаём архив Linux
tar.exe -czf (Join-Path $DistDir "custom-k6-linux-amd64.tar.gz") `
    -C $DistDir "k6-linux-amd64"

if ($LASTEXITCODE -ne 0) {
    throw "Linux archive creation failed"
}

# Создаём архив Windows
Compress-Archive `
    -LiteralPath (Join-Path $DistDir "k6-windows-amd64.exe") `
    -DestinationPath (Join-Path $DistDir "custom-k6-windows-amd64.zip") `
    -Force

# SHA256
Get-ChildItem $DistDir -File |
    Where-Object { $_.Name -like "k6-*" -or $_.Name -like "custom-k6-*" } |
    Get-FileHash -Algorithm SHA256 |
    ForEach-Object {
        "$($_.Hash)  $([System.IO.Path]::GetFileName($_.Path))"
    } | Set-Content (Join-Path $DistDir "SHA256SUMS.txt")

Write-Host ""
Write-Host "==================================" -ForegroundColor Green
Write-Host "BUILD COMPLETED" -ForegroundColor Green
Write-Host "==================================" -ForegroundColor Green

Get-ChildItem $DistDir
