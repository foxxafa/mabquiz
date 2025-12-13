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
    fetchApi<{ access_token: string; user: any }>('/auth/admin/login', {
      method: 'POST',
      body: JSON.stringify({ username, password }),
    }),

  googleLogin: (idToken: string) =>
    fetchApi<{ access_token: string; user: any }>('/auth/admin/google', {
      method: 'POST',
      body: JSON.stringify({ id_token: idToken }),
    }),

  me: () => fetchApi<any>('/auth/me'),
};

// Questions API (Legacy)
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

// ============ Admin API ============

// Types
export interface Course {
  id: number;
  name: string;
  displayName: string;
  description?: string;
  isActive: boolean;
  topicCount: number;
  createdAt?: string;
  updatedAt?: string;
}

export interface Topic {
  id: number;
  courseId: number;
  name: string;
  displayName: string;
  description?: string;
  isActive: boolean;
  subtopicCount: number;
  course?: { id: number; name: string; displayName: string };
  createdAt?: string;
  updatedAt?: string;
}

export interface Subtopic {
  id: number;
  topicId: number;
  name: string;
  displayName: string;
  description?: string;
  isActive: boolean;
  questionCount: number;
  topic?: { id: number; name: string; displayName: string; courseId: number };
  course?: { id: number; name: string; displayName: string };
  createdAt?: string;
  updatedAt?: string;
}

export interface KnowledgeType {
  id: number;
  name: string;
  displayName: string;
  description?: string;
  isActive: boolean;
  questionCount: number;
  createdAt?: string;
  updatedAt?: string;
}

export interface Question {
  id: string;
  dbId: number;
  prompt: string;
  text: string;
  type: string;
  options?: string[];
  correctAnswer: string;
  explanation?: string;
  matchPairs?: { left: string; right: string }[];
  subtopicId?: number;
  knowledgeTypeId?: number;
  course?: string;
  topic?: string;
  subtopic?: string;
  knowledgeType?: string;
  tags?: string[];
  points: number;
  isActive: boolean;
  subtopicInfo?: { id: number; name: string; displayName: string };
  topicInfo?: { id: number; name: string; displayName: string };
  courseInfo?: { id: number; name: string; displayName: string };
  knowledgeTypeInfo?: { id: number; name: string; displayName: string };
  createdAt?: string;
  updatedAt?: string;
}

export interface AdminStats {
  courses: number;
  topics: number;
  subtopics: number;
  questions: number;
  questionsByType: Record<string, number>;
}

// Admin Courses API
export const adminCoursesApi = {
  getAll: (includeInactive = false) =>
    fetchApi<{ courses: Course[] }>(`/admin/courses?include_inactive=${includeInactive}`),

  getById: (id: number) =>
    fetchApi<Course>(`/admin/courses/${id}`),

  create: (data: { name: string; displayName: string; description?: string }) =>
    fetchApi<Course>('/admin/courses', {
      method: 'POST',
      body: JSON.stringify(data),
    }),

  update: (id: number, data: Partial<{ name: string; displayName: string; description: string; isActive: boolean }>) =>
    fetchApi<Course>(`/admin/courses/${id}`, {
      method: 'PUT',
      body: JSON.stringify(data),
    }),

  delete: (id: number) =>
    fetchApi<{ message: string }>(`/admin/courses/${id}`, {
      method: 'DELETE',
    }),
};

// Admin Topics API
export const adminTopicsApi = {
  getAll: (courseId?: number, includeInactive = false) => {
    let url = `/admin/topics?include_inactive=${includeInactive}`;
    if (courseId) url += `&course_id=${courseId}`;
    return fetchApi<{ topics: Topic[] }>(url);
  },

  getById: (id: number) =>
    fetchApi<Topic>(`/admin/topics/${id}`),

  create: (data: { courseId: number; name: string; displayName: string; description?: string }) =>
    fetchApi<Topic>('/admin/topics', {
      method: 'POST',
      body: JSON.stringify(data),
    }),

  update: (id: number, data: Partial<{ courseId: number; name: string; displayName: string; description: string; isActive: boolean }>) =>
    fetchApi<Topic>(`/admin/topics/${id}`, {
      method: 'PUT',
      body: JSON.stringify(data),
    }),

  delete: (id: number) =>
    fetchApi<{ message: string }>(`/admin/topics/${id}`, {
      method: 'DELETE',
    }),
};

