const asyncHandler = require("../utils/asyncHandler");
const { success } = require("../utils/apiResponse");
const {
  broadcastSensorReading,
  queueSensorReadings,
  getLatestSensorReading,
} = require("../config/websocketHub");
const { predictFromSensorData } = require("../services/ml.service");
const { createSensorReading } = require("../services/sensorReading.service");
const { sensorDataSchema } = require("../validators/sensor.validator");

const receiveSensorData = asyncHandler(async (req, res) => {
  console.log("📥 Received sensor data:", JSON.stringify(req.body, null, 2));

  const payloads = Array.isArray(req.body) ? req.body : [req.body];
  const normalizedReadings = [];

  for (const item of payloads) {
    const reading = await createSensorReading(item, predictFromSensorData);
    const normalizedReading = {
      ...reading,
      sensorData: sensorDataSchema.parse(reading.sensorData),
    };

    normalizedReadings.push(normalizedReading);
  }

  console.log(
    "🔄 Normalized sensor readings:",
    JSON.stringify(
      normalizedReadings.map((r) => r.sensorData),
      null,
      2,
    ),
  );
  console.log(
    "🤖 Prediction results:",
    JSON.stringify(
      normalizedReadings.map((r) => r.prediction),
      null,
      2,
    ),
  );

  queueSensorReadings(normalizedReadings);

  success(
    res,
    {
      count: normalizedReadings.length,
      readings: normalizedReadings,
    },
    "Sensor readings queued for broadcast.",
    201,
  );
});

const getLatest = asyncHandler(async (req, res) => {
  const latest = getLatestSensorReading();

  success(
    res,
    latest,
    latest
      ? "Latest sensor reading fetched."
      : "No sensor reading generated yet.",
  );
});

const getSensorStatus = asyncHandler(async (req, res) => {
  const latest = getLatestSensorReading();

  let status = "offline";
  let lastSeen = null;

  if (latest && latest.sensorData && latest.sensorData.timestamp) {
    const lastTimestamp = new Date(latest.sensorData.timestamp);
    const now = new Date();
    const timeDiff = (now - lastTimestamp) / 1000; // seconds

    if (timeDiff <= 10) {
      status = "live";
    } else if (timeDiff <= 30) {
      status = "waiting";
    } else {
      status = "offline";
    }

    lastSeen = lastTimestamp.toISOString();
  }

  success(
    res,
    {
      status,
      lastSeen,
      lastReading: latest,
    },
    "Sensor status fetched.",
  );
});

module.exports = {
  receiveSensorData,
  getLatest,
  getSensorStatus,
};
