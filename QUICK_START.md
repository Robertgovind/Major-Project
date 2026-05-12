# Quick Start Checklist

Use this checklist to set up the complete Fruit Pulse pipeline.

## ☐ Backend Setup (5 minutes)

```bash
cd backend
npm install
pip install -r requirements.txt
```

Create `.env` file:
```env
NODE_ENV=development
PORT=5000
CORS_ORIGIN=*
API_KEY=fruit-pulse-secret-key-123
```

Start backend:
```bash
npm run dev
```

**Test health endpoint:**
```bash
curl http://localhost:5000/health
```

Expected: HTTP 200 with `{"success": true, ...}`

---

## ☐ ESP32 Sensor Setup (10 minutes)

**1. Hardware Assembly**
- [ ] Connect RGB Color Sensor (or use ADC)
- [ ] Connect DHT22/DHT11 (Temperature/Humidity) to GPIO 5
- [ ] Connect BMP280 (Pressure) via I2C (GPIO 21, 22)
- [ ] Connect VOC Sensor to GPIO 33 (ADC)
- [ ] Connect power and GND properly

**2. Edit Configuration**

File: `sensor-reading-code/src/main.cpp` (lines 5-11)

```cpp
const char* ssid = "YOUR_WIFI_SSID";
const char* password = "YOUR_WIFI_PASSWORD";
const char* backendUrl = "http://192.168.1.10:5000/api/v1/sensor-data";  // Your IP here
const char* apiKey = "fruit-pulse-secret-key-123";  // Must match backend
```

**3. Find Your Computer's IP**

Windows:
```bash
ipconfig
# Look for "IPv4 Address" under your network adapter
```

Mac/Linux:
```bash
ifconfig
# Look for "inet" address on your network interface
```

**4. Upload Code**

```bash
cd sensor-reading-code
pio run -t upload
```

**5. Verify Output**

```bash
pio device monitor --baud 115200
```

Expected: Every 5 seconds you should see:
```
Sensor Data:
RGB: 120, 88, 35
Temp: 24.50°C
Humidity: 55.30%
VOC: 42.15
Sending data to backend...
Response Code: 201
```

---

## ☐ Flutter App Setup (5 minutes)

**1. Configure Backend IP**

Edit: `fruit_pulse/lib/core/constants/api_config.dart`

For Android Emulator (default):
```dart
static const String host = '10.0.2.2';
```

For Physical Phone:
```dart
static const String host = '192.168.1.10';  // Your computer's LAN IP
```

Or pass at runtime:
```bash
cd fruit_pulse
flutter run --dart-define=API_HOST=192.168.1.10
```

**2. Run App**

```bash
cd fruit_pulse
flutter run
```

---

## ☐ Full Pipeline Test (5 minutes)

**1. Start Backend** (Terminal 1)
```bash
cd backend && npm run dev
```

**2. Power On ESP32** (or run via USB)
- Should connect to WiFi
- Should start sending sensor data
- Check Serial Monitor for 201 responses

**3. Run Flutter App** (Terminal 2)
```bash
cd fruit_pulse && flutter run
```

**4. Navigate in App**
1. Select a fruit from the selection screen
2. Tap on **Fruit Analysis** tab
3. Should see:
   - ✓ VOC Chart updating live (line graph)
   - ✓ Chemical Ripening Chart updating
   - ✓ Sensor Panel with current readings
   - ✓ Prediction Card with ripeness status

---

## ☐ Verification Checklist

When all three components are running:

**Backend (Terminal 1):**
- [ ] Listening on port 5000
- [ ] Receiving POST requests from ESP32 (HTTP 201 responses)
- [ ] WebSocket server ready at `/ws`

**ESP32 (Serial Monitor):**
- [ ] Connected to WiFi
- [ ] Sensors initialized successfully
- [ ] Sending data every 5 seconds
- [ ] Getting 201 responses from backend

**Flutter App:**
- [ ] Connected to WebSocket (no errors in debug console)
- [ ] Charts updating in real-time
- [ ] Showing current sensor readings
- [ ] Showing prediction (ripeness status)

---

## Troubleshooting Quick Reference

| Problem | Quick Fix |
|---------|-----------|
| ESP32 can't reach backend | Use correct LAN IP, check firewall port 5000 |
| 401 Unauthorized error | Verify API_KEY matches in ESP32 and backend `.env` |
| Flutter shows no data | Check API_HOST IP is correct, try `10.0.2.2` for emulator |
| Sensors showing 0 values | Check GPIO connections, verify sensor power |
| Backend not running | Check port 5000 not in use: `netstat -ano \| find ":5000"` |
| Python ML errors | Install requirements: `pip install -r requirements.txt` |

---

## Common IP Configurations

**Android Emulator** → Local Backend:
```
API_HOST=10.0.2.2
```

**Physical Phone** → Backend on Computer:
```
API_HOST=192.168.x.x  (your computer's LAN IP)
```

**Physical Device** → Backend on Cloud:
```
API_HOST=your.domain.com
```

---

## Environment Variables Summary

**.env (Backend)**
```
NODE_ENV=development
PORT=5000
CORS_ORIGIN=*
API_KEY=fruit-pulse-secret-key-123
PYTHON_BIN=python
```

**ESP32 (main.cpp)**
```
WiFi SSID: YOUR_WIFI_SSID
WiFi Password: YOUR_WIFI_PASSWORD
Backend URL: http://192.168.x.x:5000/api/v1/sensor-data
API Key: fruit-pulse-secret-key-123 (same as backend)
```

**Flutter (api_config.dart)**
```
API_HOST: 10.0.2.2 (emulator) or 192.168.x.x (physical)
PORT: 5000
WebSocket: ws://{API_HOST}:5000/ws
```

---

## Need Help?

Check these logs:

**Backend:**
```bash
npm run dev  # Shows all requests and WebSocket connections
```

**ESP32:**
```bash
pio device monitor --baud 115200  # Shows sensor readings and response codes
```

**Flutter:**
```bash
flutter logs  # Shows app debug output and connection errors
```

---

Created: 2026-05-12
Last Updated: 2026-05-12
