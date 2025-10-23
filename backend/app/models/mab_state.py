"""
MAB (Multi-Armed Bandit) state models for personalized learning
"""

from sqlalchemy import Column, Integer, String, Float, DateTime, Index
from sqlalchemy.sql import func
from . import Base


class UserMABQuestionArm(Base):
    """User-specific MAB state for individual questions with prior knowledge"""
    __tablename__ = "user_mab_question_arms"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(String(100), index=True, nullable=False)
    question_id = Column(String(64), index=True, nullable=False)
    difficulty = Column(String(32), nullable=False)  # beginner, intermediate, advanced

    # Performance metrics
    attempts = Column(Integer, default=0)
    successes = Column(Integer, default=0)
    failures = Column(Integer, default=0)
    total_response_time_ms = Column(Integer, default=0)

    # Beta distribution parameters for Thompson Sampling
    # Prior knowledge based on difficulty:
    # - beginner: alpha=7, beta=3 (expect 70% success)
    # - intermediate: alpha=5, beta=5 (expect 50% success)
    # - advanced: alpha=3, beta=7 (expect 30% success)
    alpha = Column(Float, default=1.0)
    beta = Column(Float, default=1.0)
    user_confidence = Column(Float, default=0.5)

    # Metadata
    last_attempted = Column(DateTime, nullable=True)  # For forgetting curve
    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now())

    # Composite unique constraint
    __table_args__ = (
        Index('idx_user_question', 'user_id', 'question_id', unique=True),
    )

    def to_dict(self):
        """Convert to dictionary"""
        return {
            "user_id": self.user_id,
            "question_id": self.question_id,
            "difficulty": self.difficulty,
            "attempts": self.attempts,
            "successes": self.successes,
            "failures": self.failures,
            "total_response_time_ms": self.total_response_time_ms,
            "alpha": self.alpha,
            "beta": self.beta,
            "user_confidence": self.user_confidence,
            "last_attempted": self.last_attempted.isoformat() if self.last_attempted else None,
            "success_rate": round(self.successes / self.attempts, 3) if self.attempts > 0 else 0.0,
        }

    def initialize_prior(self, difficulty: str):
        """Initialize prior distribution based on difficulty"""
        if difficulty == "beginner":
            self.alpha = 7.0
            self.beta = 3.0
        elif difficulty == "intermediate":
            self.alpha = 5.0
            self.beta = 5.0
        elif difficulty == "advanced":
            self.alpha = 3.0
            self.beta = 7.0
        else:
            self.alpha = 5.0
            self.beta = 5.0


class UserMABTopicArm(Base):
    """User-specific MAB state for topics"""
    __tablename__ = "user_mab_topic_arms"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(String(100), index=True, nullable=False)
    topic_key = Column(String(128), index=True, nullable=False)  # format: topic_knowledgeType

    # Topic information
    course = Column(String(64), nullable=False)
    topic = Column(String(128), nullable=False)
    knowledge_type = Column(String(64), nullable=False)

    # Performance metrics
    attempts = Column(Integer, default=0)
    successes = Column(Integer, default=0)
    failures = Column(Integer, default=0)
    total_response_time_ms = Column(Integer, default=0)

    # Beta distribution parameters for Thompson Sampling
    alpha = Column(Float, default=1.0)
    beta = Column(Float, default=1.0)

    # Metadata
    last_updated = Column(DateTime, server_default=func.now(), onupdate=func.now())
    created_at = Column(DateTime, server_default=func.now())

    # Composite unique constraint
    __table_args__ = (
        Index('idx_user_topic', 'user_id', 'topic_key', unique=True),
    )

    def to_dict(self):
        """Convert to dictionary"""
        return {
            "user_id": self.user_id,
            "topic_key": self.topic_key,
            "course": self.course,
            "topic": self.topic,
            "knowledge_type": self.knowledge_type,
            "attempts": self.attempts,
            "successes": self.successes,
            "failures": self.failures,
            "total_response_time_ms": self.total_response_time_ms,
            "alpha": self.alpha,
            "beta": self.beta,
            "last_updated": self.last_updated.isoformat() if self.last_updated else None,
        }