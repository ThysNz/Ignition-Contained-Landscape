# Starts the Linux-container Ignition 8.3.10 gateway; output is logged to start.log
Set-Location $PSScriptRoot
$log = Join-Path $PSScriptRoot 'start.log'
"=== $(Get-Date) ===" | Out-File $log
$os = docker version --format '{{.Server.Os}}' 2>&1
"Docker server OS: $os" | Tee-Object $log -Append
if ($os -ne 'linux') {
  "Docker is in Windows mode. Right-click the Docker tray icon > 'Switch to Linux containers...', then rerun." | Tee-Object $log -Append
  exit 1
}
docker compose up -d 2>&1 | Tee-Object $log -Append
"Waiting 60s for the gateway to start..." | Tee-Object $log -Append
Start-Sleep 60
docker ps -a --filter name=ignition-backend 2>&1 | Tee-Object $log -Append
docker logs --tail 40 ignition-backend 2>&1 | Tee-Object $log -Append
"=== done $(Get-Date) - open http://localhost:9088 ===" | Tee-Object $log -Append
