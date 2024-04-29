import type { Config } from "tailwindcss"

export default {
  content: ["./app/**/*.{ts,tsx}"],
  theme: {
    extend: {
      fontFamily: {
        mono: ["Fira Code Variable", "monospace"],
      },
    },
  },
  plugins: [],
} satisfies Config
