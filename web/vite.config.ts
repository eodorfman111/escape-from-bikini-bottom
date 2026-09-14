import { defineConfig } from 'vite'

export default defineConfig(({ mode }) => ({
  base: './',
  build: { assetsInlineLimit: 0 },
  plugins: mode === 'desktop' ? [{
    name: 'desktop-content-security-policy',
    transformIndexHtml: () => [{
      tag: 'meta',
      attrs: {
        'http-equiv': 'Content-Security-Policy',
        content: [
          "default-src 'none'",
          "script-src 'self'",
          "style-src 'self' 'unsafe-inline'",
          "img-src 'self' blob:",
          "font-src 'self'",
          "media-src 'self' blob:",
          "connect-src 'self'",
          "worker-src 'self' blob:",
          "object-src 'none'",
          "frame-src 'none'",
          "base-uri 'none'",
          "form-action 'none'",
        ].join('; '),
      },
      injectTo: 'head-prepend',
    }],
  }] : [],
}))
