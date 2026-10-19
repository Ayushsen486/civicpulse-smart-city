import { create } from 'zustand';
import { User, LoginRequest } from '../types/auth';
import { authApi } from '../api';

interface AuthState {
  user: User | null;
  accessToken: string | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  error: string | null;
  login: (credentials: LoginRequest) => Promise<void>;
  logout: () => Promise<void>;
  checkAuth: () => Promise<void>;
  clearError: () => void;
}

const getStoredUser = (): User | null => {
  try {
    const raw = localStorage.getItem('civicpulse_user');
    return raw ? JSON.parse(raw) : null;
  } catch {
    return null;
  }
};

export const useAuthStore = create<AuthState>((set) => ({
  user: getStoredUser(),
  accessToken: localStorage.getItem('civicpulse_access_token'),
  isAuthenticated: !!localStorage.getItem('civicpulse_access_token'),
  isLoading: false,
  error: null,

  login: async (credentials) => {
    set({ isLoading: true, error: null });
    try {
      const data = await authApi.login(credentials);

      // Verify that the user is not a CITIZEN
      if (data.user.role === 'CITIZEN') {
        throw new Error(
          'Access Denied: Citizen accounts cannot access the administrative dashboard. Please use the CivicPulse mobile app.'
        );
      }

      localStorage.setItem('civicpulse_access_token', data.accessToken);
      localStorage.setItem('civicpulse_refresh_token', data.refreshToken);
      localStorage.setItem('civicpulse_user', JSON.stringify(data.user));

      set({
        user: data.user,
        accessToken: data.accessToken,
        isAuthenticated: true,
        isLoading: false,
        error: null,
      });
    } catch (err: unknown) {
      const message =
        err instanceof Error
          ? err.message
          : (err as { response?: { data?: { detail?: string; message?: string } } })?.response?.data?.detail ||
            'Invalid credentials or server error. Please try again.';
      set({ isLoading: false, error: message });
      throw new Error(message);
    }
  },

  logout: async () => {
    try {
      await authApi.logout();
    } finally {
      localStorage.removeItem('civicpulse_access_token');
      localStorage.removeItem('civicpulse_refresh_token');
      localStorage.removeItem('civicpulse_user');
      set({
        user: null,
        accessToken: null,
        isAuthenticated: false,
        isLoading: false,
        error: null,
      });
    }
  },

  checkAuth: async () => {
    const token = localStorage.getItem('civicpulse_access_token');
    if (!token) {
      set({ user: null, isAuthenticated: false });
      return;
    }
    try {
      const user = await authApi.getMe();
      if (user.role === 'CITIZEN') {
        throw new Error('Access Denied');
      }
      localStorage.setItem('civicpulse_user', JSON.stringify(user));
      set({ user, isAuthenticated: true });
    } catch {
      localStorage.removeItem('civicpulse_access_token');
      localStorage.removeItem('civicpulse_refresh_token');
      localStorage.removeItem('civicpulse_user');
      set({ user: null, isAuthenticated: false });
    }
  },

  clearError: () => set({ error: null }),
}));

// Global auth expiration listener
if (typeof window !== 'undefined') {
  window.addEventListener('civicpulse_auth_expired', () => {
    useAuthStore.getState().logout();
  });
}
