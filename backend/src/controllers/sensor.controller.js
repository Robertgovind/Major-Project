const asyncHandler = require("../utils/asyncHandler");
const { success } = require("../utils/apiResponse");
const {
  broadcastSensorReading,
  getLatestSensorReading,
} = require("../config/websocketHub");
const { predictFromSensorData } = require("../services/ml.service");
const { createSensorReading } = require("../services/sensorReading.service");
const { sensorDataSchema } = require("../validators/sensor.validator");

const receiveSensorData = asyncHandler(async (req, res) => {
  const reading = await createSensorReading(req.body, predictFromSensorData);
  const normalizedReading = {
    ...reading,
    sensorData: sensorDataSchema.parse(reading.sensorData),
  };

  broadcastSensorReading(normalizedReading);

  success(
    res,
    normalizedReading,
    "Sensor reading predicted and broadcasted.",
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

module.exports = {
  receiveSensorData,
  getLatest,
};
