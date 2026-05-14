const compression = require("compression");
const cors = require("cors");
const express = require("express");
const helmet = require("helmet");
const morgan = require("morgan");
const env = require("./config/env");
const apiRoutes = require("./routes");
const sensorController = require("./controllers/sensor.controller.js");
const requireApiKey = require("./middleware/apiKey");
const errorHandler = require("./middleware/errorHandler");
const notFound = require("./middleware/notFound");

const app = express();

app.use(helmet());
app.use(cors({ origin: env.corsOrigin }));
app.use(compression());
app.use(express.json({ limit: "1mb" }));
app.use(express.urlencoded({ extended: true }));

if (env.nodeEnv !== "test") {
  app.use(morgan("dev"));
}

app.get("/", (req, res) => {
  res.json({
    success: true,
    message: "Fruit Pulse backend is running.",
    uptime: process.uptime(),
    timestamp: new Date().toISOString(),
  });
});

app.get("/health", (req, res) => {
  res.json({
    success: true,
    message: "Fruit Pulse backend is running.",
    uptime: process.uptime(),
    timestamp: new Date().toISOString(),
  });
});

app.use("/api/v1", apiRoutes);
app.post("/predict", requireApiKey, sensorController.receiveSensorData);
app.use(notFound);
app.use(errorHandler);

module.exports = app;
