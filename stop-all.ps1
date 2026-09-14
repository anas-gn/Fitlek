# Stop all Sirvya services

Write-Host "Stopping Sirvya services..." -ForegroundColor Cyan

$jobs = Get-Job

if ($jobs.Count -eq 0) {
    Write-Host "No running services found." -ForegroundColor Yellow
    exit
}

foreach ($job in $jobs) {
    Write-Host "Stopping $($job.Name) (Job ID: $($job.Id))..." -ForegroundColor Yellow
    Stop-Job -Id $job.Id -Force
    Remove-Job -Id $job.Id -Force
}

Write-Host "All services stopped." -ForegroundColor Green
