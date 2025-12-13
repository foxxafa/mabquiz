from sqlalchemy import Column, Integer, String, Text, Boolean, DateTime, ForeignKey
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from . import Base


class Subtopic(Base):
    """Alt konu modeli - Konularin alt kategorileri"""
    __tablename__ = "subtopics"

    id = Column(Integer, primary_key=True, autoincrement=True)
    topic_id = Column(Integer, ForeignKey("topics.id", ondelete="CASCADE"), nullable=False, index=True)
    name = Column(String(100), nullable=False, index=True)
    display_name = Column(String(150), nullable=False)
    description = Column(Text, nullable=True)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    # Relationships
    topic = relationship("Topic", back_populates="subtopics")
    questions = relationship("Question", back_populates="subtopic_rel", cascade="all, delete-orphan")

    def to_dict(self, include_topic=False):
        result = {
            "id": self.id,
            "topicId": self.topic_id,
            "name": self.name,
            "displayName": self.display_name,
            "description": self.description,
            "isActive": self.is_active,
            "createdAt": self.created_at.isoformat() if self.created_at else None,
            "updatedAt": self.updated_at.isoformat() if self.updated_at else None,
            "questionCount": len(self.questions) if self.questions else 0,
        }
        if include_topic and self.topic:
            result["topic"] = {
                "id": self.topic.id,
                "name": self.topic.name,
                "displayName": self.topic.display_name,
                "courseId": self.topic.course_id,
            }
            if self.topic.course:
                result["course"] = {
                    "id": self.topic.course.id,
                    "name": self.topic.course.name,
                    "displayName": self.topic.course.display_name,
                }
        return result