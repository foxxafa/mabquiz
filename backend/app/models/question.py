from sqlalchemy import Column, Integer, String, Text, Float, DateTime, Boolean, JSON
from sqlalchemy.sql import func
from . import Base

class Question(Base):
    """Enhanced Question model with full metadata for MAB system"""
    __tablename__ = "questions"

    # Primary fields
    id = Column(Integer, primary_key=True, autoincrement=True)
    question_id = Column(String(64), unique=True, index=True, nullable=False)

    # Content
    text = Column(Text, nullable=False)  # Question text
    type = Column(String(32), nullable=False)  # multiple_choice, true_false, etc.

    # Options and answer
    options = Column(JSON, nullable=False)  # JSON array: ["A", "B", "C", "D"] or dict
    correct_answer = Column(String(255), nullable=False)  # Correct answer
    explanation = Column(Text, nullable=True)  # Explanation

    # Categorization
    course = Column(String(64), index=True, nullable=False)  # farmakoloji, terminoloji
    subject = Column(String(64), index=True, nullable=False)  # Backward compatibility (same as course)
    topic = Column(String(128), index=True, nullable=False)  # Analjezikler, Kardiyoloji
    subtopic = Column(String(128), nullable=True)  # Subtopic
    knowledge_type = Column(String(64), index=True, nullable=False)  # dosage, terminology, etc.
    tags = Column(JSON, nullable=True)  # JSON array: ["NSAID", "pain", "aspirin"]

    # Difficulty
    difficulty = Column(String(32), index=True, nullable=False)  # beginner, intermediate, advanced
    initial_confidence = Column(Float, default=0.5)  # For MAB algorithm

    # Scoring
    points = Column(Integer, default=10)

    # Metadata
    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now())
    is_active = Column(Boolean, default=True)

    # For backward compatibility (old code using options_json)
    @property
    def options_json(self):
        """Backward compatibility property"""
        import json
        return json.dumps(self.options, ensure_ascii=False) if self.options else None

    def to_dict(self):
        """Convert to dictionary for API responses"""
        return {
            "id": self.question_id,
            "prompt": self.text,
            "text": self.text,
            "type": self.type,
            "options": self.options,
            "correctAnswer": self.correct_answer,
            "explanation": self.explanation,
            "course": self.course,
            "subject": self.subject,
            "topic": self.topic,
            "subtopic": self.subtopic,
            "knowledgeType": self.knowledge_type,
            "tags": self.tags or [],
            "difficulty": self.difficulty,
            "initialConfidence": self.initial_confidence,
            "points": self.points,
            "isActive": self.is_active,
            "createdAt": self.created_at.isoformat() if self.created_at else None,
            "updatedAt": self.updated_at.isoformat() if self.updated_at else None,
        }