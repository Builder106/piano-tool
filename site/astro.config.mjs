import { defineConfig } from 'astro/config';
import sitemap from '@astrojs/sitemap';

// Build output can live outside the checkout (ASTRO_OUT_DIR), so builds leave no dist/ behind.
export default defineConfig({
  site: 'https://piano-tool.vercel.app',
  outDir: process.env.ASTRO_OUT_DIR ?? './dist',
  trailingSlash: 'always',
  integrations: [sitemap()],
  prefetch: { prefetchAll: true, defaultStrategy: 'hover' },
  // The pages were renamed when the site was rewritten for beginners; old links still land.
  redirects: {
    '/listening': '/listens/',
    '/staff': '/marks/',
    '/shape': '/timing/',
    '/midi': '/plug-in/',
    '/import': '/stages/',
  },
  build: { inlineStylesheets: 'auto' },
});
