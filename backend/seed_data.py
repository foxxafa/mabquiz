"""
Sample data seeder for development
"""
import asyncio
import json
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession
from app.models import Base, Question
from app.db import DATABASE_URL

# Örnek sorular
SAMPLE_QUESTIONS = [
    {
        "question_id": "farm_001",
        "subject": "farmakoloji", 
        "difficulty": "easy",
        "type": "multiple_choice",
        "text": "Aspirin hangi grupta yer alır?",
        "options": {
            "A": "Antibiyotik",
            "B": "Analjezik",
            "C": "Antiviral", 
            "D": "Antihistaminik",
            "correct": "B"
        }
    },
    {
        "question_id": "term_001",
        "subject": "terminoloji",
        "difficulty": "easy", 
        "type": "true_false",
        "text": "Cardio- ön eki kalp anlamına gelir.",
        "options": {
            "correct": True
        }
    },
    {
        "question_id": "farm_002",
        "subject": "farmakoloji",
        "difficulty": "medium",
        "type": "multiple_choice", 
        "text": "Parasetamolün maksimum günlük dozu nedir?",
        "options": {
            "A": "2 gram",
            "B": "3 gram", 
            "C": "4 gram",
            "D": "5 gram",
            "correct": "C"
        }
    }
]

async def seed_data():
    """Örnek verileri veritabanına ekle"""
    engine = create_async_engine(DATABASE_URL, echo=True)
    
    # Tabloları oluştur
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    
    # Verileri ekle
    SessionLocal = async_sessionmaker(engine, expire_on_commit=False, class_=AsyncSession)
    async with SessionLocal() as session:
        for q_data in SAMPLE_QUESTIONS:
            question = Question(
                question_id=q_data["question_id"],
                subject=q_data["subject"],
                difficulty=q_data["difficulty"], 
                type=q_data["type"],
                text=q_data["text"],
                options_json=json.dumps(q_data["options"], ensure_ascii=False)
            )
            session.add(question)
        
        await session.commit()
        print(f"✅ {len(SAMPLE_QUESTIONS)} örnek soru eklendi!")

if __name__ == "__main__":
    asyncio.run(seed_data())
