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
# Description alani Gemini'ye gonderilir, bu yuzden detayli olmali
DEFAULT_KNOWLEDGE_TYPES = [
    {"name": "recall", "display_name": "Hatirlama", "description": "X nedir, Y kactir, Z ne zaman gibi temel bilgi sorulari. Ornek: Isik hizi kactir? Turkiyenin baskenti neresi?"},
    {"name": "comprehension", "display_name": "Anlama", "description": "Aciklama ve yorumlama gerektiren sorular. Ornek: Enerji korunumu ne demek? Bu kavram ne anlama gelir?"},
    {"name": "application", "display_name": "Uygulama", "description": "Hesaplama, problem cozme, formul uygulama. Ornek: Bu kuvveti hesaplayin, denklemi cozun, dozu hesaplayin"},
    {"name": "analysis", "display_name": "Analiz", "description": "Karsilastirma, yorumlama, parcalara ayirma. Ornek: Bu grafigi yorumlayin, farklari karsilastirin, nedenleri aciklayin"},
    {"name": "synthesis", "display_name": "Sentez", "description": "Tasarlama, olusturma, birlestirme. Ornek: Deney tasarlayin, plan olusturun, cozum onerin"},
    {"name": "evaluation", "display_name": "Degerlendirme", "description": "Yargilama, elestirme, secim yapma. Ornek: Hangisi daha iyi? En uygun yontem hangisi? Elestirin"},
    {"name": "factual", "display_name": "Olgusal", "description": "Tarih, sayi, isim, formul gibi somut bilgiler. Ornek: Pi sayisi kactir? Hangi yil oldu? Formulu nedir?"},
    {"name": "conceptual", "display_name": "Kavramsal", "description": "Kavramlar arasi iliski ve prensipler. Ornek: X ile Y arasindaki iliski nedir? Bu prensip nasil calisir?"},
    {"name": "procedural", "display_name": "Islemsel", "description": "Adim adim islem ve yontemler. Ornek: Nasil yapilir? Hangi adimlar izlenir? Surec nasil isler?"},
]
