"""
Quiz API endpoints for MAB Quiz app
"""
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession
import json

from ..db import get_session
from ..models.question import Question

# Main router
router = APIRouter(prefix="/api/v1", tags=["quiz"])

# Auth router temporarily disabled for deployment fix
# try:
#     from .auth import router as auth_router
#     router.include_router(auth_router, prefix="")  # auth already has /auth prefix
# except ImportError:
#     print("Auth router not found, skipping...")

@router.get("/health")
async def health_check():
    """Sağlık kontrolü endpoint'i"""
    return {"status": "healthy", "service": "mab-quiz-api"}

@router.get("/questions")
async def get_questions(
    subject: Optional[str] = Query(None, description="Ders konusu (farmakoloji, terminoloji)"),
    difficulty: Optional[str] = Query(None, description="Zorluk seviyesi (easy, medium, hard)"),
    question_type: Optional[str] = Query(None, description="Soru tipi (multiple_choice, true_false, etc.)"),
    limit: int = Query(10, ge=1, le=50, description="Maksimum soru sayısı"),
    session: AsyncSession = Depends(get_session),
):
    """Filtrelere göre sorular getir"""
    try:
        stmt = select(Question)
        
        if subject:
            stmt = stmt.where(Question.subject == subject)
        if difficulty:
            stmt = stmt.where(Question.difficulty == difficulty)
        if question_type:
            stmt = stmt.where(Question.type == question_type)
            
        stmt = stmt.limit(limit)
        
        result = await session.execute(stmt)
        questions = result.scalars().all()
        
        return {
            "questions": [
                {
                    "id": q.question_id,
                    "subject": q.subject,
                    "difficulty": q.difficulty,
                    "type": q.type,
                    "text": q.text,
                    "options": json.loads(q.options_json) if q.options_json else {},
                }
                for q in questions
            ],
            "count": len(questions)
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Sorular alınırken hata: {str(e)}")

@router.get("/subjects")
async def get_subjects(session: AsyncSession = Depends(get_session)):
    """Mevcut ders konularını getir"""
    try:
        stmt = select(Question.subject).distinct()
        result = await session.execute(stmt)
        subjects = result.scalars().all()
        return {"subjects": list(subjects)}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Konular alınırken hata: {str(e)}")

@router.get("/stats")
async def get_quiz_stats(session: AsyncSession = Depends(get_session)):
    """Quiz istatistiklerini getir"""
    try:
        # Toplam soru sayısı
        total_stmt = select(func.count(Question.id))
        total_result = await session.execute(total_stmt)
        total_questions = total_result.scalar()
        
        # Konulara göre dağılım
        subject_stmt = select(Question.subject, func.count(Question.id)).group_by(Question.subject)
        subject_result = await session.execute(subject_stmt)
        subject_distribution = {subject: count for subject, count in subject_result.fetchall()}
        
        # Zorluk seviyelerine göre dağılım
        difficulty_stmt = select(Question.difficulty, func.count(Question.id)).group_by(Question.difficulty)
        difficulty_result = await session.execute(difficulty_stmt)
        difficulty_distribution = {diff: count for diff, count in difficulty_result.fetchall()}
        
        return {
            "total_questions": total_questions,
            "subjects": subject_distribution,
            "difficulties": difficulty_distribution
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"İstatistikler alınırken hata: {str(e)}")
