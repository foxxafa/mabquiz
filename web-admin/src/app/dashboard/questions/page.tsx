"use client";

import { useState, useEffect } from "react";
import {
  adminQuestionsApi,
  adminSubtopicsApi,
  adminTopicsApi,
  adminCoursesApi,
  adminKnowledgeTypesApi,
  adminAIApi,
  Question,
  Subtopic,
  Topic,
  Course,
  KnowledgeType,
  AIAnalysisResult,
} from "@/lib/api";

const QUESTION_TYPES = [
  { value: "multiple_choice", label: "Coktan Secmeli" },
  { value: "true_false", label: "Dogru/Yanlis" },
  { value: "fill_in_blank", label: "Bosluk Doldurma" },
];

export default function QuestionsPage() {
  const [questions, setQuestions] = useState<Question[]>([]);
  const [subtopics, setSubtopics] = useState<Subtopic[]>([]);
  const [topics, setTopics] = useState<Topic[]>([]);
  const [courses, setCourses] = useState<Course[]>([]);
  const [knowledgeTypes, setKnowledgeTypes] = useState<KnowledgeType[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [showModal, setShowModal] = useState(false);
  const [editingQuestion, setEditingQuestion] = useState<Question | null>(null);
  const [saving, setSaving] = useState(false);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(0);
  const pageSize = 20;

  // Filters
  const [filterCourseId, setFilterCourseId] = useState<number | undefined>(undefined);
  const [filterTopicId, setFilterTopicId] = useState<number | undefined>(undefined);
  const [filterSubtopicId, setFilterSubtopicId] = useState<number | undefined>(undefined);
  const [filterType, setFilterType] = useState<string | undefined>(undefined);

  // AI Mode - varsayilan acik
  const [aiMode, setAiMode] = useState(true);
  const [aiCourseId, setAiCourseId] = useState<number>(0);
  const [aiQuestionText, setAiQuestionText] = useState("");
  const [aiAnalyzing, setAiAnalyzing] = useState(false);
  const [aiResult, setAiResult] = useState<AIAnalysisResult | null>(null);

  // Manual Form data
  const [formData, setFormData] = useState({
    subtopicId: 0,
    knowledgeTypeId: 0,
    type: "multiple_choice",
    text: "",
    options: ["", "", "", ""],
    correctAnswer: "",
    explanation: "",
    points: 10,
  });

  useEffect(() => {
    loadInitialData();
  }, []);

  useEffect(() => {
    loadQuestions();
  }, [filterCourseId, filterTopicId, filterSubtopicId, filterType, page]);

  const loadInitialData = async () => {
    setLoading(true);
    const [coursesR, topicsR, subtopicsR, ktR] = await Promise.all([
      adminCoursesApi.getAll(),
      adminTopicsApi.getAll(),
      adminSubtopicsApi.getAll(),
      adminKnowledgeTypesApi.getAll(),
    ]);
    if (coursesR.data) setCourses(coursesR.data.courses);
    if (topicsR.data) setTopics(topicsR.data.topics);
    if (subtopicsR.data) setSubtopics(subtopicsR.data.subtopics);
    if (ktR.data) setKnowledgeTypes(ktR.data.knowledgeTypes);

    // Seed knowledge types if empty
    if (ktR.data && ktR.data.knowledgeTypes.length === 0) {
      await adminKnowledgeTypesApi.seed();
      const newKt = await adminKnowledgeTypesApi.getAll();
      if (newKt.data) setKnowledgeTypes(newKt.data.knowledgeTypes);
    }

    await loadQuestions();
    setLoading(false);
  };

  const loadQuestions = async () => {
    const result = await adminQuestionsApi.getAll({
      courseId: filterCourseId,
      topicId: filterTopicId,
      subtopicId: filterSubtopicId,
      questionType: filterType,
      includeInactive: true,
      limit: pageSize,
      offset: page * pageSize,
    });
    if (result.error) {
      setError(result.error);
    } else if (result.data) {
      setQuestions(result.data.questions);
      setTotal(result.data.total);
    }
  };

  const openModal = (question?: Question) => {
    setAiResult(null);
    setAiQuestionText("");
    setAiCourseId(courses[0]?.id || 0);
    setError("");

    if (question) {
      // Duzenleme modunda AI kapali
      setAiMode(false);
      setEditingQuestion(question);
      setFormData({
        subtopicId: question.subtopicId || 0,
        knowledgeTypeId: question.knowledgeTypeId || 0,
        type: question.type,
        text: question.text,
        options: question.options || ["", "", "", ""],
        correctAnswer: question.correctAnswer,
        explanation: question.explanation || "",
        points: question.points,
      });
    } else {
      // Yeni soru - AI varsayilan acik
      setAiMode(true);
      setEditingQuestion(null);
      setFormData({
        subtopicId: subtopics[0]?.id || 0,
        knowledgeTypeId: knowledgeTypes[0]?.id || 0,
        type: "multiple_choice",
        text: "",
        options: ["", "", "", ""],
        correctAnswer: "",
        explanation: "",
        points: 10,
      });
    }
    setShowModal(true);
  };

  const closeModal = () => {
    setShowModal(false);
    setEditingQuestion(null);
    setAiResult(null);
    setError("");
  };

  // AI Analysis
  const handleAIAnalyze = async () => {
    if (!aiCourseId || !aiQuestionText.trim()) {
      setError("Ders secin ve soru metnini girin");
      return;
    }

    setAiAnalyzing(true);
    setError("");
    setAiResult(null);

    const result = await adminAIApi.analyzeQuestion(aiCourseId, aiQuestionText);

    if (result.error) {
      setError(result.error);
    } else if (result.data) {
      if (result.data.success) {
        setAiResult(result.data);
      } else {
        setError(result.data.error || "AI analiz hatasi");
      }
    }
    setAiAnalyzing(false);
  };

  // AI Create
  const handleAICreate = async () => {
    if (!aiResult) return;

    setSaving(true);
    setError("");

    const result = await adminAIApi.createWithAI({
      courseId: aiCourseId,
      topic: {
        id: aiResult.topic?.id || null,
        name: aiResult.topic?.name || "",
        displayName: aiResult.topic?.displayName || "",
      },
      subtopic: {
        id: aiResult.subtopic?.id || null,
        name: aiResult.subtopic?.name || "",
        displayName: aiResult.subtopic?.displayName || "",
      },
      knowledgeTypeId: aiResult.knowledgeType?.id || 9,
      questionText: aiResult.questionText || aiQuestionText,
      questionType: aiResult.questionType || "multiple_choice",
      correctAnswer: aiResult.correctAnswer || "",
      options: aiResult.options,
      explanation: aiResult.explanation,
    });

    if (result.error) {
      setError(result.error);
    } else if (result.data?.success) {
      closeModal();
      loadQuestions();
      // Reload topics/subtopics if new ones were created
      if (result.data.topicCreated || result.data.subtopicCreated) {
        const [topicsR, subtopicsR] = await Promise.all([
          adminTopicsApi.getAll(),
          adminSubtopicsApi.getAll(),
        ]);
        if (topicsR.data) setTopics(topicsR.data.topics);
        if (subtopicsR.data) setSubtopics(subtopicsR.data.subtopics);
      }
    }
    setSaving(false);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSaving(true);
    setError("");

    const payload: any = {
      subtopicId: formData.subtopicId,
      knowledgeTypeId: formData.knowledgeTypeId,
      type: formData.type,
      text: formData.text,
      correctAnswer: formData.correctAnswer,
      explanation: formData.explanation || undefined,
      points: formData.points,
    };

    if (formData.type === "multiple_choice") {
      payload.options = formData.options.filter((o) => o.trim() !== "");
    }

    let result;
    if (editingQuestion) {
      result = await adminQuestionsApi.update(editingQuestion.dbId, payload);
    } else {
      result = await adminQuestionsApi.create(payload);
    }

    if (result.error) {
      setError(result.error);
    } else {
      closeModal();
      loadQuestions();
    }
    setSaving(false);
  };

  const handleDelete = async (question: Question) => {
    if (!confirm("Bu soruyu silmek istediginizden emin misiniz?")) {
      return;
    }

    const result = await adminQuestionsApi.delete(question.dbId);
    if (result.error) {
      setError(result.error);
    } else {
      loadQuestions();
    }
  };

  const toggleActive = async (question: Question) => {
    const result = await adminQuestionsApi.update(question.dbId, { isActive: !question.isActive });
    if (result.error) {
      setError(result.error);
    } else {
      loadQuestions();
    }
  };

  const getTypeLabel = (type: string) => {
    return QUESTION_TYPES.find((t) => t.value === type)?.label || type;
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
      </div>
    );
  }

  const totalPages = Math.ceil(total / pageSize);

  return (
    <div>
      {/* Header */}
      <div className="flex justify-between items-center mb-8">
        <div>
          <h1 className="text-2xl font-bold text-white">Sorular</h1>
          <p className="text-gray-500 mt-1">Toplam {total} soru</p>
        </div>
        <button
          onClick={() => openModal()}
          disabled={courses.length === 0}
          className="px-4 py-2 bg-primary text-white rounded-lg hover:bg-primary/90 transition-colors flex items-center gap-2 disabled:opacity-50"
        >
          <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
          </svg>
          Yeni Soru
        </button>
      </div>

      {/* Filters */}
      <div className="mb-6 flex flex-wrap gap-4">
        <select
          value={filterCourseId || ""}
          onChange={(e) => {
            setFilterCourseId(e.target.value ? Number(e.target.value) : undefined);
            setFilterTopicId(undefined);
            setFilterSubtopicId(undefined);
            setPage(0);
          }}
          className="px-4 py-2 bg-surface-light border border-gray-700 rounded-lg text-white focus:outline-none focus:border-primary"
        >
          <option value="">Tum Dersler</option>
          {courses.map((c) => (
            <option key={c.id} value={c.id}>{c.displayName}</option>
          ))}
        </select>

        <select
          value={filterTopicId || ""}
          onChange={(e) => {
            setFilterTopicId(e.target.value ? Number(e.target.value) : undefined);
            setFilterSubtopicId(undefined);
            setPage(0);
          }}
          className="px-4 py-2 bg-surface-light border border-gray-700 rounded-lg text-white focus:outline-none focus:border-primary"
        >
          <option value="">Tum Konular</option>
          {topics
            .filter((t) => !filterCourseId || t.courseId === filterCourseId)
            .map((t) => (
              <option key={t.id} value={t.id}>{t.displayName}</option>
            ))}
        </select>

        <select
          value={filterSubtopicId || ""}
          onChange={(e) => {
            setFilterSubtopicId(e.target.value ? Number(e.target.value) : undefined);
            setPage(0);
          }}
          className="px-4 py-2 bg-surface-light border border-gray-700 rounded-lg text-white focus:outline-none focus:border-primary"
        >
          <option value="">Tum Alt Konular</option>
          {subtopics
            .filter((s) => !filterTopicId || s.topicId === filterTopicId)
            .map((s) => (
              <option key={s.id} value={s.id}>{s.displayName}</option>
            ))}
        </select>

        <select
          value={filterType || ""}
          onChange={(e) => {
            setFilterType(e.target.value || undefined);
            setPage(0);
          }}
          className="px-4 py-2 bg-surface-light border border-gray-700 rounded-lg text-white focus:outline-none focus:border-primary"
        >
          <option value="">Tum Tipler</option>
          {QUESTION_TYPES.map((t) => (
            <option key={t.value} value={t.value}>{t.label}</option>
          ))}
        </select>
      </div>

      {/* Error */}
      {error && (
        <div className="mb-4 p-3 bg-red-500/10 border border-red-500/20 rounded-lg text-red-400 text-sm">
          {error}
        </div>
      )}

      {courses.length === 0 ? (
        <div className="bg-surface rounded-xl border border-gray-800 p-8 text-center">
          <p className="text-gray-500">Oncelikle bir ders eklemeniz gerekiyor.</p>
          <a href="/dashboard/courses" className="text-primary hover:underline mt-2 inline-block">
            Baslayalim
          </a>
        </div>
      ) : (
        <>
          {/* Table */}
          <div className="bg-surface rounded-xl border border-gray-800 overflow-hidden">
            <table className="w-full">
              <thead className="bg-surface-light">
                <tr>
                  <th className="px-6 py-4 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">Soru</th>
                  <th className="px-6 py-4 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">Tip</th>
                  <th className="px-6 py-4 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">Konum</th>
                  <th className="px-6 py-4 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">Durum</th>
                  <th className="px-6 py-4 text-right text-xs font-medium text-gray-400 uppercase tracking-wider">Islemler</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-800">
                {questions.length === 0 ? (
                  <tr>
                    <td colSpan={5} className="px-6 py-8 text-center text-gray-500">
                      Henuz soru eklenmemis
                    </td>
                  </tr>
                ) : (
                  questions.map((q) => (
                    <tr key={q.dbId} className={!q.isActive ? "opacity-50" : ""}>
                      <td className="px-6 py-4">
                        <div className="text-white text-sm max-w-md truncate">{q.text}</div>
                        <div className="text-gray-500 text-xs mt-1">
                          Cevap: {q.correctAnswer}
                        </div>
                      </td>
                      <td className="px-6 py-4">
                        <span className="px-2 py-1 bg-purple-500/20 text-purple-400 rounded text-xs">
                          {getTypeLabel(q.type)}
                        </span>
                      </td>
                      <td className="px-6 py-4">
                        <div className="text-gray-400 text-xs">
                          {q.courseInfo?.displayName || q.course}
                        </div>
                        <div className="text-gray-500 text-xs">
                          {q.topicInfo?.displayName || q.topic} / {q.subtopicInfo?.displayName || q.subtopic}
                        </div>
                      </td>
                      <td className="px-6 py-4">
                        <button
                          onClick={() => toggleActive(q)}
                          className={`px-2 py-1 rounded text-xs font-medium ${
                            q.isActive
                              ? "bg-green-500/20 text-green-400"
                              : "bg-red-500/20 text-red-400"
                          }`}
                        >
                          {q.isActive ? "Aktif" : "Pasif"}
                        </button>
                      </td>
                      <td className="px-6 py-4 text-right">
                        <button
                          onClick={() => openModal(q)}
                          className="text-gray-400 hover:text-white mr-3"
                        >
                          <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                          </svg>
                        </button>
                        <button
                          onClick={() => handleDelete(q)}
                          className="text-red-400 hover:text-red-300"
                        >
                          <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                          </svg>
                        </button>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>

          {/* Pagination */}
          {totalPages > 1 && (
            <div className="mt-4 flex justify-center gap-2">
              <button
                onClick={() => setPage(Math.max(0, page - 1))}
                disabled={page === 0}
                className="px-3 py-1 bg-surface-light border border-gray-700 rounded text-gray-400 disabled:opacity-50"
              >
                Onceki
              </button>
              <span className="px-3 py-1 text-gray-400">
                Sayfa {page + 1} / {totalPages}
              </span>
              <button
                onClick={() => setPage(Math.min(totalPages - 1, page + 1))}
                disabled={page >= totalPages - 1}
                className="px-3 py-1 bg-surface-light border border-gray-700 rounded text-gray-400 disabled:opacity-50"
              >
                Sonraki
              </button>
            </div>
          )}
        </>
      )}

      {/* Modal */}
      {showModal && (
        <div className="fixed inset-0 bg-black/50 flex items-start justify-center z-50 overflow-y-auto py-4">
          <div className="bg-surface rounded-xl w-full max-w-2xl border border-gray-800 mx-4 my-auto max-h-[90vh] flex flex-col">
            {/* Modal Header - Fixed */}
            <div className="flex justify-between items-center p-5 border-b border-gray-800 shrink-0">
              <div className="flex items-center gap-3">
                <h2 className="text-xl font-bold text-white">
                  {editingQuestion ? "Soru Duzenle" : "Yeni Soru Ekle"}
                </h2>
                {/* Close button */}
                <button
                  onClick={closeModal}
                  className="text-gray-500 hover:text-white transition-colors ml-2"
                >
                  <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                  </svg>
                </button>
              </div>

              {/* Mode Toggle - only for new questions */}
              {!editingQuestion && (
                <div className="flex bg-surface-light rounded-lg p-1">
                  <button
                    type="button"
                    onClick={() => {
                      setAiMode(true);
                      setAiResult(null);
                      setError("");
                    }}
                    className={`px-4 py-2 rounded-md text-sm font-medium transition-all flex items-center gap-2 ${
                      aiMode
                        ? 'bg-gradient-to-r from-purple-600 to-blue-600 text-white shadow-lg'
                        : 'text-gray-400 hover:text-white'
                    }`}
                  >
                    <svg className="w-4 h-4" viewBox="0 0 24 24" fill="currentColor">
                      <path d="M12 2a2 2 0 012 2c0 .74-.4 1.39-1 1.73V7h1a7 7 0 017 7h1a1 1 0 011 1v3a1 1 0 01-1 1h-1v1a2 2 0 01-2 2H5a2 2 0 01-2-2v-1H2a1 1 0 01-1-1v-3a1 1 0 011-1h1a7 7 0 017-7h1V5.73c-.6-.34-1-.99-1-1.73a2 2 0 012-2M7.5 13A2.5 2.5 0 005 15.5 2.5 2.5 0 007.5 18a2.5 2.5 0 002.5-2.5A2.5 2.5 0 007.5 13m9 0a2.5 2.5 0 00-2.5 2.5 2.5 2.5 0 002.5 2.5 2.5 2.5 0 002.5-2.5 2.5 2.5 0 00-2.5-2.5z"/>
                    </svg>
                    AI Destekli
                  </button>
                  <button
                    type="button"
                    onClick={() => {
                      setAiMode(false);
                      setAiResult(null);
                      setError("");
                    }}
                    className={`px-4 py-2 rounded-md text-sm font-medium transition-all flex items-center gap-2 ${
                      !aiMode
                        ? 'bg-gray-700 text-white'
                        : 'text-gray-400 hover:text-white'
                    }`}
                  >
                    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                    </svg>
                    Manuel
                  </button>
                </div>
              )}
            </div>

            {/* Modal Body - Scrollable */}
            <div className="p-5 overflow-y-auto flex-1">
              {/* Error */}
              {error && (
                <div className="mb-4 p-3 bg-red-500/10 border border-red-500/20 rounded-lg text-red-400 text-sm">
                  {error}
                </div>
              )}

              {/* AI Mode */}
              {aiMode && !editingQuestion ? (
                <div>
                  {/* Step 1: Course + Question Text */}
                  {!aiResult && (
                    <>
                      <div className="mb-4">
                        <label className="block text-sm font-medium text-gray-400 mb-2">Ders Secin</label>
                        <select
                          value={aiCourseId}
                          onChange={(e) => setAiCourseId(Number(e.target.value))}
                          className="w-full px-4 py-3 bg-surface-light border border-gray-700 rounded-lg text-white focus:outline-none focus:border-primary"
                        >
                          <option value={0}>Secin</option>
                          {courses.map((c) => (
                            <option key={c.id} value={c.id}>{c.displayName}</option>
                          ))}
                        </select>
                      </div>

                      <div className="mb-4">
                        <label className="block text-sm font-medium text-gray-400 mb-2">
                          Soru Metnini Yapistirin
                        </label>
                        <textarea
                          value={aiQuestionText}
                          onChange={(e) => setAiQuestionText(e.target.value)}
                          className="w-full px-4 py-3 bg-surface-light border border-gray-700 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:border-primary resize-none"
                          rows={8}
                          placeholder="Soruyu buraya yapistirin... (Secenekler dahil)"
                        />
                      </div>

                      <div className="flex gap-3">
                        <button
                          type="button"
                          onClick={closeModal}
                          className="flex-1 px-4 py-3 border border-gray-700 text-gray-400 rounded-lg hover:bg-surface-light transition-colors"
                        >
                          Iptal
                        </button>
                        <button
                          type="button"
                          onClick={handleAIAnalyze}
                          disabled={aiAnalyzing || !aiCourseId || !aiQuestionText.trim()}
                          className="flex-1 px-4 py-3 bg-gradient-to-r from-purple-600 to-blue-600 text-white rounded-lg hover:opacity-90 transition-colors disabled:opacity-50 flex items-center justify-center gap-2"
                        >
                          {aiAnalyzing ? (
                            <>
                              <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white"></div>
                              Analiz Ediliyor...
                            </>
                          ) : (
                            <>
                              <svg className="w-5 h-5" viewBox="0 0 24 24" fill="currentColor">
                                <path d="M12 2a2 2 0 012 2c0 .74-.4 1.39-1 1.73V7h1a7 7 0 017 7h1a1 1 0 011 1v3a1 1 0 01-1 1h-1v1a2 2 0 01-2 2H5a2 2 0 01-2-2v-1H2a1 1 0 01-1-1v-3a1 1 0 011-1h1a7 7 0 017-7h1V5.73c-.6-.34-1-.99-1-1.73a2 2 0 012-2z"/>
                              </svg>
                              AI ile Analiz Et
                            </>
                          )}
                        </button>
                      </div>
                    </>
                  )}

                  {/* Step 2: Show AI Results */}
                  {aiResult && (
                    <>
                      <div className="bg-gradient-to-r from-purple-900/30 to-blue-900/30 rounded-lg p-4 mb-4 border border-purple-500/30">
                        <h3 className="text-sm font-medium text-purple-400 mb-3 flex items-center gap-2">
                          <svg className="w-5 h-5" viewBox="0 0 24 24" fill="currentColor">
                            <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/>
                          </svg>
                          AI Analiz Sonucu
                        </h3>

                        <div className="grid grid-cols-2 gap-3 text-sm">
                          <div>
                            <span className="text-gray-500">Konu:</span>
                            <span className={`ml-2 ${aiResult.topic?.isNew ? 'text-green-400' : 'text-white'}`}>
                              {aiResult.topic?.displayName}
                              {aiResult.topic?.isNew && <span className="ml-1 text-xs bg-green-500/20 px-1 rounded">YENi</span>}
                            </span>
                          </div>
                          <div>
                            <span className="text-gray-500">Alt Konu:</span>
                            <span className={`ml-2 ${aiResult.subtopic?.isNew ? 'text-green-400' : 'text-white'}`}>
                              {aiResult.subtopic?.displayName}
                              {aiResult.subtopic?.isNew && <span className="ml-1 text-xs bg-green-500/20 px-1 rounded">YENi</span>}
                            </span>
                          </div>
                          <div>
                            <span className="text-gray-500">Bilgi Turu:</span>
                            <span className="ml-2 text-white">{aiResult.knowledgeType?.displayName}</span>
                          </div>
                          <div>
                            <span className="text-gray-500">Soru Tipi:</span>
                            <span className="ml-2 text-white">{getTypeLabel(aiResult.questionType || 'multiple_choice')}</span>
                          </div>
                          <div className="col-span-2">
                            <span className="text-gray-500">Dogru Cevap:</span>
                            <span className="ml-2 text-green-400 font-medium">{aiResult.correctAnswer}</span>
                          </div>
                          {aiResult.options && aiResult.options.length > 0 && (
                            <div className="col-span-2">
                              <span className="text-gray-500">Secenekler:</span>
                              <div className="mt-1 space-y-1">
                                {aiResult.options.map((opt, i) => (
                                  <div key={i} className="text-gray-300 text-xs pl-2">
                                    {String.fromCharCode(65 + i)}) {opt}
                                  </div>
                                ))}
                              </div>
                            </div>
                          )}
                          {aiResult.explanation && (
                            <div className="col-span-2">
                              <span className="text-gray-500">Aciklama:</span>
                              <div className="mt-1 text-gray-300 text-xs">{aiResult.explanation}</div>
                            </div>
                          )}
                        </div>
                      </div>

                      <div className="bg-surface-light rounded-lg p-3 mb-4">
                        <div className="text-gray-500 text-xs mb-1">Soru Metni:</div>
                        <div className="text-white text-sm whitespace-pre-wrap">{aiResult?.questionText || aiQuestionText}</div>
                      </div>

                      <div className="flex gap-3">
                        <button
                          type="button"
                          onClick={() => {
                            setAiResult(null);
                            setError("");
                          }}
                          className="flex-1 px-4 py-3 border border-gray-700 text-gray-400 rounded-lg hover:bg-surface-light transition-colors"
                        >
                          Geri
                        </button>
                        <button
                          type="button"
                          onClick={handleAICreate}
                          disabled={saving}
                          className="flex-1 px-4 py-3 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors disabled:opacity-50"
                        >
                          {saving ? "Kaydediliyor..." : "Onayla ve Kaydet"}
                        </button>
                      </div>
                    </>
                  )}
                </div>
              ) : (
                /* Manual Mode - Compact Layout */
                <form onSubmit={handleSubmit}>
                  {/* Row 1: Alt Konu + Bilgi Turu */}
                  <div className="grid grid-cols-2 gap-3 mb-3">
                    <div>
                      <label className="block text-xs font-medium text-gray-400 mb-1">Alt Konu</label>
                      <select
                        value={formData.subtopicId}
                        onChange={(e) => setFormData({ ...formData, subtopicId: Number(e.target.value) })}
                        className="w-full px-3 py-2 bg-surface-light border border-gray-700 rounded-lg text-white text-sm focus:outline-none focus:border-primary"
                        required
                      >
                        <option value={0}>Secin</option>
                        {subtopics.map((s) => (
                          <option key={s.id} value={s.id}>
                            {s.course?.displayName} - {s.topic?.displayName} - {s.displayName}
                          </option>
                        ))}
                      </select>
                    </div>
                    <div>
                      <label className="block text-xs font-medium text-gray-400 mb-1">Bilgi Turu</label>
                      <select
                        value={formData.knowledgeTypeId}
                        onChange={(e) => setFormData({ ...formData, knowledgeTypeId: Number(e.target.value) })}
                        className="w-full px-3 py-2 bg-surface-light border border-gray-700 rounded-lg text-white text-sm focus:outline-none focus:border-primary"
                        required
                      >
                        <option value={0}>Secin</option>
                        {knowledgeTypes.map((kt) => (
                          <option key={kt.id} value={kt.id}>{kt.displayName}</option>
                        ))}
                      </select>
                    </div>
                  </div>

                  {/* Row 2: Soru Tipi + Puan */}
                  <div className="grid grid-cols-2 gap-3 mb-3">
                    <div>
                      <label className="block text-xs font-medium text-gray-400 mb-1">Soru Tipi</label>
                      <select
                        value={formData.type}
                        onChange={(e) => setFormData({ ...formData, type: e.target.value })}
                        className="w-full px-3 py-2 bg-surface-light border border-gray-700 rounded-lg text-white text-sm focus:outline-none focus:border-primary"
                      >
                        {QUESTION_TYPES.map((t) => (
                          <option key={t.value} value={t.value}>{t.label}</option>
                        ))}
                      </select>
                    </div>
                    <div>
                      <label className="block text-xs font-medium text-gray-400 mb-1">Puan</label>
                      <input
                        type="number"
                        value={formData.points}
                        onChange={(e) => setFormData({ ...formData, points: Number(e.target.value) })}
                        className="w-full px-3 py-2 bg-surface-light border border-gray-700 rounded-lg text-white text-sm focus:outline-none focus:border-primary"
                        min={1}
                      />
                    </div>
                  </div>

                  {/* Soru Metni */}
                  <div className="mb-3">
                    <label className="block text-xs font-medium text-gray-400 mb-1">Soru Metni</label>
                    <textarea
                      value={formData.text}
                      onChange={(e) => setFormData({ ...formData, text: e.target.value })}
                      className="w-full px-3 py-2 bg-surface-light border border-gray-700 rounded-lg text-white placeholder-gray-500 text-sm focus:outline-none focus:border-primary resize-none"
                      rows={2}
                      placeholder={formData.type === "fill_in_blank" ? "Soru metni (bosluk icin ___ kullanin)" : "Soru metni"}
                      required
                    />
                  </div>

                  {/* Secenekler - Compact 2x2 grid for multiple choice */}
                  {formData.type === "multiple_choice" && (
                    <div className="mb-3">
                      <label className="block text-xs font-medium text-gray-400 mb-1">Secenekler</label>
                      <div className="grid grid-cols-2 gap-2">
                        {formData.options.map((opt, idx) => (
                          <div key={idx} className="flex items-center gap-2">
                            <span className="text-gray-500 text-sm font-medium w-5">{String.fromCharCode(65 + idx)})</span>
                            <input
                              type="text"
                              value={opt}
                              onChange={(e) => {
                                const newOpts = [...formData.options];
                                newOpts[idx] = e.target.value;
                                setFormData({ ...formData, options: newOpts });
                              }}
                              className="flex-1 px-3 py-2 bg-surface-light border border-gray-700 rounded-lg text-white placeholder-gray-500 text-sm focus:outline-none focus:border-primary"
                              placeholder={`Secenek ${String.fromCharCode(65 + idx)}`}
                            />
                          </div>
                        ))}
                      </div>
                    </div>
                  )}

                  {/* Dogru Cevap + Aciklama - Side by side for compact view */}
                  <div className="grid grid-cols-2 gap-3 mb-4">
                    <div>
                      <label className="block text-xs font-medium text-gray-400 mb-1">
                        Dogru Cevap
                        {formData.type === "multiple_choice" && " (A-D)"}
                      </label>
                      {formData.type === "true_false" ? (
                        <select
                          value={formData.correctAnswer}
                          onChange={(e) => setFormData({ ...formData, correctAnswer: e.target.value })}
                          className="w-full px-3 py-2 bg-surface-light border border-gray-700 rounded-lg text-white text-sm focus:outline-none focus:border-primary"
                          required
                        >
                          <option value="">Secin</option>
                          <option value="true">Dogru</option>
                          <option value="false">Yanlis</option>
                        </select>
                      ) : (
                        <input
                          type="text"
                          value={formData.correctAnswer}
                          onChange={(e) => setFormData({ ...formData, correctAnswer: e.target.value })}
                          className="w-full px-3 py-2 bg-surface-light border border-gray-700 rounded-lg text-white placeholder-gray-500 text-sm focus:outline-none focus:border-primary"
                          placeholder={formData.type === "multiple_choice" ? "A, B, C veya D" : "Cevap"}
                          required
                        />
                      )}
                    </div>
                    <div>
                      <label className="block text-xs font-medium text-gray-400 mb-1">Aciklama (opsiyonel)</label>
                      <input
                        type="text"
                        value={formData.explanation}
                        onChange={(e) => setFormData({ ...formData, explanation: e.target.value })}
                        className="w-full px-3 py-2 bg-surface-light border border-gray-700 rounded-lg text-white placeholder-gray-500 text-sm focus:outline-none focus:border-primary"
                        placeholder="Kisa aciklama..."
                      />
                    </div>
                  </div>

                  {/* Action Buttons */}
                  <div className="flex gap-3">
                    <button
                      type="button"
                      onClick={closeModal}
                      className="flex-1 px-4 py-2.5 border border-gray-700 text-gray-400 rounded-lg hover:bg-surface-light transition-colors text-sm"
                    >
                      Iptal
                    </button>
                    <button
                      type="submit"
                      disabled={saving || formData.subtopicId === 0 || formData.knowledgeTypeId === 0}
                      className="flex-1 px-4 py-2.5 bg-primary text-white rounded-lg hover:bg-primary/90 transition-colors disabled:opacity-50 text-sm"
                    >
                      {saving ? "Kaydediliyor..." : "Kaydet"}
                    </button>
                  </div>
                </form>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}