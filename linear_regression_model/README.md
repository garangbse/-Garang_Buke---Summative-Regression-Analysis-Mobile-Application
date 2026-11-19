# Predicting Monthly Employment Earnings Among Young Rwandans

## 1. Mission and problem
**Mission:** to create technology-driven financial and employment solutions that help African youth access income opportunities.
**Problem:** young people entering work do not know what they can expect to earn, so they cannot plan career decisions well.
**Solution:** a regression model estimates the monthly cash earnings (RWF) of a young Rwandan employee from their age, education, job and working conditions.
The estimate is based on survey data and is not a salary guarantee.

## 2. Dataset
**Rwanda Labour Force Survey 2025 (LFS 2025)**, produced by the National Institute of Statistics of Rwanda (NISR): real, individual-level survey data (100,852 people, 207 variables, collected through CAPI in 2025).
Source: https://microdata.statistics.gov.rw/index.php/catalog/125
The model uses 11,232 employees aged 18 to 35 who report monthly cash income (`cash`, in RWF) and 10 input variables (age, gender, education, occupation, industry, working hours, work experience, months worked, formal/informal sector, contract duration).

## 3. Public API (Swagger UI)
**TO FILL AFTER DEPLOYMENT:** https://YOUR-SERVICE.onrender.com/docs

The free Render plan sleeps after 15 minutes without traffic; the first request can take up to a minute.

## 4. Video demo
**TO FILL AFTER RECORDING:** https://www.youtube.com/watch?v=YOUR_VIDEO_ID

## 5. Run the mobile app (Android or iOS emulator, or a phone)
1. Install the [Flutter SDK](https://docs.flutter.dev/get-started/install) and Android Studio (or Xcode on a Mac). Run `flutter doctor` and fix anything it reports.
2. Clone this repository and open a terminal in `summative/FlutterApp`.
3. Generate the Android and iOS platform folders (one time): `flutter create .` (it keeps the existing `lib/`, `test/` and `pubspec.yaml`; if one of them is replaced, restore it with `git checkout -- <file>`).
4. Android only: make sure `android/app/src/main/AndroidManifest.xml` contains `<uses-permission android:name="android.permission.INTERNET"/>` inside `<manifest>` (needed for release builds).
5. Install the packages: `flutter pub get`.
6. Start an emulator (Android Studio Device Manager, or `flutter emulators --launch <id>`) or connect a phone with USB debugging, and check it appears with `flutter devices`.
7. Open `https://YOUR-SERVICE.onrender.com/docs` in a browser first, so the free server is awake.
8. Run the app with your API address: `flutter run --dart-define=API_BASE_URL=https://YOUR-SERVICE.onrender.com` (or edit the default in `lib/config/api_config.dart` and run `flutter run`).
9. Fill in the 10 fields (the arrow in a category field opens the list of allowed values), press **Predict**, and read the result in the display area. A missing, wrongly typed or out-of-range value shows an error message in the same area.
10. Optional: `flutter test` runs the widget and service tests.

Example input: age 29, Male, Upper secondary education, Service_and_sales_workers, Services, Formal sector, 12 to less than 24 months, 40 hours, 5 years of experience, 12 months.

---

## Project layout
```
summative/
  pyproject.toml, uv.lock          Python environment (managed with uv)
  linear_regression/multivariate.ipynb   Task 1: four regression models (Google Colab notebook)
  API/prediction.py                FastAPI service (POST /predict, POST /retrain, GET /docs)
  API/best_model.pkl               saved best model: fitted preprocessing + model, plus the original training rows
  API/requirements.txt             exported from uv, used by Render
  FlutterApp/                      one-page Flutter app
    lib/main.dart, app.dart        start-up and MaterialApp
    lib/screens/                   the page (predict_screen.dart)
    lib/widgets/                   text field, section card, Predict button, display area
    lib/controllers/               page state and logic (PredictionController)
    lib/services/                  HTTP call to POST /predict (PredictionService)
    lib/models/, constants/        the 10 inputs and the result
    lib/utils/, config/, theme/    parsing, error messages, API address, spacing
    test/                          widget test and service tests
```

## Run the API locally
```bash
cd summative
uv sync
cd API
uv run uvicorn prediction:app --reload        # Swagger UI at http://127.0.0.1:8000/docs
```

## Deploy on Render (web service, free plan)
| Setting | Value |
|---|---|
| Root Directory | `summative/API` |
| Build Command | `pip install -r requirements.txt` |
| Start Command | `uvicorn prediction:app --host 0.0.0.0 --port $PORT` |
| Environment variable | `PYTHON_VERSION` = a Python 3.12 release, for example `3.12.8` |

After changing dependencies, regenerate the requirements file from `summative/`:
`uv lock && uv export --format requirements.txt --no-hashes -o API/requirements.txt`

`scikit-learn` is pinned to the version used in Colab (1.6.1) because a saved model must be loaded with the same version that trained it.

## API behaviour
- `POST /predict`: JSON body with the 10 inputs. Every field has an enforced type and range (for example age 18 to 35); a wrong type, a missing value or an out-of-range value returns a 422 error and no prediction.
- `POST /retrain`: upload a CSV with the columns `a04, usual_h, d24, d24b, a01, b02a, indd01, main_sect, prod_unit, d08, cash`. Invalid rows are skipped and reported. If the saved model is an `SGDRegressor` it continues training with `partial_fit`; any other model (the current one is a `RandomForestRegressor`) is refitted on the original rows plus the new rows. `/predict` uses the updated model immediately. On the free Render plan the retrained model is lost when the service restarts and the saved model is loaded again.
- CORS: only the listed origins, the methods GET and POST, and the headers Content-Type and Accept are allowed, with credentials off (see the comment above the middleware in `prediction.py`).
