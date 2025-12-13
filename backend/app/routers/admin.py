"""
Admin API endpoints for managing courses, topics, subtopics, knowledge types, and questions
"""
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, Request
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload
from pydantic import BaseModel
import uuid

from ..db import get_session
from ..models import Course, Topic, Subtopic, KnowledgeType, Question, DEFAULT_KNOWLEDGE_TYPES
from ..models.user_role import UserRole
from ..auth.jwt_handler import verify_token

router = APIRouter(prefix="/admin", tags=["admin"])


# ============ Auth Middleware ============
async def get_admin_user(request: Request, db: AsyncSession = Depends(get_session)):
    """Verify admin access"""
    auth_header = request.headers.get("authorization")
    if not auth_header or not auth_header.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Missing or invalid token")

    token = auth_header.split(" ")[1]
    payload = verify_token(token)
    if not payload:
        raise HTTPException(status_code=401, detail="Invalid token")

    # Check admin role
    uid = payload.get("uid")
    result = await db.execute(
        select(UserRole).filter(UserRole.user_uid == uid, UserRole.role == "admin")
    )
    admin_role = result.scalar_one_or_none()
    if not admin_role:
        raise HTTPException(status_code=403, detail="Admin privileges required")

    return payload


# ============ Pydantic Models ============
class CourseCreate(BaseModel):
    name: str
    displayName: str
    description: Optional[str] = None


class CourseUpdate(BaseModel):
    name: Optional[str] = None
    displayName: Optional[str] = None
    description: Optional[str] = None
    isActive: Optional[bool] = None


class TopicCreate(BaseModel):
    courseId: int
    name: str
    displayName: str
    description: Optional[str] = None


class TopicUpdate(BaseModel):
    courseId: Optional[int] = None
    name: Optional[str] = None
    displayName: Optional[str] = None
    description: Optional[str] = None
    isActive: Optional[bool] = None


class SubtopicCreate(BaseModel):
    topicId: int
    name: str
    displayName: str
    description: Optional[str] = None


class SubtopicUpdate(BaseModel):
    topicId: Optional[int] = None
    name: Optional[str] = None
    displayName: Optional[str] = None
    description: Optional[str] = None
    isActive: Optional[bool] = None


class KnowledgeTypeCreate(BaseModel):
    name: str
    displayName: str
    description: Optional[str] = None


class KnowledgeTypeUpdate(BaseModel):
    name: Optional[str] = None
    displayName: Optional[str] = None
    description: Optional[str] = None
    isActive: Optional[bool] = None


class QuestionCreate(BaseModel):
    subtopicId: int
    knowledgeTypeId: int
    type: str  # multiple_choice, true_false, fill_in_blank, matching
    text: str
    options: Optional[List[str]] = None
    correctAnswer: str
    explanation: Optional[str] = None
    matchPairs: Optional[List[dict]] = None
    difficulty: str = "intermediate"
    points: int = 10
    tags: Optional[List[str]] = None


class QuestionUpdate(BaseModel):
    subtopicId: Optional[int] = None
    knowledgeTypeId: Optional[int] = None
    type: Optional[str] = None
    text: Optional[str] = None
    options: Optional[List[str]] = None
    correctAnswer: Optional[str] = None
    explanation: Optional[str] = None
    matchPairs: Optional[List[dict]] = None
    difficulty: Optional[str] = None
    points: Optional[int] = None
    tags: Optional[List[str]] = None
    isActive: Optional[bool] = None


# ============ Course Endpoints ============
@router.get("/courses")
async def get_courses(
    include_inactive: bool = Query(False),
    db: AsyncSession = Depends(get_session),
    admin: dict = Depends(get_admin_user)
):
    """Get all courses"""
    stmt = select(Course).options(selectinload(Course.topics))
    if not include_inactive:
        stmt = stmt.where(Course.is_active == True)
    stmt = stmt.order_by(Course.name)

    result = await db.execute(stmt)
    courses = result.scalars().all()
    return {"courses": [c.to_dict() for c in courses]}


