from datetime import date
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from ...database import get_db
from ...models.daily_record import DailyRecord
from ...models.user import User
from ...schemas.daily_record import (
    DailyRecordCreate,
    DailyRecordResponse,
    DailyRecordUpdate,
)
from ..deps import get_current_user

router = APIRouter(prefix="/records", tags=["records"])


@router.post("", response_model=DailyRecordResponse, status_code=201)
def create_record(
    payload: DailyRecordCreate,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    existing = (
        db.query(DailyRecord)
        .filter(DailyRecord.user_id == user.id, DailyRecord.record_date == payload.record_date)
        .first()
    )
    if existing:
        raise HTTPException(
            status_code=400,
            detail="이미 해당 날짜의 기록이 있어요. PATCH로 수정해주세요",
        )

    record = DailyRecord(user_id=user.id, **payload.model_dump())
    db.add(record)
    db.commit()
    db.refresh(record)
    return record


@router.get("", response_model=List[DailyRecordResponse])
def list_records(
    start_date: Optional[date] = Query(None),
    end_date: Optional[date] = Query(None),
    limit: int = Query(30, ge=1, le=365),
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    q = db.query(DailyRecord).filter(DailyRecord.user_id == user.id)
    if start_date:
        q = q.filter(DailyRecord.record_date >= start_date)
    if end_date:
        q = q.filter(DailyRecord.record_date <= end_date)
    return q.order_by(DailyRecord.record_date.desc()).limit(limit).all()


@router.get("/by-date/{record_date}", response_model=DailyRecordResponse)
def get_record_by_date(
    record_date: date,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    record = (
        db.query(DailyRecord)
        .filter(DailyRecord.user_id == user.id, DailyRecord.record_date == record_date)
        .first()
    )
    if not record:
        raise HTTPException(status_code=404, detail="해당 날짜의 기록이 없어요")
    return record


@router.patch("/{record_id}", response_model=DailyRecordResponse)
def update_record(
    record_id: int,
    payload: DailyRecordUpdate,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    record = (
        db.query(DailyRecord)
        .filter(DailyRecord.id == record_id, DailyRecord.user_id == user.id)
        .first()
    )
    if not record:
        raise HTTPException(status_code=404, detail="기록을 찾을 수 없어요")
    for k, v in payload.model_dump(exclude_unset=True).items():
        setattr(record, k, v)
    db.commit()
    db.refresh(record)
    return record


@router.delete("/{record_id}", status_code=204)
def delete_record(
    record_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    record = (
        db.query(DailyRecord)
        .filter(DailyRecord.id == record_id, DailyRecord.user_id == user.id)
        .first()
    )
    if not record:
        raise HTTPException(status_code=404, detail="기록을 찾을 수 없어요")
    db.delete(record)
    db.commit()
