/** @type {import('next').NextConfig} */
const nextConfig = {
  experimental: {
    transpilePackages: ["lucide-react", "@repo/tailwind-config"],
  },
};

export default nextConfig;
