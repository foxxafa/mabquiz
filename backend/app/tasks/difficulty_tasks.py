"""
Celery tasks for background difficulty calculation
"""

import asyncio
import logging
from datetime import datetime, timedelta
from typing import List, Optional
from celery import Celery
from sqlalchemy import text

from ..services.difficulty_calculator import difficulty_calculator
from ..database import get_db
from ..models.question_metrics import QuestionMetrics

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Create Celery app
celery_app = Celery(
    "mabquiz_tasks",
    broker="redis://localhost:6379/0",  # Will be overridden by env vars
    backend="redis://localhost:6379/0"
)

# Celery configuration
celery_app.conf.update(
    task_serializer='json',
    accept_content=['json'],
    result_serializer='json',
    timezone='UTC',
    enable_utc=True,
    task_track_started=True,
    task_time_limit=30 * 60,  # 30 minutes max
    task_soft_time_limit=25 * 60,  # 25 minutes soft limit
    worker_prefetch_multiplier=1,
    task_acks_late=True,
    worker_disable_rate_limits=False,
    task_default_queue='difficulty_calculation',
)

@celery_app.task(bind=True, max_retries=3)
def calculate_all_question_difficulties(self, days_back: int = 30, force_recalculate: bool = False):
    """
    Daily task to calculate difficulties for all questions
    """
    try:
        logger.info(f"Starting daily difficulty calculation (days_back={days_back})")
        
        # Run the async calculation in sync context
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        
        try:
            results = loop.run_until_complete(
                difficulty_calculator.batch_calculate_difficulties(
                    question_ids=None,  # Calculate for all questions
                    days_back=days_back
                )
            )
            
            logger.info(f"Daily calculation completed: {len(results)} questions processed")
            
            return {
                "success": True,
                "processed_questions": len(results),
                "completed_at": datetime.now().isoformat(),
                "days_back": days_back
            }
            
        finally:
            loop.close()
            
    except Exception as e:
        logger.error(f"Daily difficulty calculation failed: {e}")
        
        # Retry with exponential backoff
        if self.request.retries < self.max_retries:
            raise self.retry(countdown=60 * (2 ** self.request.retries))
        
        return {
            "success": False,
            "error": str(e),
            "failed_at": datetime.now().isoformat()
        }

@celery_app.task(bind=True, max_retries=2)
def calculate_question_difficulties_batch(self, question_ids: List[str], days_back: int = 30):
    """
    Calculate difficulties for a specific batch of questions
    """
    try:
        logger.info(f"Processing difficulty batch: {len(question_ids)} questions")
        
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        
        try:
            results = loop.run_until_complete(
                difficulty_calculator.batch_calculate_difficulties(
                    question_ids=question_ids,
                    days_back=days_back
                )
            )
            
            successful_ids = list(results.keys())
            failed_ids = [q_id for q_id in question_ids if q_id not in successful_ids]
            
            logger.info(f"Batch completed: {len(successful_ids)} succeeded, {len(failed_ids)} failed")
            
            return {
                "success": True,
                "processed_count": len(successful_ids),
                "failed_count": len(failed_ids),
                "successful_ids": successful_ids,
                "failed_ids": failed_ids,
                "completed_at": datetime.now().isoformat()
            }
            
        finally:
            loop.close()
            
    except Exception as e:
        logger.error(f"Batch calculation failed: {e}")
        
        if self.request.retries < self.max_retries:
            raise self.retry(countdown=30 * (2 ** self.request.retries))
        
        return {
            "success": False,
            "error": str(e),
            "question_ids": question_ids,
            "failed_at": datetime.now().isoformat()
        }

@celery_app.task(bind=True)
def cleanup_old_metrics(self, days_to_keep: int = 90):
    """
    Cleanup task to remove old difficulty metrics
    """
    try:
        logger.info(f"Starting cleanup of metrics older than {days_to_keep} days")
        
        cutoff_date = datetime.now() - timedelta(days=days_to_keep)
        
        db = next(get_db())
        try:
            # Soft delete old metrics
            result = db.execute(text("""
                UPDATE question_metrics 
                SET is_active = FALSE, updated_at = NOW()
                WHERE last_computed < :cutoff_date AND is_active = TRUE
            """), {"cutoff_date": cutoff_date})
            
            db.commit()
            
            deactivated_count = result.rowcount
            logger.info(f"Cleanup completed: {deactivated_count} metrics deactivated")
            
            return {
                "success": True,
                "deactivated_count": deactivated_count,
                "cutoff_date": cutoff_date.isoformat(),
                "completed_at": datetime.now().isoformat()
            }
            
        finally:
            db.close()
            
    except Exception as e:
        logger.error(f"Cleanup task failed: {e}")
        return {
            "success": False,
            "error": str(e),
            "failed_at": datetime.now().isoformat()
        }

