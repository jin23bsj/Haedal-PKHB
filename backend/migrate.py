"""
DB 마이그레이션 스크립트
- 기존 데이터를 유지하면서 새 컬럼만 추가
- 서버 실행 전에 자동으로 호출됨
"""
import sqlite3
import os

DB_PATH = os.path.join(os.path.dirname(__file__), "dream_achiever.db")


def column_exists(cursor, table, column):
    cursor.execute(f"PRAGMA table_info({table})")
    return any(row[1] == column for row in cursor.fetchall())


def migrate():
    if not os.path.exists(DB_PATH):
        print("[migrate] DB 없음 → 새로 생성됩니다.")
        return

    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()

    migrations = [
        # (테이블명, 컬럼명, 타입 + 기본값)
        ("goals", "achievement_rate", "REAL NOT NULL DEFAULT 0.0"),
        ("daily_records", "future_message", "TEXT"),
        ("daily_records", "goal_progress_memos", "JSON DEFAULT '{}'"),
        ("daily_records", "goal_rates", "JSON DEFAULT '{}'"),
    ]

    for table, column, definition in migrations:
        try:
            cursor.execute(f"SELECT name FROM sqlite_master WHERE type='table' AND name='{table}'")
            if not cursor.fetchone():
                continue  # 테이블 자체가 없으면 스킵 (create_all이 만들어줌)

            if not column_exists(cursor, table, column):
                cursor.execute(f"ALTER TABLE {table} ADD COLUMN {column} {definition}")
                print(f"[migrate] {table}.{column} 컬럼 추가 완료")
            else:
                print(f"[migrate] {table}.{column} 이미 존재 → 스킵")
        except Exception as e:
            print(f"[migrate] {table}.{column} 오류: {e}")

    conn.commit()
    conn.close()
    print("[migrate] 마이그레이션 완료 ✅")


if __name__ == "__main__":
    migrate()