@router.get("/courses/{course_id}")
async def get_course(
    course_id: int,
    db: AsyncSession = Depends(get_session),
    admin: dict = Depends(get_admin_user)
):
    """Get a single course by ID"""
    result = await db.execute(
        select(Course).options(selectinload(Course.topics)).where(Course.id == course_id)
    )
    course = result.scalar_one_or_none()
    if not course:
        raise HTTPException(status_code=404, detail="Course not found")
    return course.to_dict()


@router.post("/courses")
async def create_course(
    data: CourseCreate,
    db: AsyncSession = Depends(get_session),
    admin: dict = Depends(get_admin_user)
):
    """Create a new course"""
    # Check if name already exists
    existing = await db.execute(select(Course).where(Course.name == data.name))
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="Course with this name already exists")

    course = Course(
        name=data.name,
        display_name=data.displayName,
        description=data.description
    )
    db.add(course)
    await db.commit()
    await db.refresh(course)
    return course.to_dict()


@router.put("/courses/{course_id}")
async def update_course(
    course_id: int,
    data: CourseUpdate,
    db: AsyncSession = Depends(get_session),
    admin: dict = Depends(get_admin_user)
):
    """Update a course"""
    result = await db.execute(select(Course).where(Course.id == course_id))
    course = result.scalar_one_or_none()
    if not course:
        raise HTTPException(status_code=404, detail="Course not found")

    if data.name is not None:
        course.name = data.name
    if data.displayName is not None:
        course.display_name = data.displayName
    if data.description is not None:
        course.description = data.description
    if data.isActive is not None:
        course.is_active = data.isActive

    await db.commit()
    await db.refresh(course)
    return course.to_dict()


@router.delete("/courses/{course_id}")
async def delete_course(
    course_id: int,
    db: AsyncSession = Depends(get_session),
    admin: dict = Depends(get_admin_user)
):
    """Delete a course (soft delete by setting is_active=False)"""
    result = await db.execute(select(Course).where(Course.id == course_id))
    course = result.scalar_one_or_none()
    if not course:
        raise HTTPException(status_code=404, detail="Course not found")

    course.is_active = False
    await db.commit()
    return {"message": "Course deleted successfully"}


# ============ Topic Endpoints ============
@router.get("/topics")
async def get_topics(
    course_id: Optional[int] = Query(None),
    include_inactive: bool = Query(False),
    db: AsyncSession = Depends(get_session),
    admin: dict = Depends(get_admin_user)
):
    """Get all topics, optionally filtered by course"""
    stmt = select(Topic).options(selectinload(Topic.course), selectinload(Topic.subtopics))
    if course_id:
        stmt = stmt.where(Topic.course_id == course_id)
    if not include_inactive:
        stmt = stmt.where(Topic.is_active == True)
    stmt = stmt.order_by(Topic.name)

    result = await db.execute(stmt)
    topics = result.scalars().all()
    return {"topics": [t.to_dict(include_course=True) for t in topics]}


@router.get("/topics/{topic_id}")
async def get_topic(
    topic_id: int,
    db: AsyncSession = Depends(get_session),
    admin: dict = Depends(get_admin_user)
):
    """Get a single topic by ID"""
    result = await db.execute(
        select(Topic)
        .options(selectinload(Topic.course), selectinload(Topic.subtopics))
        .where(Topic.id == topic_id)
    )
    topic = result.scalar_one_or_none()
    if not topic:
        raise HTTPException(status_code=404, detail="Topic not found")
    return topic.to_dict(include_course=True)


@router.post("/topics")
async def create_topic(
    data: TopicCreate,
    db: AsyncSession = Depends(get_session),
    admin: dict = Depends(get_admin_user)
):
    """Create a new topic"""
    # Check if course exists
    course_result = await db.execute(select(Course).where(Course.id == data.courseId))
    if not course_result.scalar_one_or_none():
        raise HTTPException(status_code=404, detail="Course not found")

    topic = Topic(
        course_id=data.courseId,
        name=data.name,
        display_name=data.displayName,
        description=data.description
    )
    db.add(topic)
    await db.commit()
    await db.refresh(topic)
    return topic.to_dict()


