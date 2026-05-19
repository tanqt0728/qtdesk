param(
  [switch]$IncludeReferenceV2
)

$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$failed = $false

function Write-Section($text) {
  Write-Host ""
  Write-Host "== $text =="
}

function Mark-Fail($text) {
  $script:failed = $true
  Write-Host "FAIL: $text" -ForegroundColor Red
}

function Mark-Ok($text) {
  Write-Host "OK: $text" -ForegroundColor Green
}

function Relative($path) {
  return $path.Substring($root.Length).TrimStart("\", "/")
}

$ignoredDirs = @(
  ".git",
  ".chrome-web3-cdp-drag-1778862454",
  ".chrome-web3-cdp-drag-1778863001",
  ".chrome-web3-cdp-drag-1778863537",
  ".chrome-web3-cdp-drag-1778865109",
  "api-config"
)
if (-not $IncludeReferenceV2) {
  $ignoredDirs += "rustdesk-api-v2"
}

function Is-IgnoredPath($fullName) {
  $rel = Relative $fullName
  foreach ($dir in $ignoredDirs) {
    if ($rel -eq $dir -or $rel.StartsWith("$dir\", [System.StringComparison]::OrdinalIgnoreCase) -or $rel.StartsWith("$dir/", [System.StringComparison]::OrdinalIgnoreCase)) {
      return $true
    }
  }
  return $false
}

function Is-GitIgnored($fullName) {
  $rel = Relative $fullName
  $name = Split-Path $rel -Leaf
  if ($name -eq ".env") { return $true }
  if ($rel -like ".env.*" -and $name -ne ".env.example") { return $true }
  if ($rel -like "api-config\*" -or $rel -like "api-config/*") { return $true }
  if ($rel -like "rustdesk-api-v2\*" -or $rel -like "rustdesk-api-v2/*") { return $true }
  if ($rel -like ".chrome*" -or $rel -like "*.log" -or $rel -like "*.db" -or $rel -like "*.sqlite" -or $rel -like "*.sqlite3" -or $rel -like "*.zip" -or $rel -like "*.bak" -or $rel -like "*.pem" -or $rel -like "*.key") { return $true }
  if ($name -eq "id_ed25519" -or $name -eq "id_ed25519.pub") { return $true }
  if ($rel -like "secrets\*" -or $rel -like "secrets/*" -or $rel -like "runtime\*" -or $rel -like "runtime/*" -or $rel -like "publish\*" -or $rel -like "publish/*" -or $rel -like "dist\*" -or $rel -like "dist/*" -or $rel -like "build\*" -or $rel -like "build/*" -or $rel -like "node_modules\*" -or $rel -like "node_modules/*") { return $true }
  return $false
}

Write-Section "Required publication files"
$required = @(
  "README.md",
  "NOTICE.md",
  "TRADEMARKS.md",
  "SECURITY.md",
  "LICENSES/README.md",
  "docs/derived-code-map.md",
  ".env.example",
  ".gitignore"
)
foreach ($item in $required) {
  $path = Join-Path $root $item
  if (Test-Path $path) { Mark-Ok $item } else { Mark-Fail "Missing $item" }
}

Write-Section "Blocked artifact names"
$artifactPatterns = @(
  '(^|[\\/])\.env$',
  '\.sqlite3?$',
  '\.db$',
  '\.zip$',
  '(^|[\\/])id_ed25519(\.pub)?$',
  '\.pem$',
  '\.key$',
  '(^|[\\/])\.chrome',
  '(^|[\\/])secrets([\\/]|$)'
)
$artifacts = @()
Get-ChildItem -LiteralPath $root -Force -Recurse -File | Where-Object { -not (Is-IgnoredPath $_.FullName) } | ForEach-Object {
  if (Is-GitIgnored $_.FullName) { return }
  $rel = Relative $_.FullName
  foreach ($pattern in $artifactPatterns) {
    if ($rel -match $pattern) {
      $artifacts += $rel
      break
    }
  }
}
if ($artifacts.Count -eq 0) {
  Mark-Ok "No publish-blocking artifacts found outside ignored/reference paths"
} else {
  $artifacts | Sort-Object -Unique | ForEach-Object { Mark-Fail "Blocked artifact: $_" }
}

Write-Section "Secret-like text scan"
$secretPatterns = @(
  'BEGIN (RSA |OPENSSH |EC |DSA |PRIVATE )?PRIVATE KEY',
  'sk-[A-Za-z0-9]{20,}',
  'client[_-]?secret\s*[:=]\s*[^<>\s]{8,}',
  'api[_-]?token\s*[:=]\s*[^<>\s]{8,}',
  'access[_-]?token\s*[:=]\s*[^<>\s]{8,}',
  'jwt[_-]?key\s*[:=]\s*[^<>\s]{16,}',
  'KEY_PRIV\s*[:=]\s*[^<>\s]{16,}'
)
$scanFiles = Get-ChildItem -LiteralPath $root -Force -Recurse -File |
  Where-Object {
    -not (Is-IgnoredPath $_.FullName) -and
    -not (Is-GitIgnored $_.FullName) -and
    $_.Length -lt 2MB -and
    $_.FullName -notmatch '\\resources\\web\\main\.dart\.js$'
  }

$hits = @()
foreach ($file in $scanFiles) {
  $relFile = Relative $file.FullName
  if ($relFile -eq ".env.example" -or $relFile -like "docker-compose*.yml" -or $relFile -like "rustdesk-server\README*") {
    continue
  }
  if ($relFile -in @(
    "rustdesk-api\http\controller\api\login.go",
    "rustdesk-api\http\controller\api\ouath.go",
    "rustdesk-api\http\request\admin\oauth.go",
    "rustdesk-api\service\oauth.go",
    "rustdesk-api\lib\jwt\jwt_test.go"
  )) {
    continue
  }
  $lineNo = 0
  try {
    foreach ($line in [System.IO.File]::ReadLines($file.FullName)) {
      $lineNo++
      foreach ($pattern in $secretPatterns) {
        if ($line -match $pattern) {
          $hits += "$(Relative $file.FullName):$lineNo pattern=$pattern"
          break
        }
      }
    }
  } catch {
    # Binary or locked files are skipped by design.
  }
}
if ($hits.Count -eq 0) {
  Mark-Ok "No high-confidence secret patterns found"
} else {
  $hits | Sort-Object -Unique | ForEach-Object { Mark-Fail "Secret-like hit: $_" }
}

Write-Section "Reference directory"
if (Test-Path (Join-Path $root "rustdesk-api-v2")) {
  if ($IncludeReferenceV2) {
    Mark-Fail "rustdesk-api-v2 is included in scan; decide explicitly before public push"
  } else {
    Mark-Ok "rustdesk-api-v2 is present locally but ignored by default"
  }
} else {
  Mark-Ok "rustdesk-api-v2 is not present"
}

if ($failed) {
  Write-Host ""
  Write-Host "Public readiness check failed." -ForegroundColor Red
  exit 1
}

Write-Host ""
Write-Host "Public readiness check passed." -ForegroundColor Green
