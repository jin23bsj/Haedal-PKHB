from datetime import datetime

from sqlalchemy import (
    Column, Date, DateTime, Float, ForeignKey, Integer, JSON, Text, UniqueConstraint
)
from sqlalchemy.orm import relationship

from ..database import Base


class DailyRecord(Base):
    __tablename__ = "daily_records"
    __table_args__ = (
        UniqueConstraint("user_id", "record_date", name="uq_user_date"),
    )

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    record_date = Column(Date, nullable=False, index=True)
    mood_score = Column(Integer, nullable=False)              # 1~10
    emotion_tags = Column(JSON, default=list)                  # ["기쁨", "불안", ...]
    behaviors = Column(JSON, default=list)                     # ["운동 30분", "독서 1시간", ...]
    note = Column(Text, nullable=True)
    related_goal_ids = Column(JSON, default=list)              # [1, 2, 3]
    achievement_score = Column(Float, nullable=True)           # 0~100, 자가평가 진행도
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)

    user = relationship("User", back_populates="records")
