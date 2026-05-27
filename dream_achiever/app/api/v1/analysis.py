from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from ...database import get_db
from ...models.user import User
from ...schemas.analysis import (
    ComparisonResponse,
    EmotionTimelineResponse,
    GoalProgressResponse,
    GrowthSummaryResponse,
)
from ...services import analysis_service
from ..deps import get_current_user

router = APIRouter(prefix="/analysis", tags=["analysis"])


@router.get("/goals/{goal_id}/progress", response_model=GoalProgressResponse)
def goal_progress(
    goal_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    """특정 목표의 진행 시계열. 플러터에서 라인차트 그리기 좋음."""
    result = analysis_service.get_goal_progress(db, user.id, goal_id)
    if not result:
        raise HTTPException(status_code=404, detail="목표를 찾을 수 없어요")
    return result


@router.get("/emotions/timeline", response_model=EmotionTimelineResponse)
def emotion_timeline(
    days: int = Query(30, ge=7, le=365, description="조회 기간(일)"),
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    """감정 점수 시계열 + 가장 많이 쓴 감정 태그 Top 10."""
    return analysis_service.get_emotion_timeline(db, user.id, days)


@router.get("/comparison", response_model=ComparisonResponse)
def comparison(
    period_days: int = Query(7, ge=1, le=90, description="비교 단위 기간(일)"),
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    """현재 기간 vs 직전 동일 기간 비교 + 자동 인사이트 텍스트."""
    return analysis_service.compare_periods(db, user.id, period_days)


@router.get("/growth", response_model=GrowthSummaryResponse)
def growth(
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    """전체 성장 요약. 연속 기록일, 완료 목표 수, 자주 한 행동 Top 5 등."""
    return analysis_service.get_growth_summary(db, user.id)
