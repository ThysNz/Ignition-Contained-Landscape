# Builds and starts the Ignition tools desktop; output is logged to start.log
Set-Location $PSScriptRoot
$log = Join-Path $PSScriptRoot 'start.log'
"=== $(Get-Date) ===" | Out-File $log -Encoding utf8
$os = docker version --format '{{.Server.Os}}' 2>&1
"Docker server OS: $os" | Out-File $log -Append -Encoding utf8
if ($os -ne 'linux') { "Docker must be in Linux containers mode." | Tee-Object $log -Append; exit 1 }
docker compose up -d --build 2>&1 | ForEach-Object { "$_" } | Tee-Object -FilePath $log -Append
"Waiting 30s..." | Out-File $log -Append -Encoding utf8
Start-Sleep 30
docker ps -a --filter name=ignition-tools 2>&1 | Out-File $log -Append -Encoding utf8
docker logs --tail 40 ignition-tools 2>&1 | Out-File $log -Append -Encoding utf8
"=== done $(Get-Date) - open https://localhost:3001 ===" | Tee-Object $log -Append
