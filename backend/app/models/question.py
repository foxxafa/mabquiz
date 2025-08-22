from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy import Integer, String, Text
from . import Base

class Question(Base):
    __tablename__ = "questions"
    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    question_id: Mapped[str] = mapped_column(String(64), unique=True, index=True)
    subject: Mapped[str] = mapped_column(String(64), index=True)
    difficulty: Mapped[str] = mapped_column(String(32), index=True)
    type: Mapped[str] = mapped_column(String(32))
    text: Mapped[str] = mapped_column(Text)
    options_json: Mapped[str] = mapped_column(Text)  # JSON string of options/answers