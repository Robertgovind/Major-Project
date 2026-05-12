# Fruit Pulse Backend

Simple Node.js backend for live ESP32-style sensor data and ML predictions.

## Flow

ESP32 sensors -> Backend ML -> WebSocket -> Flutter App

The ESP32 sends real sensor readings using HTTP `POST`. The backend normalizes that
payload, runs the saved scikit-learn models from `../ML`, and broadcasts the integrated
sensor + prediction result to every Flutter app connected to `/ws`.
No MongoDB or database is used.

## Setup

```bash
cd backend
npm install
python -m pip install -r requirements.txt
copy .env.example .env
npm run dev
```

The server runs on port `5000` by default.

## WebSocket

Flutter connects here:

```text
ws://localhost:5000/ws
```

For Android emulator, the app uses:

```text
ws://10.0.2.2:5000/ws
```

For a physical phone, run Flutter with your computer's LAN IP:

```bash
flutter run --dart-define=API_HOST=192.168.1.10
```

## Send Data From ESP32

```http
POST /api/v1/sensor-data
Content-Type: application/json
x-api-key: change-this-secret

{
  "Red": 120,
  "Green": 88,
  "Blue": 35,
  "Temperature": 24.7,
  "Humidity": 55.4,
  "Pressure": 1008.2,
  "Gas resistance in (Kohm)": 48.2,
  "Difference": 4.1,
  "VOC_percent": 0.42
}
```

The legacy `/predict` endpoint is also available for the existing ESP32 code.

The backend broadcasts this websocket message:

```json
{
  "event": "sensor:reading",
  "data": {
    "sensorData": {
      "deviceId": "esp32-1",
      "fruitType": "",
      "r": 120,
      "g": 88,
      "b": 35,
      "humidity": 55.4,
      "temperature": 24.7,
      "pressure": 1008.2,
      "gasResistance": 48.2,
      "difference": 4.1,
      "vocPercent": 0.42,
      "voc": 42,
      "chemicalRipening": 0.42,
      "timestamp": "2026-05-11T13:30:00.000Z"
    },
    "prediction": {
      "isNaturalRipening": true,
      "status": "overripe",
      "confidence": 0.355,
      "recommendation": "Fruit is naturally ripened and currently overripe. Consume immediately or discard.",
      "color": "Yellow",
      "chemicalUsed": "NO",
      "ripeness": "Overripe"
    }
  }
}
```

## Useful Endpoints

```http
GET /health
GET /api/v1/sensor-data/latest
POST /api/v1/sensor-data
POST /predict
```
