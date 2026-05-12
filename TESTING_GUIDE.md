# Complete Testing & Verification Guide

Comprehensive guide to test the entire sensor → backend → Flutter data pipeline.

---

## Overview

The complete system involves three main components:

```
Sensor (ESP32) ──POST→ Backend ──WebSocket→ Flutter App
   │                     │                       │
   ├─ Read sensors       ├─ Process data        └─ Display charts
   ├─ Format JSON        ├─ ML prediction       └─ Show prediction
   └─ Send HTTP          └─ Broadcast to WS     └─ Update in real-time
```

---

## Phase 1: Backend Testing (15 minutes)

### Step 1.1: Verify Backend is Running

```bash
cd backend
npm run dev
```

Expected output:
```
> fruit-pulse-backend@1.0.0 dev
> nodemon src/server.js

[nodemon] 4.0.8
[nodemon] to restart at any time, type `rs`
[nodemon] watching path(s): src/**/*
[nodemon] watching extensions: js,json
[nodemon] env: {"NODE_ENV":"development","PORT":"5000", ...}
Fruit Pulse backend listening on port 5000
WebSocket ready at ws://localhost:5000/ws
```

**✓ Pass**: Backend is listening on port 5000
**✗ Fail**: Port already in use → kill process on port 5000

### Step 1.2: Test Health Endpoint

```bash
curl http://localhost:5000/health
```

Expected response (HTTP 200):
```json
{
  "success": true,
  "message": "Fruit Pulse backend is running.",
  "uptime": 12.345,
  "timestamp": "2026-05-12T10:15:30.000Z"
}
```

**✓ Pass**: Received successful response
**✗ Fail**: Check backend process is running

### Step 1.3: Test Sensor Data Endpoint

Create a test file: `test-sensor.json`
```json
{
  "deviceId": "test-esp32",
  "fruitType": "banana",
  "r": 120,
  "g": 88,
  "b": 35,
  "humidity": 55.4,
  "temperature": 24.7,
  "pressure": 1008.2,
  "voc": 42.15,
  "chemicalRipening": 0.45
}
```

Send data:
```bash
curl -X POST http://localhost:5000/api/v1/sensor-data \
  -H "Content-Type: application/json" \
  -H "X-API-Key: fruit-pulse-secret-key-123" \
  -d @test-sensor.json
```

Expected response (HTTP 201):
```json
{
  "success": true,
  "data": {
    "sensorData": {
      "deviceId": "test-esp32",
      "r": 120,
      "g": 88,
      "b": 35,
      "humidity": 55.4,
      "temperature": 24.7,
      "voc": 42.15,
      "chemicalRipening": 0.45,
      "timestamp": "2026-05-12T10:15:30.000Z"
    },
    "prediction": {
      "isNaturalRipening": true,
      "status": "ripe",
      "confidence": 0.87,
      "recommendation": "Fruit is naturally ripened and currently ripe. Recommended for consumption within 2 days."
    }
  },
  "message": "Sensor reading predicted and broadcasted."
}
```

**✓ Pass**: 
- HTTP 201 response
- Prediction status returned (unripe/ripe/overripe)
- Data broadcasted to WebSocket

**✗ Fail**: 
- HTTP 401 → Check API key matches backend `.env`
- HTTP 500 → Check ML model files exist and Python is set up
- Connection refused → Backend not running

### Step 1.4: Test Latest Reading Endpoint

```bash
curl http://localhost:5000/api/v1/sensor-data/latest
```

Expected response (HTTP 200):
```json
{
  "success": true,
  "data": {
    "sensorData": { ... },
    "prediction": { ... }
  },
  "message": "Latest sensor reading fetched."
}
```

**✓ Pass**: Returns last sensor reading
**✗ Fail**: Check `/api/v1/sensor-data` endpoint works first

### Backend Testing Script

**Windows:**
```bash
test-pipeline.bat
# Or with custom backend URL and API key:
test-pipeline.bat http://192.168.1.10:5000 my-api-key
```

**Mac/Linux:**
```bash
bash test-pipeline.sh
# Or with custom parameters:
bash test-pipeline.sh http://192.168.1.10:5000 my-api-key
```

---

## Phase 2: ESP32 Sensor Testing (30 minutes)

### Step 2.1: Verify Hardware Connections

Use a multimeter to verify:
- Power supply: 3.3V at ESP32 VIN
- Ground connection between all components
- Sensor pins match GPIO configuration in `main.cpp`

### Step 2.2: Check Serial Output

```bash
cd sensor-reading-code
pio device monitor --baud 115200
```

