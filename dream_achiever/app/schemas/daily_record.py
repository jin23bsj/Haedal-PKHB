from datetime import date, datetime
from typing import List, Optional

from pydantic import BaseModel, Field


class DailyRecordBase(BaseModel):
    record_date: date
    mood_score: int = Field(..., ge=1, le=10, description="기분 점수 1~10")
    emotion_tags: List[str] = Field(default_factory=list, description="예: ['기쁨','불안']")
    behaviors: List[str] = Field(default_factory=list, description="예: ['운동 30분','독서']")
    note: Optional[str] = None
    related_goal_ids: List[int] = Field(default_factory=list, description="이 기록과 연결된 목표 id 목록")
    achievement_score: Optional[float] = Field(None, ge=0, le=100, description="오늘의 목표 진행도 자가평가 0~100")


class DailyRecordCreate(DailyRecordBase):
    pass


class DailyRecordUpdate(BaseModel):
    mood_score: Optional[int] = Field(None, ge=1, le=10)
    emotion_tags: Optional[List[str]] = None
    behaviors: Optional[List[str]] = None
    note: Optional[str] = None
    related_goal_ids: Optional[List[int]] = None
    achievement_score: Optional[float] = Field(None, ge=0, le=100)


class DailyRecordResponse(DailyRecordBase):
    id: int
    user_id: int
    created_at: datetime

    class Config:
        from_attributes = True
