# Inspect the installed WebView via Windows accessibility on the disposable runner.
param([Parameter(Mandatory)][int]$AppProcessId, [ValidateSet('failure', 'success')][string]$Mode)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName UIAutomationClient, UIAutomationTypes
$ui = [System.Windows.Automation.AutomationElement]
$subtree = [System.Windows.Automation.TreeScope]::Descendants
$all = [System.Windows.Automation.Condition]::TrueCondition
$until = [DateTime]::UtcNow.AddSeconds($(if ($Mode -eq 'failure') { 150 } else { 780 }))
$observed = @()
while ([DateTime]::UtcNow -lt $until) {
    $app = Get-Process -Id $AppProcessId -ErrorAction Stop
    if ($app.MainWindowHandle -ne [IntPtr]::Zero) {
        try {
            $root = $ui::FromHandle($app.MainWindowHandle)
            $elements = $root.FindAll($subtree, $all)
            $names = @($elements | ForEach-Object { $_.Current.Name } | Where-Object { $_ })
            $observed = @($names | Select-Object -First 25)
            if ($Mode -eq 'failure') {
                if (($names -match '(?i)^copy (log|details)$') -and ($names -match '(?i)could not start|failed|startup failure|stopped unexpectedly')) {
                    Write-Host 'The native window displayed the failure and an accessible copy action.'
                    exit 0
                }
            } else {
                if ($names -match '(?i)^sign in$|^log in$|^create (an |your )?(account|administrator)|^email address$|^projects$') {
                    Write-Host 'The installed ERP window displayed its sign-in, setup or project interface.'
                    exit 0
                }
            }
        } catch [System.Windows.Automation.ElementNotAvailableException] { }
    }
    Start-Sleep -Seconds 2
}
throw "The $Mode window did not expose the expected controls. Window title: $($app.MainWindowTitle). Accessible controls: $($observed -join ' | ')"