@router.put("/topics/{topic_id}")
async def update_topic(
    topic_id: int,
    data: TopicUpdate,
    db: AsyncSession = Depends(get_session),
    admin: dict = Depends(get_admin_user)
):
    """Update a topic"""
    result = await db.execute(select(Topic).where(Topic.id == topic_id))
    topic = result.scalar_one_or_none()
    if not topic:
        raise HTTPException(status_code=404, detail="Topic not found")

    if data.courseId is not None:
        topic.course_id = data.courseId
    if data.name is not None:
        topic.name = data.name
    if data.displayName is not None:
        topic.display_name = data.displayName
    if data.description is not None:
        topic.description = data.description
    if data.isActive is not None:
        topic.is_active = data.isActive

    await db.commit()
    await db.refresh(topic)
    return topic.to_dict()


@router.delete("/topics/{topic_id}")
async def delete_topic(
    topic_id: int,
    db: AsyncSession = Depends(get_session),
    admin: dict = Depends(get_admin_user)
):
    """Delete a topic (soft delete)"""
    result = await db.execute(select(Topic).where(Topic.id == topic_id))
    topic = result.scalar_one_or_none()
    if not topic:
        raise HTTPException(status_code=404, detail="Topic not found")

    topic.is_active = False
    await db.commit()
    return {"message": "Topic deleted successfully"}


# ============ Subtopic Endpoints ============
@router.get("/subtopics")
async def get_subtopics(
    topic_id: Optional[int] = Query(None),
    course_id: Optional[int] = Query(None),
    include_inactive: bool = Query(False),
    db: AsyncSession = Depends(get_session),
    admin: dict = Depends(get_admin_user)
):
    """Get all subtopics, optionally filtered by topic or course"""
    stmt = select(Subtopic).options(
        selectinload(Subtopic.topic).selectinload(Topic.course),
        selectinload(Subtopic.questions)
    )
    if topic_id:
        stmt = stmt.where(Subtopic.topic_id == topic_id)
    if course_id:
        stmt = stmt.join(Topic).where(Topic.course_id == course_id)
    if not include_inactive:
        stmt = stmt.where(Subtopic.is_active == True)
    stmt = stmt.order_by(Subtopic.name)

    result = await db.execute(stmt)
    subtopics = result.scalars().all()
    return {"subtopics": [s.to_dict(include_topic=True) for s in subtopics]}


@router.get("/subtopics/{subtopic_id}")
async def get_subtopic(
    subtopic_id: int,
    db: AsyncSession = Depends(get_session),
    admin: dict = Depends(get_admin_user)
):
    """Get a single subtopic by ID"""
    result = await db.execute(
        select(Subtopic)
        .options(selectinload(Subtopic.topic).selectinload(Topic.course))
        .where(Subtopic.id == subtopic_id)
    )
    subtopic = result.scalar_one_or_none()
    if not subtopic:
        raise HTTPException(status_code=404, detail="Subtopic not found")
    return subtopic.to_dict(include_topic=True)


@router.post("/subtopics")
async def create_subtopic(
    data: SubtopicCreate,
    db: AsyncSession = Depends(get_session),
    admin: dict = Depends(get_admin_user)
):
    """Create a new subtopic"""
    # Check if topic exists
    topic_result = await db.execute(select(Topic).where(Topic.id == data.topicId))
    if not topic_result.scalar_one_or_none():
        raise HTTPException(status_code=404, detail="Topic not found")

    subtopic = Subtopic(
        topic_id=data.topicId,
        name=data.name,
        display_name=data.displayName,
        description=data.description
    )
    db.add(subtopic)
    await db.commit()
    await db.refresh(subtopic)
    return subtopic.to_dict()


