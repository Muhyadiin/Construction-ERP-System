$ErrorActionPreference = 'Stop'
$setup = Get-Item "$PSScriptRoot/Kobci-Construction-ERP-Windows-x64-Preview-2.exe"
$old = "$env:RUNNER_TEMP/kobci-preview-1.exe"
$previousHash = '05548e557db4bead2ee13063126465b7104e830bdaec5a6546cb5214221c24b3'
Invoke-WebRequest 'https://github.com/Muhyadiin/Construction-ERP-System/releases/download/kobci-windows-preview-1/Kobci-Construction-ERP-Windows-x64-Preview-1.exe' -OutFile $old
if ((Get-FileHash $old).Hash -ne $previousHash) { throw 'Preview 1 reference installer differs' }
function Install-Setup($path) {
    $installed = Start-Process $path -ArgumentList '/S' -Wait -PassThru
    if ($installed.ExitCode) { throw "Setup failed with exit code $($installed.ExitCode)" }
}
Install-Setup $old
$data = (Get-Item "$env:LOCALAPPDATA/Kobci Construction ERP/Data").FullName
$marker = Join-Path $data 'preview-1-upgrade-test.txt'
$original = [guid]::NewGuid().ToString()
Set-Content -LiteralPath $marker -Value $original -NoNewline
Install-Setup $setup.FullName
if ((Get-Content -LiteralPath $marker -Raw) -ne $original) { throw 'Update changed the old data folder' }
if ((Get-AuthenticodeSignature $setup.FullName).Status -ne 'NotSigned') { throw 'Unexpected preview publisher status' }
$link = Join-Path ([Environment]::GetFolderPath('Programs')) 'Kobci Construction ERP/Kobci Construction ERP.lnk'
$shortcut = (New-Object -ComObject WScript.Shell).CreateShortcut((Get-Item $link).FullName)
$install = (Get-Item "$env:LOCALAPPDATA/Programs/Kobci Construction ERP").FullName
if ($shortcut.TargetPath -ne (Join-Path $install 'Kobci.exe') -or $shortcut.WorkingDirectory -ne $data -or $shortcut.Arguments) { throw 'Desktop shortcut is incorrect' }
$server = Join-Path $install 'server/openconstructionerp-server.exe'
$env:WEBVIEW2_ADDITIONAL_BROWSER_ARGUMENTS = '--remote-debugging-port=9338 --remote-debugging-address=127.0.0.1'

function Inspect-Window($mode) {
    Start-Process -FilePath $link
    try {
        node "$PSScriptRoot/check-window.mjs" $mode
        if ($LASTEXITCODE) { throw "The $mode desktop window did not pass" }
        $app = Get-Process -Name Kobci -ErrorAction Stop | Select-Object -First 1
        if ($app.MainWindowHandle -eq 0) { throw 'Missing native app window' }
        if ($mode -eq 'success') {
            $health = Invoke-RestMethod 'http://127.0.0.1:8765/api/health' -TimeoutSec 10
            if ($health.database -ne 'ok' -or !$health.frontend_dist_present -or !$health.schema_matches_models) { throw 'The installed ERP reported an unhealthy database or UI' }
            if ((Get-Content -LiteralPath $marker -Raw) -ne $original) { throw 'First launch changed prior user data' }
            Write-Host "Database and UI passed with $($health.modules_loaded) loaded modules."
        }
        $null = $app.CloseMainWindow()
        if (!$app.WaitForExit(90000)) { throw 'Native window failed to close cleanly' }
    } catch {
        $log = Join-Path $data 'logs/desktop-launcher.log'
        if (Test-Path $log) { Get-Content $log -Tail 45 | Where-Object { $_ -notmatch '(?i)password|token|secret' } | Write-Host }
        throw
    }
}

# Exercise the failure that a shortcut to the console server used to hide.
# Only substitute the runner's pristine installed test binary, then restore it.
$fixtureDir = New-Item -Path (Join-Path $env:RUNNER_TEMP 'kobci-fixture') -ItemType Directory -Force
Push-Location $fixtureDir.FullName
try {
    Set-Content -LiteralPath 'SimulatedServerExit.cs' -Value 'class ExitServer { static int Main() { System.Console.Error.WriteLine("Simulated startup failure"); return 23; } }'
    & "$env:WINDIR/Microsoft.NET/Framework64/v4.0.30319/csc.exe" /nologo /out:SimulatedServerExit.exe SimulatedServerExit.cs
    if ($LASTEXITCODE) { throw 'Could not compile the test fixture' }
} finally { Pop-Location }
Move-Item -LiteralPath $server -Destination "$server.saved"
try {
    Copy-Item -LiteralPath (Join-Path $fixtureDir.FullName 'SimulatedServerExit.exe') -Destination $server
    Inspect-Window failure
} finally {
    if (Test-Path -LiteralPath $server) { Remove-Item -LiteralPath $server }
    Move-Item -LiteralPath "$server.saved" -Destination $server
}
Inspect-Window success
