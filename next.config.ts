import type { NextConfig } from 'next';
import createNextIntlPlugin from 'next-intl/plugin';

const withNextIntl = createNextIntlPlugin('./src/lib/i18n/request.ts');

const nextConfig: NextConfig = {
  reactStrictMode: true,
  poweredByHeader: false,
  // typedRoutes is intentionally not set. In Next 15.1 it lives under
  // `experimental.typedRoutes`, not at the top level — as a root key it is
  // ignored and warns. It is off by default, which is what we want anyway:
  // the navigation tree is filtered from permission data at runtime
  // (src/config/navigation.ts), so hrefs are typed `string` until the approved
  // screen set fixes the route literals. Enable it via `experimental` once
  // routes are stable.
  eslint: { ignoreDuringBuilds: false },
  typescript: { ignoreBuildErrors: false },
  async headers() {
    // Baseline security headers. CSP is intentionally NOT set here:
    // it depends on the (undecided) map, analytics and payment providers.
    // See docs/MISSING-INFORMATION.md — MI-13.
    return [
      {
        source: '/:path*',
        headers: [
          { key: 'X-Content-Type-Options', value: 'nosniff' },
          { key: 'Referrer-Policy', value: 'strict-origin-when-cross-origin' },
          { key: 'X-Frame-Options', value: 'DENY' },
        ],
      },
    ];
  },
};

export default withNextIntl(nextConfig);
