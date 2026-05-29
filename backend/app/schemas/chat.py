from typing import List, Optional

from pydantic import BaseModel, Field


class ChatMessage(BaseModel):
    message: str = Field(..., min_length=1, max_length=2000)
    include_recent_context: bool = Field(
        True, description="최근 7일 감정 기록 + 활성 목표를 컨텍스트로 주입할지"
    )


class ChatResponse(BaseModel):
    reply: str
    context_used: bool


class EmotionAnalysisResponse(BaseModel):
    summary: str
    insights: List[str] = []
    suggestions: List[str] = []
