from sqlalchemy import Column, Integer, String, Text, Boolean, DateTime
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from . import Base


class KnowledgeType(Base):
    """Bilgi turu modeli - Soru icerigi tipleri"""
    __tablename__ = "knowledge_types"

    id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String(50), unique=True, nullable=False, index=True)
    display_name = Column(String(100), nullable=False)
    description = Column(Text, nullable=True)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    # Relationships
    questions = relationship("Question", back_populates="knowledge_type_rel")

    def to_dict(self):
        # Safely get question count - avoid lazy loading in async context
        try:
            question_count = len(self.questions) if self.questions else 0
        except Exception:
            question_count = 0

        return {
            "id": self.id,
            "name": self.name,
            "displayName": self.display_name,
            "description": self.description,
            "isActive": self.is_active,
            "createdAt": self.created_at.isoformat() if self.created_at else None,
            "updatedAt": self.updated_at.isoformat() if self.updated_at else None,
            "questionCount": question_count,
        }


# Default knowledge types to seed - Bloom taksonomisine dayali genel egitim icin
DEFAULT_KNOWLEDGE_TYPES = [
    {"name": "recall", "display_name": "Hatirlama", "description": "Temel bilgileri hatirlama ve tanimlama"},
    {"name": "comprehension", "display_name": "Anlama", "description": "Kavramlari aciklama ve yorumlama"},
    {"name": "application", "display_name": "Uygulama", "description": "Bilgiyi yeni durumlara uygulama"},
    {"name": "analysis", "display_name": "Analiz", "description": "Bilgiyi parcalara ayirma ve inceleme"},
    {"name": "synthesis", "display_name": "Sentez", "description": "Bilgileri birlestirip yeni sonuclar cikarma"},
    {"name": "evaluation", "display_name": "Degerlendirme", "description": "Yargi ve karar verme"},
    {"name": "factual", "display_name": "Olgusal", "description": "Somut olgular, tarihler, sayilar"},
    {"name": "conceptual", "display_name": "Kavramsal", "description": "Kavramlar arasi iliskiler ve prensipler"},
    {"name": "procedural", "display_name": "Islemsel", "description": "Adim adim islemler ve yontemler"},
]
