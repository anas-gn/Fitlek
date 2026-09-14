# Start all Sirvya services on Windows
# Ports: Sirvya backend 3000, Workout API 3001, Workout frontend 5173, Flutter web 8090

$ErrorActionPreference = "Stop"

function Test-PortInUse {
    param([int]$Port)
    try {
        $connection = New-Object System.Net.Sockets.TcpClient
        $connection.Connect("127.0.0.1", $Port)
        $connection.Close()
        return $true
    } catch {
        return $false
    }
}

# Check if ports are already in use
$portsToCheck = @(3000, 3001, 5173, 8090)
$portsInUse = @()
foreach ($port in $portsToCheck) {
    if (Test-PortInUse -Port $port) {
        $portsInUse += $port
    }
}

if ($portsInUse.Count -gt 0) {
    Write-Host "ERROR: The following ports are already in use: $($portsInUse -join ', ')" -ForegroundColor Red
    Write-Host "Please stop the services using these ports before running this script." -ForegroundColor Yellow
    exit 1
}

Write-Host "Starting Sirvya services..." -ForegroundColor Cyan

# Start Sirvya backend (port 3000)
Write-Host "Starting Sirvya backend on port 3000..." -ForegroundColor Yellow
$backendJob = Start-Job -ScriptBlock {
    Set-Location "c:\Users\natso\OneDrive\Desktop\Sirvya\Fitlek\backend"
    node index.js
} -Name "SirvyaBackend"
Start-Sleep -Seconds 2
Write-Host "Sirvya backend started (Job ID: $($backendJob.Id))" -ForegroundColor Green

# Start Workout API (port 3001)
Write-Host "Starting Workout API on port 3001..." -ForegroundColor Yellow
$env:PORT = "3001"
$workoutApiJob = Start-Job -ScriptBlock {
    Set-Location "c:\Users\natso\OneDrive\Desktop\Sirvya\Fitlek\workout\api"
    $env:PORT = "3001"
    node server.js
} -Name "WorkoutAPI"
Start-Sleep -Seconds 2
Write-Host "Workout API started (Job ID: $($workoutApiJob.Id))" -ForegroundColor Green

# Start Workout frontend (port 5173 with API_TARGET=http://127.0.0.1:3001)
Write-Host "Starting Workout frontend on port 5173..." -ForegroundColor Yellow
$env:API_TARGET = "http://127.0.0.1:3001"
$workoutFrontendJob = Start-Job -ScriptBlock {
    Set-Location "c:\Users\natso\OneDrive\Desktop\Sirvya\Fitlek\workout\frontend"
    $env:API_TARGET = "http://127.0.0.1:3001"
    npm run dev
} -Name "WorkoutFrontend"
Start-Sleep -Seconds 3
Write-Host "Workout frontend started (Job ID: $($workoutFrontendJob.Id))" -ForegroundColor Green

# Start Flutter web build (port 8090)
Write-Host "Starting Flutter web server on port 8090..." -ForegroundColor Yellow
$flutterWebJob = Start-Job -ScriptBlock {
    Set-Location "c:\Users\natso\OneDrive\Desktop\Sirvya\Fitlek"
    # Build Flutter web if not already built
    if (-not (Test-Path "build\web")) {
        flutter build web
    }
    # Serve the build
    npx serve@latest build\web -l 8090
} -Name "FlutterWeb"
Start-Sleep -Seconds 3
Write-Host "Flutter web server started (Job ID: $($flutterWebJob.Id))" -ForegroundColor Green

Write-Host "`nAll services started successfully!" -ForegroundColor Cyan
Write-Host "`nService URLs:" -ForegroundColor White
Write-Host "  Sirvya backend:       http://localhost:3000" -ForegroundColor Gray
Write-Host "  Workout API:          http://localhost:3001" -ForegroundColor Gray
Write-Host "  Workout frontend:     http://localhost:5173" -ForegroundColor Gray
Write-Host "  Flutter web:          http://localhost:8090" -ForegroundColor Gray
Write-Host "`nTo stop all services, run: .\stop-all.ps1" -ForegroundColor Yellow

# Keep script running to monitor jobs
try {
    while ($true) {
        Start-Sleep -Seconds 10
        $runningJobs = Get-Job | Where-Object { $_.State -eq 'Running' }
        if ($runningJobs.Count -eq 0) {
            Write-Host "All jobs have stopped." -ForegroundColor Red
            break
        }
    }
} finally {
    Write-Host "`nCleaning up jobs..." -ForegroundColor Yellow
    Get-Job | Remove-Job -Force
}
