$ErrorActionPreference = 'Stop'
$installer = Get-Item "$PSScriptRoot/Kobci-Construction-ERP-Windows-x64-Preview-1.exe"
$signature = (Get-AuthenticodeSignature -LiteralPath $installer.FullName).Status
if ($signature -ne 'NotSigned') { throw "Unexpected preview signing status: $signature" }
$setup = Start-Process -FilePath $installer.FullName -ArgumentList '/S' -Wait -PassThru
if ($setup.ExitCode -ne 0) { throw "Setup failed with exit code $($setup.ExitCode)" }
$linkPath = Join-Path ([Environment]::GetFolderPath('Programs')) 'Kobci Construction ERP/Kobci Construction ERP.lnk'
$link = (New-Object -ComObject WScript.Shell).CreateShortcut((Get-Item $linkPath).FullName)
$binary = (Get-Item "$env:LOCALAPPDATA/Programs/Kobci Construction ERP/server/openconstructionerp-server.exe").FullName
$data = (Get-Item "$env:LOCALAPPDATA/Kobci Construction ERP/Data").FullName
if ($link.TargetPath -ne $binary -or $link.WorkingDirectory -ne $data) { throw 'Incorrect shortcut paths' }
if ($link.Arguments -ne "serve --host 127.0.0.1 --port 8765 --no-demo --open --data-dir ""$data""") {
    throw "Unexpected shortcut arguments: $($link.Arguments)"
}
$process = Start-Process $binary -ArgumentList $link.Arguments -WorkingDirectory $link.WorkingDirectory -PassThru -RedirectStandardOutput "$env:RUNNER_TEMP/kobci-out.log" -RedirectStandardError "$env:RUNNER_TEMP/kobci-error.log"
try {
    $deadline = (Get-Date).AddMinutes(10)
    $ready = $false
    while ((Get-Date) -lt $deadline) {
        if ($process.HasExited) { throw "Server stopped with exit code $($process.ExitCode)" }
        try {
            $health = Invoke-RestMethod 'http://127.0.0.1:8765/api/health' -TimeoutSec 5
            if ($health.status -in @('healthy', 'degraded') -and $health.database -eq 'ok' -and $health.frontend_dist_present) {
                $ready = $true
                break
            }
        } catch {
            # The embedded database and HTTP listener are still starting.
        }
        Start-Sleep -Seconds 3
    }
    if (!$ready) { throw 'The installed app did not become healthy' }
    $page = Invoke-WebRequest 'http://127.0.0.1:8765/' -TimeoutSec 15
    if ($page.StatusCode -ne 200 -or $page.Content -notmatch 'id="root"') { throw 'Missing ERP interface' }
    Write-Host "Installed app, database and web UI passed. Authenticode: $signature"
} finally {
    if (!$process.HasExited) { taskkill /pid $process.Id /t /f | Out-Null }
}
