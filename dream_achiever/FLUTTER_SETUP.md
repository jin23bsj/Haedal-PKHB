# Flutter 담당자용 — 백엔드 셋업 가이드

이 백엔드를 본인 노트북에서 직접 돌리고, 플러터 앱으로 호출하는 방법.

## 1. 사전 준비

- **Python 3.10 이상** 설치되어 있어야 함  
  확인: `python3 --version`  
  없으면: https://www.python.org/downloads/

- **Gemini API 키** 발급 (무료, 1분이면 됨)  
  https://aistudio.google.com/apikey → Create API key → 복사

## 2. 코드 받기

### GitHub인 경우
```bash
git clone <백엔드_repo_링크>
cd dream-achiever-backend
```

### Zip인 경우
압축 풀고 폴더로 이동
```bash
cd ~/Downloads/dream_achiever
```

## 3. 환경 셋업 (한 번만)

```bash
# 가상환경 만들기
python3 -m venv .venv
source .venv/bin/activate          # 윈도우: .venv\Scripts\activate

# 라이브러리 설치
pip install --upgrade pip
pip install -r requirements.txt

# 환경변수 파일 만들기
cp .env.example .env
```

`.env` 파일 열어서 두 줄만 채우기:
```
SECRET_KEY=아무거나_긴_랜덤_문자열
GEMINI_API_KEY=발급받은_키_붙여넣기
```

## 4. 테스트 데이터 만들기

```bash
python seed.py
```

테스트 계정 자동 생성:
- 이메일: `test@example.com`
- 비번: `test1234`
- 목표 3개 + 최근 30일치 기록

## 5. 서버 켜기

```bash
python run.py
```

`Uvicorn running on http://0.0.0.0:8000` 메시지 뜨면 성공.

이 터미널 창은 그대로 놔두기 (서버 실행 창).

## 6. API 문서 확인

브라우저로 → http://localhost:8000/docs

Swagger UI에서 모든 엔드포인트 클릭해서 바로 테스트 가능.

---

## 플러터에서 호출할 때 주소

| 환경 | Base URL |
|---|---|
| iOS 시뮬레이터 | `http://localhost:8000` |
| **Android 에뮬레이터** | `http://10.0.2.2:8000` ⚠️ |
| 실제 폰 (같은 와이파이) | `http://<노트북IP>:8000` |

> Android 에뮬레이터는 `localhost`가 에뮬레이터 자기 자신을 가리켜서 안 됨. `10.0.2.2`가 호스트 PC를 의미하는 특수 주소야.

## 인증 흐름

1. `POST /api/v1/auth/login` (form-data: username=이메일, password=비번)
2. 응답에서 `access_token` 받기
3. 이후 모든 요청 헤더에: `Authorization: Bearer <토큰>`

## Dio 예시 코드

```dart
import 'package:dio/dio.dart';

class ApiClient {
  late final Dio dio;
  String? _token;

  ApiClient() {
    dio = Dio(BaseOptions(
      baseUrl: 'http://10.0.2.2:8000',  // Android 에뮬레이터 기준
      connectTimeout: const Duration(seconds: 10),
    ));

    // 모든 요청에 자동으로 토큰 부착
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_token != null) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        return handler.next(options);
      },
    ));
  }

  Future<void> login(String email, String password) async {
    final res = await dio.post(
      '/api/v1/auth/login',
      data: {'username': email, 'password': password},
      options: Options(contentType: 'application/x-www-form-urlencoded'),
    );
    _token = res.data['access_token'];
  }

  Future<List<dynamic>> getGoals() async {
    final res = await dio.get('/api/v1/goals');
    return res.data;
  }

  Future<Map<String, dynamic>> getGrowthSummary() async {
    final res = await dio.get('/api/v1/analysis/growth');
    return res.data;
  }

  Future<String> chatMessage(String message) async {
    final res = await dio.post('/api/v1/chat/message', data: {
      'message': message,
      'include_recent_context': true,
    });
    return res.data['reply'];
  }
}
```

## 다음에 다시 서버 켤 때

```bash
cd dream-achiever-backend
source .venv/bin/activate
python run.py
```

## 자주 막히는 부분

| 증상 | 해결 |
|---|---|
| `command not found: python3` | Python 설치 안 됨 |
| `(.venv)` 안 보임 | `source .venv/bin/activate` 다시 |
| `pydantic-core` 빌드 에러 | `pip install --upgrade pip` 먼저, 그 다음 재시도 |
| `passlib` / `bcrypt` 에러 | 백엔드 담당자한테 최신 `security.py` 받기 |
| Android 에뮬레이터에서 연결 안 됨 | `localhost` 말고 `10.0.2.2` 써야 함 |
| 실제 폰에서 연결 안 됨 | 같은 와이파이인지 확인, 노트북 방화벽 끄기 |
| 401 Unauthorized | 토큰 만료 또는 누락. 로그인 다시 |
| Gemini 응답이 "키 미설정" | `.env`에 `GEMINI_API_KEY` 채우고 서버 재시작 |

## 주요 엔드포인트 요약

| Method | Path | 용도 |
|---|---|---|
| POST | `/api/v1/auth/register` | 회원가입 |
| POST | `/api/v1/auth/login` | 로그인 (토큰 발급) |
| GET | `/api/v1/auth/me` | 내 정보 |
| GET/POST/PATCH/DELETE | `/api/v1/goals` | 목표 CRUD |
| GET/POST/PATCH/DELETE | `/api/v1/records` | 일일 기록 CRUD |
| GET | `/api/v1/analysis/growth` | 누적 통계 (대시보드용) |
| GET | `/api/v1/analysis/emotions/timeline?days=30` | 감정 시계열 (그래프용) |
| GET | `/api/v1/analysis/comparison?period_days=7` | 기간 비교 (인사이트 포함) |
| GET | `/api/v1/analysis/goals/{id}/progress` | 목표별 진행 시계열 |
| POST | `/api/v1/chat/message` | Gemini 챗봇 (위로/대화) |
| GET | `/api/v1/chat/analyze` | 최근 7일 감정 분석 |

상세 스펙은 `/docs`에서 확인.
