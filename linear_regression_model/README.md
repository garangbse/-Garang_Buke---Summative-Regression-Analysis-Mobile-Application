# Predicting Monthly Employment Earnings Among Young Rwandans

## 1. Mission and problem
- **Mission:** to create technology-driven financial and employment solutions that help African youth access income opportunities.
- **Problem:** young people entering work have little information about what they can expect to earn.
- **Solution:** a regression model estimates the monthly cash earnings (RWF) of a young Rwandan employee from their age, education, job and working conditions, and serves it through an API and a mobile app.
- The estimate comes from survey data. It is not a salary guarantee.

## 2. Dataset
**Rwanda Labour Force Survey 2025 (LFS 2025)**, produced by the National Institute of Statistics of Rwanda (NISR). It is real, individual-level survey data: 100,852 people and 207 variables, collected through computer-assisted interviews in 2025.

Source: https://microdata.statistics.gov.rw/index.php/catalog/125

The model uses the **11,232 employees aged 18 to 35** who report a monthly cash income (`cash`, in RWF, the value we predict) and 10 input variables: age, gender, education, occupation, industry, usual working hours, work experience, months worked per year, formal or informal sector, and contract duration.

The CSV file (`RW_LFS2025_3.csv`, about 100 MB) is **not stored in this repository**. It is only needed to re-run the notebook, and you can run the API and the app without it (see "How the model is trained when the dataset is not on GitHub" below).

## 3. Public API (Swagger UI)
https://garang-buke-summative-regression-lb0z.onrender.com/docs

The free Render plan sleeps after 15 minutes without traffic, so the first request can take up to a minute.

## 4. Video demo
**ADD YOUR LINK HERE:** https://www.youtube.com/watch?v=YOUR_VIDEO_ID

## 5. Run the mobile app (Android or iOS emulator, or a phone)
All paths in this README start from the `linear_regression_model/` folder.

