import { create } from 'zustand';
import { persist } from 'zustand/middleware';

export const useAuthStore = create(
  persist(
    (set, get) => ({
      user: null,
      token: null,
      refreshToken: null,

      setAuth: (user, accessToken, refreshToken) => set({
        user,
        token: accessToken,
        refreshToken,
      }),

      setTokens: (accessToken, refreshToken) => set({
        token: accessToken,
        refreshToken,
      }),

      logout: () => set({
        user: null,
        token: null,
        refreshToken: null,
      }),

      isAdmin: () => get().user?.role === 'ADMIN',
      isVet: () => get().user?.role === 'VETERINARIO',
      hasRole: (...roles) => roles.includes(get().user?.role),
    }),
    {
      name: 'vetclinic-auth',
      partialize: (state) => ({
        user: state.user,
        token: state.token,
        refreshToken: state.refreshToken,
      }),
    }
  )
);
