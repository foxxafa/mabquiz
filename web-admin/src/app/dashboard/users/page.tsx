"use client";

import { useState, useEffect } from "react";

interface User {
  uid: string;
  email: string;
  display_name: string;
  username?: string;
  email_verified: boolean;
  created_at?: string;
}

export default function UsersPage() {
  const [users, setUsers] = useState<User[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState("");

  useEffect(() => {
    // TODO: Fetch users from API
    setIsLoading(false);
  }, []);

  const filteredUsers = users.filter(
    (user) =>
      user.display_name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      user.email?.toLowerCase().includes(searchTerm.toLowerCase())
  );

  return (
    <div>
      {/* Header */}
      <div className="mb-8">
        <h1 className="text-2xl font-bold text-white">Kullanicilar</h1>
        <p className="text-gray-500 mt-1">
          Sistemdeki tum kullanicilari goruntuleyin
        </p>
      </div>

      {/* Search */}
      <div className="mb-6">
        <input
          type="text"
          placeholder="Kullanici ara..."
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
          className="w-full max-w-md px-4 py-2 bg-surface border border-gray-700 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:border-primary"
        />
      </div>

      {/* Users Table */}
      <div className="bg-surface rounded-xl border border-gray-800 overflow-hidden">
        {isLoading ? (
          <div className="p-12 text-center">
            <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-primary mx-auto"></div>
          </div>
        ) : users.length === 0 ? (
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
                d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z"
              />
            </svg>
            <h3 className="text-lg font-medium text-white mb-2">
              Henuz kullanici yok
            </h3>
            <p className="text-gray-500">
              Kullanicilar mobil uygulamadan kayit oldugunda burada gorunecek
            </p>
          </div>
        ) : (
          <table className="w-full">
            <thead className="bg-surface-light">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">
                  Kullanici
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">
                  Email
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">
                  Durum
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">
                  Kayit Tarihi
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-800">
              {filteredUsers.map((user) => (
                <tr key={user.uid} className="hover:bg-surface-light">
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 rounded-full bg-primary flex items-center justify-center text-white font-bold">
                        {user.display_name?.charAt(0) || "?"}
                      </div>
                      <div>
                        <p className="text-sm font-medium text-white">
                          {user.display_name}
                        </p>
                        <p className="text-xs text-gray-500">
                          @{user.username || user.email?.split("@")[0]}
                        </p>
                      </div>
                    </div>
                  </td>
                  <td className="px-6 py-4 text-sm text-gray-400">
                    {user.email}
                  </td>
                  <td className="px-6 py-4">
                    <span
                      className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                        user.email_verified
                          ? "bg-green-500/20 text-green-400"
                          : "bg-yellow-500/20 text-yellow-400"
                      }`}
                    >
                      {user.email_verified ? "Dogrulanmis" : "Beklemede"}
                    </span>
                  </td>
                  <td className="px-6 py-4 text-sm text-gray-400">
                    {user.created_at
                      ? new Date(user.created_at).toLocaleDateString("tr-TR")
                      : "-"}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
}
