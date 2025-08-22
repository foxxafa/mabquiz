"""
Database models for MAB Quiz System
"""

from sqlalchemy.ext.declarative import declarative_base

Base = declarative_base()

# Import all models to register them with SQLAlchemy
from .question_metrics import QuestionMetrics, StudentResponse
from .user import UserDB
from .question import Question

__all__ = ["Base", "QuestionMetrics", "StudentResponse", "UserDB", "Question"]