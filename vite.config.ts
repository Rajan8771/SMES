import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

const env = (globalThis as { process?: { env?: Record<string, string | undefined> } }).process?.env;

export default defineConfig({
  base: env?.GITHUB_PAGES ? "/SMES/" : "/",
  plugins: [react()],
  server: {
    host: "0.0.0.0",
    port: 5173,
  },
});
