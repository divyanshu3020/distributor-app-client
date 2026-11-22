param (
    [string]$SecretKey = ""
)

$SupabaseUrl = "https://smbepsxpvswrxlbfbnrj.supabase.co"
$KeyFile = Join-Path $PSScriptRoot ".developer_key"

if (-not $SecretKey) {
    if (Test-Path $KeyFile) {
        $SecretKey = (Get-Content $KeyFile).Trim()
    } else {
        $SecretKey = Read-Host "Paste your Supabase Secret Key (from Dashboard -> API Keys -> Secret key)"
        if ($SecretKey) {
            $SecretKey.Trim() | Set-Content $KeyFile
        }
    }
}

if (-not $SecretKey) {
    Write-Host "Error: Supabase Secret key is required." -ForegroundColor Red
    exit 1
}

$Headers = @{
    "apikey" = $SecretKey
    "Authorization" = "Bearer $SecretKey"
    "Content-Type" = "application/json"
    "Prefer" = "return=representation"
}

Write-Host "Contacting Supabase to lock app..." -ForegroundColor Cyan

try {
    $checkUrl = "$SupabaseUrl/rest/v1/announcements?title=eq.APP_LICENSE_LOCK"
    $existing = Invoke-RestMethod -Uri $checkUrl -Headers $Headers -Method Get

    if ($existing.Count -gt 0) {
        $updateUrl = "$SupabaseUrl/rest/v1/announcements?title=eq.APP_LICENSE_LOCK"
        $body = @{
            is_published = $true
            message = "This demo build evaluation has ended. Please contact the developer to finalize terms and unlock the production app."
        } | ConvertTo-Json
        Invoke-RestMethod -Uri $updateUrl -Headers $Headers -Method Patch -Body $body | Out-Null
    } else {
        $insertUrl = "$SupabaseUrl/rest/v1/announcements"
        $body = @{
            title = "APP_LICENSE_LOCK"
            category = "general"
            message = "This demo build evaluation has ended. Please contact the developer to finalize terms and unlock the production app."
            is_published = $true
        } | ConvertTo-Json
        Invoke-RestMethod -Uri $insertUrl -Headers $Headers -Method Post -Body $body | Out-Null
    }

    Write-Host ""
    Write-Host "==========================================================" -ForegroundColor Red
    Write-Host "  APP IS NOW REMOTELY LOCKED!                             " -ForegroundColor Red
    Write-Host "  Anyone opening the app on their phone is now blocked.   " -ForegroundColor Yellow
    Write-Host "  To restore access later, simply run: .\scripts\unlock-app.ps1" -ForegroundColor White
    Write-Host "==========================================================" -ForegroundColor Red
    Write-Host ""
} catch {
    Write-Host "Error locking app: $_" -ForegroundColor Red
}
