"use client";

import { useState, useEffect } from "react";
import { adminCoursesApi, Course } from "@/lib/api";

export default function CoursesPage() {
  const [courses, setCourses] = useState<Course[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [showModal, setShowModal] = useState(false);
  const [editingCourse, setEditingCourse] = useState<Course | null>(null);
  const [formData, setFormData] = useState({ name: "", displayName: "", description: "" });
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    loadCourses();
  }, []);

  const loadCourses = async () => {
    setLoading(true);
    const result = await adminCoursesApi.getAll(true);
    if (result.error) {
      setError(result.error);
    } else if (result.data) {
      setCourses(result.data.courses);
    }
    setLoading(false);
  };

  const openModal = (course?: Course) => {
    if (course) {
      setEditingCourse(course);
      setFormData({
        name: course.name,
        displayName: course.displayName,
        description: course.description || "",
      });
    } else {
      setEditingCourse(null);
      setFormData({ name: "", displayName: "", description: "" });
    }
    setShowModal(true);
  };

  const closeModal = () => {
    setShowModal(false);
    setEditingCourse(null);
    setFormData({ name: "", displayName: "", description: "" });
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSaving(true);
    setError("");

    let result;
    if (editingCourse) {
      result = await adminCoursesApi.update(editingCourse.id, formData);
    } else {
      result = await adminCoursesApi.create(formData);
    }

    if (result.error) {
      setError(result.error);
    } else {
      closeModal();
      loadCourses();
    }
    setSaving(false);
  };

  const handleDelete = async (course: Course) => {
    if (!confirm(`"${course.displayName}" dersini silmek istediginizden emin misiniz?`)) {
      return;
    }

    const result = await adminCoursesApi.delete(course.id);
    if (result.error) {
      setError(result.error);
    } else {
      loadCourses();
    }
  };

  const toggleActive = async (course: Course) => {
    const result = await adminCoursesApi.update(course.id, { isActive: !course.isActive });
    if (result.error) {
      setError(result.error);
    } else {
      loadCourses();
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
          <h1 className="text-2xl font-bold text-white">Dersler</h1>
          <p className="text-gray-500 mt-1">Sistemdeki dersleri yonetin</p>
        </div>
        <button
          onClick={() => openModal()}
          className="px-4 py-2 bg-primary text-white rounded-lg hover:bg-primary/90 transition-colors flex items-center gap-2"
        >
          <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
          </svg>
          Yeni Ders
        </button>
      </div>

      {/* Error */}
      {error && (
        <div className="mb-4 p-3 bg-red-500/10 border border-red-500/20 rounded-lg text-red-400 text-sm">
          {error}
        </div>
      )}

      {/* Table */}
      <div className="bg-surface rounded-xl border border-gray-800 overflow-hidden">
        <table className="w-full">
          <thead className="bg-surface-light">
            <tr>
              <th className="px-6 py-4 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">Ders Adi</th>
              <th className="px-6 py-4 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">Sistem Adi</th>
              <th className="px-6 py-4 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">Konu Sayisi</th>
              <th className="px-6 py-4 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">Durum</th>
              <th className="px-6 py-4 text-right text-xs font-medium text-gray-400 uppercase tracking-wider">Islemler</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-800">
            {courses.length === 0 ? (
              <tr>
                <td colSpan={5} className="px-6 py-8 text-center text-gray-500">
                  Henuz ders eklenmemis
                </td>
              </tr>
            ) : (
              courses.map((course) => (
                <tr key={course.id} className={!course.isActive ? "opacity-50" : ""}>
                  <td className="px-6 py-4">
                    <div className="text-white font-medium">{course.displayName}</div>
                    {course.description && (
                      <div className="text-gray-500 text-sm truncate max-w-xs">{course.description}</div>
                    )}
                  </td>
                  <td className="px-6 py-4 text-gray-400 font-mono text-sm">{course.name}</td>
                  <td className="px-6 py-4 text-gray-400">{course.topicCount}</td>
                  <td className="px-6 py-4">
                    <button
                      onClick={() => toggleActive(course)}
                      className={`px-2 py-1 rounded text-xs font-medium ${
                        course.isActive
                          ? "bg-green-500/20 text-green-400"
                          : "bg-red-500/20 text-red-400"
                      }`}
                    >
                      {course.isActive ? "Aktif" : "Pasif"}
                    </button>
                  </td>
                  <td className="px-6 py-4 text-right">
                    <button
                      onClick={() => openModal(course)}
                      className="text-gray-400 hover:text-white mr-3"
                    >
                      <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                      </svg>
                    </button>
                    <button
                      onClick={() => handleDelete(course)}
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

      {/* Modal */}
      {showModal && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-surface rounded-xl p-6 w-full max-w-md border border-gray-800">
            <h2 className="text-xl font-bold text-white mb-4">
              {editingCourse ? "Ders Duzenle" : "Yeni Ders Ekle"}
            </h2>
            <form onSubmit={handleSubmit}>
              <div className="mb-4">
                <label className="block text-sm font-medium text-gray-400 mb-2">
                  Gorunen Ad
                </label>
                <input
                  type="text"
                  value={formData.displayName}
                  onChange={(e) => setFormData({ ...formData, displayName: e.target.value })}
                  className="w-full px-4 py-3 bg-surface-light border border-gray-700 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:border-primary"
                  placeholder="Farmakoloji"
                  required
                />
              </div>
              <div className="mb-4">
                <label className="block text-sm font-medium text-gray-400 mb-2">
                  Sistem Adi (ingilizce, bosluksuz)
                </label>
                <input
                  type="text"
                  value={formData.name}
                  onChange={(e) => setFormData({ ...formData, name: e.target.value.toLowerCase().replace(/\s+/g, '_') })}
                  className="w-full px-4 py-3 bg-surface-light border border-gray-700 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:border-primary font-mono"
                  placeholder="farmakoloji"
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
                  placeholder="Ders hakkinda kisa aciklama..."
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
                  disabled={saving}
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
