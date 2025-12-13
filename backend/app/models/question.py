from sqlalchemy import Column, Integer, String, Text, Float, DateTime, Boolean, JSON, ForeignKey
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from . import Base


class Question(Base):
    """Enhanced Question model with foreign keys for MAB system"""
    __tablename__ = "questions"

    # Primary fields
    id = Column(Integer, primary_key=True, autoincrement=True)
    question_id = Column(String(64), unique=True, index=True, nullable=False)

    # Foreign keys for categorization
    subtopic_id = Column(Integer, ForeignKey("subtopics.id", ondelete="SET NULL"), nullable=True, index=True)
    knowledge_type_id = Column(Integer, ForeignKey("knowledge_types.id", ondelete="SET NULL"), nullable=True, index=True)

    # Content
    text = Column(Text, nullable=False)  # Question text (prompt)
    type = Column(String(32), nullable=False, index=True)  # multiple_choice, true_false, fill_in_blank, matching

    # Options and answer
    options = Column(JSON, nullable=True)  # JSON array for multiple_choice: ["A", "B", "C", "D"]
    correct_answer = Column(String(500), nullable=False)  # Correct answer
    explanation = Column(Text, nullable=True)  # Explanation

    # For matching questions (future support)
    match_pairs = Column(JSON, nullable=True)  # JSON for matching: [{"left": "...", "right": "..."}, ...]

    # Legacy string fields (for backward compatibility during migration)
    course = Column(String(64), index=True, nullable=True)
    subject = Column(String(64), index=True, nullable=True)
    topic = Column(String(128), index=True, nullable=True)
    subtopic = Column(String(128), nullable=True)
    knowledge_type = Column(String(64), index=True, nullable=True)

    # Tags for additional categorization
    tags = Column(JSON, nullable=True)  # JSON array: ["NSAID", "pain", "aspirin"]

    # Difficulty
    difficulty = Column(String(32), index=True, default="intermediate")  # beginner, intermediate, advanced
    initial_confidence = Column(Float, default=0.5)  # For MAB algorithm

    # Scoring
    points = Column(Integer, default=10)

    # Metadata
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    is_active = Column(Boolean, default=True)

    # Relationships
    subtopic_rel = relationship("Subtopic", back_populates="questions")
    knowledge_type_rel = relationship("KnowledgeType", back_populates="questions")

    @property
    def options_json(self):
        """Backward compatibility property"""
        import json
        return json.dumps(self.options, ensure_ascii=False) if self.options else None

    def to_dict(self, include_relations=False):
        """Convert to dictionary for API responses"""
        result = {
            "id": self.question_id,
            "dbId": self.id,
            "prompt": self.text,
            "text": self.text,
            "type": self.type,
            "options": self.options,
            "correctAnswer": self.correct_answer,
            "explanation": self.explanation,
            "matchPairs": self.match_pairs,
            "subtopicId": self.subtopic_id,
            "knowledgeTypeId": self.knowledge_type_id,
            # Legacy fields
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

        if include_relations:
            if self.subtopic_rel:
                result["subtopicInfo"] = {
                    "id": self.subtopic_rel.id,
                    "name": self.subtopic_rel.name,
                    "displayName": self.subtopic_rel.display_name,
                }
                if self.subtopic_rel.topic:
                    result["topicInfo"] = {
                        "id": self.subtopic_rel.topic.id,
                        "name": self.subtopic_rel.topic.name,
                        "displayName": self.subtopic_rel.topic.display_name,
                    }
                    if self.subtopic_rel.topic.course:
                        result["courseInfo"] = {
                            "id": self.subtopic_rel.topic.course.id,
                            "name": self.subtopic_rel.topic.course.name,
                            "displayName": self.subtopic_rel.topic.course.display_name,
                        }
            if self.knowledge_type_rel:
                result["knowledgeTypeInfo"] = {
                    "id": self.knowledge_type_rel.id,
                    "name": self.knowledge_type_rel.name,
                    "displayName": self.knowledge_type_rel.display_name,
                }

        return result
