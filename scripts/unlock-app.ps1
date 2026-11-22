param (
    [string]$SecretKey = ""
)

$SupabaseUrl = "https://smbepsxpvswrxlbfbnrj.supabase.co"
$KeyFile = Join-Path $PSScriptRoot ".developer_key"

if (-not $SecretKey) {
    if (Test-Path $KeyFile) {
        $SecretKey = (Get-Content $KeyFile).Trim()
    } else {
        $SecretKey = Read-Host "Paste your Supabase Secret Key"
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
}

Write-Host "Contacting Supabase to unlock app..." -ForegroundColor Cyan

try {
    $url = "$SupabaseUrl/rest/v1/announcements?title=eq.APP_LICENSE_LOCK"
    Invoke-RestMethod -Uri $url -Headers $Headers -Method Delete | Out-Null

    Write-Host ""
    Write-Host "==========================================================" -ForegroundColor Green
    Write-Host "  APP IS NOW UNLOCKED!                                    " -ForegroundColor Green
    Write-Host "  The app is fully accessible again on all phones.        " -ForegroundColor White
    Write-Host "==========================================================" -ForegroundColor Green
    Write-Host ""
} catch {
    Write-Host "Error unlocking app: $_" -ForegroundColor Red
}
