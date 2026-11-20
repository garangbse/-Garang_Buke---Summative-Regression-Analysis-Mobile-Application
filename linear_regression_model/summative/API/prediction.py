"""
FastAPI service for "Predicting Monthly Employment Earnings Among Young Rwandans".

Routes
    POST /predict   predicted monthly cash earnings (RWF) for one young employee
    POST /retrain   upload a CSV of new rows; the model is updated and used immediately
    GET  /docs      Swagger UI (generated automatically by FastAPI)

Run locally (from this folder):  uvicorn prediction:app --reload
"""
import copy
import io
import os
import threading
from pathlib import Path
from typing import Literal, get_args

import joblib
import numpy as np
import pandas as pd
from fastapi import FastAPI, File, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import RedirectResponse
from pydantic import BaseModel, ConfigDict, Field, field_validator, model_validator
from sklearn.base import clone
from sklearn.linear_model import SGDRegressor
from sklearn.metrics import mean_squared_error


# Settings

MODEL_PATH = Path(__file__).with_name("best_model.pkl")
MAX_UPLOAD_BYTES = 10 * 1024 * 1024          # reject CSV uploads larger than 10 MB
MAX_MONTHLY_CASH = 10_000_000                # same plausibility limit as the notebook (RWF per month)

TARGET = "cash"
NUMERICAL = ["a04", "usual_h", "d24", "d24b"]
CATEGORICAL = ["a01", "b02a", "indd01", "main_sect", "prod_unit", "d08"]
FEATURES = NUMERICAL + CATEGORICAL           # same order as in the notebook

# Allowed values of the categorical inputs: the labels used in the NISR Labour Force Survey data.
# "Missing" means "not recorded"; the notebook's preprocessing treats it as its own category.
Gender = Literal["Female", "Male"]
Education = Literal["Pre-primary", "Primary education", "Lower secondary education",
                    "Upper secondary education", "Tertiary education", "Missing"]
Occupation = Literal["Managers", "Professionals", "Technicians_and_associate_professionals",
                     "Clerical_support_workers", "Service_and_sales_workers",
                     "Skilled_agricultural,_forestry_and_fishery workers",
                     "Craft_and_related_trades_workers",
                     "Plant_and_machine_operators_and_assemblers", "Elementary_occupations"]
Industry = Literal["Agriculture", "Industry", "Services"]
Sector = Literal["Formal sector", "Informal Sector", "Household"]
Contract = Literal["Daily contract/Agreement", "Less than one month", "One to less than 3 months",
                   "3 to less than 6 months", "6 to less than 12 months", "12 to less than 24 months",
                   "2 years or more", "Missing"]

ALLOWED = {"a01": get_args(Gender), "b02a": get_args(Education), "indd01": get_args(Occupation),
           "main_sect": get_args(Industry), "prod_unit": get_args(Sector), "d08": get_args(Contract)}
OPTIONAL_IN_CSV = {"b02a", "d08"}            # blank values are allowed in an uploaded CSV (they become "Missing")

# Realistic ranges of the numeric inputs (the model was trained on employees aged 18 to 35)
AGE_RANGE, HOURS_RANGE, EXPERIENCE_RANGE, MONTHS_RANGE = (18, 35), (1, 120), (0, 25), (1, 12)



# Request and response models (Pydantic)

