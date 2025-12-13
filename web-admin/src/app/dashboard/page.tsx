"use client";

import { useState, useEffect } from "react";
import { useAuth } from "@/lib/auth";
import { adminStatsApi, AdminStats } from "@/lib/api";

export default function DashboardPage() {
  const { user } = useAuth();
  const [stats, setStats] = useState<AdminStats | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadStats();
  }, []);

  const loadStats = async () => {
    const result = await adminStatsApi.getStats();
    if (result.data) {
      setStats(result.data);
    }
    setLoading(false);
  };

  const statCards = [
    { label: "Dersler", value: stats?.courses || 0, icon: "M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253", color: "bg-blue-500", href: "/dashboard/courses" },
    { label: "Konular", value: stats?.topics || 0, icon: "M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10", color: "bg-green-500", href: "/dashboard/topics" },
    { label: "Alt Konular", value: stats?.subtopics || 0, icon: "M4 6h16M4 10h16M4 14h16M4 18h16", color: "bg-purple-500", href: "/dashboard/subtopics" },
    { label: "Sorular", value: stats?.questions || 0, icon: "M8.228 9c.549-1.165 2.03-2 3.772-2 2.21 0 4 1.343 4 3 0 1.4-1.278 2.575-3.006 2.907-.542.104-.994.54-.994 1.093m0 3h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z", color: "bg-orange-500", href: "/dashboard/questions" },
  ];

  const questionTypes = [
    { key: "multiple_choice", label: "Coktan Secmeli", color: "text-blue-400" },
    { key: "true_false", label: "Dogru/Yanlis", color: "text-green-400" },
    { key: "fill_in_blank", label: "Bosluk Doldurma", color: "text-purple-400" },
  ];

  return (
    <div>
      {/* Header */}
      <div className="mb-8">
        <h1 className="text-2xl font-bold text-white">
          Hos geldin, {user?.display_name}
        </h1>
        <p className="text-gray-500 mt-1">
          MAB Quiz yonetim paneline hosgeldiniz
        </p>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        {statCards.map((stat, index) => (
          <a
            key={index}
            href={stat.href}
            className="bg-surface rounded-xl p-6 border border-gray-800 hover:border-gray-700 transition-colors"
          >
            <div className="flex items-center gap-4">
              <div className={`${stat.color} p-3 rounded-lg`}>
                <svg
                  className="w-6 h-6 text-white"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d={stat.icon}
                  />
                </svg>
              </div>
              <div>
                <p className="text-2xl font-bold text-white">
                  {loading ? "-" : stat.value}
                </p>
                <p className="text-sm text-gray-500">{stat.label}</p>
              </div>
            </div>
          </a>
        ))}
      </div>

      {/* Question Types Breakdown */}
      {stats && stats.questionsByType && Object.keys(stats.questionsByType).length > 0 && (
        <div className="bg-surface rounded-xl p-6 border border-gray-800 mb-8">
          <h2 className="text-lg font-semibold text-white mb-4">Soru Tipleri</h2>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            {questionTypes.map((type) => (
              <div key={type.key} className="bg-surface-light rounded-lg p-4">
                <div className="flex items-center justify-between">
                  <span className="text-gray-400">{type.label}</span>
                  <span className={`text-xl font-bold ${type.color}`}>
                    {stats.questionsByType[type.key] || 0}
                  </span>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Quick Actions */}
      <div className="bg-surface rounded-xl p-6 border border-gray-800">
        <h2 className="text-lg font-semibold text-white mb-4">Hizli Islemler</h2>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <a
            href="/dashboard/courses"
            className="flex items-center gap-3 p-4 bg-surface-light rounded-lg hover:bg-gray-700 transition-colors"
          >
            <div className="bg-primary/20 p-2 rounded-lg">
              <svg
                className="w-5 h-5 text-primary"
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
            </div>
            <div>
              <p className="font-medium text-white">Ders Ekle</p>
              <p className="text-sm text-gray-500">Yeni ders olustur</p>
            </div>
          </a>

          <a
            href="/dashboard/questions"
            className="flex items-center gap-3 p-4 bg-surface-light rounded-lg hover:bg-gray-700 transition-colors"
          >
            <div className="bg-green-500/20 p-2 rounded-lg">
              <svg
                className="w-5 h-5 text-green-500"
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
            </div>
            <div>
              <p className="font-medium text-white">Soru Ekle</p>
              <p className="text-sm text-gray-500">Yeni soru olustur</p>
            </div>
          </a>

          <a
            href="/dashboard/users"
            className="flex items-center gap-3 p-4 bg-surface-light rounded-lg hover:bg-gray-700 transition-colors"
          >
            <div className="bg-blue-500/20 p-2 rounded-lg">
              <svg
                className="w-5 h-5 text-blue-500"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"
                />
              </svg>
            </div>
            <div>
              <p className="font-medium text-white">Kullanicilari Gor</p>
              <p className="text-sm text-gray-500">Kayitli kullanicilar</p>
            </div>
          </a>
        </div>
      </div>
    </div>
  );
}
