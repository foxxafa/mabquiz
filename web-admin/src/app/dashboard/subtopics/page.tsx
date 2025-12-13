"use client";

import { useState, useEffect } from "react";
import { adminSubtopicsApi, adminTopicsApi, adminCoursesApi, Subtopic, Topic, Course } from "@/lib/api";

export default function SubtopicsPage() {
  const [subtopics, setSubtopics] = useState<Subtopic[]>([]);
  const [topics, setTopics] = useState<Topic[]>([]);
  const [courses, setCourses] = useState<Course[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [showModal, setShowModal] = useState(false);
  const [editingSubtopic, setEditingSubtopic] = useState<Subtopic | null>(null);
  const [formData, setFormData] = useState({ topicId: 0, name: "", displayName: "", description: "" });
  const [saving, setSaving] = useState(false);
  const [filterCourseId, setFilterCourseId] = useState<number | undefined>(undefined);
  const [filterTopicId, setFilterTopicId] = useState<number | undefined>(undefined);

  useEffect(() => {
    loadInitialData();
  }, []);

  useEffect(() => {
    loadSubtopics();
  }, [filterCourseId, filterTopicId]);

  useEffect(() => {
    // Filter topics when course changes
    if (filterCourseId) {
      loadTopicsForCourse(filterCourseId);
    }
  }, [filterCourseId]);

  const loadInitialData = async () => {
    setLoading(true);
    const [coursesResult, topicsResult] = await Promise.all([
      adminCoursesApi.getAll(),
      adminTopicsApi.getAll(),
    ]);
    if (coursesResult.data) setCourses(coursesResult.data.courses);
    if (topicsResult.data) setTopics(topicsResult.data.topics);
    await loadSubtopics();
    setLoading(false);
  };

  const loadTopicsForCourse = async (courseId: number) => {
    const result = await adminTopicsApi.getAll(courseId);
    if (result.data) {
      setTopics(result.data.topics);
      setFilterTopicId(undefined);
    }
  };

  const loadSubtopics = async () => {
    const result = await adminSubtopicsApi.getAll(filterTopicId, filterCourseId, true);
    if (result.error) {
      setError(result.error);
    } else if (result.data) {
      setSubtopics(result.data.subtopics);
    }
  };

  const openModal = (subtopic?: Subtopic) => {
    if (subtopic) {
      setEditingSubtopic(subtopic);
      setFormData({
        topicId: subtopic.topicId,
        name: subtopic.name,
        displayName: subtopic.displayName,
        description: subtopic.description || "",
      });
    } else {
      setEditingSubtopic(null);
      setFormData({ topicId: topics[0]?.id || 0, name: "", displayName: "", description: "" });
    }
    setShowModal(true);
  };

  const closeModal = () => {
    setShowModal(false);
    setEditingSubtopic(null);
    setFormData({ topicId: 0, name: "", displayName: "", description: "" });
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSaving(true);
    setError("");

    let result;
    if (editingSubtopic) {
      result = await adminSubtopicsApi.update(editingSubtopic.id, formData);
    } else {
      result = await adminSubtopicsApi.create(formData);
    }

    if (result.error) {
      setError(result.error);
    } else {
      closeModal();
      loadSubtopics();
    }
    setSaving(false);
  };

  const handleDelete = async (subtopic: Subtopic) => {
    if (!confirm(`"${subtopic.displayName}" alt konusunu silmek istediginizden emin misiniz?`)) {
      return;
    }

    const result = await adminSubtopicsApi.delete(subtopic.id);
    if (result.error) {
      setError(result.error);
    } else {
      loadSubtopics();
    }
  };

  const toggleActive = async (subtopic: Subtopic) => {
    const result = await adminSubtopicsApi.update(subtopic.id, { isActive: !subtopic.isActive });
    if (result.error) {
      setError(result.error);
    } else {
      loadSubtopics();
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
      </div>
    );
  }

  return (
    <div>
      {/* Header */}
      <div className="flex justify-between items-center mb-8">
        <div>
          <h1 className="text-2xl font-bold text-white">Alt Konular</h1>
          <p className="text-gray-500 mt-1">Konu alt kategorilerini yonetin</p>
        </div>
        <button
          onClick={() => openModal()}
          disabled={topics.length === 0}
          className="px-4 py-2 bg-primary text-white rounded-lg hover:bg-primary/90 transition-colors flex items-center gap-2 disabled:opacity-50"
        >
          <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
          </svg>
          Yeni Alt Konu
        </button>
      </div>

      {/* Filters */}
      <div className="mb-6 flex gap-4">
        <select
          value={filterCourseId || ""}
          onChange={(e) => {
            setFilterCourseId(e.target.value ? Number(e.target.value) : undefined);
            if (!e.target.value) {
              adminTopicsApi.getAll().then(r => r.data && setTopics(r.data.topics));
            }
          }}
          className="px-4 py-2 bg-surface-light border border-gray-700 rounded-lg text-white focus:outline-none focus:border-primary"
        >
          <option value="">Tum Dersler</option>
          {courses.map((course) => (
            <option key={course.id} value={course.id}>{course.displayName}</option>
          ))}
        </select>
        <select
          value={filterTopicId || ""}
          onChange={(e) => setFilterTopicId(e.target.value ? Number(e.target.value) : undefined)}
          className="px-4 py-2 bg-surface-light border border-gray-700 rounded-lg text-white focus:outline-none focus:border-primary"
        >
          <option value="">Tum Konular</option>
          {topics.map((topic) => (
            <option key={topic.id} value={topic.id}>{topic.displayName}</option>
          ))}
        </select>
      </div>

      {/* Error */}
      {error && (
        <div className="mb-4 p-3 bg-red-500/10 border border-red-500/20 rounded-lg text-red-400 text-sm">
          {error}
        </div>
      )}

      {topics.length === 0 ? (
        <div className="bg-surface rounded-xl border border-gray-800 p-8 text-center">
          <p className="text-gray-500">Oncelikle bir konu eklemeniz gerekiyor.</p>
          <a href="/dashboard/topics" className="text-primary hover:underline mt-2 inline-block">
            Konu Ekle
          </a>
        </div>
      ) : (
        /* Table */
        <div className="bg-surface rounded-xl border border-gray-800 overflow-hidden">
          <table className="w-full">
            <thead className="bg-surface-light">
              <tr>
                <th className="px-6 py-4 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">Alt Konu</th>
                <th className="px-6 py-4 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">Konu</th>
                <th className="px-6 py-4 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">Ders</th>
                <th className="px-6 py-4 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">Soru</th>
                <th className="px-6 py-4 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">Durum</th>
                <th className="px-6 py-4 text-right text-xs font-medium text-gray-400 uppercase tracking-wider">Islemler</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-800">
              {subtopics.length === 0 ? (
                <tr>
                  <td colSpan={6} className="px-6 py-8 text-center text-gray-500">
                    Henuz alt konu eklenmemis
                  </td>
                </tr>
              ) : (
                subtopics.map((subtopic) => (
                  <tr key={subtopic.id} className={!subtopic.isActive ? "opacity-50" : ""}>
                    <td className="px-6 py-4">
                      <div className="text-white font-medium">{subtopic.displayName}</div>
                      <div className="text-gray-500 text-sm font-mono">{subtopic.name}</div>
                    </td>
                    <td className="px-6 py-4">
                      <span className="px-2 py-1 bg-blue-500/20 text-blue-400 rounded text-sm">
                        {subtopic.topic?.displayName}
                      </span>
                    </td>
                    <td className="px-6 py-4">
                      <span className="px-2 py-1 bg-primary/20 text-primary rounded text-sm">
                        {subtopic.course?.displayName}
                      </span>
                    </td>
                    <td className="px-6 py-4 text-gray-400">{subtopic.questionCount}</td>
                    <td className="px-6 py-4">
                      <button
                        onClick={() => toggleActive(subtopic)}
                        className={`px-2 py-1 rounded text-xs font-medium ${
                          subtopic.isActive
                            ? "bg-green-500/20 text-green-400"
                            : "bg-red-500/20 text-red-400"
                        }`}
                      >
                        {subtopic.isActive ? "Aktif" : "Pasif"}
                      </button>
                    </td>
                    <td className="px-6 py-4 text-right">
                      <button
                        onClick={() => openModal(subtopic)}
                        className="text-gray-400 hover:text-white mr-3"
                      >
                        <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                        </svg>
                      </button>
                      <button
                        onClick={() => handleDelete(subtopic)}
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
      )}

      {/* Modal */}
      {showModal && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-surface rounded-xl p-6 w-full max-w-md border border-gray-800">
            <h2 className="text-xl font-bold text-white mb-4">
              {editingSubtopic ? "Alt Konu Duzenle" : "Yeni Alt Konu Ekle"}
            </h2>
            <form onSubmit={handleSubmit}>
              <div className="mb-4">
                <label className="block text-sm font-medium text-gray-400 mb-2">
                  Konu
                </label>
                <select
                  value={formData.topicId}
                  onChange={(e) => setFormData({ ...formData, topicId: Number(e.target.value) })}
                  className="w-full px-4 py-3 bg-surface-light border border-gray-700 rounded-lg text-white focus:outline-none focus:border-primary"
                  required
                >
                  <option value={0}>Konu Secin</option>
                  {topics.map((topic) => (
                    <option key={topic.id} value={topic.id}>
                      {topic.course?.displayName} - {topic.displayName}
                    </option>
                  ))}
                </select>
              </div>
              <div className="mb-4">
                <label className="block text-sm font-medium text-gray-400 mb-2">
                  Gorunen Ad
                </label>
                <input
                  type="text"
                  value={formData.displayName}
                  onChange={(e) => setFormData({ ...formData, displayName: e.target.value })}
                  className="w-full px-4 py-3 bg-surface-light border border-gray-700 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:border-primary"
                  placeholder="NSAIDler"
                  required
                />
              </div>
              <div className="mb-4">
                <label className="block text-sm font-medium text-gray-400 mb-2">
                  Sistem Adi
                </label>
                <input
                  type="text"
                  value={formData.name}
                  onChange={(e) => setFormData({ ...formData, name: e.target.value.toLowerCase().replace(/\s+/g, '_') })}
                  className="w-full px-4 py-3 bg-surface-light border border-gray-700 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:border-primary font-mono"
                  placeholder="nsaidler"
                  required
                />
              </div>
              <div className="mb-6">
                <label className="block text-sm font-medium text-gray-400 mb-2">
                  Aciklama (opsiyonel)
                </label>
                <textarea
                  value={formData.description}
                  onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                  className="w-full px-4 py-3 bg-surface-light border border-gray-700 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:border-primary resize-none"
                  rows={3}
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
                  type="submit"
                  disabled={saving || formData.topicId === 0}
                  className="flex-1 px-4 py-3 bg-primary text-white rounded-lg hover:bg-primary/90 transition-colors disabled:opacity-50"
                >
                  {saving ? "Kaydediliyor..." : "Kaydet"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