class EmployeeFeatures(BaseModel):
    """Input of /predict: one value per model input variable. Wrong types, missing or out-of-range values are rejected."""
    model_config = ConfigDict(
        extra="forbid",     # unknown fields are rejected instead of silently ignored
        json_schema_extra={"example": {
            "a04": 29, "usual_h": 40, "d24": 5, "d24b": 12, "a01": "Male", "b02a": "Upper secondary education",
            "indd01": "Service_and_sales_workers", "main_sect": "Services", "prod_unit": "Formal sector",
            "d08": "12 to less than 24 months"}})

    # numeric inputs: strict=True means a string such as "29" is rejected instead of being converted
    a04: int = Field(..., strict=True, ge=AGE_RANGE[0], le=AGE_RANGE[1], description="Age in years (18 to 35)")
    usual_h: float = Field(..., strict=True, ge=HOURS_RANGE[0], le=HOURS_RANGE[1], description="Usual working hours per week (1 to 120)")
    d24: float = Field(..., strict=True, ge=EXPERIENCE_RANGE[0], le=EXPERIENCE_RANGE[1], description="Total work experience in years (0 to 25)")
    d24b: int = Field(..., strict=True, ge=MONTHS_RANGE[0], le=MONTHS_RANGE[1], description="Months typically worked in a year (1 to 12)")
    # categorical inputs: only the listed values are accepted (matching ignores upper/lower case)
    a01: Gender = Field(..., description="Sex")
    b02a: Education = Field(..., description="Education level (use 'Missing' if not recorded)")
    indd01: Occupation = Field(..., description="Occupation group")
    main_sect: Industry = Field(..., description="Main economic sector")
    prod_unit: Sector = Field(..., description="Formal, informal or household sector")
    d08: Contract = Field(..., description="Duration of the employment contract (use 'Missing' if not recorded)")

    @field_validator(*CATEGORICAL, mode="before")
    @classmethod
    def match_allowed_value(cls, value, info):
        """Accept 'male' or ' Male ' for 'Male', and give a readable error that lists the allowed values."""
        if isinstance(value, str):
            allowed = ALLOWED[info.field_name]
            lookup = {" ".join(option.lower().split()): option for option in allowed}
            key = " ".join(value.lower().split())
            if key in lookup:
                return lookup[key]
            raise ValueError(f"'{value}' is not a valid option. Allowed values: {', '.join(allowed)}")
        return value        # not a string: the Literal check rejects it with a type error

    @model_validator(mode="after")
    def experience_fits_age(self):
        """Nobody has worked since before age 10 (this holds for every row of the training data)."""
        if self.d24 > self.a04 - 10:
            raise ValueError("Work experience cannot be longer than age minus 10 years")
        return self


class PredictionResponse(BaseModel):
    predicted_monthly_cash_rwf: float = Field(..., description="Predicted monthly cash earnings in Rwandan francs")
    currency: str = "RWF"
    model: str = Field(..., description="Type of model that made the prediction")


class RetrainResponse(BaseModel):
    message: str
    model: str
    method: str
    rows_received: int
    rows_used: int
    rows_rejected: int
    rejected_reasons: dict[str, int]
    mse_on_new_rows_before: float
    mse_on_new_rows_after: float
    note: str



# Model storage. The saved file best_model.pkl holds the fitted scikit-learn Pipeline (preprocessing + model)
# and the original training rows (needed to refit models that cannot learn from new rows with partial_fit).

class ModelState:
    def __init__(self):
        self.lock = threading.Lock()            # only one retraining at a time
        self.pipeline = None
        self.training_data = None               # DataFrame with FEATURES + cash, or None
        self.model_name = None

state = ModelState()


def load_model(path: Path = MODEL_PATH):
    bundle = joblib.load(path)
    if isinstance(bundle, dict):
        pipeline, rows = bundle["pipeline"], bundle.get("training_data")
    else:                                       # a bare Pipeline was saved: predicting works, refitting is not possible
        pipeline, rows = bundle, None
    state.pipeline = pipeline
    state.training_data = pd.DataFrame(rows)[FEATURES + [TARGET]] if rows is not None else None
    state.model_name = type(pipeline.steps[-1][1]).__name__


# The model is loaded from the repository when the service starts
try:
    load_model()
except FileNotFoundError:
    print(f"WARNING: {MODEL_PATH} not found; /predict will return 503 until it is added.")



# Application and CORS

app = FastAPI(
    title="Young Rwandan Employee Earnings API",
    description="Predicts the monthly cash earnings (RWF) of a young employee (aged 18 to 35) in Rwanda from the "
                "Rwanda Labour Force Survey 2025 (NISR). It is an estimate based on survey data, not a salary guarantee.",
    version="1.0.0",
)

