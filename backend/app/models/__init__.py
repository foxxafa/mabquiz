"""
Database models for MAB Quiz System
"""

from sqlalchemy.ext.declarative import declarative_base

Base = declarative_base()

# Import all models to register them with SQLAlchemy
from .question_metrics import QuestionMetrics, StudentResponsefrom .user import UserDB

__all__ = ["Base", "QuestionMetrics", "StudentResponse", "UserDB"]