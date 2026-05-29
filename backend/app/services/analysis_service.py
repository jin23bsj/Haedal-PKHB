"""분석/시각화용 비즈니스 로직.

플러터 측에서 그래프를 그릴 수 있도록 시계열·집계 데이터를 만들어주는 곳.
"""

from collections import Counter
from datetime import date, timedelta
from typing import Dict, List, Optional

from sqlalchemy.orm import Session

from ..models.daily_record import DailyRecord
from ..models.goal import Goal, GoalStatus


def get_goal_progress(db: Session, user_id: int, goal_id: int) -> Optional[Dict]:
    goal = db.query(Goal).filter(Goal.id == goal_id, Goal.user_id == user_id).first()
    if not goal:
        return None

    records = (
        db.query(DailyRecord)
        .filter(DailyRecord.user_id == user_id)
        .order_by(DailyRecord.record_date.asc())
        .all()
    )

    timeline = []
    scores: List[float] = []
    for r in records:
        if goal_id not in (r.related_goal_ids or []):
            continue
        if r.achievement_score is None:
            continue
        timeline.append(
            {
                "date": r.record_date,
                "achievement_score": r.achievement_score,
                "mood_score": r.mood_score,
            }
        )
        scores.append(r.achievement_score)

    current_progress = round(sum(scores) / len(scores), 2) if scores else 0.0

    days_remaining: Optional[int] = None
    if goal.target_date:
        days_remaining = max((goal.target_date - date.today()).days, 0)

    return {
        "goal_id": goal.id,
        "goal_title": goal.title,
        "current_progress": current_progress,
        "timeline": timeline,
        "days_tracked": len(timeline),
        "days_remaining": days_remaining,
    }


def get_emotion_timeline(db: Session, user_id: int, days: int = 30) -> Dict:
    start = date.today() - timedelta(days=days)
    records = (
        db.query(DailyRecord)
        .filter(DailyRecord.user_id == user_id, DailyRecord.record_date >= start)
        .order_by(DailyRecord.record_date.asc())
        .all()
    )

    timeline = [
        {
            "date": r.record_date,
            "mood_score": r.mood_score,
            "emotion_tags": r.emotion_tags or [],
        }
        for r in records
    ]

    avg_mood = round(sum(r.mood_score for r in records) / len(records), 2) if records else 0.0

    all_tags: List[str] = []
    for r in records:
        all_tags.extend(r.emotion_tags or [])
    most_common = [
        {"tag": t, "count": c} for t, c in Counter(all_tags).most_common(10)
    ]

    return {
        "timeline": timeline,
        "avg_mood": avg_mood,
        "most_common_emotions": most_common,
    }


def _aggregate_period(db: Session, user_id: int, start: date, end: date) -> Dict:
    records = (
        db.query(DailyRecord)
        .filter(
            DailyRecord.user_id == user_id,
            DailyRecord.record_date >= start,
            DailyRecord.record_date <= end,
        )
        .all()
    )

    if not records:
        return {
            "start_date": start,
            "end_date": end,
            "avg_mood": 0.0,
            "avg_achievement": 0.0,
            "record_count": 0,
            "behaviors": [],
        }

    mood_avg = sum(r.mood_score for r in records) / len(records)
    ach_scores = [r.achievement_score for r in records if r.achievement_score is not None]
    ach_avg = sum(ach_scores) / len(ach_scores) if ach_scores else 0.0

    all_behaviors: List[str] = []
    for r in records:
        all_behaviors.extend(r.behaviors or [])
    behavior_counts = [
        {"behavior": b, "count": c} for b, c in Counter(all_behaviors).most_common(5)
    ]

    return {
        "start_date": start,
        "end_date": end,
        "avg_mood": round(mood_avg, 2),
        "avg_achievement": round(ach_avg, 2),
        "record_count": len(records),
        "behaviors": behavior_counts,
    }


def compare_periods(db: Session, user_id: int, period_days: int = 7) -> Dict:
    today = date.today()
    current_start = today - timedelta(days=period_days - 1)
    past_end = current_start - timedelta(days=1)
    past_start = past_end - timedelta(days=period_days - 1)

    current = _aggregate_period(db, user_id, current_start, today)
    past = _aggregate_period(db, user_id, past_start, past_end)

    mood_change = round(current["avg_mood"] - past["avg_mood"], 2)
    ach_change = round(current["avg_achievement"] - past["avg_achievement"], 2)

    insights: List[str] = []
    if past["record_count"] == 0:
        insights.append("아직 비교할 과거 데이터가 부족해요. 꾸준히 기록하면 변화가 보일 거예요.")
    else:
        if mood_change > 0.5:
            insights.append(f"지난 기간보다 기분이 {mood_change}점 좋아졌어요!")
        elif mood_change < -0.5:
            insights.append(f"지난 기간보다 기분이 {abs(mood_change)}점 떨어졌어요. 좀 쉬어가도 괜찮아요.")

        if ach_change > 5:
            insights.append(f"목표 진행률이 {ach_change}% 올랐어요. 꾸준함이 빛나고 있어요!")
        elif ach_change < -5:
            insights.append(f"목표 진행률이 {abs(ach_change)}% 떨어졌어요. 페이스 조절이 필요할 수도.")

        if not insights:
            insights.append("비슷한 흐름을 유지하고 있어요. 안정적인 페이스예요.")

    return {
        "current_period": current,
        "past_period": past,
        "mood_change": mood_change,
        "achievement_change": ach_change,
        "insights": insights,
    }


def get_growth_summary(db: Session, user_id: int) -> Dict:
    records = db.query(DailyRecord).filter(DailyRecord.user_id == user_id).all()
    goals = db.query(Goal).filter(Goal.user_id == user_id).all()

    avg_mood = round(sum(r.mood_score for r in records) / len(records), 2) if records else 0.0
    ach_scores = [r.achievement_score for r in records if r.achievement_score is not None]
    avg_ach = round(sum(ach_scores) / len(ach_scores), 2) if ach_scores else 0.0

    # streak: 오늘부터 거꾸로, 기록이 있는 날짜가 연속으로 이어진 일수
    date_set = {r.record_date for r in records}
    streak = 0
    check = date.today()
    if check not in date_set:
        check -= timedelta(days=1)  # 오늘 아직 안 적었어도 어제부터 카운트
    while check in date_set:
        streak += 1
        check -= timedelta(days=1)

    all_behaviors: List[str] = []
    for r in records:
        all_behaviors.extend(r.behaviors or [])
    common_behaviors = [
        {"behavior": b, "count": c} for b, c in Counter(all_behaviors).most_common(5)
    ]

    return {
        "total_records": len(records),
        "total_goals": len(goals),
        "completed_goals": sum(1 for g in goals if g.status == GoalStatus.completed),
        "avg_mood": avg_mood,
        "avg_achievement": avg_ach,
        "streak_days": streak,
        "most_common_behaviors": common_behaviors,
    }
