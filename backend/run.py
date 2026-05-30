import uvicorn
from migrate import migrate

if __name__ == "__main__":
    migrate()  # 서버 시작 전 DB 마이그레이션 (데이터 유지하며 새 컬럼만 추가)
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)
