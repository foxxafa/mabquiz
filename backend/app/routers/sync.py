"""
Sync API endpoints for MAB state synchronization
Delta sync strategy: client sends data updated after lastSyncTime
"""
from typing import List, Optional
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select, and_
from sqlalchemy.ext.asyncio import AsyncSession
from pydantic import BaseModel

from ..db import get_session
from ..models.mab_state import UserMABQuestionArm, UserMABTopicArm
from ..auth.jwt_handler import get_current_user

router = APIRouter(prefix="/sync", tags=["sync"])


# ==================== Request/Response Models ====================

class QuestionArmSync(BaseModel):
    question_id: str
    attempts: int
    successes: int
    failures: int
    total_response_time_ms: int
    alpha: float
    beta: float
    user_confidence: float
    last_attempted: Optional[int] = None  # epoch ms
    created_at: int  # epoch ms
    updated_at: int  # epoch ms


class TopicArmSync(BaseModel):
    topic_key: str
    topic: str
    knowledge_type: str
    course: str
    attempts: int
    successes: int
    failures: int
    total_response_time_ms: int
    alpha: float
    beta: float
    created_at: int  # epoch ms
    updated_at: int  # epoch ms


class SyncRequest(BaseModel):
    last_sync_time: int  # epoch ms - client's last known sync time
    question_arms: List[QuestionArmSync] = []
    topic_arms: List[TopicArmSync] = []


class SyncResponse(BaseModel):
    server_time: int  # epoch ms - use this as next lastSyncTime
    question_arms: List[dict] = []
    topic_arms: List[dict] = []
    conflicts_resolved: int = 0


# ==================== Sync Endpoints ====================

@router.post("/mab", response_model=SyncResponse)
async def sync_mab_state(
    request: SyncRequest,
    session: AsyncSession = Depends(get_session),
    current_user: dict = Depends(get_current_user),
):
    """
    Two-way delta sync for MAB state

    Strategy:
    1. Client sends records where updated_at > lastSyncTime
    2. Server merges using "last write wins" based on updated_at
    3. Server returns records updated since lastSyncTime (including merged ones)
    4. Client updates local DB with server response
    """
    user_id = current_user["user_id"]
    server_time = int(datetime.utcnow().timestamp() * 1000)
    last_sync_datetime = datetime.fromtimestamp(request.last_sync_time / 1000) if request.last_sync_time > 0 else None
    conflicts_resolved = 0

    # ==================== Process Question Arms ====================
    for arm in request.question_arms:
        existing = await session.execute(
            select(UserMABQuestionArm).where(
                and_(
                    UserMABQuestionArm.user_id == user_id,
                    UserMABQuestionArm.question_id == arm.question_id,
                )
            )
        )
        existing_arm = existing.scalar_one_or_none()

        client_updated = datetime.fromtimestamp(arm.updated_at / 1000)

        if existing_arm:
            # Conflict resolution: last write wins
            if existing_arm.updated_at is None or client_updated > existing_arm.updated_at:
                existing_arm.attempts = arm.attempts
                existing_arm.successes = arm.successes
                existing_arm.failures = arm.failures
                existing_arm.total_response_time_ms = arm.total_response_time_ms
                existing_arm.alpha = arm.alpha
                existing_arm.beta = arm.beta
                existing_arm.user_confidence = arm.user_confidence
                existing_arm.last_attempted = datetime.fromtimestamp(arm.last_attempted / 1000) if arm.last_attempted else None
                existing_arm.updated_at = client_updated
                conflicts_resolved += 1
        else:
            # New record
            new_arm = UserMABQuestionArm(
                user_id=user_id,
                question_id=arm.question_id,
                attempts=arm.attempts,
                successes=arm.successes,
                failures=arm.failures,
                total_response_time_ms=arm.total_response_time_ms,
                alpha=arm.alpha,
                beta=arm.beta,
                user_confidence=arm.user_confidence,
                last_attempted=datetime.fromtimestamp(arm.last_attempted / 1000) if arm.last_attempted else None,
                created_at=datetime.fromtimestamp(arm.created_at / 1000),
                updated_at=client_updated,
            )
            session.add(new_arm)

    # ==================== Process Topic Arms ====================
    for arm in request.topic_arms:
        existing = await session.execute(
            select(UserMABTopicArm).where(
                and_(
                    UserMABTopicArm.user_id == user_id,
                    UserMABTopicArm.topic_key == arm.topic_key,
                )
            )
        )
        existing_arm = existing.scalar_one_or_none()

        client_updated = datetime.fromtimestamp(arm.updated_at / 1000)

        if existing_arm:
            # Conflict resolution: last write wins
            if existing_arm.updated_at is None or client_updated > existing_arm.updated_at:
                existing_arm.attempts = arm.attempts
                existing_arm.successes = arm.successes
                existing_arm.failures = arm.failures
                existing_arm.total_response_time_ms = arm.total_response_time_ms
                existing_arm.alpha = arm.alpha
                existing_arm.beta = arm.beta
                existing_arm.topic = arm.topic
                existing_arm.knowledge_type = arm.knowledge_type
                existing_arm.course = arm.course
                existing_arm.updated_at = client_updated
                conflicts_resolved += 1
        else:
            # New record
            new_arm = UserMABTopicArm(
                user_id=user_id,
                topic_key=arm.topic_key,
                topic=arm.topic,
                knowledge_type=arm.knowledge_type,
                course=arm.course,
                attempts=arm.attempts,
                successes=arm.successes,
                failures=arm.failures,
                total_response_time_ms=arm.total_response_time_ms,
                alpha=arm.alpha,
                beta=arm.beta,
                created_at=datetime.fromtimestamp(arm.created_at / 1000),
                updated_at=client_updated,
            )
            session.add(new_arm)

    await session.commit()

    # ==================== Fetch Server Updates ====================
    # Get all records updated since client's lastSyncTime
    question_arms_result = await session.execute(
        select(UserMABQuestionArm).where(
            and_(
                UserMABQuestionArm.user_id == user_id,
                UserMABQuestionArm.updated_at > last_sync_datetime if last_sync_datetime else True,
            )
        )
    )
    server_question_arms = [arm.to_dict() for arm in question_arms_result.scalars().all()]

    topic_arms_result = await session.execute(
        select(UserMABTopicArm).where(
            and_(
                UserMABTopicArm.user_id == user_id,
                UserMABTopicArm.updated_at > last_sync_datetime if last_sync_datetime else True,
            )
        )
    )
    server_topic_arms = [arm.to_dict() for arm in topic_arms_result.scalars().all()]

    return SyncResponse(
        server_time=server_time,
        question_arms=server_question_arms,
        topic_arms=server_topic_arms,
        conflicts_resolved=conflicts_resolved,
    )


@router.get("/mab/status")
async def get_sync_status(
    session: AsyncSession = Depends(get_session),
    current_user: dict = Depends(get_current_user),
):
    """Get user's MAB sync status"""
    user_id = current_user["user_id"]

    question_count = await session.execute(
        select(UserMABQuestionArm).where(UserMABQuestionArm.user_id == user_id)
    )
    question_arms = question_count.scalars().all()

    topic_count = await session.execute(
        select(UserMABTopicArm).where(UserMABTopicArm.user_id == user_id)
    )
    topic_arms = topic_count.scalars().all()

    return {
        "user_id": user_id,
        "question_arms_count": len(question_arms),
        "topic_arms_count": len(topic_arms),
        "server_time": int(datetime.utcnow().timestamp() * 1000),
    }
