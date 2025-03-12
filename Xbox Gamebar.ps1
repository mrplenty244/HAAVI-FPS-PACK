If (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator"))
{
    Start-Process PowerShell.exe -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"{0}`"" -f $PSCommandPath) -Verb RunAs
    Exit
}

$Host.UI.RawUI.WindowTitle = "Disable Xbox Game Bar (Administrator)"
$Host.UI.RawUI.BackgroundColor = "Black"
$Host.PrivateData.ProgressBackgroundColor = "Black"
$Host.PrivateData.ProgressForegroundColor = "White"
Clear-Host

Write-Host "Disabling Xbox Game Bar and related services..."

$progresspreference = 'silentlycontinue'

# Disable Game Bar in registry
reg add "HKCU\System\GameConfigStore" /v "GameDVR_Enabled" /t REG_DWORD /d "0" /f | Out-Null
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v "AppCaptureEnabled" /t REG_DWORD /d "0" /f | Out-Null
reg add "HKCU\Software\Microsoft\GameBar" /v "UseNexusForGameBarEnabled" /t REG_DWORD /d "0" /f | Out-Null

# Disable services related to Xbox and Game Bar
$services = @(
    "GameInputSvc",
    "BcastDVRUserService",
    "XboxGipSvc",
    "XblAuthManager",
    "XblGameSave",
    "XboxNetApiSvc"
)

foreach ($service in $services) {
    reg add "HKLM\SYSTEM\ControlSet001\Services\$service" /v "Start" /t REG_DWORD /d "4" /f | Out-Null
}

# Stop any running Game Bar processes
Stop-Process -Force -Name GameBar -ErrorAction SilentlyContinue | Out-Null

# Uninstall Xbox and Game Bar-related apps
$apps = @(
    "Microsoft.GamingApp",
    "Microsoft.Xbox.TCUI",
    "Microsoft.XboxApp",
    "Microsoft.XboxGameOverlay",
    "Microsoft.XboxGamingOverlay",
    "Microsoft.XboxIdentityProvider",
    "Microsoft.XboxSpeechToTextOverlay"
)

foreach ($app in $apps) {
    Get-AppxPackage -AllUsers *$app* | Remove-AppxPackage
}

Write-Host "Xbox Game Bar and related services have been disabled."
Write-Host "Restart your PC to apply changes..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
Start-Process ms-settings:gaming-gamebar
exit
