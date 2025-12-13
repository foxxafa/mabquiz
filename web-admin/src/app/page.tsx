"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { GoogleOAuthProvider, GoogleLogin } from "@react-oauth/google";
import { authApi } from "@/lib/api";
import { useAuth } from "@/lib/auth";
import { AuthProvider } from "@/components/AuthProvider";

const GOOGLE_CLIENT_ID = "724215071142-s8r5t9kes47jed4ap1lepc1v9beqmuj8.apps.googleusercontent.com";

function LoginForm() {
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const router = useRouter();
  const { login } = useAuth();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError("");
    setIsLoading(true);

    const result = await authApi.login(username, password);

    if (result.error) {
      setError(result.error);
      setIsLoading(false);
      return;
    }

    if (result.data) {
      login(result.data.access_token, result.data.user);
      router.push("/dashboard");
    }

    setIsLoading(false);
  };

  const handleGoogleSuccess = async (credentialResponse: any) => {
    setError("");
    setIsLoading(true);

    const result = await authApi.googleLogin(credentialResponse.credential);

    if (result.error) {
      setError(result.error);
      setIsLoading(false);
      return;
    }

    if (result.data) {
      login(result.data.access_token, result.data.user);
      router.push("/dashboard");
    }

    setIsLoading(false);
  };

  const handleGoogleError = () => {
    setError("Google ile giris basarisiz oldu");
  };

  return (
    <div className="min-h-screen bg-background flex items-center justify-center p-4">
      <div className="w-full max-w-md">
        {/* Logo */}
        <div className="text-center mb-8">
          <div className="w-16 h-16 bg-primary rounded-2xl flex items-center justify-center mx-auto mb-4">
            <svg
              className="w-8 h-8 text-white"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z"
              />
            </svg>
          </div>
          <h1 className="text-2xl font-bold text-white">MAB Quiz Admin</h1>
          <p className="text-gray-500 mt-2">Yonetim paneline giris yapin</p>
        </div>

        {/* Login Form */}
        <div className="bg-surface rounded-2xl p-8 border border-gray-800">
          {error && (
            <div className="mb-4 p-3 bg-red-500/10 border border-red-500/20 rounded-lg text-red-400 text-sm">
              {error}
            </div>
          )}

          {/* Google Login Button */}
          <div className="mb-6">
            <div className="flex justify-center">
              <GoogleLogin
                onSuccess={handleGoogleSuccess}
                onError={handleGoogleError}
                theme="filled_black"
                size="large"
                text="signin_with"
                shape="rectangular"
              />
            </div>
          </div>

          <div className="relative mb-6">
            <div className="absolute inset-0 flex items-center">
              <div className="w-full border-t border-gray-700"></div>
            </div>
            <div className="relative flex justify-center text-sm">
              <span className="px-2 bg-surface text-gray-500">veya</span>
            </div>
          </div>

          <form onSubmit={handleSubmit}>
            <div className="mb-4">
              <label
                htmlFor="username"
                className="block text-sm font-medium text-gray-400 mb-2"
              >
                Kullanici Adi
              </label>
              <input
                type="text"
                id="username"
                value={username}
                onChange={(e) => setUsername(e.target.value)}
                className="w-full px-4 py-3 bg-surface-light border border-gray-700 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:border-primary transition-colors"
                placeholder="Kullanici adinizi girin"
              />
            </div>

            <div className="mb-6">
              <label
                htmlFor="password"
                className="block text-sm font-medium text-gray-400 mb-2"
              >
                Sifre
              </label>
              <input
                type="password"
                id="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="w-full px-4 py-3 bg-surface-light border border-gray-700 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:border-primary transition-colors"
                placeholder="Sifrenizi girin"
              />
            </div>

            <button
              type="submit"
              disabled={isLoading || (!username || !password)}
              className="w-full py-3 bg-primary hover:bg-primary/90 text-white font-medium rounded-lg transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {isLoading ? "Giris yapiliyor..." : "Giris Yap"}
            </button>
          </form>
        </div>
      </div>
    </div>
  );
}

export default function LoginPage() {
  return (
    <GoogleOAuthProvider clientId={GOOGLE_CLIENT_ID}>
      <AuthProvider>
        <LoginForm />
      </AuthProvider>
    </GoogleOAuthProvider>
  );
}
