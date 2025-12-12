const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'https://mabquiz-production.up.railway.app/api/v1';

interface ApiResponse<T> {
  data?: T;
  error?: string;
}

async function fetchApi<T>(
  endpoint: string,
  options: RequestInit = {}
): Promise<ApiResponse<T>> {
  try {
    const token = typeof window !== 'undefined' ? localStorage.getItem('token') : null;

    const headers: HeadersInit = {
      'Content-Type': 'application/json',
      ...options.headers,
    };

    if (token) {
      (headers as Record<string, string>)['Authorization'] = `Bearer ${token}`;
    }

    const response = await fetch(`${API_BASE_URL}${endpoint}`, {
      ...options,
      headers,
    });

    if (!response.ok) {
      const error = await response.json().catch(() => ({ detail: 'Bir hata olustu' }));
      return { error: error.detail || 'Bir hata olustu' };
    }

    const data = await response.json();
    return { data };
  } catch (error) {
    return { error: 'Sunucuya baglanilamadi' };
  }
}

// Auth API
export const authApi = {
  login: (username: string, password: string) =>
    fetchApi<{ access_token: string; user: any }>('/auth/login', {
      method: 'POST',
      body: JSON.stringify({ username, password }),
    }),

  me: () => fetchApi<any>('/auth/me'),
};

// Questions API
export const questionsApi = {
  getAll: () => fetchApi<any[]>('/questions'),

  getById: (id: string) => fetchApi<any>(`/questions/${id}`),

  create: (question: any) =>
    fetchApi<any>('/questions', {
      method: 'POST',
      body: JSON.stringify(question),
    }),

  update: (id: string, question: any) =>
    fetchApi<any>(`/questions/${id}`, {
      method: 'PUT',
      body: JSON.stringify(question),
    }),

  delete: (id: string) =>
    fetchApi<void>(`/questions/${id}`, {
      method: 'DELETE',
    }),
};

// Users API
export const usersApi = {
  getAll: () => fetchApi<any[]>('/users'),
};