RENDER_URL = "https://garang-buke-summative-regression-lb0z.onrender.com"       # replace with the URL of your Render service
ALLOWED_ORIGINS = [
    RENDER_URL,                       # the deployed service itself (for example a web page served from Render)
    "http://localhost:5000",          # Flutter web debug server: flutter run -d chrome --web-port 5000
    "http://127.0.0.1:5000",
    "http://localhost:8000",          # local FastAPI / Swagger UI
    "http://127.0.0.1:8000",
]
if os.getenv("RENDER_EXTERNAL_URL"):                            # Render sets this automatically
    ALLOWED_ORIGINS.append(os.environ["RENDER_EXTERNAL_URL"])

# CORS: what is allowed and what is restricted, and why.
#  - Origins: only the websites listed above may call this API from a browser. The wildcard "*" is NOT used,
#    so a random website cannot make a visitor's browser use this API.
#  - Methods: only GET (the docs, the redirect) and POST (/predict and /retrain). PUT, PATCH and DELETE are not
#    needed, so they are blocked.
#  - Headers: only "Content-Type" (JSON and file uploads) and "Accept". No custom or authorisation headers are needed.
#  - Credentials: False. The API uses no cookies or login sessions, so browsers must not send any; this also keeps the
#    configuration safe, because credentials may never be combined with a wildcard origin.
# A Flutter mobile app is not a browser, so CORS does not restrict it; this only controls which websites may call the API.
app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,
    allow_credentials=False,
    allow_methods=["GET", "POST"],
    allow_headers=["Content-Type", "Accept"],
)


@app.get("/", include_in_schema=False)
def home():
    """Send visitors of the base URL to the Swagger UI."""
    return RedirectResponse(url="/docs")



# POST /predict

@app.post("/predict", response_model=PredictionResponse, summary="Predict monthly cash earnings (RWF)")
def predict(features: EmployeeFeatures):
    """Return the predicted monthly cash earnings for one young employee.
    A request with a wrong type, a missing value or an out-of-range value returns a 422 validation error."""
    pipeline = state.pipeline
    if pipeline is None:
        raise HTTPException(status_code=503, detail="The model is not loaded on the server.")
    row = pd.DataFrame([features.model_dump()])[FEATURES]
    prediction = max(float(pipeline.predict(row)[0]), 0.0)         # income cannot be negative
    return PredictionResponse(predicted_monthly_cash_rwf=round(prediction, 2), model=state.model_name)



# POST /retrain

def read_training_csv(content: bytes):
    """Read and validate an uploaded CSV. Returns (clean rows, number received, reasons for rejected rows)."""
    try:
        raw = pd.read_csv(io.BytesIO(content), low_memory=False)
    except Exception:
        raise HTTPException(status_code=422, detail="The uploaded file could not be read as a CSV.")
    raw.columns = raw.columns.astype(str).str.strip().str.lower()
    missing_columns = [c for c in FEATURES + [TARGET] if c not in raw.columns]
    if missing_columns:
        raise HTTPException(status_code=422, detail=f"The CSV is missing required columns: {missing_columns}. "
                                                    f"Expected columns: {FEATURES + [TARGET]}")
    data = raw[FEATURES + [TARGET]].copy()
    for column in NUMERICAL + [TARGET]:
        data[column] = pd.to_numeric(data[column], errors="coerce")

    # categorical columns: match allowed labels ignoring case and spaces; blanks allowed only for b02a and d08
    bad_category = pd.Series(False, index=data.index)
    for column in CATEGORICAL:
        lookup = {" ".join(option.lower().split()): option for option in ALLOWED[column]}
        cleaned = data[column].astype("object").map(
            lambda v: np.nan if pd.isna(v) else lookup.get(" ".join(str(v).lower().split()), "__invalid__"))
        bad_category |= cleaned.eq("__invalid__")
        if column not in OPTIONAL_IN_CSV:
            bad_category |= cleaned.isna()
        data[column] = cleaned

    problems = {
        "age outside 18-35": ~data["a04"].between(*AGE_RANGE),
        "usual hours outside 1-120": ~data["usual_h"].between(*HOURS_RANGE),
        "experience outside 0-25 years": ~data["d24"].between(*EXPERIENCE_RANGE),
        "months worked outside 1-12": ~data["d24b"].between(*MONTHS_RANGE),
        "experience longer than age minus 10": data["d24"] > data["a04"] - 10,
        "unknown or missing category value": bad_category,
        "cash missing, not positive, or above the plausibility limit": ~(data[TARGET].gt(0) & data[TARGET].le(MAX_MONTHLY_CASH)),
    }
    invalid = pd.concat(problems, axis=1).any(axis=1)
    reasons = {name: int(mask.sum()) for name, mask in problems.items() if mask.sum() > 0}
    clean = data[~invalid].copy()
    clean["a04"] = clean["a04"].astype(int)                         # keep the same column types as the training data
    clean[["usual_h", "d24", "d24b", TARGET]] = clean[["usual_h", "d24", "d24b", TARGET]].astype(float)
    return clean.reset_index(drop=True), len(data), reasons