@router.put("/subtopics/{subtopic_id}")
async def update_subtopic(
    subtopic_id: int,
    data: SubtopicUpdate,
    db: AsyncSession = Depends(get_session),
    admin: dict = Depends(get_admin_user)
):
    """Update a subtopic"""
    result = await db.execute(select(Subtopic).where(Subtopic.id == subtopic_id))
    subtopic = result.scalar_one_or_none()
    if not subtopic:
        raise HTTPException(status_code=404, detail="Subtopic not found")

    if data.topicId is not None:
        subtopic.topic_id = data.topicId
    if data.name is not None:
        subtopic.name = data.name
    if data.displayName is not None:
        subtopic.display_name = data.displayName
    if data.description is not None:
        subtopic.description = data.description
    if data.isActive is not None:
        subtopic.is_active = data.isActive

    await db.commit()
    await db.refresh(subtopic)
    return subtopic.to_dict()


@router.delete("/subtopics/{subtopic_id}")
async def delete_subtopic(
    subtopic_id: int,
    db: AsyncSession = Depends(get_session),
    admin: dict = Depends(get_admin_user)
):
    """Delete a subtopic (soft delete)"""
    result = await db.execute(select(Subtopic).where(Subtopic.id == subtopic_id))
    subtopic = result.scalar_one_or_none()
    if not subtopic:
        raise HTTPException(status_code=404, detail="Subtopic not found")

    subtopic.is_active = False
    await db.commit()
    return {"message": "Subtopic deleted successfully"}


# ============ Knowledge Type Endpoints ============
@router.get("/knowledge-types")
async def get_knowledge_types(
    include_inactive: bool = Query(False),
    db: AsyncSession = Depends(get_session),
    admin: dict = Depends(get_admin_user)
):
    """Get all knowledge types"""
    stmt = select(KnowledgeType)
    if not include_inactive:
        stmt = stmt.where(KnowledgeType.is_active == True)
    stmt = stmt.order_by(KnowledgeType.name)

    result = await db.execute(stmt)
    knowledge_types = result.scalars().all()
    return {"knowledgeTypes": [kt.to_dict() for kt in knowledge_types]}


@router.post("/knowledge-types")
async def create_knowledge_type(
    data: KnowledgeTypeCreate,
    db: AsyncSession = Depends(get_session),
    admin: dict = Depends(get_admin_user)
):
    """Create a new knowledge type"""
    # Check if name already exists
    existing = await db.execute(select(KnowledgeType).where(KnowledgeType.name == data.name))
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="Knowledge type with this name already exists")

    kt = KnowledgeType(
        name=data.name,
        display_name=data.displayName,
        description=data.description
    )
    db.add(kt)
    await db.commit()
    await db.refresh(kt)
    return kt.to_dict()


@router.put("/knowledge-types/{kt_id}")
async def update_knowledge_type(
    kt_id: int,
    data: KnowledgeTypeUpdate,
    db: AsyncSession = Depends(get_session),
    admin: dict = Depends(get_admin_user)
):
    """Update a knowledge type"""
    result = await db.execute(select(KnowledgeType).where(KnowledgeType.id == kt_id))
    kt = result.scalar_one_or_none()
    if not kt:
        raise HTTPException(status_code=404, detail="Knowledge type not found")

    if data.name is not None:
        kt.name = data.name
    if data.displayName is not None:
        kt.display_name = data.displayName
    if data.description is not None:
        kt.description = data.description
    if data.isActive is not None:
        kt.is_active = data.isActive

    await db.commit()
    await db.refresh(kt)
    return kt.to_dict()


@router.post("/knowledge-types/seed")
async def seed_knowledge_types(
    db: AsyncSession = Depends(get_session),
    admin: dict = Depends(get_admin_user)
):
    """Seed default knowledge types"""
    created = []
    for kt_data in DEFAULT_KNOWLEDGE_TYPES:
        existing = await db.execute(select(KnowledgeType).where(KnowledgeType.name == kt_data["name"]))
        if not existing.scalar_one_or_none():
            kt = KnowledgeType(
                name=kt_data["name"],
                display_name=kt_data["display_name"],
                description=kt_data["description"]
            )
            db.add(kt)
            created.append(kt_data["name"])

    await db.commit()
    return {"message": f"Created {len(created)} knowledge types", "created": created}


