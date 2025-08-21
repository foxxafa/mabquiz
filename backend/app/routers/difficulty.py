"""
API endpoints for difficulty calculation and metrics
"""

from fastapi import APIRouter, HTTPException, BackgroundTasks, Query, Depends
from sqlalchemy.orm import Session
from sqlalchemy import text
from typing import List, Dict, Optional
import logging
from datetime import datetime, timedelta

from ..database import get_db
from ..services.difficulty_calculator import difficulty_calculator, DifficultyMetrics
from ..models.question_metrics import QuestionMetrics, StudentResponse

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/difficulty", tags=["difficulty"])

@router.get("/calculate/{question_id}")
async def calculate_single_question_difficulty(
    question_id: str,
    days_back: int = Query(30, ge=1, le=365),
    db: Session = Depends(get_db)
):
    """Calculate difficulty for a single question"""
    try:
        metrics = await difficulty_calculator.calculate_question_difficulty(
            question_id, days_back
        )
        
        if not metrics:
            raise HTTPException(
                status_code=404, 
                detail=f"Insufficient data for question {question_id}"
            )
        
        return {
            "success": True,
            "data": metrics.__dict__,
            "computed_at": datetime.now().isoformat()
        }
        
    except Exception as e:
        logger.error(f"Error calculating difficulty: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/calculate/batch")
async def calculate_batch_difficulties(
    background_tasks: BackgroundTasks,
    question_ids: Optional[List[str]] = None,
    days_back: int = Query(30, ge=1, le=365),
    force_recalculate: bool = Query(False)
):
    """Trigger batch difficulty calculation"""
    try:
        # Run calculation in background
        background_tasks.add_task(
            _run_batch_calculation,
            question_ids,
            days_back,
            force_recalculate
        )
        
        return {
            "success": True,
            "message": "Batch difficulty calculation started",
            "estimated_questions": len(question_ids) if question_ids else "all",
            "started_at": datetime.now().isoformat()
        }
        
    except Exception as e:
        logger.error(f"Error starting batch calculation: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/metrics/{question_id}")
async def get_question_metrics(
    question_id: str,
    db: Session = Depends(get_db)
):
    """Get cached difficulty metrics for a question"""
    try:
        metrics = db.query(QuestionMetrics).filter(
            QuestionMetrics.question_id == question_id,
            QuestionMetrics.is_active == True
        ).first()
        
        if not metrics:
            raise HTTPException(
                status_code=404,
                detail=f"No metrics found for question {question_id}"
            )
        
        return {
            "success": True,
            "data": metrics.to_dict(),
            "cached": True
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error retrieving metrics: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/metrics/batch")
async def get_batch_metrics(
    question_ids: List[str] = Query(...),
    include_stale: bool = Query(False),
    max_age_days: int = Query(7, ge=1, le=30),
    db: Session = Depends(get_db)
):
    """Get difficulty metrics for multiple questions"""
    try:
        query = db.query(QuestionMetrics).filter(
            QuestionMetrics.question_id.in_(question_ids),
            QuestionMetrics.is_active == True
        )
        
        if not include_stale:
            cutoff_date = datetime.now() - timedelta(days=max_age_days)
            query = query.filter(QuestionMetrics.last_computed >= cutoff_date)
        
        metrics = query.all()
        
        results = {}
        for metric in metrics:
            results[metric.question_id] = metric.to_dict()
        
        # Identify missing metrics
        missing_questions = set(question_ids) - set(results.keys())
        
        return {
            "success": True,
            "data": results,
            "found_count": len(results),
            "missing_questions": list(missing_questions),
            "cached": True
        }
        
    except Exception as e:
        logger.error(f"Error retrieving batch metrics: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/responses/submit")
async def submit_student_response(
    response_data: dict,
    db: Session = Depends(get_db)
):
    """Submit student response for difficulty calculation"""
    try:
        # Validate required fields
        required_fields = ['user_id', 'question_id', 'is_correct', 'response_time_ms']
        for field in required_fields:
            if field not in response_data:
                raise HTTPException(
                    status_code=400,
                    detail=f"Missing required field: {field}"
                )
        
        # Create response record
        response = StudentResponse(
            user_id=response_data['user_id'],
            question_id=response_data['question_id'],
            is_correct=response_data['is_correct'],
            response_time_ms=response_data['response_time_ms'],
            user_answer=response_data.get('user_answer'),
            user_confidence=response_data.get('user_confidence'),
            session_id=response_data.get('session_id'),
            course=response_data.get('course'),
            topic=response_data.get('topic'),
            knowledge_type=response_data.get('knowledge_type')
        )
        
        db.add(response)
        db.commit()
        db.refresh(response)
        
        return {
            "success": True,
            "message": "Response submitted successfully",
            "response_id": response.id
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error submitting response: {e}")
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/stats/global")
async def get_global_difficulty_stats(
    days_back: int = Query(30, ge=1, le=365),
    db: Session = Depends(get_db)
):
    """Get global difficulty statistics"""
    try:
        cutoff_date = datetime.now() - timedelta(days=days_back)
        
        # Global stats query
        query = text("""
            SELECT 
                COUNT(DISTINCT question_id) as total_questions,
                COUNT(DISTINCT user_id) as total_users,
                COUNT(*) as total_responses,
                AVG(CASE WHEN is_correct THEN 1.0 ELSE 0.0 END) as global_success_rate,
                AVG(response_time_ms) as avg_response_time_ms,
                COUNT(DISTINCT DATE(created_at)) as active_days
            FROM student_responses 
            WHERE created_at >= :cutoff_date
        """)
        
        result = db.execute(query, {"cutoff_date": cutoff_date}).fetchone()
        
        if not result:
            raise HTTPException(status_code=404, detail="No data found")
        
        # Difficulty distribution
        difficulty_dist_query = text("""
            SELECT 
                computed_difficulty,
                COUNT(*) as count,
                AVG(global_success_rate) as avg_success_rate
            FROM question_metrics 
            WHERE is_active = TRUE
            GROUP BY computed_difficulty
        """)
        
        difficulty_dist = db.execute(difficulty_dist_query).fetchall()
        
        return {
            "success": True,
            "data": {
                "global_stats": {
                    "total_questions": result.total_questions or 0,
                    "total_users": result.total_users or 0,
                    "total_responses": result.total_responses or 0,
                    "global_success_rate": round(result.global_success_rate or 0, 3),
                    "avg_response_time_seconds": round((result.avg_response_time_ms or 0) / 1000, 1),
                    "active_days": result.active_days or 0
                },
                "difficulty_distribution": {
                    row.computed_difficulty: {
                        "count": row.count,
                        "avg_success_rate": round(row.avg_success_rate, 3)
                    }
                    for row in difficulty_dist
                },
                "period_days": days_back,
                "computed_at": datetime.now().isoformat()
            }
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting global stats: {e}")
        raise HTTPException(status_code=500, detail=str(e))

async def _run_batch_calculation(
    question_ids: Optional[List[str]],
    days_back: int,
    force_recalculate: bool
):
    """Background task for batch difficulty calculation"""
    try:
        logger.info(f"Starting batch difficulty calculation for {len(question_ids) if question_ids else 'all'} questions")
        
        results = await difficulty_calculator.batch_calculate_difficulties(
            question_ids, days_back
        )
        
        logger.info(f"Completed batch calculation for {len(results)} questions")
        
    except Exception as e:
        logger.error(f"Batch calculation failed: {e}")