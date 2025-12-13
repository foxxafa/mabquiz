"""
Database models for MAB Quiz System
"""

from sqlalchemy.ext.declarative import declarative_base

Base = declarative_base()

# Import all models to register them with SQLAlchemy
from .question_metrics import QuestionMetrics, StudentResponse
from .user import UserDB
from .question import Question
from .quiz_session import UserQuizSession
from .mab_state import UserMABQuestionArm, UserMABTopicArm
from .user_role import UserRole

__all__ = [
    "Base",
    "QuestionMetrics",
    "StudentResponse",
    "UserDB",
    "Question",
    "UserQuizSession",
    "UserMABQuestionArm",
    "UserMABTopicArm",
    "UserRole",
]
