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


# Default knowledge types to seed
DEFAULT_KNOWLEDGE_TYPES = [
    {"name": "terminology", "display_name": "Terminoloji", "description": "Tibbi terimlerin anlami ve kullanimi"},
    {"name": "dosage", "display_name": "Dozaj", "description": "Ilac dozlari ve uygulama sekilleri"},
    {"name": "mechanism", "display_name": "Mekanizma", "description": "Ilac etki mekanizmalari"},
    {"name": "indication", "display_name": "Endikasyon", "description": "Ilac kullanim alanlari"},
    {"name": "contraindication", "display_name": "Kontrendikasyon", "description": "Ilac kullanim engelleri"},
    {"name": "side_effect", "display_name": "Yan Etki", "description": "Ilaclarin yan etkileri"},
    {"name": "interaction", "display_name": "Etkilesim", "description": "Ilac-ilac ve ilac-besin etkilesimleri"},
    {"name": "pharmacokinetics", "display_name": "Farmakokinetik", "description": "Ilacin vucuttaki hareketi"},
    {"name": "general", "display_name": "Genel", "description": "Genel bilgi sorulari"},
]
