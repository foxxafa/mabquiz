from sqlalchemy import Column, Integer, String, Text, Boolean, DateTime, ForeignKey
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from . import Base


class Topic(Base):
    """Konu modeli - Ders altindaki ana konular"""
    __tablename__ = "topics"

    id = Column(Integer, primary_key=True, autoincrement=True)
    course_id = Column(Integer, ForeignKey("courses.id", ondelete="CASCADE"), nullable=False, index=True)
    name = Column(String(100), nullable=False, index=True)
    display_name = Column(String(150), nullable=False)
    description = Column(Text, nullable=True)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    # Relationships
    course = relationship("Course", back_populates="topics")
    subtopics = relationship("Subtopic", back_populates="topic", cascade="all, delete-orphan")

    # Unique constraint: same topic name can't exist twice in same course
    __table_args__ = (
        {"sqlite_autoincrement": True},
    )

    def to_dict(self, include_course=False):
        result = {
            "id": self.id,
            "courseId": self.course_id,
            "name": self.name,
            "displayName": self.display_name,
            "description": self.description,
            "isActive": self.is_active,
            "createdAt": self.created_at.isoformat() if self.created_at else None,
            "updatedAt": self.updated_at.isoformat() if self.updated_at else None,
            "subtopicCount": len(self.subtopics) if self.subtopics else 0,
        }
        if include_course and self.course:
            result["course"] = {
                "id": self.course.id,
                "name": self.course.name,
                "displayName": self.course.display_name,
            }
        return result