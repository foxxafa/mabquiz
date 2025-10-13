"""
Quiz session models for tracking user quiz activity
"""

from sqlalchemy import Column, Integer, String, DateTime, Float, Boolean
from sqlalchemy.sql import func
from . import Base


class UserQuizSession(Base):
    """User quiz sessions for tracking quiz activity and results"""
    __tablename__ = "user_quiz_sessions"

    id = Column(Integer, primary_key=True, index=True)
    session_id = Column(String(100), unique=True, index=True, nullable=False)
    user_id = Column(String(100), index=True, nullable=False)

    # Quiz configuration
    subject = Column(String(64), nullable=True)
    difficulty = Column(String(32), nullable=True)
    total_questions = Column(Integer, nullable=False)

    # Results
    correct_answers = Column(Integer, default=0)
    total_points = Column(Integer, default=0)
    earned_points = Column(Integer, default=0)
    percentage = Column(Float, default=0.0)

    # Timing
    started_at = Column(DateTime, server_default=func.now(), index=True)
    completed_at = Column(DateTime, nullable=True)
    total_duration_ms = Column(Integer, nullable=True)

    # Status
    is_completed = Column(Boolean, default=False)

    # MAB context
    used_mab = Column(Boolean, default=True)

    # Timestamps
    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now())

    def to_dict(self):
        """Convert to dictionary for API responses"""
        return {
            "session_id": self.session_id,
            "user_id": self.user_id,
            "subject": self.subject,
            "difficulty": self.difficulty,
            "total_questions": self.total_questions,
            "correct_answers": self.correct_answers,
            "total_points": self.total_points,
            "earned_points": self.earned_points,
            "percentage": round(self.percentage, 2),
            "started_at": self.started_at.isoformat() if self.started_at else None,
            "completed_at": self.completed_at.isoformat() if self.completed_at else None,
            "total_duration_ms": self.total_duration_ms,
            "is_completed": self.is_completed,
            "used_mab": self.used_mab,
        }