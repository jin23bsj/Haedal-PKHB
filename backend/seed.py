"""테스트 계정 + 더미 데이터 시딩 스크립트.

실행: python seed.py
계정: test@example.com / test1234
"""

from datetime import date, timedelta
import random

from app.core.security import hash_password
from app.database import Base, SessionLocal, engine
from app.models.daily_record import DailyRecord
from app.models.goal import Goal, GoalStatus
from app.models.user import User

Base.metadata.create_all(bind=engine)

EMOTION_POOL = ["기쁨", "불안", "평온", "설렘", "피곤", "뿌듯", "외로움", "답답함", "감사", "집중"]
BEHAVIOR_POOL = ["운동 30분", "독서 1시간", "산책", "명상 10분", "공부 2시간", "친구 만남", "충분한 수면", "건강식"]


def seed():
    db = SessionLocal()
    try:
        # 기존 테스트 계정이 있으면 삭제
        existing = db.query(User).filter(User.email == "test@example.com").first()
        if existing:
            db.delete(existing)
            db.commit()

        user = User(
            email="test@example.com",
            nickname="테스터",
            password_hash=hash_password("test1234"),
        )
        db.add(user)
        db.commit()
        db.refresh(user)
        print(f"[+] 유저 생성: {user.email} (id={user.id})")

        goals = [
            Goal(user_id=user.id, title="6개월 내 토익 900점", category="학업",
                 target_date=date.today() + timedelta(days=180)),
            Goal(user_id=user.id, title="매일 운동 습관 만들기", category="건강",
                 target_date=date.today() + timedelta(days=90)),
            Goal(user_id=user.id, title="개인 프로젝트 출시", category="커리어",
                 target_date=date.today() + timedelta(days=120)),
        ]
        db.add_all(goals)
        db.commit()
        for g in goals:
            db.refresh(g)
            print(f"[+] 목표 생성: {g.title}")

        goal_ids = [g.id for g in goals]

        # 최근 30일치 기록 랜덤 생성
        random.seed(42)
        for i in range(30):
            d = date.today() - timedelta(days=i)
            record = DailyRecord(
                user_id=user.id,
                record_date=d,
                mood_score=random.randint(4, 9),
                emotion_tags=random.sample(EMOTION_POOL, k=random.randint(1, 3)),
                behaviors=random.sample(BEHAVIOR_POOL, k=random.randint(1, 4)),
                note=f"{d.month}월 {d.day}일의 메모",
                related_goal_ids=random.sample(goal_ids, k=random.randint(1, len(goal_ids))),
                achievement_score=round(random.uniform(30, 95), 1),
            )
            db.add(record)
        db.commit()
        print(f"[+] 최근 30일 기록 생성 완료")

        print("\n✅ 시딩 완료!")
        print("   로그인: test@example.com / test1234")
    finally:
        db.close()


if __name__ == "__main__":
    seed()
