# Convenience wrapper for local Windows builds.
& "$PSScriptRoot/build-windows.ps1"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
