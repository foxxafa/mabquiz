"use client";

import { useState } from "react";

interface Question {
  id: string;
  text: string;
  course: string;
  topic: string;
  knowledge_type: string;
  difficulty: string;
  correct_answer: string;
}

export default function QuestionsPage() {
  const [questions, setQuestions] = useState<Question[]>([]);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [searchTerm, setSearchTerm] = useState("");

  // Form state
  const [formData, setFormData] = useState({
    text: "",
    course: "",
    topic: "",
    knowledge_type: "multiple_choice",
    option_a: "",
    option_b: "",
    option_c: "",
    option_d: "",
    option_e: "",
    correct_answer: "A",
    explanation: "",
  });

  const courses = ["Farmakoloji", "Terminoloji", "Anatomi", "Fizyoloji"];
  const knowledgeTypes = [
    { value: "multiple_choice", label: "Coktan Secmeli" },
    { value: "true_false", label: "Dogru/Yanlis" },
    { value: "fill_blank", label: "Bosluk Doldurma" },
  ];

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    // TODO: API call to create question
    console.log("Creating question:", formData);
    setIsModalOpen(false);
    // Reset form
    setFormData({
      text: "",
      course: "",
      topic: "",
      knowledge_type: "multiple_choice",
      option_a: "",
      option_b: "",
      option_c: "",
      option_d: "",
      option_e: "",
      correct_answer: "A",
      explanation: "",
    });
  };

  return (
    <div>
      {/* Header */}
      <div className="flex justify-between items-center mb-8">
        <div>
          <h1 className="text-2xl font-bold text-white">Sorular</h1>
          <p className="text-gray-500 mt-1">
            Sistemdeki tum sorulari yonetin
          </p>
        </div>
        <button
          onClick={() => setIsModalOpen(true)}
          className="flex items-center gap-2 px-4 py-2 bg-primary hover:bg-primary/90 text-white rounded-lg transition-colors"
        >
          <svg
            className="w-5 h-5"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M12 4v16m8-8H4"
            />
          </svg>
          Yeni Soru Ekle
        </button>
      </div>

      {/* Search and Filter */}
      <div className="flex gap-4 mb-6">
        <div className="flex-1">
          <input
            type="text"
            placeholder="Soru ara..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full px-4 py-2 bg-surface border border-gray-700 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:border-primary"
          />
        </div>
        <select className="px-4 py-2 bg-surface border border-gray-700 rounded-lg text-white focus:outline-none focus:border-primary">
          <option value="">Tum Dersler</option>
          {courses.map((course) => (
            <option key={course} value={course}>
              {course}
            </option>
          ))}
        </select>
      </div>

      {/* Questions Table */}
      <div className="bg-surface rounded-xl border border-gray-800 overflow-hidden">
        {questions.length === 0 ? (
          <div className="p-12 text-center">
            <svg
              className="w-16 h-16 text-gray-600 mx-auto mb-4"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M8.228 9c.549-1.165 2.03-2 3.772-2 2.21 0 4 1.343 4 3 0 1.4-1.278 2.575-3.006 2.907-.542.104-.994.54-.994 1.093m0 3h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
              />
            </svg>
            <h3 className="text-lg font-medium text-white mb-2">
              Henuz soru yok
            </h3>
            <p className="text-gray-500 mb-4">
              Sisteme soru ekleyerek baslayabilirsiniz
            </p>
            <button
              onClick={() => setIsModalOpen(true)}
              className="px-4 py-2 bg-primary hover:bg-primary/90 text-white rounded-lg transition-colors"
            >
              Ilk Soruyu Ekle
            </button>
          </div>
        ) : (
          <table className="w-full">
            <thead className="bg-surface-light">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">
                  Soru
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">
                  Ders
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">
                  Konu
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">
                  Tip
                </th>
                <th className="px-6 py-3 text-right text-xs font-medium text-gray-400 uppercase tracking-wider">
                  Islemler
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-800">
              {questions.map((question) => (
                <tr key={question.id} className="hover:bg-surface-light">
                  <td className="px-6 py-4 text-sm text-white">
                    {question.text.substring(0, 60)}...
                  </td>
                  <td className="px-6 py-4 text-sm text-gray-400">
                    {question.course}
                  </td>
                  <td className="px-6 py-4 text-sm text-gray-400">
                    {question.topic}
                  </td>
                  <td className="px-6 py-4 text-sm text-gray-400">
                    {question.knowledge_type}
                  </td>
                  <td className="px-6 py-4 text-right text-sm">
                    <button className="text-primary hover:text-primary/80 mr-3">
                      Duzenle
                    </button>
                    <button className="text-red-500 hover:text-red-400">
                      Sil
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>

      {/* Add Question Modal */}
      {isModalOpen && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-surface rounded-xl border border-gray-800 w-full max-w-2xl max-h-[90vh] overflow-y-auto">
            <div className="p-6 border-b border-gray-800">
              <h2 className="text-xl font-bold text-white">Yeni Soru Ekle</h2>
            </div>

            <form onSubmit={handleSubmit} className="p-6 space-y-4">
              {/* Question Text */}
              <div>
                <label className="block text-sm font-medium text-gray-400 mb-2">
                  Soru Metni *
                </label>
                <textarea
                  value={formData.text}
                  onChange={(e) =>
                    setFormData({ ...formData, text: e.target.value })
                  }
                  rows={3}
                  className="w-full px-4 py-2 bg-surface-light border border-gray-700 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:border-primary"
                  placeholder="Soru metnini girin..."
                  required
                />
              </div>

              {/* Course and Topic */}
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-400 mb-2">
                    Ders *
                  </label>
                  <select
                    value={formData.course}
                    onChange={(e) =>
                      setFormData({ ...formData, course: e.target.value })
                    }
                    className="w-full px-4 py-2 bg-surface-light border border-gray-700 rounded-lg text-white focus:outline-none focus:border-primary"
                    required
                  >
                    <option value="">Ders secin</option>
                    {courses.map((course) => (
                      <option key={course} value={course}>
                        {course}
                      </option>
                    ))}
                  </select>
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-400 mb-2">
                    Konu *
                  </label>
                  <input
                    type="text"
                    value={formData.topic}
                    onChange={(e) =>
                      setFormData({ ...formData, topic: e.target.value })
                    }
                    className="w-full px-4 py-2 bg-surface-light border border-gray-700 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:border-primary"
                    placeholder="Konu girin"
                    required
                  />
                </div>
              </div>

              {/* Knowledge Type */}
              <div>
                <label className="block text-sm font-medium text-gray-400 mb-2">
                  Soru Tipi *
                </label>
                <select
                  value={formData.knowledge_type}
                  onChange={(e) =>
                    setFormData({ ...formData, knowledge_type: e.target.value })
                  }
                  className="w-full px-4 py-2 bg-surface-light border border-gray-700 rounded-lg text-white focus:outline-none focus:border-primary"
                >
                  {knowledgeTypes.map((type) => (
                    <option key={type.value} value={type.value}>
                      {type.label}
                    </option>
                  ))}
                </select>
              </div>

              {/* Options */}
              <div className="space-y-3">
                <label className="block text-sm font-medium text-gray-400">
                  Secenekler *
                </label>
                {["A", "B", "C", "D", "E"].map((letter) => (
                  <div key={letter} className="flex items-center gap-3">
                    <span className="w-8 h-8 flex items-center justify-center bg-surface-light rounded-lg text-white font-medium">
                      {letter}
                    </span>
                    <input
                      type="text"
                      value={formData[`option_${letter.toLowerCase()}` as keyof typeof formData]}
                      onChange={(e) =>
                        setFormData({
                          ...formData,
                          [`option_${letter.toLowerCase()}`]: e.target.value,
                        })
                      }
                      className="flex-1 px-4 py-2 bg-surface-light border border-gray-700 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:border-primary"
                      placeholder={`Secenek ${letter}`}
                      required={letter !== "E"}
                    />
                  </div>
                ))}
              </div>

              {/* Correct Answer */}
              <div>
                <label className="block text-sm font-medium text-gray-400 mb-2">
                  Dogru Cevap *
                </label>
                <select
                  value={formData.correct_answer}
                  onChange={(e) =>
                    setFormData({ ...formData, correct_answer: e.target.value })
                  }
                  className="w-full px-4 py-2 bg-surface-light border border-gray-700 rounded-lg text-white focus:outline-none focus:border-primary"
                >
                  {["A", "B", "C", "D", "E"].map((letter) => (
                    <option key={letter} value={letter}>
                      {letter}
                    </option>
                  ))}
                </select>
              </div>

              {/* Explanation */}
              <div>
                <label className="block text-sm font-medium text-gray-400 mb-2">
                  Aciklama (Opsiyonel)
                </label>
                <textarea
                  value={formData.explanation}
                  onChange={(e) =>
                    setFormData({ ...formData, explanation: e.target.value })
                  }
                  rows={2}
                  className="w-full px-4 py-2 bg-surface-light border border-gray-700 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:border-primary"
                  placeholder="Dogru cevap aciklamasi..."
                />
              </div>

              {/* Buttons */}
              <div className="flex justify-end gap-3 pt-4">
                <button
                  type="button"
                  onClick={() => setIsModalOpen(false)}
                  className="px-4 py-2 text-gray-400 hover:text-white transition-colors"
                >
                  Iptal
                </button>
                <button
                  type="submit"
                  className="px-4 py-2 bg-primary hover:bg-primary/90 text-white rounded-lg transition-colors"
                >
                  Kaydet
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
