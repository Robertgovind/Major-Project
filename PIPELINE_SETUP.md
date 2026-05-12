# Fruit Pulse Data Pipeline Setup Guide

Complete end-to-end setup for sensor data → backend → Flutter app pipeline.

## System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Data Flow Pipeline                        │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ESP32 Sensor                Backend Server        Flutter   │
│  (sensor-reading-code)       (Node.js)              App       │
│         │                         │                  │        │
│  Read RGB, Temp,      ────────>  Process         ──────>  Display
│  Humidity, VOC            Data & ML          WebSocket    in UI
│         │                    Prediction              │        │
│         │                         │              ◄────       │
│  POST every 5s        Broadcast via WS                       │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

---

## Part 1: Backend Setup

### 1.1 Install Dependencies

```bash
cd backend
npm install
pip install -r requirements.txt
```

### 1.2 Configure Environment

Create `.env` file in `backend/` directory:

```env
NODE_ENV=development
PORT=5000
CORS_ORIGIN=*
API_KEY=your-secure-api-key-123
PYTHON_BIN=python
```

**Note:** For production, set specific CORS origins instead of `*`.

### 1.3 Verify ML Models

Ensure Python ML models exist in `backend/src/ml/`:
- `predict.py` - Main prediction script
- Required model files (pickle/joblib files)

### 1.4 Start Backend Server

```bash
npm run dev
```

Expected output:
```
Fruit Pulse backend listening on port 5000
WebSocket ready at ws://localhost:5000/ws
```

**Verify** the health endpoint:
```bash
curl http://localhost:5000/health
```

Should return:
```json
{
  "success": true,
  "message": "Fruit Pulse backend is running.",
  "uptime": 0.123,
  "timestamp": "2026-05-12T10:00:00.000Z"
}
```

---

## Part 2: ESP32 Sensor Setup

### 2.1 Hardware Assembly

Connect sensors to ESP32 pins as configured in `src/main.cpp`:

| Sensor Type | Component | ESP32 Pin | Notes |
|-----------|-----------|-----------|-------|
| RGB Color | TCS34725 | I2C (21, 22) | Optional, uses ADC if not available |
| Temperature/Humidity | DHT22 | GPIO 5 | Pull-up required |
| Pressure | BMP280 | I2C (21, 22) | 0x77 default address |
| VOC/Gas | MQ-135 or similar | GPIO 33 (ADC) | Requires calibration |
| Red Channel | Analog Sensor | GPIO 34 (ADC) | For RGB fallback |
| Green Channel | Analog Sensor | GPIO 35 (ADC) | For RGB fallback |
| Blue Channel | Analog Sensor | GPIO 32 (ADC) | For RGB fallback |

### 2.2 PlatformIO Configuration

Open `sensor-reading-code/platformio.ini` and verify libraries are installed:

```ini
lib_deps = 
	adafruit/Adafruit BME680 Library@^2.0.6
	adafruit/DHT sensor library@^1.4.6
	adafruit/Adafruit BMP280 Library@^2.6.8
	bblanchon/ArduinoJson@^7.0.4
```

### 2.3 Configure WiFi and Backend

Edit `sensor-reading-code/src/main.cpp` (lines 5-11):

```cpp
// WiFi credentials
const char* ssid = "YOUR_SSID";
const char* password = "YOUR_PASSWORD";

// Backend server config
const char* backendUrl = "http://YOUR_BACKEND_IP:5000/api/v1/sensor-data";
const char* apiKey = "your-secure-api-key-123";  // Must match backend API_KEY
```

**Important:** 
- Replace `YOUR_SSID` and `YOUR_PASSWORD` with your WiFi credentials
- Replace `YOUR_BACKEND_IP` with your backend server IP (NOT localhost)
  - If running locally: use your computer's LAN IP (e.g., `192.168.1.10`)
  - Find it with: `ipconfig` (Windows) or `ifconfig` (Mac/Linux)
- Use the same `apiKey` as configured in backend `.env`

### 2.4 Upload Firmware

```bash
cd sensor-reading-code
pio run -t upload
```

### 2.5 Verify Sensor Output

Open Serial Monitor:

```bash
pio device monitor --baud 115200
```

