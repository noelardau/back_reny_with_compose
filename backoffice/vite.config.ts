import { reactRouter } from "@react-router/dev/vite";
import tailwindcss from "@tailwindcss/vite";
import { defineConfig } from "vite";
import tsconfigPaths from "vite-tsconfig-paths";

export default defineConfig({
  plugins: [tailwindcss(), reactRouter(), tsconfigPaths()],
    server: {
    host: true,
    watch: {
      usePolling: true,   // 👈 active le polling
      interval: 100,      // 👈 interval de 100ms (ajuste si besoin)
    }
  }
});
