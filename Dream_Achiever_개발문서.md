# 🌟 Dream Achiever 개발 문서

> 미래의 목표를 향한 오늘의 기록 — 목표 관리 & 감정 기록 앱

---

## 📌 프로젝트 개요

| 항목 | 내용 |
|------|------|
| 프로젝트명 | Dream Achiever |
| 유형 | 동아리 아이디어톤 |
| 플랫폼 | Flutter (Web/Android) |
| 백엔드 | FastAPI + SQLite |
| AI | Google Gemini API |

---

## 🏗️ 전체 아키텍처

```
[Flutter 앱]
    ↓ HTTP (Dio)
[FastAPI 백엔드] → [SQLite DB]
    ↓
[Gemini API] (챗봇 & 감정 분석)
```

- 백엔드는 로컬(localhost:8000)에서 실행
- Flutter는 Chrome(웹) 또는 Android 에뮬레이터로 실행
- 백엔드 없어도 Mock 데이터로 앱 동작 가능

---

## 🐍 백엔드 (FastAPI + Python)

### 기술 스택

| 라이브러리 | 용도 |
|-----------|------|
| FastAPI | REST API 프레임워크 |
| SQLAlchemy | ORM (DB 모델 관리) |
| SQLite | 로컬 데이터베이스 |
| Pydantic | 요청/응답 데이터 검증 |
| python-jose | JWT 토큰 생성/검증 |
| bcrypt | 비밀번호 해싱 |
| google-generativeai | Gemini AI 연동 |
| uvicorn | ASGI 서버 |

### 폴더 구조

```
backend/
├── app/
│   ├── api/v1/
│   │   ├── auth.py       # 회원가입, 로그인, 토큰 발급
│   │   ├── goals.py      # 목표 CRUD
│   │   ├── records.py    # 일일 기록 저장/조회
│   │   ├── chat.py       # Gemini 챗봇
│   │   └── analysis.py   # 성장 요약, 기간 비교
│   ├── core/
│   │   ├── gemini.py     # Gemini AI 통합
│   │   └── security.py   # JWT 인증
│   ├── models/           # DB 테이블 정의
│   ├── schemas/          # 요청/응답 형식 정의
│   ├── database.py       # DB 연결 설정
│   └── main.py           # FastAPI 앱 진입점
├── requirements.txt
├── run.py
└── .env                  # API 키 (깃허브 미포함)
```

### API 엔드포인트

| Method | 경로 | 기능 |
|--------|------|------|
| POST | /api/v1/auth/register | 회원가입 |
| POST | /api/v1/auth/login | 로그인 (JWT 발급) |
| GET | /api/v1/auth/me | 내 정보 조회 |
| GET | /api/v1/goals | 목표 목록 조회 |
| POST | /api/v1/goals | 목표 생성 |
| PATCH | /api/v1/goals/{id} | 목표 수정 (달성률 포함) |
| DELETE | /api/v1/goals/{id} | 목표 삭제 |
| GET | /api/v1/records | 기록 목록 조회 |
| POST | /api/v1/records | 기록 생성 |
| PATCH | /api/v1/records/{id} | 기록 수정 |
| GET | /api/v1/records/by-date/{date} | 날짜별 기록 조회 |
| POST | /api/v1/chat/message | Gemini 챗봇 메시지 |
| GET | /api/v1/analysis/growth | 성장 요약 (streak 등) |
| GET | /api/v1/analysis/comparison | 기간별 감정 비교 |

### DB 모델

**Goal (목표)**
- id, user_id, title, description, category
- target_date, status (active/completed/abandoned)
- achievement_rate (0.0~1.0)
- created_at, updated_at

**DailyRecord (일일 기록)**
- id, user_id, record_date
- mood_score (1~10), emotion_tags (JSON)
- behaviors (JSON), note
- related_goal_ids (JSON)
- goal_progress_memos (JSON)
- achievement_score, future_message
- created_at

### Gemini AI 활용

1. **챗봇 대화** (`chat_with_gemini`)
   - 사용자 메시지 + 최근 7일 기록 + 진행 중인 목표를 컨텍스트로 주입
   - 따뜻한 친구처럼 공감하며 대화

2. **감정 분석** (`analyze_emotional_state`)
   - 최근 기록을 분석해 감정 요약 / 통찰 / 제안 반환

### 실행 방법

```bash
cd backend
pip install -r requirements.txt
python run.py
# → http://localhost:8000 에서 실행
# → http://localhost:8000/docs 에서 API 문서 확인
```

### 환경변수 (.env)

```
DATABASE_URL=sqlite:///./dream_achiever.db
SECRET_KEY=...
GEMINI_API_KEY=...  # Google AI Studio에서 발급
GEMINI_MODEL=gemini-1.5-flash
```

---

## 📱 프론트엔드 (Flutter)

### 기술 스택

