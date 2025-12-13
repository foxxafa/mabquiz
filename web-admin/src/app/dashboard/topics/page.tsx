"use client";

import { useState, useEffect } from "react";
import { adminTopicsApi, adminCoursesApi, Topic, Course } from "@/lib/api";

export default function TopicsPage() {
  const [topics, setTopics] = useState<Topic[]>([]);
  const [courses, setCourses] = useState<Course[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [showModal, setShowModal] = useState(false);
  const [editingTopic, setEditingTopic] = useState<Topic | null>(null);
  const [formData, setFormData] = useState({ courseId: 0, name: "", displayName: "", description: "" });
  const [saving, setSaving] = useState(false);
  const [filterCourseId, setFilterCourseId] = useState<number | undefined>(undefined);

  useEffect(() => {
    loadData();
  }, []);

  useEffect(() => {
    loadTopics();
  }, [filterCourseId]);

  const loadData = async () => {
    setLoading(true);
    const coursesResult = await adminCoursesApi.getAll();
    if (coursesResult.data) {
      setCourses(coursesResult.data.courses);
    }
    await loadTopics();
    setLoading(false);
  };

  const loadTopics = async () => {
    const result = await adminTopicsApi.getAll(filterCourseId, true);
    if (result.error) {
      setError(result.error);
    } else if (result.data) {
      setTopics(result.data.topics);
    }
  };

  const openModal = (topic?: Topic) => {
    if (topic) {
      setEditingTopic(topic);
      setFormData({
        courseId: topic.courseId,
        name: topic.name,
        displayName: topic.displayName,
        description: topic.description || "",
      });
    } else {
      setEditingTopic(null);
      setFormData({ courseId: courses[0]?.id || 0, name: "", displayName: "", description: "" });
    }
    setShowModal(true);
  };

  const closeModal = () => {
    setShowModal(false);
    setEditingTopic(null);
    setFormData({ courseId: 0, name: "", displayName: "", description: "" });
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSaving(true);
    setError("");

    let result;
    if (editingTopic) {
      result = await adminTopicsApi.update(editingTopic.id, formData);
    } else {
      result = await adminTopicsApi.create(formData);
    }

    if (result.error) {
      setError(result.error);
    } else {
      closeModal();
      loadTopics();
    }
    setSaving(false);
  };

  const handleDelete = async (topic: Topic) => {
    if (!confirm(`"${topic.displayName}" konusunu silmek istediginizden emin misiniz?`)) {
      return;
    }

    const result = await adminTopicsApi.delete(topic.id);
    if (result.error) {
      setError(result.error);
    } else {
      loadTopics();
    }
  };

  const toggleActive = async (topic: Topic) => {
    const result = await adminTopicsApi.update(topic.id, { isActive: !topic.isActive });
    if (result.error) {
      setError(result.error);
    } else {
      loadTopics();
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
          <h1 className="text-2xl font-bold text-white">Konular</h1>
          <p className="text-gray-500 mt-1">Ders konularini yonetin</p>
        </div>
        <button
          onClick={() => openModal()}
          disabled={courses.length === 0}
          className="px-4 py-2 bg-primary text-white rounded-lg hover:bg-primary/90 transition-colors flex items-center gap-2 disabled:opacity-50"
        >
          <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
          </svg>
          Yeni Konu
        </button>
      </div>

      {/* Filter */}
      <div className="mb-6">
        <select
          value={filterCourseId || ""}
          onChange={(e) => setFilterCourseId(e.target.value ? Number(e.target.value) : undefined)}
          className="px-4 py-2 bg-surface-light border border-gray-700 rounded-lg text-white focus:outline-none focus:border-primary"
        >
          <option value="">Tum Dersler</option>
          {courses.map((course) => (
            <option key={course.id} value={course.id}>{course.displayName}</option>
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
            Ders Ekle
          </a>
        </div>
      ) : (
        /* Table */
        <div className="bg-surface rounded-xl border border-gray-800 overflow-hidden">
          <table className="w-full">
            <thead className="bg-surface-light">
              <tr>
                <th className="px-6 py-4 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">Konu Adi</th>
                <th className="px-6 py-4 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">Ders</th>
                <th className="px-6 py-4 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">Alt Konu</th>
                <th className="px-6 py-4 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">Durum</th>
                <th className="px-6 py-4 text-right text-xs font-medium text-gray-400 uppercase tracking-wider">Islemler</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-800">
              {topics.length === 0 ? (
                <tr>
                  <td colSpan={5} className="px-6 py-8 text-center text-gray-500">
                    Henuz konu eklenmemis
                  </td>
                </tr>
              ) : (
                topics.map((topic) => (
                  <tr key={topic.id} className={!topic.isActive ? "opacity-50" : ""}>
                    <td className="px-6 py-4">
                      <div className="text-white font-medium">{topic.displayName}</div>
                      <div className="text-gray-500 text-sm font-mono">{topic.name}</div>
                    </td>
                    <td className="px-6 py-4">
                      <span className="px-2 py-1 bg-primary/20 text-primary rounded text-sm">
                        {topic.course?.displayName}
                      </span>
                    </td>
                    <td className="px-6 py-4 text-gray-400">{topic.subtopicCount}</td>
                    <td className="px-6 py-4">
                      <button
                        onClick={() => toggleActive(topic)}
                        className={`px-2 py-1 rounded text-xs font-medium ${
                          topic.isActive
                            ? "bg-green-500/20 text-green-400"
                            : "bg-red-500/20 text-red-400"
                        }`}
                      >
                        {topic.isActive ? "Aktif" : "Pasif"}
                      </button>
                    </td>
                    <td className="px-6 py-4 text-right">
                      <button
                        onClick={() => openModal(topic)}
                        className="text-gray-400 hover:text-white mr-3"
                      >
                        <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                        </svg>
                      </button>
                      <button
                        onClick={() => handleDelete(topic)}
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
              {editingTopic ? "Konu Duzenle" : "Yeni Konu Ekle"}
            </h2>
            <form onSubmit={handleSubmit}>
              <div className="mb-4">
                <label className="block text-sm font-medium text-gray-400 mb-2">
                  Ders
                </label>
                <select
                  value={formData.courseId}
                  onChange={(e) => setFormData({ ...formData, courseId: Number(e.target.value) })}
                  className="w-full px-4 py-3 bg-surface-light border border-gray-700 rounded-lg text-white focus:outline-none focus:border-primary"
                  required
                >
                  <option value={0}>Ders Secin</option>
                  {courses.map((course) => (
                    <option key={course.id} value={course.id}>{course.displayName}</option>
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
                  placeholder="Analjezikler"
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
                  placeholder="analjezikler"
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
                  disabled={saving || formData.courseId === 0}
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
