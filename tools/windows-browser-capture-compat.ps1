param(
  [switch]$DisableMpo,
  [switch]$KillBrowsers,
  [switch]$Undo
)

$ErrorActionPreference = "Stop"

function Test-Admin {
  $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
  $principal = [Security.Principal.WindowsPrincipal]::new($identity)
  return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Set-Dword {
  param(
    [Parameter(Mandatory=$true)][string]$Path,
    [Parameter(Mandatory=$true)][string]$Name,
    [Parameter(Mandatory=$true)][int]$Value
  )
  if (-not (Test-Path $Path)) {
    New-Item -Path $Path -Force | Out-Null
  }
  New-ItemProperty -Path $Path -Name $Name -PropertyType DWord -Value $Value -Force | Out-Null
}

function Remove-Value {
  param(
    [Parameter(Mandatory=$true)][string]$Path,
    [Parameter(Mandatory=$true)][string]$Name
  )
  if (Test-Path $Path) {
    Remove-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
  }
}

function Set-BrowserLocalState {
  param(
    [Parameter(Mandatory=$true)][string]$Path,
    [Parameter(Mandatory=$true)][bool]$Enabled
  )
  if (-not (Test-Path $Path)) {
    return
  }
  try {
    $json = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
    if ($null -eq $json) {
      return
    }
    if (-not ($json.PSObject.Properties.Name -contains "hardware_acceleration_mode_enabled")) {
      $json | Add-Member -NotePropertyName "hardware_acceleration_mode_enabled" -NotePropertyValue $Enabled
    } else {
      $json.hardware_acceleration_mode_enabled = $Enabled
    }
    $json | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $Path -Encoding UTF8
    Write-Host "Updated browser Local State: $Path"
  } catch {
    Write-Warning "Could not update browser Local State: $Path ($($_.Exception.Message))"
  }
}

function Stop-Browsers {
  Stop-Process -Name chrome,msedge,brave,opera,firefox -Force -ErrorAction SilentlyContinue
}

$browserPolicies = @(
  @{ Path = "HKCU:\Software\Policies\Google\Chrome"; Name = "HardwareAccelerationModeEnabled" },
  @{ Path = "HKCU:\Software\Policies\Microsoft\Edge"; Name = "HardwareAccelerationModeEnabled" },
  @{ Path = "HKCU:\Software\Policies\BraveSoftware\Brave"; Name = "HardwareAccelerationModeEnabled" }
)

$browserLocalStateFiles = @(
  Join-Path $env:LOCALAPPDATA "Google\Chrome\User Data\Local State",
  Join-Path $env:LOCALAPPDATA "Microsoft\Edge\User Data\Local State",
  Join-Path $env:LOCALAPPDATA "BraveSoftware\Brave-Browser\User Data\Local State"
)

if ($Undo) {
  foreach ($policy in $browserPolicies) {
    Remove-Value -Path $policy.Path -Name $policy.Name
  }
  if (Test-Admin) {
    Remove-Value -Path "HKLM:\SOFTWARE\Microsoft\Windows\Dwm" -Name "OverlayTestMode"
  }
  foreach ($file in $browserLocalStateFiles) {
    Set-BrowserLocalState -Path $file -Enabled $true
  }
  Write-Host "QT Desk browser capture compatibility settings were removed where possible."
  Write-Host "Restart Chrome/Edge and reconnect the RustDesk session."
  exit 0
}

if ($KillBrowsers) {
  Stop-Browsers
}

foreach ($policy in $browserPolicies) {
  Set-Dword -Path $policy.Path -Name $policy.Name -Value 0
}

foreach ($file in $browserLocalStateFiles) {
  Set-BrowserLocalState -Path $file -Enabled $false
}

Write-Host "Chrome, Edge, and Brave hardware acceleration settings are now disabled for the current Windows user."

if ($DisableMpo) {
  if (-not (Test-Admin)) {
    Write-Warning "MPO overlay disable requires Administrator. Re-run PowerShell as Administrator with -DisableMpo."
  } else {
    Set-Dword -Path "HKLM:\SOFTWARE\Microsoft\Windows\Dwm" -Name "OverlayTestMode" -Value 5
    Write-Host "Windows DWM MPO overlay is disabled. This helps some black/frozen browser video captures."
  }
}

Write-Host "Close all browser windows, reopen the browser, then reconnect QT Desk Web v3."
Write-Host "For Firefox, disable hardware acceleration manually in Settings > General > Performance."
