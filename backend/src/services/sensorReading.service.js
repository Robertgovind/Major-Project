const clamp = (value, min, max) => Math.min(Math.max(value, min), max);

const asNumber = (body, ...keys) => {
  for (const key of keys) {
    const value = body[key];
    if (value !== undefined && value !== null && value !== "") {
      return Number(value);
    }
  }

  return undefined;
};

const normalizeVocPercent = (value) => {
  if (!Number.isFinite(value)) return 0;
  return clamp(value, -1, 1);
};

const normalizeSensorPayload = (body) => {
  const vocPercent = normalizeVocPercent(
    asNumber(
      body,
      "VOC%",
      "VOC_percent",
      "vocPercent",
      "voc",
      "chemicalRipening",
    ),
  );

  const gasResistance = asNumber(
    body,
    "Gas resistance in (Kohm)",
    "GasResistance",
    "gasResistance",
    "gas",
  );

  const difference = asNumber(body, "Difference", "difference");

  return {
    deviceId: String(body.deviceId || "esp32-1"),
    fruitType: String(body.fruitType || ""),
    r: asNumber(body, "Red", "red", "r") ?? 0,
    g: asNumber(body, "Green", "green", "g") ?? 0,
    b: asNumber(body, "Blue", "blue", "b") ?? 0,
    humidity: asNumber(body, "Humidity", "humidity") ?? 0,
    temperature: asNumber(body, "Temperature", "temperature") ?? 0,
    pressure: asNumber(body, "Pressure", "pressure") ?? 0,
    gasResistance: gasResistance ?? 0,
    difference: difference ?? 0,
    vocPercent,
    voc: Number((vocPercent * 100).toFixed(2)),
    chemicalRipening: clamp(vocPercent, 0, 1),
    timestamp: body.timestamp || new Date(),
  };
};

const createSensorReading = (body, prediction) => {
  const sensorData = normalizeSensorPayload(body);

  return {
    sensorData,
    prediction,
  };
};

module.exports = {
  createSensorReading,
  normalizeSensorPayload,
};
