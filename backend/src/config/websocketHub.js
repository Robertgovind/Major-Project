const { WebSocket, WebSocketServer } = require("ws");

let wss;
let latestSensorReading = null;
let readingQueue = [];
let emissionTimer = null;

const sendJson = (client, event, data) => {
  if (client.readyState !== WebSocket.OPEN) return;
  client.send(JSON.stringify({ event, data }));
};

const initWebSocket = (server) => {
  wss = new WebSocketServer({
    server,
    path: "/ws",
  });

  wss.on("connection", (client) => {
    sendJson(client, "connected", {
      message: "Connected to Fruit Pulse live sensor stream.",
    });
  });

  return wss;
};

const _processReadingQueue = () => {
  if (!wss || readingQueue.length === 0) {
    if (emissionTimer) {
      clearInterval(emissionTimer);
      emissionTimer = null;
    }
    return;
  }

  const nextReading = readingQueue.shift();
  latestSensorReading = nextReading;

  wss.clients.forEach((client) => {
    sendJson(client, "sensor:reading", nextReading);
  });

  if (readingQueue.length === 0 && emissionTimer) {
    clearInterval(emissionTimer);
    emissionTimer = null;
  }
};

const broadcastSensorReading = (reading) => {
  latestSensorReading = reading;

  if (!wss) return;

  wss.clients.forEach((client) => {
    sendJson(client, "sensor:reading", reading);
  });
};

const queueSensorReadings = (readings) => {
  if (!Array.isArray(readings) || readings.length === 0) return;

  readingQueue.push(...readings);

  if (!emissionTimer) {
    // Emit the first queued reading immediately, then continue at 2-second intervals.
    _processReadingQueue();
    emissionTimer = setInterval(_processReadingQueue, 2000);
  }
};

const getLatestSensorReading = () => latestSensorReading;

module.exports = {
  initWebSocket,
  broadcastSensorReading,
  queueSensorReadings,
  getLatestSensorReading,
};
