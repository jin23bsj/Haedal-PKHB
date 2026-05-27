from fastapi import APIRouter

from . import analysis, auth, chat, goals, records

api_router = APIRouter(prefix="/api/v1")
api_router.include_router(auth.router)
api_router.include_router(goals.router)
api_router.include_router(records.router)
api_router.include_router(analysis.router)
api_router.include_router(chat.router)
