from datetime import date
from typing import Dict, List, Optional

from pydantic import BaseModel


class GoalProgressPoint(BaseModel):
    date: date
    achievement_score: float
    mood_score: int


class GoalProgressResponse(BaseModel):
    goal_id: int
    goal_title: str
    current_progress: float           # 평균 진행률 (0~100)
    timeline: List[GoalProgressPoint] # 그래프용 시계열
    days_tracked: int
    days_remaining: Optional[int] = None


class EmotionPoint(BaseModel):
    date: date
    mood_score: int
    emotion_tags: List[str]


class EmotionTagCount(BaseModel):
    tag: str
    count: int


class EmotionTimelineResponse(BaseModel):
    timeline: List[EmotionPoint]
    avg_mood: float
    most_common_emotions: List[EmotionTagCount]


class BehaviorCount(BaseModel):
    behavior: str
    count: int


class PeriodSummary(BaseModel):
    start_date: Optional[date] = None
    end_date: Optional[date] = None
    avg_mood: float
    avg_achievement: float
    record_count: int
    behaviors: List[BehaviorCount]


class ComparisonResponse(BaseModel):
    current_period: PeriodSummary
    past_period: PeriodSummary
    mood_change: float
    achievement_change: float
    insights: List[str]


class GrowthSummaryResponse(BaseModel):
    total_records: int
    total_goals: int
    completed_goals: int
    avg_mood: float
    avg_achievement: float
    streak_days: int
    most_common_behaviors: List[BehaviorCount]
