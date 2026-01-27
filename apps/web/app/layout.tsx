import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'Site360 - Construction Site Management',
  description: 'Bringing transparency, efficiency, and data-driven decision-making to the building industry.',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className="min-h-screen bg-gray-50 antialiased">
        {children}
      </body>
    </html>
  );
}
