/** @type {import('tailwindcss').Config} */
export default {
  darkMode: 'class',
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      gridTemplateColumns:{
        'auto':'repeat(auto-fill, minmax(200px, 1fr))'
      },
      colors:{
        'primary':'#0ea5e9',
        'admin': '#0ea5e9',
        'dean': '#14b8a6',
        'doctor': '#6366f1',
        'health': '#14b8a6',
        'mc-bg': 'var(--mc-bg)',
        'mc-surface': 'var(--mc-surface)',
        'mc-surface-elevated': 'var(--mc-surface-elevated)',
        'mc-text': 'var(--mc-text)',
        'mc-text-muted': 'var(--mc-text-muted)',
        'mc-border': 'var(--mc-border)',
        'mc-accent': 'var(--mc-accent)',
      }
    },
  },
  plugins: [],
}
