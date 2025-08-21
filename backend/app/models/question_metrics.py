"""
Database models for question difficulty metrics
"""

from sqlalchemy import Column, Integer, String, Float, DateTime, Boolean, Text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.sql import func
from datetime import datetime

Base = declarative_base()

class QuestionMetrics(Base):
    """Store calculated difficulty metrics for questions"""
    __tablename__ = "question_metrics"
    
    id = Column(Integer, primary_key=True, index=True)
    question_id = Column(String(50), unique=True, index=True, nullable=False)
    
    # Performance metrics
    global_success_rate = Column(Float, nullable=False)
    total_attempts = Column(Integer, nullable=False)
    average_response_time = Column(Float, nullable=False)  # in seconds
    reach_rate = Column(Float, nullable=False)
    
    # Difficulty calculation
    difficulty_score = Column(Float, nullable=False)  # 0-1 composite score
    computed_difficulty = Column(String(20), nullable=False)  # beginner/intermediate/advanced
    
    # Confidence intervals
    confidence_lower = Column(Float, nullable=False)
    confidence_upper = Column(Float, nullable=False)
    
    # Metadata
    last_computed = Column(DateTime, nullable=False)
    is_active = Column(Boolean, default=True)
    
    # Timestamps
    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now())
    
    def to_dict(self):
        """Convert to dictionary for API responses"""
        return {
            "question_id": self.question_id,
            "dynamicMetrics": {
                "globalSuccessRate": round(self.global_success_rate, 3),
                "totalAttempts": self.total_attempts,
                "averageResponseTime": round(self.average_response_time, 1),
                "reachRate": round(self.reach_rate, 3),
                "difficultyScore": round(self.difficulty_score, 3),
                "computedAt": self.last_computed.isoformat(),
                "sampleSize": self.total_attempts,
                "confidenceInterval": {
                    "lower": round(self.confidence_lower, 3),
                    "upper": round(self.confidence_upper, 3)
                }
            },
            "computedDifficulty": self.computed_difficulty,
            "lastUpdated": self.updated_at.isoformat() if self.updated_at else None
        }

class StudentResponse(Base):
    """Store student responses for difficulty calculation"""
    __tablename__ = "student_responses"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(String(100), index=True, nullable=False)
    question_id = Column(String(50), index=True, nullable=False)
    
    # Response data
    is_correct = Column(Boolean, nullable=False)
    response_time_ms = Column(Integer, nullable=False)
    user_answer = Column(Text, nullable=True)
    user_confidence = Column(Float, nullable=True)  # 0-1 scale
    
    # Context
    session_id = Column(String(100), nullable=True)
    course = Column(String(50), nullable=True)
    topic = Column(String(100), nullable=True)
    knowledge_type = Column(String(50), nullable=True)
    
    # Timestamps
    created_at = Column(DateTime, server_default=func.now(), index=True)
    
    def to_dict(self):
        """Convert to dictionary"""
        return {
            "id": self.id,
            "user_id": self.user_id,
            "question_id": self.question_id,
            "is_correct": self.is_correct,
            "response_time_ms": self.response_time_ms,
            "user_answer": self.user_answer,
            "user_confidence": self.user_confidence,
            "session_id": self.session_id,
            "course": self.course,
            "topic": self.topic,
            "knowledge_type": self.knowledge_type,
            "created_at": self.created_at.isoformat() if self.created_at else None
        }