# ============ Question Endpoints ============
@router.get("/questions")
async def get_questions(
    subtopic_id: Optional[int] = Query(None),
    topic_id: Optional[int] = Query(None),
    course_id: Optional[int] = Query(None),
    knowledge_type_id: Optional[int] = Query(None),
    question_type: Optional[str] = Query(None),
    include_inactive: bool = Query(False),
    limit: int = Query(50, ge=1, le=500),
    offset: int = Query(0, ge=0),
    db: AsyncSession = Depends(get_session),
    admin: dict = Depends(get_admin_user)
):
    """Get questions with filters"""
    stmt = select(Question).options(
        selectinload(Question.subtopic_rel).selectinload(Subtopic.topic).selectinload(Topic.course),
        selectinload(Question.knowledge_type_rel)
    )

    if subtopic_id:
        stmt = stmt.where(Question.subtopic_id == subtopic_id)
    if topic_id:
        stmt = stmt.join(Subtopic).where(Subtopic.topic_id == topic_id)
    if course_id:
        stmt = stmt.join(Subtopic).join(Topic).where(Topic.course_id == course_id)
    if knowledge_type_id:
        stmt = stmt.where(Question.knowledge_type_id == knowledge_type_id)
    if question_type:
        stmt = stmt.where(Question.type == question_type)
    if not include_inactive:
        stmt = stmt.where(Question.is_active == True)

    # Count total
    count_stmt = select(func.count()).select_from(stmt.subquery())
    total_result = await db.execute(count_stmt)
    total = total_result.scalar()

    # Apply pagination
    stmt = stmt.order_by(Question.created_at.desc()).offset(offset).limit(limit)

    result = await db.execute(stmt)
    questions = result.scalars().all()

    return {
        "questions": [q.to_dict(include_relations=True) for q in questions],
        "total": total,
        "limit": limit,
        "offset": offset
    }


@router.get("/questions/{question_id}")
async def get_question(
    question_id: int,
    db: AsyncSession = Depends(get_session),
    admin: dict = Depends(get_admin_user)
):
    """Get a single question by database ID"""
    result = await db.execute(
        select(Question)
        .options(
            selectinload(Question.subtopic_rel).selectinload(Subtopic.topic).selectinload(Topic.course),
            selectinload(Question.knowledge_type_rel)
        )
        .where(Question.id == question_id)
    )
    question = result.scalar_one_or_none()
    if not question:
        raise HTTPException(status_code=404, detail="Question not found")
    return question.to_dict(include_relations=True)


@router.post("/questions")
async def create_question(
    data: QuestionCreate,
    db: AsyncSession = Depends(get_session),
    admin: dict = Depends(get_admin_user)
):
    """Create a new question"""
    # Validate subtopic exists
    subtopic_result = await db.execute(
        select(Subtopic)
        .options(selectinload(Subtopic.topic).selectinload(Topic.course))
        .where(Subtopic.id == data.subtopicId)
    )
    subtopic = subtopic_result.scalar_one_or_none()
    if not subtopic:
        raise HTTPException(status_code=404, detail="Subtopic not found")

    # Validate knowledge type exists
    kt_result = await db.execute(select(KnowledgeType).where(KnowledgeType.id == data.knowledgeTypeId))
    knowledge_type = kt_result.scalar_one_or_none()
    if not knowledge_type:
        raise HTTPException(status_code=404, detail="Knowledge type not found")

    # Generate question_id
    question_id = f"{subtopic.topic.course.name}_{subtopic.topic.name}_{data.type}_{uuid.uuid4().hex[:8]}"

    question = Question(
        question_id=question_id,
        subtopic_id=data.subtopicId,
        knowledge_type_id=data.knowledgeTypeId,
        type=data.type,
        text=data.text,
        options=data.options,
        correct_answer=data.correctAnswer,
        explanation=data.explanation,
        match_pairs=data.matchPairs,
        difficulty=data.difficulty,
        points=data.points,
        tags=data.tags,
        # Legacy fields for backward compatibility
        course=subtopic.topic.course.name,
        subject=subtopic.topic.course.name,
        topic=subtopic.topic.name,
        subtopic=subtopic.name,
        knowledge_type=knowledge_type.name
    )
    db.add(question)
    await db.commit()
    await db.refresh(question)
    return question.to_dict()


