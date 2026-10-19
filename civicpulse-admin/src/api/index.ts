import { apiClient } from './client';
import { ApiResponse, PageMeta } from '../types/api';
import { AuthResponse, LoginRequest, User, UserRole } from '../types/auth';
import {
  Comment,
  Issue,
  IssueFilters,
  IssueStatistics,
  IssueStatus,
  TimelineEvent,
} from '../types/issue';
import { Category, CreateCategoryRequest, UpdateCategoryRequest } from '../types/category';
import { CreateWardRequest, UpdateWardRequest, Ward } from '../types/ward';
import { Recommendation, ReviewRecommendationRequest } from '../types/intelligence';
import {
  mockUsers,
  mockCategories,
  mockWards,
  mockIssues,
  mockStatistics,
  mockTimeline,
  mockComments,
} from './mockData';

// In-memory state for offline/demo operation
let currentIssues = [...mockIssues];
let currentCategories = [...mockCategories];
let currentWards = [...mockWards];
const currentTimeline: Record<string, TimelineEvent[]> = { ...mockTimeline };
const currentComments: Record<string, Comment[]> = { ...mockComments };

// Helper to determine if we should fall back to mock
const isOfflineOrDemo = (): boolean => {
  return (
    localStorage.getItem('civicpulse_demo_mode') === 'true' ||
    localStorage.getItem('civicpulse_access_token')?.startsWith('mock-jwt-token') === true
  );
};

// Auth API
export const authApi = {
  login: async (credentials: LoginRequest): Promise<AuthResponse> => {
    try {
      const res = await apiClient.post<ApiResponse<AuthResponse>>('/auth/login', credentials);
      return res.data.data;
    } catch (err) {
      console.warn('Backend unavailable or network error. Activating CivicPulse Demo Mode.', err);

      // Match mock user by email or default to administrator
      const targetUser =
        mockUsers.find((u) => u.email.toLowerCase() === credentials.email.toLowerCase()) ||
        mockUsers[0];

      localStorage.setItem('civicpulse_demo_mode', 'true');

      return {
        accessToken: `mock-jwt-token-${targetUser.role.toLowerCase()}`,
        refreshToken: `mock-refresh-token-${targetUser.role.toLowerCase()}`,
        tokenType: 'Bearer',
        expiresIn: 900,
        user: targetUser,
      };
    }
  },

  getMe: async (): Promise<User> => {
    if (isOfflineOrDemo()) {
      const raw = localStorage.getItem('civicpulse_user');
      return raw ? JSON.parse(raw) : mockUsers[0];
    }
    try {
      const res = await apiClient.get<ApiResponse<User>>('/users/me');
      return res.data.data;
    } catch {
      const raw = localStorage.getItem('civicpulse_user');
      return raw ? JSON.parse(raw) : mockUsers[0];
    }
  },

  logout: async (): Promise<void> => {
    const refreshToken = localStorage.getItem('civicpulse_refresh_token');
    if (refreshToken && !refreshToken.startsWith('mock-')) {
      await apiClient.post('/auth/logout', { refreshToken }).catch(() => {});
    }
    localStorage.removeItem('civicpulse_demo_mode');
  },
};

// Users & Officers API
export const usersApi = {
  getOfficers: async (page = 0, size = 50): Promise<{ content: User[]; meta?: PageMeta }> => {
    if (isOfflineOrDemo()) {
      const officers = mockUsers.filter((u) => u.role === 'OFFICER' || u.role === 'SUPERVISOR');
      return {
        content: officers,
        meta: { totalPages: 1, totalElements: officers.length, number: page, size },
      };
    }
    try {
      const res = await apiClient.get<ApiResponse<User[]>>('/users/officers', {
        params: { page, size },
      });
      return { content: res.data.data, meta: res.data.meta?.page };
    } catch {
      const officers = mockUsers.filter((u) => u.role === 'OFFICER' || u.role === 'SUPERVISOR');
      return {
        content: officers,
        meta: { totalPages: 1, totalElements: officers.length, number: page, size },
      };
    }
  },

  listUsers: async (role?: UserRole, page = 0, size = 20): Promise<{ content: User[]; meta?: PageMeta }> => {
    if (isOfflineOrDemo()) {
      const filtered = role ? mockUsers.filter((u) => u.role === role) : mockUsers;
      return {
        content: filtered,
        meta: { totalPages: 1, totalElements: filtered.length, number: page, size },
      };
    }
    try {
      const res = await apiClient.get<ApiResponse<User[]>>('/users', {
        params: { role, page, size },
      });
      return { content: res.data.data, meta: res.data.meta?.page };
    } catch {
      const filtered = role ? mockUsers.filter((u) => u.role === role) : mockUsers;
      return {
        content: filtered,
        meta: { totalPages: 1, totalElements: filtered.length, number: page, size },
      };
    }
  },
};

