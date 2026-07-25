/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./app/**/*.{js,jsx,ts,tsx}",
    "./components/**/*.{js,jsx,ts,tsx}",
  ],
  presets: [require("nativewind/preset")],
  theme: {
    extend: {
      colors: {
        primary: {
          50: "#E3F2FD",
          100: "#BBDEFB",
          500: "#1565C0",
          600: "#1565C0",
          700: "#0D47A1",
          800: "#011A4D",
        },
        brand: {
          blue: "#1565C0",
          cyan: "#57D2E8",
        },
        surface: "#F5F9FC",
      },
    },
  },
  plugins: [],
};
