# Dream Achiever — Backend

미래의 목표를 향한 오늘의 기록을 돕는 앱의 백엔드. FastAPI 기반.

## 핵심 기능

- ✅ 미래 목표 작성·관리 (Goal CRUD)
- ✅ 오늘의 감정/행동 기록 (DailyRecord CRUD)
- ✅ 과거 vs 현재 비교 분석 (기간 비교 + 자동 인사이트)
- ✅ 목표 달성률 시각화용 시계열 데이터 제공
- ✅ Gemini API 친구 챗봇 — 최근 7일 기록을 컨텍스트로 자동 주입
- ✅ 성장 요약 (연속 기록일 streak, 자주 한 행동 등)

## 스택

- **FastAPI** — 비동기 + 자동 OpenAPI 문서
- **SQLAlchemy 2.0** — ORM
- **SQLite** (dev) / Postgres (prod 권장)
- **JWT** — `python-jose` + bcrypt
- **Gemini** — `google-generativeai` (model: `gemini-1.5-flash`)

## 시작하기

```bash
# 1. 가상환경 + 의존성
python -m venv .venv
source .venv/bin/activate   # Windows는 .venv\Scripts\activate
pip install -r requirements.txt

# 2. 환경변수 설정
cp .env.example .env
# .env 에서 GEMINI_API_KEY, SECRET_KEY 채우기

# 3. (선택) 시드 데이터 생성
python seed.py
# 테스트 계정: test@example.com / test1234

# 4. 개발 서버 실행
python run.py
# 또는: uvicorn app.main:app --reload
```

- API 문서: http://localhost:8000/docs (Swagger)
- ReDoc: http://localhost:8000/redoc

## 폴더 구조

```
dream_achiever/
├── app/
│   ├── main.py              # FastAPI 진입점
│   ├── config.py            # 환경설정
│   ├── database.py          # SQLAlchemy 엔진/세션
│   ├── models/              # ORM 모델 (User, Goal, DailyRecord)
│   ├── schemas/             # Pydantic 스키마 (요청/응답)
│   ├── core/
│   │   ├── security.py      # JWT, bcrypt
│   │   └── gemini.py        # Gemini API 통합
│   ├── services/
│   │   └── analysis_service.py   # 분석/시각화 비즈니스 로직
│   └── api/
│       ├── deps.py          # get_current_user
│       └── v1/              # 라우터 (auth, goals, records, analysis, chat)
├── run.py                   # 개발 서버 실행
├── seed.py                  # 더미 데이터 생성
├── requirements.txt
└── .env.example
```

## API 엔드포인트 요약 (플러터용 치트시트)

모든 보호된 엔드포인트는 `Authorization: Bearer <token>` 헤더 필요.

### 🔐 Auth
| Method | Path | Body | 비고 |
|---|---|---|---|
| POST | `/api/v1/auth/register` | `{email, nickname, password}` | 회원가입 + 토큰 반환 |
| POST | `/api/v1/auth/login` | form: `username`(=email), `password` | OAuth2 표준 form |
| GET | `/api/v1/auth/me` | — | 내 정보 |

### 🎯 Goals
| Method | Path | 설명 |
|---|---|---|
| POST | `/api/v1/goals` | 목표 생성 (title, description, category, target_date) |
| GET | `/api/v1/goals?status=active` | 내 목표 목록 |
| GET | `/api/v1/goals/{id}` | 단건 조회 |
| PATCH | `/api/v1/goals/{id}` | 부분 수정 (status 변경으로 완료 처리도 여기서) |
| DELETE | `/api/v1/goals/{id}` | 삭제 |

### 📝 Daily Records
| Method | Path | 설명 |
|---|---|---|
| POST | `/api/v1/records` | 오늘 기록 (record_date, mood_score 1~10, emotion_tags[], behaviors[], related_goal_ids[], achievement_score 0~100) |
| GET | `/api/v1/records?start_date=&end_date=&limit=30` | 기간 조회 |
| GET | `/api/v1/records/by-date/{YYYY-MM-DD}` | 특정 날짜 조회 |
| PATCH | `/api/v1/records/{id}` | 수정 |
| DELETE | `/api/v1/records/{id}` | 삭제 |

> 같은 날짜에 두 개 못 만들게 unique constraint 걸려있음. 같은 날 다시 적으려면 PATCH.

### 📊 Analysis (그래프용)
| Method | Path | 응답 핵심 |
|---|---|---|
| GET | `/api/v1/analysis/goals/{id}/progress` | `timeline[]` 시계열 → 라인차트 |
| GET | `/api/v1/analysis/emotions/timeline?days=30` | 감정 시계열 + 태그 Top10 |
| GET | `/api/v1/analysis/comparison?period_days=7` | 현재 N일 vs 직전 N일 + 자동 인사이트 |
| GET | `/api/v1/analysis/growth` | 누적 통계 + streak |

### 💬 Chat (Gemini)
| Method | Path | 설명 |
|---|---|---|
| POST | `/api/v1/chat/message` | `{message, include_recent_context}` → 친구 페르소나 답변 |
| GET | `/api/v1/chat/analyze` | 최근 7일 분석 (summary, insights, suggestions) |

## 데이터 흐름 예시

1. 사용자가 회원가입 → 토큰 받음
2. 미래 목표 등록 (`POST /goals`)
3. 매일 `POST /records`로 오늘 기록 (어느 목표와 관련 있는지 `related_goal_ids`에 담기)
4. 플러터에서 그래프:
   - 특정 목표 진행도 → `/analysis/goals/{id}/progress`
   - 감정 추이 → `/analysis/emotions/timeline`
   - "지난주보다 어땠지?" → `/analysis/comparison`
5. 위로 받고 싶을 때 → `/chat/message` (자동으로 최근 기록 + 목표가 컨텍스트로 들어감)

## 운영 체크리스트

- [ ] `SECRET_KEY`를 충분히 긴 랜덤 문자열로 교체 (`openssl rand -hex 32`)
- [ ] `DATABASE_URL`을 Postgres로 변경
- [ ] `CORS_ORIGINS`를 실제 도메인으로 한정 (`["*"]` 금지)
- [ ] `Base.metadata.create_all` 제거하고 Alembic 마이그레이션으로 전환
- [ ] HTTPS 종단 (nginx/CloudFront 앞단)
- [ ] Gemini 호출 실패 시 재시도/타임아웃 보강
- [ ] 로깅 (structlog 등) 추가