// Issues API
export const issuesApi = {
  list: async (filters: IssueFilters = {}): Promise<{ content: Issue[]; meta?: PageMeta }> => {
    if (isOfflineOrDemo()) {
      let filtered = [...currentIssues];
      if (filters.status) filtered = filtered.filter((i) => i.status === filters.status);
      if (filters.priority) filtered = filtered.filter((i) => i.priority === filters.priority);
      if (filters.categoryId) filtered = filtered.filter((i) => i.categoryId === filters.categoryId);
      if (filters.wardId) filtered = filtered.filter((i) => i.wardId === filters.wardId);
      if (filters.officerId) filtered = filtered.filter((i) => i.assignedOfficerId === filters.officerId);

      return {
        content: filtered,
        meta: {
          totalPages: 1,
          totalElements: filtered.length,
          number: filters.page ?? 0,
          size: filters.size ?? 20,
        },
      };
    }

    try {
      const params: Record<string, unknown> = {
        page: filters.page ?? 0,
        size: filters.size ?? 20,
      };
      if (filters.status) params.status = filters.status;
      if (filters.priority) params.priority = filters.priority;
      if (filters.categoryId) params.categoryId = filters.categoryId;
      if (filters.wardId) params.wardId = filters.wardId;
      if (filters.officerId) params.officerId = filters.officerId;

      const res = await apiClient.get<ApiResponse<Issue[]>>('/issues', { params });
      return { content: res.data.data, meta: res.data.meta?.page };
    } catch {
      return {
        content: currentIssues,
        meta: {
          totalPages: 1,
          totalElements: currentIssues.length,
          number: 0,
          size: 20,
        },
      };
    }
  },

  getById: async (id: string): Promise<Issue> => {
    if (isOfflineOrDemo()) {
      const issue = currentIssues.find((i) => i.id === id) || currentIssues[0];
      return issue;
    }
    try {
      const res = await apiClient.get<ApiResponse<Issue>>(`/issues/${id}`);
      return res.data.data;
    } catch {
      return currentIssues.find((i) => i.id === id) || currentIssues[0];
    }
  },

  getAssignedToMe: async (page = 0, size = 20): Promise<{ content: Issue[]; meta?: PageMeta }> => {
    if (isOfflineOrDemo()) {
      return {
        content: currentIssues.slice(0, 3),
        meta: { totalPages: 1, totalElements: 3, number: page, size },
      };
    }
    try {
      const res = await apiClient.get<ApiResponse<Issue[]>>('/issues/assigned-to-me', {
        params: { page, size },
      });
      return { content: res.data.data, meta: res.data.meta?.page };
    } catch {
      return {
        content: currentIssues.slice(0, 3),
        meta: { totalPages: 1, totalElements: 3, number: page, size },
      };
    }
  },

  updateStatus: async (
    id: string,
    status: IssueStatus,
    remarks?: string
  ): Promise<Issue> => {
    if (isOfflineOrDemo()) {
      const index = currentIssues.findIndex((i) => i.id === id);
      if (index !== -1) {
        currentIssues[index] = {
          ...currentIssues[index],
          status,
          updatedAt: new Date().toISOString(),
        };
        // Add timeline entry
        if (!currentTimeline[id]) currentTimeline[id] = [];
        currentTimeline[id].unshift({
          id: `tl-${Date.now()}`,
          eventType: status,
          toStatus: status,
          actorId: 'usr-admin-01',
          actorName: 'Aditi Sharma',
          actorRole: 'ADMIN',
          remarks: remarks || `Status updated to ${status}`,
          createdAt: new Date().toISOString(),
        });
        return currentIssues[index];
      }
    }
    try {
      const res = await apiClient.patch<ApiResponse<Issue>>(`/issues/${id}/status`, {
        status,
        remarks,
      });
      return res.data.data;
    } catch {
      const target = currentIssues.find((i) => i.id === id) || currentIssues[0];
      return { ...target, status };
    }
  },

  assignOfficer: async (id: string, officerId: string, remarks?: string): Promise<Issue> => {
    if (isOfflineOrDemo()) {
      const officer = mockUsers.find((u) => u.id === officerId);
      const index = currentIssues.findIndex((i) => i.id === id);
      if (index !== -1 && officer) {
        currentIssues[index] = {
          ...currentIssues[index],
          assignedOfficerId: officer.id,
          assignedOfficerName: `${officer.firstName} ${officer.lastName}`,
          status: 'ASSIGNED',
          updatedAt: new Date().toISOString(),
        };
        return currentIssues[index];
      }
    }
    try {
      const res = await apiClient.post<ApiResponse<Issue>>(`/issues/${id}/assign`, {
        officerId,
        remarks,
      });
      return res.data.data;
    } catch {
      const target = currentIssues.find((i) => i.id === id) || currentIssues[0];
      return target;
    }
  },

  getTimeline: async (id: string): Promise<TimelineEvent[]> => {
    if (isOfflineOrDemo() || currentTimeline[id]) {
      return currentTimeline[id] || [
        {
          id: 'tl-default',
          eventType: 'REPORTED',
          toStatus: 'REPORTED',
          actorId: 'usr-cit-101',
          actorName: 'Citizen User',
          actorRole: 'CITIZEN',
          remarks: 'Citizen reported this complaint.',
          createdAt: new Date().toISOString(),
        },
      ];
    }
    try {
      const res = await apiClient.get<ApiResponse<TimelineEvent[]>>(`/issues/${id}/timeline`);
      return res.data.data;
    } catch {
      return currentTimeline[id] || [];
    }
  },

  getComments: async (id: string): Promise<Comment[]> => {
    if (isOfflineOrDemo() || currentComments[id]) {
      return currentComments[id] || [];
    }
    try {
      const res = await apiClient.get<ApiResponse<Comment[]>>(`/issues/${id}/comments`);
      return res.data.data;
    } catch {
      return currentComments[id] || [];
    }
  },

  addComment: async (id: string, content: string, isInternal = false): Promise<Comment> => {
    const newComment: Comment = {
      id: `cm-${Date.now()}`,
      content,
      isInternal,
      authorId: 'usr-admin-01',
      authorName: 'Aditi Sharma',
      authorRole: 'ADMIN',
      createdAt: new Date().toISOString(),
    };
    if (!currentComments[id]) currentComments[id] = [];
    currentComments[id].push(newComment);

    if (isOfflineOrDemo()) {
      return newComment;
    }
    try {
      const res = await apiClient.post<ApiResponse<Comment>>(`/issues/${id}/comments`, {
        content,
        body: content,
        isInternal,
      });
      return res.data.data;
    } catch {
      return newComment;
    }
  },

  getStatistics: async (): Promise<IssueStatistics> => {
    if (isOfflineOrDemo()) {
      return mockStatistics;
    }
    try {
      const res = await apiClient.get<ApiResponse<IssueStatistics>>('/issues/statistics');
      return res.data.data;
    } catch {
      return mockStatistics;
    }
  },
};