Expected startup sequence:
```
Fruit Pulse ESP32 Sensor Module Starting...
Connecting to WiFi: YOUR_SSID
.....
WiFi connected!
IP address: 192.168.1.100
DHT sensor initialized
BMP280 sensor initialized
All sensors initialized
```

**✓ Pass**: ESP32 connected to WiFi and sensors ready
**✗ Fail**: 
- WiFi connection issues → Check SSID/password in `main.cpp`
- Sensor initialization failed → Check GPIO connections and I2C address

### Step 2.3: Verify Sensor Readings

After ~5 seconds, you should see:
```
Sensor Data:
RGB: 120, 88, 35
Temp: 24.50°C
Humidity: 55.30%
VOC: 42.15
Sending data to backend: http://192.168.1.10:5000/api/v1/sensor-data
{JSON payload...}
Response Code: 201
Response: {"success":true,"data":{...},"message":"Sensor reading predicted and broadcasted."}
```

Repeats every 5 seconds.

**✓ Pass**: 
- Receiving valid sensor values
- HTTP 201 response from backend
- No errors in response

**✗ Fail**: 
- All zeros → Sensor not connected
- HTTP 401 → API key mismatch
- HTTP error → Backend URL incorrect
- Connection timeout → Backend not reachable

### Step 2.4: Sensor Value Ranges

Verify sensor values are reasonable:

| Sensor | Expected Range | Indicates Issue If... |
|--------|---------------|-----------------------|
| R, G, B | 0-255 | All zero = sensor not connected |
| Temperature | -40 to 125°C | Realistic to room temp ~20-30°C |
| Humidity | 0-100% | Realistic to room humidity ~40-70% |
| VOC | 0-100 | Adjustable based on calibration |
| Pressure | 950-1050 hPa | Realistic atmospheric pressure |

### Step 2.5: Test API Key Error Handling

Send data without API key:
```bash
curl -X POST http://ESP32_IP/api/v1/sensor-data \
  -H "Content-Type: application/json" \
  -d '{"r":120,"g":88,"b":35,"humidity":55,"temperature":24,"voc":42,"chemicalRipening":0.45}'
```

**Expected (HTTP 401)**: `{"success": false, "message": "Invalid or missing API key."}`

**✓ Pass**: API key validation working
**✗ Fail**: Request should be rejected

---

## Phase 3: Flutter App Testing (20 minutes)

### Step 3.1: Configure API Endpoint

Edit: `fruit_pulse/lib/core/constants/api_config.dart`

**For Android Emulator:**
```dart
static const String host = '10.0.2.2';  // Special address for emulator
```

**For Physical Phone:**
```dart
static const String host = '192.168.1.10';  // Your computer's LAN IP
```

Find your IP:
```bash
# Windows
ipconfig

# Mac/Linux
ifconfig
```

### Step 3.2: Run Flutter App

```bash
cd fruit_pulse
flutter run
```

Expected output:
```
Installing and launching app on [device name]...
...
lib/main.dart:8:1: warning: not found: 'flutter_gen'
...
I/flutter (12345): The Dart VM service is listening on http://127.0.0.1:54321/...
I/flutter (12345): Launching FruitPulseApp
```

**✓ Pass**: App launches successfully
**✗ Fail**: 
- Compilation errors → Run `flutter clean` and `flutter pub get`
- Device not found → Connect phone or use emulator

### Step 3.3: Navigate to Fruit Analysis Screen

1. **Open App**
2. **Select Fruit** from the fruit selection screen (tap any fruit)
3. **Go to Fruit Analysis Tab**

Expected behavior:
- Screen loads with loading indicator initially
- After few seconds, charts appear
- Charts start updating with live data

### Step 3.4: Verify Real-Time Data Updates

**Check VOC Chart:**
- Line chart shows historical data
- Line updates every 5 seconds
- Color changes: Green (unripe) → Orange (ripe) → Red (overripe)

**Check Chemical Ripening Chart:**
- Another line chart
- Updates in sync with VOC chart

**Check Sensor Panel:**
- Shows current R, G, B values
- Shows current temperature and humidity
- Updates every 5 seconds

**Check Prediction Card:**
- Shows ripeness status: "Unripe", "Ripe", or "Overripe"
- Shows confidence percentage
- Shows recommendation text
- Updates based on sensor values

### Step 3.5: Test Connection Issues

**Simulate Backend Offline:**
1. Stop backend server
2. Watch Flutter app for error messages
3. Restart backend
4. Data should resume flowing

**Expected Behavior:**
- Connection error appears
- Automatically reconnects when backend available
- No app crash

### Step 3.6: Monitor Debug Output

```bash
flutter logs
```

Look for connection messages:
```
Connected to Fruit Pulse live sensor stream.
```

