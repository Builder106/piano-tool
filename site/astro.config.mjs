import { defineConfig } from 'astro/config';
import sitemap from '@astrojs/sitemap';

// Build output can live outside the checkout (ASTRO_OUT_DIR), so builds leave no dist/ behind.
export default defineConfig({
  site: 'https://piano-tool.vercel.app',
  outDir: process.env.ASTRO_OUT_DIR ?? './dist',
  trailingSlash: 'always',
  integrations: [sitemap()],
  prefetch: { prefetchAll: true, defaultStrategy: 'hover' },
  build: { inlineStylesheets: 'auto' },
});
