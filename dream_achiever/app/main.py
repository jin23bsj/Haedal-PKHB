from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .api.v1 import api_router
from .config import settings
from .database import Base, engine
# 모델 등록(테이블 생성 트리거)
from .models import DailyRecord, Goal, User  # noqa: F401

# 개발 단계용 자동 테이블 생성. 운영에서는 Alembic 마이그레이션으로 교체 권장.
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Dream Achiever API",
    description="미래의 목표를 향한 오늘의 기록 — 백엔드 API",
    version="0.1.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(api_router)


@app.get("/", tags=["root"])
def root():
    return {"app": "Dream Achiever", "status": "running", "docs": "/docs"}


@app.get("/health", tags=["root"])
def health():
    return {"status": "ok"}
