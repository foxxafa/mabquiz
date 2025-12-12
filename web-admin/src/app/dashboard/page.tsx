"use client";

import { useAuth } from "@/lib/auth";

export default function DashboardPage() {
  const { user } = useAuth();

  const stats = [
    { label: "Toplam Soru", value: "0", icon: "M8.228 9c.549-1.165 2.03-2 3.772-2 2.21 0 4 1.343 4 3 0 1.4-1.278 2.575-3.006 2.907-.542.104-.994.54-.994 1.093m0 3h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z", color: "bg-blue-500" },
    { label: "Toplam Kullanici", value: "0", icon: "M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z", color: "bg-green-500" },
    { label: "Aktif Oturum", value: "0", icon: "M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z", color: "bg-purple-500" },
    { label: "Bugun Cozulen", value: "0", icon: "M13 10V3L4 14h7v7l9-11h-7z", color: "bg-orange-500" },
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
        {stats.map((stat, index) => (
          <div
            key={index}
            className="bg-surface rounded-xl p-6 border border-gray-800"
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
                <p className="text-2xl font-bold text-white">{stat.value}</p>
                <p className="text-sm text-gray-500">{stat.label}</p>
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Quick Actions */}
      <div className="bg-surface rounded-xl p-6 border border-gray-800">
        <h2 className="text-lg font-semibold text-white mb-4">Hizli Islemler</h2>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <a
            href="/dashboard/questions"
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
              <p className="font-medium text-white">Yeni Soru Ekle</p>
              <p className="text-sm text-gray-500">Sisteme soru ekleyin</p>
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
                  d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-8l-4-4m0 0L8 8m4-4v12"
                />
              </svg>
            </div>
            <div>
              <p className="font-medium text-white">Excel Yukle</p>
              <p className="text-sm text-gray-500">Toplu soru yukleyin</p>
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
