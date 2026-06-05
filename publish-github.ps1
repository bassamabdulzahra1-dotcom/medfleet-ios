# MedFleet iOS — رفع إلى GitHub
# شغّل مرة واحدة: gh auth login
$ErrorActionPreference = "Stop"
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

gh auth status | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "سجّل دخول GitHub أولاً:" -ForegroundColor Yellow
    gh auth login
}

$repo = "medfleet-ios"
Write-Host "إنشاء المستودع $repo ..."
gh repo create $repo --private --source=. --remote=origin --push --description "MedFleet iOS — تطبيق المندوب (SwiftUI)"

if ($LASTEXITCODE -eq 0) {
    $url = gh repo view --json url -q .url
    Write-Host "تم الرفع: $url" -ForegroundColor Green
}