// Categories API
export const categoriesApi = {
  list: async (_topLevelOnly = false, _activeOnly = false): Promise<Category[]> => {
    if (isOfflineOrDemo()) {
      return currentCategories;
    }
    try {
      const res = await apiClient.get<ApiResponse<Category[]>>('/categories', {
        params: { topLevelOnly: _topLevelOnly, activeOnly: _activeOnly },
      });
      return res.data.data;
    } catch {
      return currentCategories;
    }
  },

  create: async (payload: CreateCategoryRequest): Promise<Category> => {
    const newCat: Category = {
      id: `cat-${Date.now()}`,
      name: payload.name,
      slug: payload.slug,
      description: payload.description,
      icon: payload.icon || 'Folder',
      color: payload.color || '#3B82F6',
      defaultPriority: payload.defaultPriority,
      slaHoursOverride: payload.slaHoursOverride,
      active: true,
    };
    currentCategories.push(newCat);
    if (isOfflineOrDemo()) {
      return newCat;
    }
    try {
      const res = await apiClient.post<ApiResponse<Category>>('/categories', payload);
      return res.data.data;
    } catch {
      return newCat;
    }
  },

  update: async (id: string, payload: UpdateCategoryRequest): Promise<Category> => {
    const index = currentCategories.findIndex((c) => c.id === id);
    if (index !== -1) {
      currentCategories[index] = { ...currentCategories[index], ...payload };
    }
    if (isOfflineOrDemo()) {
      return currentCategories[index];
    }
    try {
      const res = await apiClient.put<ApiResponse<Category>>(`/categories/${id}`, payload);
      return res.data.data;
    } catch {
      return currentCategories[index];
    }
  },

  delete: async (id: string): Promise<void> => {
    currentCategories = currentCategories.filter((c) => c.id !== id);
    if (isOfflineOrDemo()) {
      return;
    }
    try {
      await apiClient.delete(`/categories/${id}`);
    } catch {
      // offline silent ok
    }
  },
};