@celery_app.task(bind=True)
def generate_difficulty_report(self, days_back: int = 7):
    """
    Generate weekly difficulty analysis report
    """
    try:
        logger.info(f"Generating difficulty report for last {days_back} days")
        
        db = next(get_db())
        try:
            cutoff_date = datetime.now() - timedelta(days=days_back)
            
            # Get metrics summary
            summary_query = text("""
                SELECT 
                    COUNT(*) as total_questions,
                    AVG(global_success_rate) as avg_success_rate,
                    AVG(difficulty_score) as avg_difficulty_score,
                    COUNT(CASE WHEN computed_difficulty = 'beginner' THEN 1 END) as beginner_count,
                    COUNT(CASE WHEN computed_difficulty = 'intermediate' THEN 1 END) as intermediate_count,
                    COUNT(CASE WHEN computed_difficulty = 'advanced' THEN 1 END) as advanced_count
                FROM question_metrics 
                WHERE is_active = TRUE 
                AND last_computed >= :cutoff_date
            """)
            
            summary = db.execute(summary_query, {"cutoff_date": cutoff_date}).fetchone()
            
            # Get top difficult questions
            difficult_query = text("""
                SELECT question_id, difficulty_score, computed_difficulty, global_success_rate
                FROM question_metrics 
                WHERE is_active = TRUE AND last_computed >= :cutoff_date
                ORDER BY difficulty_score DESC 
                LIMIT 10
            """)
            
            difficult_questions = db.execute(difficult_query, {"cutoff_date": cutoff_date}).fetchall()
            
            report = {
                "report_period_days": days_back,
                "generated_at": datetime.now().isoformat(),
                "summary": {
                    "total_questions": summary.total_questions or 0,
                    "avg_success_rate": round(summary.avg_success_rate or 0, 3),
                    "avg_difficulty_score": round(summary.avg_difficulty_score or 0, 3),
                    "difficulty_distribution": {
                        "beginner": summary.beginner_count or 0,
                        "intermediate": summary.intermediate_count or 0,
                        "advanced": summary.advanced_count or 0
                    }
                },
                "most_difficult_questions": [
                    {
                        "question_id": q.question_id,
                        "difficulty_score": round(q.difficulty_score, 3),
                        "computed_difficulty": q.computed_difficulty,
                        "success_rate": round(q.global_success_rate, 3)
                    }
                    for q in difficult_questions
                ]
            }
            
            logger.info(f"Report generated: {summary.total_questions} questions analyzed")
            
            return {
                "success": True,
                "report": report
            }
            
        finally:
            db.close()
            
    except Exception as e:
        logger.error(f"Report generation failed: {e}")
        return {
            "success": False,
            "error": str(e),
            "failed_at": datetime.now().isoformat()
        }

# Periodic task scheduling
celery_app.conf.beat_schedule = {
    'daily-difficulty-calculation': {
        'task': 'app.tasks.difficulty_tasks.calculate_all_question_difficulties',
        'schedule': 86400.0,  # 24 hours in seconds
        'args': (30, False),  # days_back=30, force_recalculate=False
    },
    'weekly-cleanup': {
        'task': 'app.tasks.difficulty_tasks.cleanup_old_metrics',
        'schedule': 604800.0,  # 7 days in seconds
        'args': (90,),  # days_to_keep=90
    },
    'weekly-report': {
        'task': 'app.tasks.difficulty_tasks.generate_difficulty_report',
        'schedule': 604800.0,  # 7 days in seconds
        'args': (7,),  # days_back=7
    },
}

celery_app.conf.timezone = 'UTC'

if __name__ == '__main__':
    celery_app.start()