@router.put("/questions/{question_id}")
async def update_question(
    question_id: int,
    data: QuestionUpdate,
    db: AsyncSession = Depends(get_session),
    admin: dict = Depends(get_admin_user)
):
    """Update a question"""
    result = await db.execute(select(Question).where(Question.id == question_id))
    question = result.scalar_one_or_none()
    if not question:
        raise HTTPException(status_code=404, detail="Question not found")

    if data.subtopicId is not None:
        # Validate and update legacy fields too
        subtopic_result = await db.execute(
            select(Subtopic)
            .options(selectinload(Subtopic.topic).selectinload(Topic.course))
            .where(Subtopic.id == data.subtopicId)
        )
        subtopic = subtopic_result.scalar_one_or_none()
        if not subtopic:
            raise HTTPException(status_code=404, detail="Subtopic not found")
        question.subtopic_id = data.subtopicId
        question.course = subtopic.topic.course.name
        question.subject = subtopic.topic.course.name
        question.topic = subtopic.topic.name
        question.subtopic = subtopic.name

    if data.knowledgeTypeId is not None:
        kt_result = await db.execute(select(KnowledgeType).where(KnowledgeType.id == data.knowledgeTypeId))
        kt = kt_result.scalar_one_or_none()
        if not kt:
            raise HTTPException(status_code=404, detail="Knowledge type not found")
        question.knowledge_type_id = data.knowledgeTypeId
        question.knowledge_type = kt.name

    if data.type is not None:
        question.type = data.type
    if data.text is not None:
        question.text = data.text
    if data.options is not None:
        question.options = data.options
    if data.correctAnswer is not None:
        question.correct_answer = data.correctAnswer
    if data.explanation is not None:
        question.explanation = data.explanation
    if data.matchPairs is not None:
        question.match_pairs = data.matchPairs
    if data.difficulty is not None:
        question.difficulty = data.difficulty
    if data.points is not None:
        question.points = data.points
    if data.tags is not None:
        question.tags = data.tags
    if data.isActive is not None:
        question.is_active = data.isActive

    await db.commit()
    await db.refresh(question)
    return question.to_dict()


@router.delete("/questions/{question_id}")
async def delete_question(
    question_id: int,
    db: AsyncSession = Depends(get_session),
    admin: dict = Depends(get_admin_user)
):
    """Delete a question (soft delete)"""
    result = await db.execute(select(Question).where(Question.id == question_id))
    question = result.scalar_one_or_none()
    if not question:
        raise HTTPException(status_code=404, detail="Question not found")

    question.is_active = False
    await db.commit()
    return {"message": "Question deleted successfully"}


# ============ Stats Endpoint ============
@router.get("/stats")
async def get_admin_stats(
    db: AsyncSession = Depends(get_session),
    admin: dict = Depends(get_admin_user)
):
    """Get admin dashboard statistics"""
    # Count courses
    course_count = await db.execute(select(func.count(Course.id)).where(Course.is_active == True))
    courses = course_count.scalar()

    # Count topics
    topic_count = await db.execute(select(func.count(Topic.id)).where(Topic.is_active == True))
    topics = topic_count.scalar()

    # Count subtopics
    subtopic_count = await db.execute(select(func.count(Subtopic.id)).where(Subtopic.is_active == True))
    subtopics = subtopic_count.scalar()

    # Count questions
    question_count = await db.execute(select(func.count(Question.id)).where(Question.is_active == True))
    questions = question_count.scalar()

    # Questions by type
    type_stats = await db.execute(
        select(Question.type, func.count(Question.id))
        .where(Question.is_active == True)
        .group_by(Question.type)
    )
    questions_by_type = {t: c for t, c in type_stats.fetchall()}

    return {
        "courses": courses,
        "topics": topics,
        "subtopics": subtopics,
        "questions": questions,
        "questionsByType": questions_by_type
    }
