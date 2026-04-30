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
        background: {
          DEFAULT: "#FAF8F5",  // Warm cream/beige
          light: "#FAF8F5",
        },
        surface: {
          DEFAULT: "#F5F1EB",  // Light coffee cream
          light: "#FEFDFB",    // Almost white with warm tint
        },
        text: {
          primary: {
            DEFAULT: "#3E2723",  // Deep walnut brown
            light: "#3E2723",
          },
          secondary: {
            DEFAULT: "#6D4C41",  // Medium coffee brown
            light: "#6D4C41",
          },
        },
        accent: {
          primary: "#5D4037",    // Rich walnut
          secondary: "#8D6E63",  // Light coffee
          hover: "#4E342E",      // Dark coffee
          cream: "#D7CCC8",      // Soft cream accent
        },
        border: {
          DEFAULT: "rgba(93, 64, 55, 0.08)",  // Walnut with transparency
          light: "rgba(93, 64, 55, 0.04)",
        },
      },
      fontFamily: {
        sans: ["var(--font-inter)", "Inter", "system-ui", "sans-serif"],
        mono: ["var(--font-jetbrains-mono)", "JetBrains Mono", "monospace"],
      },
      boxShadow: {
        'card': '0 1px 3px rgba(62, 39, 35, 0.04), 0 1px 2px rgba(62, 39, 35, 0.06)',
        'card-hover': '0 10px 15px rgba(62, 39, 35, 0.08), 0 4px 6px rgba(62, 39, 35, 0.04)',
        'card-lg': '0 20px 25px rgba(62, 39, 35, 0.12), 0 10px 10px rgba(62, 39, 35, 0.04)',
      },
    },
  },
  plugins: [],
};

export default config;
