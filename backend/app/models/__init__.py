"""
Database models for MAB Quiz System
"""

from sqlalchemy.ext.declarative import declarative_base

Base = declarative_base()

# Import all models to register them with SQLAlchemy
# Order matters for foreign key relationships
from .course import Course
from .topic import Topic
from .subtopic import Subtopic
from .knowledge_type import KnowledgeType, DEFAULT_KNOWLEDGE_TYPES
from .question import Question
from .question_metrics import QuestionMetrics, StudentResponse
from .user import UserDB
from .quiz_session import UserQuizSession
from .mab_state import UserMABQuestionArm, UserMABTopicArm
from .user_role import UserRole

__all__ = [
    "Base",
    "Course",
    "Topic",
    "Subtopic",
    "KnowledgeType",
    "DEFAULT_KNOWLEDGE_TYPES",
    "Question",
    "QuestionMetrics",
    "StudentResponse",
    "UserDB",
    "UserQuizSession",
    "UserMABQuestionArm",
    "UserMABTopicArm",
    "UserRole",
]
