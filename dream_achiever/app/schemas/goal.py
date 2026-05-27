from datetime import date, datetime
from typing import Optional

from pydantic import BaseModel, Field

from ..models.goal import GoalStatus


class GoalBase(BaseModel):
    title: str = Field(..., min_length=1, max_length=200)
    description: Optional[str] = None
    category: Optional[str] = Field(None, max_length=50)
    target_date: Optional[date] = None


class GoalCreate(GoalBase):
    pass


class GoalUpdate(BaseModel):
    title: Optional[str] = Field(None, min_length=1, max_length=200)
    description: Optional[str] = None
    category: Optional[str] = None
    target_date: Optional[date] = None
    status: Optional[GoalStatus] = None


class GoalResponse(GoalBase):
    id: int
    user_id: int
    status: GoalStatus
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