| 패키지 | 용도 |
|--------|------|
| flutter | 크로스플랫폼 UI |
| provider | 전역 상태 관리 |
| dio | HTTP 통신 |
| shared_preferences | 로컬 데이터 저장 |
| fl_chart | 차트 (막대/꺾은선) |
| intl | 날짜/숫자 포맷 |
| flutter_localizations | 한국어 로케일 |
| google_generative_ai | Gemini 연동 (패키지) |

### 폴더 구조

```
lib/
├── main.dart               # 앱 진입점 + 하단 네비게이션
├── theme/
│   └── app_theme.dart      # 색상 & 디자인 테마
├── models/
│   ├── goal.dart           # 목표 데이터 모델
│   ├── daily_record.dart   # 일일 기록 모델
│   └── goal_rate_entry.dart # 달성률 변화 기록 모델
├── services/
│   ├── api_service.dart    # HTTP 클라이언트 & 자동 로그인
│   ├── goal_service.dart   # 목표 API 호출
│   ├── record_service.dart # 기록 API 호출
│   ├── chat_service.dart   # 챗봇 API 호출
│   └── auth_service.dart   # 인증 서비스
├── providers/
│   ├── goal_provider.dart  # 목표 전역 상태
│   └── record_provider.dart # 기록 전역 상태
└── screens/
    ├── home_screen.dart        # 홈
    ├── goal_list_screen.dart   # 목표 목록
    ├── goal_form_screen.dart   # 목표 추가/수정 폼
    ├── goal_detail_screen.dart # 목표 상세 (달성률 히스토리)
    ├── record_screen.dart      # 기록 입력/수정
    ├── analysis_screen.dart    # 성장 분석
    └── chat_screen.dart        # AI 챗봇
```

### 화면 구성 (5개 탭)

#### 🏠 홈 탭
- 연속 기록 streak 카드 (실시간 계산)
- 오늘 기록 여부 표시 + 수정하기 버튼
- 진행 중인 목표 달성률 Top 3
- 최근 7일 감정 흐름
- 📅 달력 버튼 → 날짜 선택 → 해당 날 기록 팝업

#### 🎯 목표 탭
- 진행중 / 완료 탭 분리
- 목표 카드 탭 → 상세 화면 이동
- 달성률 100% 달성 시 자동으로 완료 탭 이동
- 목표 추가/수정/삭제

#### ✏️ 기록 탭
- 날짜 선택 (과거 날짜 소급 입력 가능)
- 감정 선택 (5가지: 최고/행복/보통/피곤/힘듦)
- 행동 태그 입력 (추천 + 직접 입력)
- 목표별 달성률 슬라이더 + 메모
- 한 줄 메모
- 💌 미래의 나에게 한마디

#### 📊 분석 탭
- 성장 요약 (연속 기록, 총 기록일, 자주 한 행동)
- 💌 미래 메시지 카드 (가장 최근 메시지 표시)
- 목표 달성률 막대그래프
- 🔗 목표와 연결된 기록 카드
- 감정 변화 꺾은선그래프 (14일)
- 과거 vs 현재 감정 비교

#### 💬 챗봇 탭
- Gemini AI와 자유 대화
- 최근 기록 & 목표 컨텍스트 자동 주입
- 빠른 답변 제안 칩

### 주요 구현 포인트

#### 자동 로그인
- 앱 시작 시 저장된 토큰 확인
- 없거나 만료 시 데모 계정으로 자동 로그인/가입
- 로그인 화면 없이 바로 메인으로 진입

#### Mock 데이터 Fallback
- 백엔드 연결 실패 시 자동으로 샘플 데이터 사용
- 오프라인에서도 UI 테스트 가능

#### 달성률 로컬 저장
- `achievement_rate`를 SharedPreferences에도 백업 저장
- 앱 재시작 후에도 달성률 유지

#### 달성률 히스토리
- 기록 저장 시 `GoalRateEntry` 생성
- 달성률 변화 or 메모가 있을 때만 저장
- 목표 상세 화면에서 타임라인으로 표시

#### 중복 기록 처리
- 같은 날 기록이 있으면 POST 대신 PATCH로 자동 전환

### 디자인 테마

- **Primary**: `#FF8B6A` (코랄 오렌지)
- **Background**: `#FFF6F0` (따뜻한 크림)
- **Surface**: `#FFFFFF`
- 전반적으로 따뜻한 파스텔 톤

---

## 🔐 보안

- Gemini API 키는 `.env` 파일에만 저장
- `.env`는 `.gitignore`에 등록 → GitHub에 업로드되지 않음
- 팀원은 각자 API 키를 발급받아 `.env` 직접 생성

---

## 🚀 로컬 실행 방법

### 백엔드 실행
```bash
cd backend
pip install -r requirements.txt
python run.py
```

### 프론트엔드 실행
```bash
flutter pub get
flutter run -d chrome   # Chrome으로 실행
```

> 백엔드와 Flutter를 동시에 켜놓고 사용

---

## 📦 GitHub

- 레포: https://github.com/jin23bsj/Haedal-PKHB
- `.env` 파일은 포함되지 않음 (각자 생성 필요)
- 팀원 clone 후 `flutter pub get` → `.env` 생성 → 백엔드 실행 → 앱 실행
