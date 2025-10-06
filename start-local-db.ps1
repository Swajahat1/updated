# Mindease Local Database Startup Script
Write-Host "Starting Mindease with Local MongoDB..." -ForegroundColor Green

# Check if MongoDB data directory exists
$dataDir = "C:\data\db"
if (-not (Test-Path $dataDir)) {
    Write-Host "Creating MongoDB data directory..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Force -Path $dataDir | Out-Null
    Write-Host "Data directory created: $dataDir" -ForegroundColor Green
}

# Check if MongoDB is already running
$mongoProcess = Get-Process -Name "mongod" -ErrorAction SilentlyContinue
if ($mongoProcess) {
    Write-Host "MongoDB is already running (PID: $($mongoProcess.Id))" -ForegroundColor Green
} else {
    Write-Host "Starting MongoDB..." -ForegroundColor Yellow

    # Start MongoDB in background
    $mongoPath = "C:\Program Files\MongoDB\Server\8.0\bin\mongod.exe"
    if (Test-Path $mongoPath) {
        Start-Process -FilePath $mongoPath -ArgumentList "--dbpath", "`"$dataDir`"" -WindowStyle Hidden
        Write-Host "MongoDB started successfully" -ForegroundColor Green
        Start-Sleep -Seconds 3
    } else {
        Write-Host "MongoDB not found at: $mongoPath" -ForegroundColor Red
        Write-Host "Please install MongoDB Community Server" -ForegroundColor Yellow
        exit 1
    }
}

# Test MongoDB connection
Write-Host "🧪 Testing MongoDB connection..." -ForegroundColor Yellow
Set-Location "project"
$testResult = node test-db.js 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ MongoDB connection successful" -ForegroundColor Green
} else {
    Write-Host "❌ MongoDB connection failed" -ForegroundColor Red
    Write-Host $testResult -ForegroundColor Red
    exit 1
}

Write-Host "`n🎉 Local MongoDB setup completed!" -ForegroundColor Green
Write-Host "📋 Database: mindease_local" -ForegroundColor Cyan
Write-Host "🌐 Connection: mongodb:// 192.168.2.102:27017/mindease_local" -ForegroundColor Cyan
Write-Host "`nTo start your server, run: cd project && npm start" -ForegroundColor Yellow
Write-Host "To stop MongoDB, find the mongod process and kill it" -ForegroundColor Yellow
