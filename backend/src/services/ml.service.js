const path = require("path");
const { spawn } = require("child_process");

const scriptPath = path.resolve(__dirname, "../ml/predict.py");

const runPythonPrediction = (features) =>
  new Promise((resolve, reject) => {
    const python = spawn(process.env.PYTHON_BIN || "python", [scriptPath], {
      stdio: ["pipe", "pipe", "pipe"],
    });

    let stdout = "";
    let stderr = "";

    python.stdout.on("data", (chunk) => {
      stdout += chunk.toString();
    });

    python.stderr.on("data", (chunk) => {
      stderr += chunk.toString();
    });

    python.on("error", reject);

    python.on("close", (code) => {
      if (code !== 0) {
        const message = stderr.trim() || `ML process exited with code ${code}.`;
        reject(new Error(message));
        return;
      }

      try {
        resolve(JSON.parse(stdout));
      } catch (error) {
        reject(new Error(`Invalid ML response: ${stdout || error.message}`));
      }
    });

    python.stdin.end(JSON.stringify(features));
  });

const formatStatus = (ripeness) => String(ripeness || "Unknown").toLowerCase();

const buildRecommendation = ({ ripeness, chemicalUsed }) => {
  const status = formatStatus(ripeness);
  const isNatural = String(chemicalUsed).toUpperCase() !== "YES";
  const method = isNatural ? "naturally" : "chemically";

  if (status === "unripe") {
    return `Fruit is currently unripe. Wait for ripening.`;
  }

  if (status === "ripe") {
    return `Fruit is ${method} ripened and currently ripe. Recommended for consumption within 2 days.`;
  }

  if (status === "overripe") {
    return `Fruit is ${method} ripened and currently overripe. Consume immediately or discard.`;
  }

  return `Fruit is ${method} ripened and currently ${status}. Review before consumption.`;
};

const predictFromSensorData = async (sensorData) => {
  const result = await runPythonPrediction({
    Red: sensorData.r ?? 0,
    Green: sensorData.g ?? 0,
    Blue: sensorData.b ?? 0,
    Temperature: sensorData.temperature ?? 0,
    Humidity: sensorData.humidity ?? 0,
    Pressure: sensorData.pressure ?? 0,
    GasResistance:
      sensorData.gasResistance ?? sensorData["Gas resistance in (Kohm)"] ?? 0,
    Difference: sensorData.difference ?? 0,
    "VOC%": sensorData.vocPercent ?? sensorData.VOC_percent ?? 0,
  });

  return {
    isNaturalRipening: String(result.chemicalUsed).toUpperCase() !== "YES",
    status: formatStatus(result.ripeness),
    confidence: result.confidence,
    recommendation: buildRecommendation(result),
    color: result.color,
    chemicalUsed: result.chemicalUsed,
    ripeness: result.ripeness,
  };
};

module.exports = {
  predictFromSensorData,
};
