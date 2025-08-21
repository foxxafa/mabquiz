"""
Server-side difficulty calculation service for MAB quiz system.
Calculates dynamic question difficulty based on global student performance.
"""

import math
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Tuple
from dataclasses import dataclass
from sqlalchemy import text
from ..database import get_db
from ..models import QuestionMetrics
import logging

logger = logging.getLogger(__name__)

@dataclass
class DifficultyMetrics:
    """Question difficulty metrics"""
    question_id: str
    global_success_rate: float
    total_attempts: int
    average_response_time: float
    reach_rate: float
    difficulty_score: float
    computed_difficulty: str
    confidence_interval: Tuple[float, float]
    last_computed: datetime

class DifficultyCalculator:
    """Calculate dynamic question difficulty based on student performance"""
    
    # Difficulty thresholds
    DIFFICULTY_THRESHOLDS = {
        'beginner': (0.7, float('inf')),     # >70% success rate
        'intermediate': (0.4, 0.7),          # 40-70% success rate  
        'advanced': (0.0, 0.4)               # <40% success rate
    }
    
    # Response time expectations (seconds)
    EXPECTED_RESPONSE_TIMES = {
        'terminology': 15,
        'dosage': 30,
        'side_effect': 25,
        'pharmacodynamics': 45,
        'pharmacokinetics': 40
    }
    
    def __init__(self, min_sample_size: int = 10):
        self.min_sample_size = min_sample_size
    
    async def calculate_question_difficulty(
        self, 
        question_id: str,
        days_back: int = 30
    ) -> Optional[DifficultyMetrics]:
        """Calculate difficulty for a single question"""
        
        try:
            db = next(get_db())
            
            # Get performance data from last N days
            cutoff_date = datetime.now() - timedelta(days=days_back)
            
            # Query to get aggregated performance data
            query = text("""
                SELECT 
                    question_id,
                    COUNT(*) as total_attempts,
                    SUM(CASE WHEN is_correct THEN 1 ELSE 0 END) as total_correct,
                    AVG(response_time_ms) as avg_response_time_ms,
                    COUNT(DISTINCT user_id) as unique_users,
                    AVG(user_confidence) as avg_confidence
                FROM student_responses 
                WHERE question_id = :question_id 
                AND created_at >= :cutoff_date
                GROUP BY question_id
            """)
            
            result = db.execute(query, {
                "question_id": question_id,
                "cutoff_date": cutoff_date
            }).fetchone()
            
            if not result or result.total_attempts < self.min_sample_size:
                logger.warning(f"Insufficient data for question {question_id}")
                return None
            
            # Calculate basic metrics
            success_rate = result.total_correct / result.total_attempts
            avg_response_time = (result.avg_response_time_ms or 30000) / 1000  # Convert to seconds
            
            # Calculate reach rate (how many students attempt this question)
            total_active_students = await self._get_active_students_count(db, days_back)
            reach_rate = result.unique_users / max(total_active_students, 1)
            
            # Calculate confidence interval for success rate
            confidence_interval = self._calculate_confidence_interval(
                result.total_correct, 
                result.total_attempts
            )
            
            # Calculate composite difficulty score
            difficulty_score = self._calculate_composite_difficulty(
                success_rate, 
                reach_rate, 
                avg_response_time,
                question_id
            )
            
            # Determine difficulty category
            computed_difficulty = self._score_to_difficulty(difficulty_score)
            
            return DifficultyMetrics(
                question_id=question_id,
                global_success_rate=success_rate,
                total_attempts=result.total_attempts,
                average_response_time=avg_response_time,
                reach_rate=reach_rate,
                difficulty_score=difficulty_score,
                computed_difficulty=computed_difficulty,
                confidence_interval=confidence_interval,
                last_computed=datetime.now()
            )
            
        except Exception as e:
            logger.error(f"Error calculating difficulty for {question_id}: {e}")
            return None
        finally:
            db.close()
    
    async def batch_calculate_difficulties(
        self,
        question_ids: List[str] = None,
        days_back: int = 30
    ) -> Dict[str, DifficultyMetrics]:
        """Calculate difficulties for multiple questions in batch"""
        
        results = {}
        
        try:
            db = next(get_db())
            
            # If no specific questions provided, get all questions with recent activity
            if not question_ids:
                cutoff_date = datetime.now() - timedelta(days=days_back)
                query = text("""
                    SELECT DISTINCT question_id 
                    FROM student_responses 
                    WHERE created_at >= :cutoff_date
                    GROUP BY question_id
                    HAVING COUNT(*) >= :min_sample_size
                """)
                
                result = db.execute(query, {
                    "cutoff_date": cutoff_date,
                    "min_sample_size": self.min_sample_size
                }).fetchall()
                
                question_ids = [row.question_id for row in result]
            
            # Calculate difficulty for each question
            for question_id in question_ids:
                metrics = await self.calculate_question_difficulty(question_id, days_back)
                if metrics:
                    results[question_id] = metrics
                    
                    # Save to database
                    await self._save_difficulty_metrics(db, metrics)
            
            logger.info(f"Calculated difficulties for {len(results)} questions")
            
        except Exception as e:
            logger.error(f"Error in batch calculation: {e}")
        finally:
            if 'db' in locals():
                db.close()
        
        return results
    
    def _calculate_composite_difficulty(
        self, 
        success_rate: float, 
        reach_rate: float,
        avg_response_time: float,
        question_id: str
    ) -> float:
        """Calculate composite difficulty score (0-1, where 1 = most difficult)"""
        
        # Base difficulty from success rate (inverted)
        success_difficulty = 1.0 - success_rate
        
        # Reach penalty - if few students reach this question, it's likely difficult
        reach_penalty = max(0, (0.5 - reach_rate) * 2)  # Max penalty of 1.0
        
        # Response time factor
        # Get expected time based on question knowledge type
        knowledge_type = self._extract_knowledge_type(question_id)
        expected_time = self.EXPECTED_RESPONSE_TIMES.get(knowledge_type, 30)
        
        time_factor = min(1.0, avg_response_time / expected_time)  # Cap at 1.0
        
        # Weighted composite score
        composite_score = (
            success_difficulty * 0.6 +      # Success rate is most important
            reach_penalty * 0.25 +          # Reach rate penalty
            (time_factor - 0.5) * 0.15      # Response time adjustment
        )
        
        return max(0.0, min(1.0, composite_score))  # Clamp to [0, 1]
    
    def _score_to_difficulty(self, score: float) -> str:
        """Convert difficulty score to difficulty category"""
        if score <= 0.3:
            return 'beginner'
        elif score <= 0.7:
            return 'intermediate'
        else:
            return 'advanced'
    
    def _calculate_confidence_interval(
        self, 
        successes: int, 
        total: int, 
        confidence: float = 0.95
    ) -> Tuple[float, float]:
        """Calculate Wilson score confidence interval for success rate"""
        if total == 0:
            return (0.0, 0.0)
        
        p = successes / total
        z = 1.96 if confidence == 0.95 else 1.645  # Z-score for 95% or 90% confidence
        
        denominator = 1 + (z**2) / total
        center = (p + (z**2) / (2 * total)) / denominator
        margin = z * math.sqrt((p * (1 - p) + (z**2) / (4 * total)) / total) / denominator
        
        return (max(0, center - margin), min(1, center + margin))
    
    def _extract_knowledge_type(self, question_id: str) -> str:
        """Extract knowledge type from question ID or metadata"""
        # Simple heuristic based on question ID patterns
        if 'dosage' in question_id.lower() or 'dose' in question_id.lower():
            return 'dosage'
        elif 'side_effect' in question_id.lower() or 'adverse' in question_id.lower():
            return 'side_effect'
        elif 'pharmacodynamics' in question_id.lower() or 'mechanism' in question_id.lower():
            return 'pharmacodynamics'
        elif 'pharmacokinetics' in question_id.lower() or 'absorption' in question_id.lower():
            return 'pharmacokinetics'
        elif 'term' in question_id.lower():
            return 'terminology'
        else:
            return 'general'
    
    async def _get_active_students_count(self, db, days_back: int) -> int:
        """Get count of active students in the given time period"""
        cutoff_date = datetime.now() - timedelta(days=days_back)
        query = text("""
            SELECT COUNT(DISTINCT user_id) as active_students
            FROM student_responses 
            WHERE created_at >= :cutoff_date
        """)
        
        result = db.execute(query, {"cutoff_date": cutoff_date}).fetchone()
        return result.active_students if result else 1
    
    async def _save_difficulty_metrics(self, db, metrics: DifficultyMetrics):
        """Save calculated difficulty metrics to database"""
        try:
            # Insert or update question metrics
            query = text("""
                INSERT INTO question_metrics (
                    question_id, global_success_rate, total_attempts, 
                    average_response_time, reach_rate, difficulty_score,
                    computed_difficulty, confidence_lower, confidence_upper,
                    last_computed, created_at, updated_at
                ) VALUES (
                    :question_id, :global_success_rate, :total_attempts,
                    :average_response_time, :reach_rate, :difficulty_score,
                    :computed_difficulty, :confidence_lower, :confidence_upper,
                    :last_computed, NOW(), NOW()
                ) ON CONFLICT (question_id) DO UPDATE SET
                    global_success_rate = EXCLUDED.global_success_rate,
                    total_attempts = EXCLUDED.total_attempts,
                    average_response_time = EXCLUDED.average_response_time,
                    reach_rate = EXCLUDED.reach_rate,
                    difficulty_score = EXCLUDED.difficulty_score,
                    computed_difficulty = EXCLUDED.computed_difficulty,
                    confidence_lower = EXCLUDED.confidence_lower,
                    confidence_upper = EXCLUDED.confidence_upper,
                    last_computed = EXCLUDED.last_computed,
                    updated_at = NOW()
            """)
            
            db.execute(query, {
                "question_id": metrics.question_id,
                "global_success_rate": metrics.global_success_rate,
                "total_attempts": metrics.total_attempts,
                "average_response_time": metrics.average_response_time,
                "reach_rate": metrics.reach_rate,
                "difficulty_score": metrics.difficulty_score,
                "computed_difficulty": metrics.computed_difficulty,
                "confidence_lower": metrics.confidence_interval[0],
                "confidence_upper": metrics.confidence_interval[1],
                "last_computed": metrics.last_computed
            })
            
            db.commit()
            
        except Exception as e:
            logger.error(f"Error saving difficulty metrics: {e}")
            db.rollback()

# Global instance
difficulty_calculator = DifficultyCalculator()