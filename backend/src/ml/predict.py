import json
import sys
from pathlib import Path
import joblib
import pandas as pd


ROOT = Path(__file__).resolve().parents[3]
ML_DIR = ROOT / "ML"

RIPENESS_FEATURES = [
    "Humidity",
    "GasResistance",
    "Difference",
    "Red",
    "Green",
    "Blue",
]
COLOR_FEATURES = ["Red", "Green", "Blue"]
CHEMICAL_FEATURES = [
    "Temperature",
    "Pressure",
    "Humidity",
    "GasResistance",
    "Difference",
    "VOC%",
    "Red",
    "Green",
    "Blue",
    
]


def load_model(name):
    return joblib.load(ML_DIR / name)


def predict_label(model, encoder, payload, features):
    frame = pd.DataFrame([{feature: float(payload[feature]) for feature in features}])
    encoded = model.predict(frame)[0]
    label = encoder.inverse_transform([encoded])[0]

    confidence = None
    if hasattr(model, "predict_proba"):
        probabilities = model.predict_proba(frame)[0]
        confidence = float(max(probabilities))

    return str(label), confidence


def main():
    payload = json.loads(sys.stdin.read())

    try:
        ripeness_model = load_model("ripeness_model (2).pkl")
        color_model = load_model("color_model (2).pkl")
        chemical_model = load_model("chemical_model (2).pkl")
        ripeness_encoder = load_model("ripeness_encoder.pkl")
        color_encoder = load_model("color_encoder.pkl")
        chemical_encoder = load_model("chemical_encoder.pkl")
    except Exception as error:
        raise RuntimeError(
            "Unable to load ML model files. These models were saved with "
            "scikit-learn 1.6.1, so install a matching version in the Python "
            f"environment used by the backend. Original error: {error}"
        ) from error

    ripeness, ripeness_confidence = predict_label(
        ripeness_model,
        ripeness_encoder,
        payload,
        RIPENESS_FEATURES,
    )
    color, color_confidence = predict_label(
        color_model,
        color_encoder,
        payload,
        COLOR_FEATURES,
    )
    chemical_used, chemical_confidence = predict_label(
        chemical_model,
        chemical_encoder,
        payload,
        CHEMICAL_FEATURES,
    )

    confidences = [
        value
        for value in [ripeness_confidence, color_confidence, chemical_confidence]
        if value is not None
    ]

    print(
        json.dumps(
            {
                "ripeness": ripeness,
                "color": color,
                "chemicalUsed": chemical_used,
                "confidence": min(confidences) if confidences else 1.0,
            }
        )
    )


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        print(str(error), file=sys.stderr)
        sys.exit(1)
