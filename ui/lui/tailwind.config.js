/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{ts,tsx}'],
  theme: {
    extend: {
      colors: {
        lui: {
          accent: 'var(--lui-accent, #18181b)',
          accentForeground: 'var(--lui-accent-foreground, #fafafa)',
          accentSoft: 'var(--lui-accent-soft, #f4f4f5)',
          background: 'var(--lui-background, transparent)',
          ink: 'var(--lui-ink, #09090b)',
          line: 'var(--lui-line, #e4e4e7)',
          muted: 'var(--lui-muted, #71717a)',
          panel: 'var(--lui-panel, #ffffff)',
          panelSoft: 'var(--lui-panel-soft, #f4f4f5)',
        },
      },
      fontFamily: {
        sans: ['var(--lui-font)', 'ui-sans-serif', 'system-ui', 'sans-serif'],
      },
      boxShadow: {
        lui: '0 10px 15px -3px rgb(0 0 0 / 0.1), 0 4px 6px -4px rgb(0 0 0 / 0.1)',
      },
    },
  },
  plugins: [],
}
