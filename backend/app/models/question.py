from sqlalchemy import Column, Integer, String, Text, DateTime, Boolean, JSON, ForeignKey
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from . import Base


class Question(Base):
    """Clean Question model with foreign keys for MAB system"""
    __tablename__ = "questions"

    # Primary fields
    id = Column(Integer, primary_key=True, autoincrement=True)
    question_id = Column(String(64), unique=True, index=True, nullable=False)

    # Foreign keys for categorization
    subtopic_id = Column(Integer, ForeignKey("subtopics.id", ondelete="CASCADE"), nullable=False, index=True)
    knowledge_type_id = Column(Integer, ForeignKey("knowledge_types.id", ondelete="RESTRICT"), nullable=False, index=True)

    # Content
    text = Column(Text, nullable=False)  # Question text (prompt)
    type = Column(String(32), nullable=False, index=True)  # multiple_choice, true_false, fill_in_blank, matching

    # Options and answer
    options = Column(JSON, nullable=True)  # JSON array for multiple_choice: ["A", "B", "C", "D"]
    correct_answer = Column(String(500), nullable=False)  # Correct answer
    explanation = Column(Text, nullable=True)  # Explanation

    # For matching questions (future support)
    match_pairs = Column(JSON, nullable=True)  # JSON for matching: [{"left": "...", "right": "..."}, ...]

    # Tags for additional categorization
    tags = Column(JSON, nullable=True)  # JSON array: ["NSAID", "pain", "aspirin"]

    # Scoring
    points = Column(Integer, default=10)

    # Metadata
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    is_active = Column(Boolean, default=True)

    # Relationships
    subtopic_rel = relationship("Subtopic", back_populates="questions")
    knowledge_type_rel = relationship("KnowledgeType", back_populates="questions")

    def to_dict(self, include_relations=True):
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
            "tags": self.tags or [],
            "points": self.points,
            "isActive": self.is_active,
            "createdAt": self.created_at.isoformat() if self.created_at else None,
            "updatedAt": self.updated_at.isoformat() if self.updated_at else None,
        }

        if include_relations:
            if self.subtopic_rel:
                result["subtopic"] = self.subtopic_rel.name
                result["subtopicInfo"] = {
                    "id": self.subtopic_rel.id,
                    "name": self.subtopic_rel.name,
                    "displayName": self.subtopic_rel.display_name,
                }
                if self.subtopic_rel.topic:
                    result["topic"] = self.subtopic_rel.topic.name
                    result["topicInfo"] = {
                        "id": self.subtopic_rel.topic.id,
                        "name": self.subtopic_rel.topic.name,
                        "displayName": self.subtopic_rel.topic.display_name,
                    }
                    if self.subtopic_rel.topic.course:
                        result["course"] = self.subtopic_rel.topic.course.name
                        result["courseInfo"] = {
                            "id": self.subtopic_rel.topic.course.id,
                            "name": self.subtopic_rel.topic.course.name,
                            "displayName": self.subtopic_rel.topic.course.display_name,
                        }
            if self.knowledge_type_rel:
                result["knowledgeType"] = self.knowledge_type_rel.name
                result["knowledgeTypeInfo"] = {
                    "id": self.knowledge_type_rel.id,
                    "name": self.knowledge_type_rel.name,
                    "displayName": self.knowledge_type_rel.display_name,
                }

        return result
