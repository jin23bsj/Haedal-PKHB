# Dream Achiever

> **Record today toward the dreams of tomorrow** — A goal management & emotion tracking app

---

## 📱 Demo

[▶ Watch Demo Video](#)

---

## 📌 Project Overview

| Item | Details |
|------|---------|
| Project Name | Dream Achiever |
| Type | Club Ideathon |
| Platform | Flutter (Web / Android) |
| Backend | FastAPI + SQLite |
| AI | Google Gemini API |

---

## 🏗️ Architecture

```
[Flutter App]
    ↓ HTTP (Dio)
[FastAPI Backend] → [SQLite DB]
    ↓
[Gemini API] (Chatbot & Emotion Analysis)
```

- Backend runs locally at `localhost:8000`
- Flutter runs on Chrome (web) or Android Emulator
- Mock data fallback available — app works without a backend connection

---

## 🐍 Backend (FastAPI + Python)

### Tech Stack

| Library | Purpose |
|---------|---------|
| FastAPI | REST API framework |
| SQLAlchemy | ORM (DB model management) |
| SQLite | Local database |
| Pydantic | Request/response validation |
| python-jose | JWT token generation & verification |
| bcrypt | Password hashing |
| google-generativeai | Gemini AI integration |
| uvicorn | ASGI server |

### Folder Structure

```
backend/
├── app/
│   ├── api/v1/
│   │   ├── auth.py       # Register, login, token issuance
│   │   ├── goals.py      # Goal CRUD
│   │   ├── records.py    # Daily record save/retrieve
│   │   ├── chat.py       # Gemini chatbot
│   │   └── analysis.py   # Growth summary, period comparison
│   ├── core/
│   │   ├── gemini.py     # Gemini AI integration
│   │   └── security.py   # JWT authentication
│   ├── models/           # DB table definitions
│   ├── schemas/          # Request/response schema definitions
│   ├── database.py       # DB connection setup
│   └── main.py           # FastAPI app entry point
├── requirements.txt
├── run.py
└── .env                  # API keys (not included in GitHub)
```

### API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| POST | `/api/v1/auth/register` | Sign up |
| POST | `/api/v1/auth/login` | Log in (issues JWT) |
| GET | `/api/v1/auth/me` | Get current user info |
| GET | `/api/v1/goals` | List goals |
| POST | `/api/v1/goals` | Create goal |
| PATCH | `/api/v1/goals/{id}` | Update goal (incl. achievement rate) |
| DELETE | `/api/v1/goals/{id}` | Delete goal |
| GET | `/api/v1/records` | List records |
| POST | `/api/v1/records` | Create record |
| PATCH | `/api/v1/records/{id}` | Update record |
| GET | `/api/v1/records/by-date/{date}` | Get record by date |
| POST | `/api/v1/chat/message` | Send Gemini chatbot message |
| GET | `/api/v1/analysis/growth` | Growth summary (streak, etc.) |
| GET | `/api/v1/analysis/comparison` | Emotion comparison by period |

### DB Models

**Goal**
- `id`, `user_id`, `title`, `description`, `category`
- `target_date`, `status` (`active` / `completed` / `abandoned`)
- `achievement_rate` (0.0 ~ 1.0)
- `created_at`, `updated_at`

**DailyRecord**
- `id`, `user_id`, `record_date`
- `mood_score` (1~10), `emotion_tags` (JSON)
- `behaviors` (JSON), `note`
- `related_goal_ids` (JSON), `goal_progress_memos` (JSON)
- `achievement_score`, `future_message`
- `created_at`

### Gemini AI Usage

**Chatbot (`chat_with_gemini`)**
- Injects user message + last 7 days of records + active goals as context
- Responds like a warm, empathetic friend

**Emotion Analysis (`analyze_emotional_state`)**
- Analyzes recent records and returns an emotional summary, insights, and suggestions

### Running the Backend

```bash
cd backend
pip install -r requirements.txt
python run.py
# → Runs at http://localhost:8000
# → API docs at http://localhost:8000/docs
```

### Environment Variables (`.env`)

```env
DATABASE_URL=sqlite:///./dream_achiever.db
SECRET_KEY=...
GEMINI_API_KEY=...  # Get from Google AI Studio
GEMINI_MODEL=gemini-1.5-flash
```

---

## 📱 Frontend (Flutter)

### Tech Stack

| Package | Purpose |
|---------|---------|
| flutter | Cross-platform UI |
| provider | Global state management |
| dio | HTTP communication |
| shared_preferences | Local data storage |
| fl_chart | Charts (bar / line) |
| intl | Date/number formatting |
| flutter_localizations | Korean locale support |
| google_generative_ai | Gemini integration |

### Folder Structure

```
lib/
├── main.dart                  # App entry point + bottom navigation
├── theme/
│   └── app_theme.dart         # Colors & design theme
├── models/
│   ├── goal.dart              # Goal data model
│   ├── daily_record.dart      # Daily record model
│   └── goal_rate_entry.dart   # Achievement rate history model
├── services/
│   ├── api_service.dart       # HTTP client & auto-login
│   ├── goal_service.dart      # Goal API calls
│   ├── record_service.dart    # Record API calls
│   ├── chat_service.dart      # Chatbot API calls
│   └── auth_service.dart      # Authentication service
├── providers/
│   ├── goal_provider.dart     # Goal global state
│   └── record_provider.dart   # Record global state
└── screens/
    ├── home_screen.dart           # Home
    ├── goal_list_screen.dart      # Goal list
    ├── goal_form_screen.dart      # Add/edit goal form
    ├── goal_detail_screen.dart    # Goal detail (achievement history)
    ├── record_screen.dart         # Create/edit record
    ├── analysis_screen.dart       # Growth analysis
    └── chat_screen.dart           # AI chatbot
```

### Screen Layout (5 Tabs)

**🏠 Home Tab**
- Consecutive record streak card (real-time calculation)
- Today's record status + edit button
- Top 3 active goals by achievement rate
- Last 7 days emotion trend
- 📅 Calendar button → date picker → daily record popup

**🎯 Goals Tab**
- Separate tabs for In Progress / Completed
- Tap a goal card to view details
- Auto-moves to Completed tab when achievement rate hits 100%
- Add / edit / delete goals

**✏️ Record Tab**
- Date picker (supports backdating past records)
- Mood selection (5 options: Best / Happy / Okay / Tired / Tough)
- Behavior tag input (suggestions + custom)
- Per-goal achievement rate slider + memo
- One-line note
- 💌 Message to future self

**📊 Analysis Tab**
- Growth summary (streak, total recorded days, frequent behaviors)
- 💌 Latest future message card
- Goal achievement rate bar chart
- Records linked to goals
- Emotion trend line chart (14 days)
- Past vs. present emotion comparison

**💬 Chatbot Tab**
- Free conversation with Gemini AI
- Recent records & goals auto-injected as context
- Quick reply suggestion chips

### Key Implementation Details

**Auto Login**
- Checks saved token on app start
- If missing or expired, auto-registers and logs in with a demo account
- Goes directly to main screen — no login screen needed

**Mock Data Fallback**
- Automatically uses sample data when backend is unreachable
- Allows UI testing fully offline

**Local Achievement Rate Backup**
- `achievement_rate` is also backed up in `SharedPreferences`
- Persists across app restarts

**Achievement Rate History**
- `GoalRateEntry` is created on each record save
- Only saved when achievement rate or memo has changed
- Displayed as a timeline on the goal detail screen

**Duplicate Record Handling**
- If a record already exists for the day, automatically switches from `POST` to `PATCH`

### Design Theme

- **Primary**: `#FF8B6A` (Coral Orange)
- **Background**: `#FFF6F0` (Warm Cream)
- **Surface**: `#FFFFFF`
- Overall warm pastel tone

---

## 🔐 Security

- Gemini API key is stored only in the `.env` file
- `.env` is listed in `.gitignore` — never uploaded to GitHub
- Each team member must generate their own API key and create a `.env` file locally

---

## 🚀 Running Locally

**Start Backend**

```bash
cd backend
pip install -r requirements.txt
python run.py
```

**Start Frontend**

```bash
flutter pub get
flutter run -d chrome   # Run in Chrome
```

> Keep both the backend and Flutter running simultaneously for full functionality.

---

## 📦 GitHub

- **Repo**: [https://github.com/jin23bsj/Haedal-PKHB](https://github.com/jin23bsj/Haedal-PKHB)
- `.env` file is **not included** — each team member must create their own

**Setup steps after cloning:**
1. `flutter pub get`
2. Create `.env` in the `backend/` directory
3. Start the backend: `python run.py`
4. Start the app: `flutter run -d chrome`
