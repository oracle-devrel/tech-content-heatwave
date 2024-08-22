/** @type {import('next').NextConfig} */
module.exports = {
    eslint: {
        // Disabling on production builds because we're running checks on PRs via GitHub Actions.
        ignoreDuringBuilds: true,
    },
    images: {
        formats: ['image/avif', 'image/webp'],
        remotePatterns: [
            {
                protocol: 'https',
                hostname: 'd2j6dbq0eux0bg-cdn.ecwid.net',
                pathname: '/images/**',
            },
            {
                protocol: 'https',
                hostname: 'd2j6dbq0eux0bg.cloudfront.net',
                pathname: '/images/**',
            },
        ],
    },
    async redirects() {
        return [
            {
                source: '/password',
                destination: '/',
                permanent: true,
            },
        ];
    },
};
