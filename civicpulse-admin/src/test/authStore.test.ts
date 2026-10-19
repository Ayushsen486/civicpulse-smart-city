import { describe, it, expect, beforeEach, vi } from 'vitest';
import { useAuthStore } from '../store/authStore';
import { authApi } from '../api';

vi.mock('../api', () => ({
  authApi: {
    login: vi.fn(),
    getMe: vi.fn(),
    logout: vi.fn(),
  },
}));

describe('AuthStore', () => {
  beforeEach(() => {
    localStorage.clear();
    useAuthStore.setState({
      user: null,
      accessToken: null,
      isAuthenticated: false,
      isLoading: false,
      error: null,
    });
    vi.clearAllMocks();
  });

  it('rejects CITIZEN role and prevents login to admin portal', async () => {
    vi.mocked(authApi.login).mockResolvedValueOnce({
      accessToken: 'jwt-citizen',
      refreshToken: 'refresh-citizen',
      tokenType: 'Bearer',
      expiresIn: 900,
      user: {
        id: 'u-1',
        email: 'citizen@civicpulse.org',
        firstName: 'Citizen',
        lastName: 'One',
        role: 'CITIZEN',
      },
    });

    await expect(
      useAuthStore.getState().login({
        email: 'citizen@civicpulse.org',
        password: 'password123',
      })
    ).rejects.toThrow(/Citizen accounts cannot access/);

    expect(useAuthStore.getState().isAuthenticated).toBe(false);
    expect(localStorage.getItem('civicpulse_access_token')).toBeNull();
  });

  it('successfully logs in ADMIN and sets local storage', async () => {
    const adminUser = {
      id: 'admin-1',
      email: 'admin@civicpulse.city',
      firstName: 'Municipal',
      lastName: 'Admin',
      role: 'ADMIN' as const,
    };

    vi.mocked(authApi.login).mockResolvedValueOnce({
      accessToken: 'jwt-admin',
      refreshToken: 'refresh-admin',
      tokenType: 'Bearer',
      expiresIn: 900,
      user: adminUser,
    });

    await useAuthStore.getState().login({
      email: 'admin@civicpulse.city',
      password: 'AdminPassword123',
    });

    const state = useAuthStore.getState();
    expect(state.isAuthenticated).toBe(true);
    expect(state.user?.role).toBe('ADMIN');
    expect(localStorage.getItem('civicpulse_access_token')).toBe('jwt-admin');
  });

  it('clears state and storage on logout', async () => {
    useAuthStore.setState({
      user: {
        id: 'admin-1',
        email: 'admin@civicpulse.city',
        firstName: 'Municipal',
        lastName: 'Admin',
        role: 'ADMIN',
      },
      accessToken: 'jwt-admin',
      isAuthenticated: true,
    });
    localStorage.setItem('civicpulse_access_token', 'jwt-admin');

    await useAuthStore.getState().logout();

    expect(useAuthStore.getState().isAuthenticated).toBe(false);
    expect(useAuthStore.getState().user).toBeNull();
    expect(localStorage.getItem('civicpulse_access_token')).toBeNull();
  });
});
