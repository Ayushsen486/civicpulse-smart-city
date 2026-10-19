/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        primary: {
          DEFAULT: '#1E3A8A',
          hover: '#1D4ED8',
          light: '#3B82F6',
          dark: '#172554',
        },
        secondary: {
          DEFAULT: '#0D9488',
          hover: '#0F766E',
          light: '#14B8A6',
        },
        status: {
          reported: '#64748B',
          acknowledged: '#0284C7',
          assigned: '#6366F1',
          in_progress: '#D97706',
          resolved: '#10B981',
          closed: '#475569',
        },
        priority: {
          low: '#3B82F6',
          medium: '#F59E0B',
          high: '#F97316',
          critical: '#EF4444',
        },
      },
    },
  },
  plugins: [],
}
