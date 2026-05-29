from datetime import date, timedelta

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from ...core.gemini import analyze_emotional_state, chat_with_gemini
from ...database import get_db
from ...models.daily_record import DailyRecord
from ...models.goal import Goal, GoalStatus
from ...models.user import User
from ...schemas.chat import ChatMessage, ChatResponse, EmotionAnalysisResponse
from ..deps import get_current_user

router = APIRouter(prefix="/chat", tags=["chat"])


def _fetch_context(db: Session, user_id: int):
    start = date.today() - timedelta(days=7)
    records = (
        db.query(DailyRecord)
        .filter(DailyRecord.user_id == user_id, DailyRecord.record_date >= start)
        .order_by(DailyRecord.record_date.desc())
        .all()
    )
    goals = (
        db.query(Goal)
        .filter(Goal.user_id == user_id, Goal.status == GoalStatus.active)
        .all()
    )

    records_dict = [
        {
            "record_date": str(r.record_date),
            "mood_score": r.mood_score,
            "emotion_tags": r.emotion_tags or [],
            "behaviors": r.behaviors or [],
            "note": r.note,
        }
        for r in records
    ]
    goals_dict = [
        {"title": g.title, "category": g.category, "description": g.description}
        for g in goals
    ]
    return records_dict, goals_dict


@router.post("/message", response_model=ChatResponse)
async def chat(
    payload: ChatMessage,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    """친구 페르소나의 Gemini와 대화. 최근 7일 기록 + 활성 목표를 자동 컨텍스트로 주입."""
    records_dict: list = []
    goals_dict: list = []
    if payload.include_recent_context:
        records_dict, goals_dict = _fetch_context(db, user.id)

    reply = await chat_with_gemini(payload.message, records_dict, goals_dict)
    return ChatResponse(
        reply=reply,
        context_used=payload.include_recent_context and bool(records_dict or goals_dict),
    )


@router.get("/analyze", response_model=EmotionAnalysisResponse)
async def analyze(
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    """최근 7일 기록을 Gemini로 분석. 요약/통찰/제안 JSON 반환."""
    records_dict, _ = _fetch_context(db, user.id)
    result = await analyze_emotional_state(records_dict)
    return EmotionAnalysisResponse(**result)
