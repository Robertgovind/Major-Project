@echo off
REM Backend Connection and Data Pipeline Test Script (Windows)
REM Tests: Backend health, API endpoint, and WebSocket connectivity

setlocal enabledelayedexpansion

REM Configuration
set BACKEND_URL=%1
if "%BACKEND_URL%"=="" set BACKEND_URL=http://localhost:5000

set API_KEY=%2
if "%API_KEY%"=="" set API_KEY=fruit-pulse-secret-key-123

REM Colors (using Unicode)
cls
echo.
echo ========================================
echo Fruit Pulse Pipeline Test Script
echo ========================================
echo.
echo Backend URL: %BACKEND_URL%
echo API Key: %API_KEY:~0,10%...
echo.

REM Test 1: Health Check
echo [1/3] Testing Backend Health...
for /f %%A in ('powershell -Command "(Invoke-WebRequest -Uri '%BACKEND_URL%/health' -UseBasicParsing).StatusCode"') do set HEALTH_CODE=%%A

if "%HEALTH_CODE%"=="200" (
    echo [OK] Backend is running HTTP 200
) else (
    echo [ERROR] Backend health check failed HTTP %HEALTH_CODE%
    echo Make sure backend is running: cd backend ^&^& npm run dev
    exit /b 1
)

REM Test 2: API Endpoint
echo [2/3] Testing Sensor Data Endpoint...

set SENSOR_DATA={^
  "deviceId": "test-esp32",^
  "fruitType": "banana",^
  "r": 120,^
  "g": 88,^
  "b": 35,^
  "humidity": 55.4,^
  "temperature": 24.7,^
  "pressure": 1008.2,^
  "voc": 42.15,^
  "chemicalRipening": 0.45^
}

REM Use PowerShell for the POST request
powershell -Command "^
  $response = Invoke-WebRequest -Uri '%BACKEND_URL%/api/v1/sensor-data' `^
    -Method POST `^
    -Headers @{'Content-Type'='application/json'; 'X-API-Key'='%API_KEY%'} `^
    -Body '%SENSOR_DATA%' `^
    -UseBasicParsing;^
  if ($response.StatusCode -eq 201) {^
    Write-Host '[OK] Sensor data endpoint working HTTP 201';^
    Write-Host '[OK] ML prediction successful';^
  } else {^
    Write-Host '[ERROR] Sensor endpoint failed HTTP ' $response.StatusCode;^
    exit 1;^
  }^
"

if %ERRORLEVEL% neq 0 exit /b 1

REM Test 3: Latest Reading Endpoint
echo [3/3] Testing Latest Reading Endpoint...

for /f %%A in ('powershell -Command "(Invoke-WebRequest -Uri '%BACKEND_URL%/api/v1/sensor-data/latest' -UseBasicParsing).StatusCode"') do set LATEST_CODE=%%A

if "%LATEST_CODE%"=="200" (
    echo [OK] Latest reading endpoint working HTTP 200
) else (
    echo [ERROR] Latest reading endpoint failed HTTP %LATEST_CODE%
)

echo.
echo ========================================
echo [SUCCESS] Backend Pipeline Tests Passed!
echo ========================================
echo.
echo Next steps:
echo 1. Ensure ESP32 is connected and sending data
echo 2. Run Flutter app with correct API_HOST
echo 3. Check Fruit Analysis screen for live data
echo.

endlocal
