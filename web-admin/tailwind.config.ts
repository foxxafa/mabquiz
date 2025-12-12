import type { Config } from "tailwindcss";

const config: Config = {
  content: [
    "./src/pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/components/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      colors: {
        primary: "#7C3AED",
        secondary: "#10B981",
        background: "#0f0f0f",
        surface: "#1a1a1a",
        "surface-light": "#2a2a2a",
      },
    },
  },
  plugins: [],
};

export default config;