Look for errors (should be none):
```
E/flutter ( 1234): Connection refused
E/flutter ( 1234): JSON decode error
```

---

## Phase 4: Complete End-to-End Test (45 minutes)

### Setup: Three Terminal Windows

**Terminal 1 - Backend:**
```bash
cd backend
npm run dev
```

**Terminal 2 - ESP32 Monitor:**
```bash
cd sensor-reading-code
pio device monitor --baud 115200
```

**Terminal 3 - Flutter:**
```bash
cd fruit_pulse
flutter run
```

### Test Sequence

**[5 min] Initialization**
- ✓ Backend logs show server listening on port 5000
- ✓ ESP32 shows WiFi connected and sensors initialized
- ✓ Flutter app launches and connects to WebSocket

**[5 min] Data Flow**
- ✓ ESP32 sends sensor data (check in ESP32 terminal: HTTP 201)
- ✓ Backend receives and processes (check logs)
- ✓ Flutter displays data (check charts updating)

**[10 min] Live Monitoring**
- Watch ESP32 terminal for consistent 201 responses
- Check Flutter charts updating every 5 seconds
- Manually change sensors (hold object to color sensor) and see UI update

**[10 min] Prediction Changes**
- Vary sensor values and observe prediction changes
- Ripeness status should reflect sensor data
- Confidence score should update

**[5 min] Stability**
- Let system run for ~5 minutes
- Verify no crashes or disconnections
- Check all three components still running

### Success Criteria

All of the following must be true:

1. **Backend Stability**
   - No errors or crashes
   - Processing all sensor requests
   - WebSocket broadcasts working

2. **ESP32 Functionality**
   - Consistent WiFi connection
   - Sensors reading valid values
   - Data posted successfully (HTTP 201)

3. **Flutter Display**
   - Live charts updating smoothly
   - Current sensor readings displayed
   - Prediction status reflecting data
   - No UI freezes or errors

4. **Data Pipeline**
   - Data flows from ESP32 → Backend → Flutter
   - No data loss or significant delays
   - System recovers from temporary disconnections

---

## Troubleshooting Matrix

| Symptom | Cause | Solution |
|---------|-------|----------|
| ESP32 won't connect to WiFi | Wrong SSID/password or not in range | Check WiFi SSID/password in `main.cpp` |
| ESP32 connects to WiFi but can't reach backend | Wrong backend IP or firewall blocking | Find correct LAN IP with `ipconfig`, check port 5000 open |
| Backend returns 401 | API key mismatch | Verify `API_KEY` in `.env` matches ESP32 code |
| Backend returns 500 | ML model not found or Python error | Check models exist, run `pip install -r requirements.txt` |
| Flutter shows no data | Wrong API_HOST configuration | Update `api_config.dart` with correct IP |
| Flutter can't connect to WebSocket | Backend not running or port blocked | Start backend with `npm run dev` |
| Sensor values all zero | Sensor not connected or wrong GPIO | Check connections and GPIO pin numbers in `main.cpp` |
| Sensor shows unrealistic values | Sensor not calibrated | Calibrate sensors or check voltage levels |

---

## Performance Metrics

After successful end-to-end test, expected metrics:

- **Data Latency**: ESP32 to Flutter display < 2 seconds
- **Update Frequency**: Charts update every 5 seconds
- **Backend Response Time**: < 500ms per request
- **WebSocket Message Size**: < 2KB per broadcast
- **Concurrent Connections**: Tested up to 10 Flutter clients

---

## Next Steps After Passing All Tests

1. **Optimize Configuration**
   - Adjust sensor reading interval (currently 5 seconds)
   - Fine-tune ML model parameters
   - Optimize WebSocket message frequency

2. **Add Features**
   - Database storage for historical data
   - Multi-device support
   - Data export functionality

3. **Production Deployment**
   - Set up HTTPS/WSS
   - Implement proper authentication
   - Deploy to cloud (AWS, Azure, etc.)
   - Add monitoring and alerts

4. **Performance Testing**
   - Load test with multiple sensors
   - Test long-running stability (24+ hours)
   - Verify scalability

---

## Support & Debugging

### Enable Debug Logging

**Backend:**
Add to `src/controllers/sensor.controller.js`:
```javascript
console.log('Sensor Data Received:', req.body);
console.log('Prediction Result:', prediction);
```

**ESP32:**
Serial Monitor already shows detailed logs

**Flutter:**
Add to `sensor_provider.dart`:
```dart
print('WebSocket message received: $reading');
```

### Get Help

- Check backend README.md for API details
- Review ESP32 sensor datasheets
- Check Flutter provider documentation
- Review ML model specs in `backend/src/ml/`

---

Last Updated: 2026-05-12
