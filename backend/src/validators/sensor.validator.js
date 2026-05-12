const { z } = require('zod');

const numericString = (schema) =>
  z.preprocess((value) => {
    if (typeof value === 'string' && value.trim() !== '') {
      return Number(value);
    }
    return value;
  }, schema);

const sensorDataSchema = z.object({
  deviceId: z.string().trim().min(1).max(80).optional().default('esp32-1'),
  fruitType: z.string().trim().max(80).optional().default(''),
  r: numericString(z.number().int().min(0).max(255)),
  g: numericString(z.number().int().min(0).max(255)),
  b: numericString(z.number().int().min(0).max(255)),
  humidity: numericString(z.number().min(0).max(100)),
  temperature: numericString(z.number().min(-40).max(125)),
  pressure: numericString(z.number().min(0)).optional(),
  gasResistance: numericString(z.number().min(0)).optional(),
  difference: numericString(z.number()).optional(),
  vocPercent: numericString(z.number().min(0).max(1)).optional(),
  voc: numericString(z.number().min(0).max(100000)),
  chemicalRipening: numericString(z.number().min(0).max(1)),
  timestamp: z.coerce.date().optional().default(() => new Date()),
}).passthrough();

module.exports = {
  sensorDataSchema,
};
