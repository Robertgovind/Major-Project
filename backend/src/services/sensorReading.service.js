const clamp = (value, min, max) => Math.min(Math.max(value, min), max);

const asNumber = (body, ...keys) => {
  for (const key of keys) {
    const value = body[key];
    if (value !== undefined && value !== null && value !== '') {
      return Number(value);
    }
  }

  return undefined;
};

const normalizeVocPercent = (value) => {
  if (!Number.isFinite(value)) return 0;
  return clamp(value, 0, 1);
};

const normalizeSensorPayload = (body) => {
  const vocPercent = normalizeVocPercent(
    asNumber(body, 'VOC_percent', 'vocPercent', 'voc', 'chemicalRipening'),
  );

  return {
    deviceId: String(body.deviceId || 'esp32-1'),
    fruitType: String(body.fruitType || ''),
    r: asNumber(body, 'Red', 'red', 'r'),
    g: asNumber(body, 'Green', 'green', 'g'),
    b: asNumber(body, 'Blue', 'blue', 'b'),
    humidity: asNumber(body, 'Humidity', 'humidity'),
    temperature: asNumber(body, 'Temperature', 'temperature'),
    pressure: asNumber(body, 'Pressure', 'pressure'),
    gasResistance: asNumber(
      body,
      'Gas resistance in (Kohm)',
      'gasResistance',
      'gas',
    ),
    difference: asNumber(body, 'Difference', 'difference'),
    vocPercent,
    voc: Number((vocPercent * 100).toFixed(2)),
    chemicalRipening: vocPercent,
    timestamp: body.timestamp || new Date(),
  };
};

const createSensorReading = async (body, predictFromSensorData) => {
  const sensorData = normalizeSensorPayload(body);
  const prediction = await predictFromSensorData(sensorData);

  return {
    sensorData,
    prediction,
  };
};

module.exports = {
  createSensorReading,
  normalizeSensorPayload,
};