1. Install the [Flutter SDK](https://docs.flutter.dev/get-started/install) and Android Studio (or Xcode on a Mac). Run `flutter doctor` and fix anything it reports.
2. Open a terminal in `summative/FlutterApp`.
3. Create the Android and iOS folders (one time): `flutter create .` It keeps the existing `lib/`, `test/` and `pubspec.yaml`. If one of them is replaced, restore it with `git checkout -- <file>`.
4. Android only: make sure `android/app/src/main/AndroidManifest.xml` contains `<uses-permission android:name="android.permission.INTERNET"/>` inside the `<manifest>` tag.
5. Install the packages: `flutter pub get`
6. Start an emulator (Android Studio, Device Manager) or connect a phone with USB debugging, and check it is listed with `flutter devices`.
7. Open the Swagger link above in a browser, so the free server is awake.
8. Run the app:
   ```
   flutter run --dart-define=API_BASE_URL=https://garang-buke-summative-regression-lb0z.onrender.com
   ```
   (The address must have no `/docs` and no `/` at the end. It is also the default in `lib/config/api_config.dart`.)
9. Fill in the 10 fields (the arrow in a category field lists the allowed values), press **Predict**, and read the result in the display area. A missing, wrongly typed or out-of-range value shows a readable error in the same area.

Example input: age 29, Male, Upper secondary education, Service_and_sales_workers, Services, Formal sector, 12 to less than 24 months, 40 hours, 5 years of experience, 12 months. Expected result: about RWF 126,600.

Optional: `flutter test` runs the widget test and the API-call tests.

---

## How the model is trained when the dataset is not on GitHub

The dataset is used in **one place only: the notebook**. Everything else runs from the saved model.

1. **Training (notebook).** `summative/linear_regression/multivariate.ipynb` loads the CSV, filters and cleans it, splits it 80/20, trains and compares four models, and picks the best one by test MSE.
2. **Saving.** The notebook saves the best model as `summative/API/best_model.pkl`. This file contains the fitted preprocessing, the fitted model, and the 8,985 training rows (11 columns), so the model can be refitted later.
3. **Using.** The API loads `best_model.pkl` when it starts. The Flutter app only talks to the API. Neither needs the CSV.

| What you want to do | Needs the dataset? |
|---|---|
| Open the repository and read the notebook with its saved results | No |
| Call `/predict` on the public Swagger link | No |
| Run the API on your computer | No (the model file is in the repository) |
| Run the Flutter app | No |
| Upload a CSV to `/retrain` | No (the API uses the training rows stored in `best_model.pkl` plus your uploaded CSV) |
| Re-run the notebook and train the models again | **Yes** |

### To re-run the notebook (the only step that needs the dataset)
1. Download the NISR file from the catalogue link in section 2 (the site may ask you to register or accept its terms). The file used here is called `RW_LFS2025_3.csv`, about 100 MB, with 100,852 rows and 207 columns.
2. Open the notebook in Colab: [Open in Colab](https://colab.research.google.com/github/garangbse/-Garang_Buke---Summative-Regression-Analysis-Mobile-Application/blob/main/linear_regression_model/summative/linear_regression/multivariate.ipynb)
3. Rename or upload the file as `RW_LFS2025.csv` (the name the notebook looks for). If the file is not found, Colab opens an upload box.
4. Run all cells. Check that the printed shape is `(100852, 207)`. A smaller number means the upload was cut short, so upload again.
5. At the end the notebook creates `best_model.joblib` and `best_model.pkl`. Copy `best_model.pkl` into `summative/API/`.

## Run the API on your computer
Needs Python 3.12 and [uv](https://docs.astral.sh/uv/) (`pip install uv`).
```
cd summative
uv sync
cd API
uv run uvicorn prediction:app --reload
```
Open http://127.0.0.1:8000/docs. The model file is already in the `API` folder.

## API endpoints
| Route | Method | What it does |
|---|---|---|
| `/predict` | POST | Takes the 10 input variables and returns the predicted monthly cash earnings in RWF |
| `/retrain` | POST | Takes an uploaded CSV of new rows, retrains the model and starts using it |
| `/docs` | GET | Swagger UI, generated by FastAPI |

**Input rules for `/predict`** (a wrong type, a missing value or an out-of-range value returns a 422 error and no prediction):

| Field | Type | Allowed |
|---|---|---|
| `a04` age | integer | 18 to 35 |
| `usual_h` hours per week | number | 1 to 120 |
| `d24` work experience (years) | number | 0 to 25, and not more than age minus 10 |
| `d24b` months worked per year | integer | 1 to 12 |
| `a01`, `b02a`, `indd01`, `main_sect`, `prod_unit`, `d08` | text | only the listed category values (shown in Swagger) |

**`/retrain`** accepts a CSV with these columns. Rows that break the rules above are skipped and reported in the answer:
```
a04,usual_h,d24,d24b,a01,b02a,indd01,main_sect,prod_unit,d08,cash
20,70.0,0.0,3.0,Female,Primary education,Elementary_occupations,Services,Household,,15000.0
26,42.0,10.0,5.0,Male,Lower secondary education,Plant_and_machine_operators_and_assemblers,Services,Household,,120000.0
```
Uploading the file starts the retraining. No other step is needed.
- If the saved model is an `SGDRegressor`, training continues on the new rows with `partial_fit`.
- Any other model (the saved one is a `RandomForestRegressor`) is refitted on the original training rows plus the new rows, with the same settings.
- `/predict` uses the updated model straight away, with no redeploy.
- On the free Render plan the update lives in memory only. After a restart the service loads the saved `best_model.pkl` again. To keep a new model for good, retrain in the notebook and commit a new `best_model.pkl`.

## CORS 
 The configuration is in `summative/API/prediction.py`, above `app.add_middleware(CORSMiddleware, ...)`.

| Option | Setting | Why |
|---|---|---|
| `allow_origins` | the Render URL, `http://localhost:5000` and `http://127.0.0.1:5000` (Flutter web debug), `http://localhost:8000` and `http://127.0.0.1:8000` (local Swagger) | Only these websites may use the API from a browser. The wildcard `*` is not used. |
| `allow_methods` | `GET`, `POST` | These are the only methods the API uses. |
| `allow_headers` | `Content-Type`, `Accept` | JSON and file uploads need nothing else. |
| `allow_credentials` | `False` | The API uses no cookies or logins. |

The Flutter mobile app is not a browser, so CORS does not restrict it. The Swagger page on the Render URL is the same origin as the API, so CORS does not apply to it either. The configuration only controls which other websites can call the API from a visitor's browser.


## Deploy on Render (web service, free plan)
| Setting | Value |
|---|---|
| Root Directory | `summative/API` (in this repository the project sits inside the `linear_regression_model` folder, so the value is `linear_regression_model/summative/API`) |
| Build Command | `pip install -r requirements.txt` |
| Start Command | `uvicorn prediction:app --host 0.0.0.0 --port $PORT` |
| Environment variable | `PYTHON_VERSION` = `3.12.8` |

The packages are managed with uv (`pyproject.toml` and `uv.lock` are in `summative/`). Regenerate the requirements file after changing dependencies, from `summative/`:
```
uv lock
uv export --format requirements.txt --no-hashes -o API/requirements.txt
```
`scikit-learn` is pinned to 1.6.1, the version used in Colab, because a saved model must be loaded with the version that trained it.

## Project structure
```
linear_regression_model/
  README.md
  summative/
    pyproject.toml, uv.lock           uv environment
    linear_regression/
      multivariate.ipynb              Task 1: data, four models, comparison, saved model
    API/
      prediction.py                   Task 2: FastAPI service
      requirements.txt                exported from uv, used by Render
      best_model.pkl                  saved best model (pipeline + training rows)
    FlutterApp/                       Task 3: one-page mobile app
      lib/main.dart, app.dart         start-up
      lib/screens, widgets            the page and its parts
      lib/controllers, services       state and the call to POST /predict
      lib/models, constants, utils    inputs, result, parsing, error messages
      lib/config, theme               API address, spacing
      test/                           widget and service tests
```

## Troubleshooting
| Problem | What to do |
|---|---|
| The app shows "The server returned an unexpected answer (code 404)" | The address has a `/` at the end or `/docs`. Use exactly `https://garang-buke-summative-regression-lb0z.onrender.com`. |
| The first request is very slow | The free server was asleep. Wait up to a minute and try again. |
| `/predict` returns 503 | `best_model.pkl` is missing from the `API` folder. |
| A warning or error about the scikit-learn version when loading the model | Use scikit-learn 1.6.1, as pinned in `pyproject.toml`. |
| The notebook prints a shape other than `(100852, 207)` | The dataset file is incomplete. Download and upload it again. |