@app.post("/retrain", response_model=RetrainResponse, summary="Retrain the model with an uploaded CSV")
def retrain(file: UploadFile = File(..., description="CSV with the columns: " + ", ".join(FEATURES + [TARGET]))):
    """Upload a CSV with the same columns as the training data (the 10 inputs plus `cash`, the monthly earnings in RWF).
    The upload itself starts the retraining, and /predict uses the updated model straight away.
    - SGDRegressor: training continues on the new rows with `partial_fit`.
    - Any other model: it is refitted on the original training data plus the new rows.
    The updated model is kept in memory; on the free Render plan it returns to the saved model after a restart."""
    content = file.file.read(MAX_UPLOAD_BYTES + 1)
    if len(content) > MAX_UPLOAD_BYTES:
        raise HTTPException(status_code=413, detail="The file is larger than 10 MB.")
    new_rows, n_received, reasons = read_training_csv(content)
    if new_rows.empty:
        raise HTTPException(status_code=422, detail={"message": "No valid rows found in the CSV.", "rejected_reasons": reasons})

    with state.lock:
        if state.pipeline is None:
            raise HTTPException(status_code=503, detail="The model is not loaded on the server.")
        X_new, y_new = new_rows[FEATURES], new_rows[TARGET]
        mse_before = float(mean_squared_error(y_new, state.pipeline.predict(X_new)))

        if isinstance(state.pipeline.steps[-1][1], SGDRegressor):
            updated = copy.deepcopy(state.pipeline)                     # work on a copy so a failure cannot corrupt the live model
            X_new_transformed = updated[:-1].transform(X_new)           # the already fitted preprocessing steps
            updated.steps[-1][1].partial_fit(X_new_transformed, y_new)  # continue training on the new rows
            method = "partial_fit: continued training the saved SGDRegressor on the new rows"
            combined = pd.concat([state.training_data, new_rows], ignore_index=True) if state.training_data is not None else None
        else:
            if state.training_data is None:
                raise HTTPException(status_code=409, detail="The original training data is not stored with the model, "
                                                            "so this model type cannot be refitted.")
            combined = pd.concat([state.training_data, new_rows], ignore_index=True)
            updated = clone(state.pipeline)                             # same settings, unfitted
            updated.fit(combined[FEATURES], combined[TARGET])
            method = "refit: trained again on the original training data plus the new rows"

        mse_after = float(mean_squared_error(y_new, updated.predict(X_new)))
        state.pipeline, state.training_data = updated, combined         # /predict now uses the updated model

    return RetrainResponse(
        message="Model retrained. /predict now uses the updated model.",
        model=state.model_name, method=method, rows_received=n_received, rows_used=len(new_rows),
        rows_rejected=n_received - len(new_rows), rejected_reasons=reasons,
        mse_on_new_rows_before=round(mse_before, 2), mse_on_new_rows_after=round(mse_after, 2),
        note="Both MSE values are measured on the uploaded rows only, so the 'after' value is not a test score.")