Expected output (every 5 seconds):
```
Connecting to WiFi: YOUR_SSID
.....
WiFi connected!
IP address: 192.168.1.100
All sensors initialized
Sensor Data:
RGB: 120, 88, 35
Temp: 24.50°C
Humidity: 55.30%
VOC: 42.15
Sending data to backend: http://192.168.1.10:5000/api/v1/sensor-data
{...sensor data JSON...}
Response Code: 201
Response: {"success":true,"data":{...},"message":"Sensor reading predicted and broadcasted."}
```

---

## Part 3: Flutter App Setup

### 3.1 Configure API Endpoint

Edit `fruit_pulse/lib/core/constants/api_config.dart`:

```dart
class ApiConfig {
  static const int port = 5000;
  
  // Set your backend IP here
  static const String host = String.fromEnvironment(
    'API_HOST',
    defaultValue: '10.0.2.2',  // Android emulator default
  );

  static String get websocketUrl {
    final resolvedHost = kIsWeb ? 'localhost' : host;
    return 'ws://$resolvedHost:$port/ws';
  }
}
```

### 3.2 Run on Android Emulator

```bash
cd fruit_pulse
flutter run --dart-define=API_HOST=10.0.2.2
```

### 3.3 Run on Physical Phone

Get your computer's LAN IP:
```bash
ipconfig  # Windows
ifconfig  # Mac/Linux
```

```bash
cd fruit_pulse
flutter run --dart-define=API_HOST=192.168.1.10
```

### 3.4 Navigate to Fruit Analysis Screen

1. Open the app
2. Select a fruit from fruit selection screen
3. Go to **Fruit Analysis** tab
4. Should see live sensor data charts updating every 5 seconds

---

## Part 4: Testing the Complete Pipeline

### 4.1 Test Sensor → Backend

**From ESP32 Serial Monitor:**
- Verify data is being read from sensors
- Check response code 201 from backend (indicates success)

**From Backend Logs:**
```bash
npm run dev
# Should show incoming POST requests with sensor data
```

**Curl Test:**
```bash
curl -X POST http://localhost:5000/api/v1/sensor-data \
  -H "Content-Type: application/json" \
  -H "X-API-Key: your-secure-api-key-123" \
  -d '{
    "deviceId": "esp32-1",
    "fruitType": "banana",
    "r": 120,
    "g": 88,
    "b": 35,
    "humidity": 55.4,
    "temperature": 24.7,
    "voc": 42.15,
    "chemicalRipening": 0.45
  }'
```

Expected response:
```json
{
  "success": true,
  "data": {
    "sensorData": {...},
    "prediction": {
      "isNaturalRipening": true,
      "status": "ripe",
      "confidence": 0.87,
      "recommendation": "Fruit is naturally ripened and currently ripe..."
    }
  },
  "message": "Sensor reading predicted and broadcasted."
}
```

### 4.2 Test Backend → WebSocket

**From Backend Logs:**
- Should see WebSocket clients connected
- Should see broadcast events for each sensor reading

**Check WebSocket Connection:**

In Flutter, go to Fruit Analysis screen and:
1. Look for charts updating in real-time
2. Check for errors in debug console
3. Prediction status should change based on readings

**Debug WebSocket (Optional):**

```bash
# Install wscat globally
npm install -g wscat

# Connect to WebSocket
wscat -c ws://localhost:5000/ws

# Should receive sensor readings:
# > {"event":"sensor:reading","data":{...}}
```

### 4.3 Test WebSocket → Flutter Display

When on the **Fruit Analysis** screen:
- **VOC Chart** should show live updates
- **Chemical Ripening Chart** should update
- **Prediction Card** shows ripeness status (unripe/ripe/overripe)
- **Sensor Panel** displays current readings

---

## Troubleshooting

### Issue: ESP32 connects to WiFi but can't reach backend

**Solutions:**
- Verify backend IP is correct: `ipconfig` / `ifconfig`
- Ensure ESP32 and backend are on same network
- Check firewall allows port 5000
- Verify API_KEY matches between ESP32 and backend `.env`

### Issue: Backend receiving data but Flutter shows no updates

**Solutions:**
- Check Flutter is using correct API_HOST IP address
- Verify WebSocket URL: `ws://IP:5000/ws` (not HTTP)
- Check backend CORS_ORIGIN includes Flutter client
- Look for errors in Flutter debug console

### Issue: ESP32 POST requests return 401 Unauthorized

