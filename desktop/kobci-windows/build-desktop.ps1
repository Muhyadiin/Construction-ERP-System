$ErrorActionPreference = 'Stop'
$project = (Resolve-Path "$PSScriptRoot/../src-tauri").Path
Push-Location $project
try {
    # The local splash is all the shell embeds. The tested server serves the ERP UI.
    $assets = 'target/kobci-shell'
    New-Item -ItemType Directory -Path $assets -Force | Out-Null
    Copy-Item '../../frontend/public/splash.html' "$assets/splash.html"
    Copy-Item '../../frontend/public/splash.html' "$assets/index.html"
    $config = Get-Content tauri.conf.json -Raw | ConvertFrom-Json
    $config.app.windows[0].title = 'Kobci Construction ERP'
    $env:TAURI_CONFIG = @{
        productName = 'Kobci Construction ERP'
        identifier = 'org.kobci.constructionerp'
        app = @{ windows = @($config.app.windows) }
        build = @{ frontendDist = $assets }
        bundle = @{ externalBin = @(); resources = @() }
    } | ConvertTo-Json -Depth 10 -Compress
    cargo build --locked --release --features kobci-windows
    if ($LASTEXITCODE) { throw 'Native desktop build failed' }
    Copy-Item 'target/release/openconstructionerp-desktop.exe' "$PSScriptRoot/Kobci.exe"
} finally {
    Pop-Location
    Remove-Item Env:TAURI_CONFIG -ErrorAction SilentlyContinue
}

# Package the evergreen x64 standalone runtime so installation also works offline.
# Setup invokes it only on Windows installations without a WebView2 runtime.
$runtime = "$PSScriptRoot/MicrosoftEdgeWebView2RuntimeInstallerX64.exe"
Invoke-WebRequest 'https://go.microsoft.com/fwlink/?linkid=2124701' -OutFile $runtime
$signature = Get-AuthenticodeSignature -LiteralPath $runtime
if ($signature.Status -ne 'Valid' -or $signature.SignerCertificate.Subject -notmatch '(?:^|, )O=Microsoft Corporation(?:,|$)') {
    throw 'Microsoft WebView2 runtime publisher verification failed'
}
if ((Get-Item $runtime).Length -lt 80MB) { throw 'Expected the full x64 offline WebView2 runtime' }