// Admin Subtopics API
export const adminSubtopicsApi = {
  getAll: (topicId?: number, courseId?: number, includeInactive = false) => {
    let url = `/admin/subtopics?include_inactive=${includeInactive}`;
    if (topicId) url += `&topic_id=${topicId}`;
    if (courseId) url += `&course_id=${courseId}`;
    return fetchApi<{ subtopics: Subtopic[] }>(url);
  },

  getById: (id: number) =>
    fetchApi<Subtopic>(`/admin/subtopics/${id}`),

  create: (data: { topicId: number; name: string; displayName: string; description?: string }) =>
    fetchApi<Subtopic>('/admin/subtopics', {
      method: 'POST',
      body: JSON.stringify(data),
    }),

  update: (id: number, data: Partial<{ topicId: number; name: string; displayName: string; description: string; isActive: boolean }>) =>
    fetchApi<Subtopic>(`/admin/subtopics/${id}`, {
      method: 'PUT',
      body: JSON.stringify(data),
    }),

  delete: (id: number) =>
    fetchApi<{ message: string }>(`/admin/subtopics/${id}`, {
      method: 'DELETE',
    }),
};

// Admin Knowledge Types API
export const adminKnowledgeTypesApi = {
  getAll: (includeInactive = false) =>
    fetchApi<{ knowledgeTypes: KnowledgeType[] }>(`/admin/knowledge-types?include_inactive=${includeInactive}`),

  create: (data: { name: string; displayName: string; description?: string }) =>
    fetchApi<KnowledgeType>('/admin/knowledge-types', {
      method: 'POST',
      body: JSON.stringify(data),
    }),

  update: (id: number, data: Partial<{ name: string; displayName: string; description: string; isActive: boolean }>) =>
    fetchApi<KnowledgeType>(`/admin/knowledge-types/${id}`, {
      method: 'PUT',
      body: JSON.stringify(data),
    }),

  seed: () =>
    fetchApi<{ message: string; created: string[] }>('/admin/knowledge-types/seed', {
      method: 'POST',
    }),
};

// Admin Questions API
export const adminQuestionsApi = {
  getAll: (filters?: {
    subtopicId?: number;
    topicId?: number;
    courseId?: number;
    knowledgeTypeId?: number;
    questionType?: string;
    includeInactive?: boolean;
    limit?: number;
    offset?: number;
  }) => {
    const params = new URLSearchParams();
    if (filters?.subtopicId) params.append('subtopic_id', filters.subtopicId.toString());
    if (filters?.topicId) params.append('topic_id', filters.topicId.toString());
    if (filters?.courseId) params.append('course_id', filters.courseId.toString());
    if (filters?.knowledgeTypeId) params.append('knowledge_type_id', filters.knowledgeTypeId.toString());
    if (filters?.questionType) params.append('question_type', filters.questionType);
    if (filters?.includeInactive) params.append('include_inactive', 'true');
    if (filters?.limit) params.append('limit', filters.limit.toString());
    if (filters?.offset) params.append('offset', filters.offset.toString());

    return fetchApi<{ questions: Question[]; total: number; limit: number; offset: number }>(
      `/admin/questions?${params.toString()}`
    );
  },

  getById: (id: number) =>
    fetchApi<Question>(`/admin/questions/${id}`),

  create: (data: {
    subtopicId: number;
    knowledgeTypeId: number;
    type: string;
    text: string;
    options?: string[];
    correctAnswer: string;
    explanation?: string;
    matchPairs?: { left: string; right: string }[];
    points?: number;
    tags?: string[];
  }) =>
    fetchApi<Question>('/admin/questions', {
      method: 'POST',
      body: JSON.stringify(data),
    }),

  update: (id: number, data: Partial<{
    subtopicId: number;
    knowledgeTypeId: number;
    type: string;
    text: string;
    options: string[];
    correctAnswer: string;
    explanation: string;
    matchPairs: { left: string; right: string }[];
    points: number;
    tags: string[];
    isActive: boolean;
  }>) =>
    fetchApi<Question>(`/admin/questions/${id}`, {
      method: 'PUT',
      body: JSON.stringify(data),
    }),

  delete: (id: number) =>
    fetchApi<{ message: string }>(`/admin/questions/${id}`, {
      method: 'DELETE',
    }),
};

// Admin Stats API
export const adminStatsApi = {
  getStats: () => fetchApi<AdminStats>('/admin/stats'),
};