**Solutions:**
- Check ESP32 `apiKey` matches backend `API_KEY` in `.env`
- Verify header is exactly: `X-API-Key: your-api-key`
- Check backend `.env` has `API_KEY` set (not empty)

### Issue: Sensor readings show 0 or NaN

**Solutions:**
- Verify sensors are properly connected to GPIO pins
- Check sensor calibration in `main.cpp`
- Use Serial Monitor to debug individual sensor reads
- Consult sensor datasheets for voltage requirements

### Issue: Python ML model fails to load

**Solutions:**
- Verify Python dependencies installed: `pip install -r requirements.txt`
- Check model files exist in `backend/src/ml/`
- Run `python backend/src/ml/predict.py` directly to debug
- Check Python version compatibility (>=3.8)

---

## Monitoring & Debugging

### Enable Detailed Logging (Backend)

Edit `backend/src/controllers/sensor.controller.js`:
```javascript
console.log('Received sensor data:', req.body);
console.log('Prediction result:', prediction);
```

### Monitor WebSocket Traffic

In browser console (if using web version):
```javascript
const ws = new WebSocket('ws://localhost:5000/ws');
ws.onmessage = (event) => {
  console.log('WebSocket message:', event.data);
};
```

### Flutter Debug Output

Add this to `sensor_provider.dart`:
```dart
_sensorService.readingStream.listen((reading) {
  print('New reading: ${reading.sensorData}');
  print('Prediction: ${reading.prediction}');
});
```

---

## Performance Considerations

### Current Configuration:
- **Sensor Sampling Rate**: 5 seconds
- **WebSocket Broadcast**: Per sensor reading (~every 5 seconds)
- **Chart History**: Last 60 readings (~5 minutes)
- **API Timeout**: 30 seconds

### For Production:
- Implement database to store sensor history
- Add authentication beyond API key
- Use HTTPS/WSS instead of HTTP/WS
- Implement rate limiting
- Add error recovery and reconnection logic
- Monitor backend resources and WebSocket connections

---

## File Structure Reference

```
Major Project/
├── backend/
│   ├── src/
│   │   ├── app.js                 # Express app setup
│   │   ├── server.js              # Server startup
│   │   ├── config/
│   │   │   ├── env.js             # Environment variables
│   │   │   └── websocketHub.js    # WebSocket broadcasting
│   │   ├── controllers/
│   │   │   └── sensor.controller.js
│   │   ├── services/
│   │   │   ├── ml.service.js      # ML predictions
│   │   │   └── sensorReading.service.js
│   │   ├── middleware/
│   │   │   └── apiKey.js          # API key validation
│   │   └── ml/
│   │       └── predict.py         # ML model script
│   ├── .env                       # Configuration (create from .env.example)
│   ├── package.json
│   └── requirements.txt
│
├── sensor-reading-code/
│   ├── src/
│   │   └── main.cpp               # ESP32 sensor code
│   ├── platformio.ini             # PlatformIO config with libraries
│   └── include/
│
└── fruit_pulse/
    ├── lib/
    │   ├── main.dart              # App entry point
    │   ├── core/
    │   │   ├── utils/
    │   │   │   ├── api_config.dart           # API configuration
    │   │   │   └── live_sensor_service.dart  # WebSocket client
    │   │   └── constants/
    │   ├── features/
    │   │   └── fruit_analysis/
    │   │       └── presentation/
    │   │           └── fruit_analysis_screen.dart  # Display charts
    │   └── shared/
    │       ├── providers/
    │       │   └── sensor_provider.dart      # State management
    │       └── models/
    │           ├── sensor_data.dart
    │           └── prediction_result.dart
    └── pubspec.yaml
```

---

## Next Steps

1. ✅ **Hardware**: Assemble sensors and connect to ESP32
2. ✅ **Backend**: Set up Node.js server and Python ML environment
3. ✅ **Sensor Code**: Upload firmware to ESP32 with WiFi credentials
4. ✅ **Flutter**: Configure API endpoint and run app
5. ✅ **Testing**: Verify complete pipeline with sensor → backend → Flutter
6. 📊 **Monitoring**: Set up logging and error handling
7. 🔒 **Security**: Implement proper authentication for production

---

## Support

For issues or questions:
- Check backend logs: `npm run dev`
- Check ESP32 serial output: `pio device monitor --baud 115200`
- Check Flutter console: `flutter logs`
- Review backend README.md for API details
- Review ML models documentation in `backend/src/ml/`
