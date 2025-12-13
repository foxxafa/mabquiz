from sqlalchemy import Column, Integer, String, ForeignKey, DateTime
from sqlalchemy.sql import func
from . import Base


class UserRole(Base):
    __tablename__ = "user_roles"

    id = Column(Integer, primary_key=True, index=True)
    user_uid = Column(String, ForeignKey("users.uid"), index=True)
    role = Column(String, index=True)  # "admin", "moderator", etc.
    created_at = Column(DateTime(timezone=True), server_default=func.now())