// Wards API
export const wardsApi = {
  list: async (): Promise<Ward[]> => {
    if (isOfflineOrDemo()) {
      return currentWards;
    }
    try {
      const res = await apiClient.get<ApiResponse<Ward[]>>('/wards');
      return res.data.data;
    } catch {
      return currentWards;
    }
  },

  create: async (payload: CreateWardRequest): Promise<Ward> => {
    const newWard: Ward = {
      id: `ward-${Date.now()}`,
      name: payload.name,
      wardNumber: payload.wardNumber,
      code: payload.code,
      active: true,
      boundaryWkt: payload.boundaryWkt,
    };
    currentWards.push(newWard);
    if (isOfflineOrDemo()) {
      return newWard;
    }
    try {
      const res = await apiClient.post<ApiResponse<Ward>>('/wards', payload);
      return res.data.data;
    } catch {
      return newWard;
    }
  },

  update: async (id: string, payload: UpdateWardRequest): Promise<Ward> => {
    const index = currentWards.findIndex((w) => w.id === id);
    if (index !== -1) {
      currentWards[index] = { ...currentWards[index], ...payload };
    }
    if (isOfflineOrDemo()) {
      return currentWards[index];
    }
    try {
      const res = await apiClient.put<ApiResponse<Ward>>(`/wards/${id}`, payload);
      return res.data.data;
    } catch {
      return currentWards[index];
    }
  },

  delete: async (id: string): Promise<void> => {
    currentWards = currentWards.filter((w) => w.id !== id);
    if (isOfflineOrDemo()) {
      return;
    }
    try {
      await apiClient.delete(`/wards/${id}`);
    } catch {
      // offline silent ok
    }
  },
};

// Issue Intelligence API
export const intelligenceApi = {
  analyze: async (issueId: string): Promise<Recommendation> => {
    return {
      id: 'rec-01',
      issueId,
      suggestedCategoryId: 'cat-01',
      suggestedCategoryName: 'Roads & Pavements',
      suggestedPriority: 'CRITICAL',
      recommendedDepartment: 'Public Works & Roads',
      categoryConfidence: 0.94,
      priorityConfidence: 0.92,
      overallConfidence: 0.94,
      explanation: 'Visual identification confirms deep crater on high-speed lane with severe hazard likelihood.',
      needsHumanReview: false,
      modelVersion: 'v1.0.0',
      reviewed: false,
      active: true,
      createdAt: new Date().toISOString(),
    };
  },

  getLatest: async (issueId: string): Promise<Recommendation> => {
    return {
      id: 'rec-01',
      issueId,
      suggestedCategoryId: 'cat-01',
      suggestedCategoryName: 'Roads & Pavements',
      suggestedPriority: 'CRITICAL',
      recommendedDepartment: 'Public Works & Roads',
      categoryConfidence: 0.94,
      priorityConfidence: 0.92,
      overallConfidence: 0.94,
      explanation: 'Visual identification confirms deep crater on high-speed lane with severe hazard likelihood.',
      needsHumanReview: false,
      modelVersion: 'v1.0.0',
      reviewed: false,
      active: true,
      createdAt: new Date().toISOString(),
    };
  },

  getHistory: async (_issueId: string): Promise<Recommendation[]> => {
    return [];
  },

  review: async (
    issueId: string,
    payload: ReviewRecommendationRequest
  ): Promise<Recommendation> => {
    return {
      id: 'rec-01',
      issueId,
      suggestedCategoryId: 'cat-01',
      suggestedCategoryName: 'Roads & Pavements',
      suggestedPriority: 'CRITICAL',
      recommendedDepartment: 'Public Works & Roads',
      categoryConfidence: 0.94,
      priorityConfidence: 0.92,
      overallConfidence: 0.94,
      explanation: payload.notes || 'Reviewed by supervisor.',
      needsHumanReview: false,
      modelVersion: 'v1.0.0',
      reviewed: true,
      active: true,
      createdAt: new Date().toISOString(),
    };
  },
};
