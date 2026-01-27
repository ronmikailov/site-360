export default function HomePage() {
  return (
    <main className="flex min-h-screen flex-col">
      {/* Header */}
      <header className="border-b bg-white">
        <div className="container mx-auto px-4 py-6">
          <h1 className="text-3xl font-bold text-primary-600">
            Site360
          </h1>
          <p className="mt-2 text-gray-600">
            Construction Site Management Platform
          </p>
        </div>
      </header>

      {/* Hero Section */}
      <section className="flex-1 bg-gradient-to-b from-primary-50 to-white">
        <div className="container mx-auto px-4 py-20">
          <div className="max-w-3xl">
            <h2 className="text-5xl font-bold text-gray-900">
              Bringing transparency to construction
            </h2>
            <p className="mt-6 text-xl text-gray-600">
              Replace fragmented communication with a centralized system for material tracking,
              project management, and compliance monitoring.
            </p>

            <div className="mt-10 flex gap-4">
              <button className="rounded-lg bg-primary-600 px-6 py-3 text-white font-semibold hover:bg-primary-700 transition-colors">
                Get Started
              </button>
              <button className="rounded-lg border border-gray-300 px-6 py-3 font-semibold hover:bg-gray-50 transition-colors">
                Learn More
              </button>
            </div>
          </div>
        </div>
      </section>

      {/* Features Grid */}
      <section className="py-20">
        <div className="container mx-auto px-4">
          <h3 className="text-3xl font-bold text-center mb-12">
            14 Control Dimensions
          </h3>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {features.map((feature) => (
              <div
                key={feature.title}
                className="rounded-lg border bg-white p-6 hover:shadow-lg transition-shadow"
              >
                <div className="text-3xl mb-3">{feature.icon}</div>
                <h4 className="font-semibold text-lg mb-2">{feature.title}</h4>
                <p className="text-gray-600 text-sm">{feature.description}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="border-t bg-gray-50">
        <div className="container mx-auto px-4 py-8">
          <p className="text-center text-gray-600">
            © 2026 Site360. All rights reserved.
          </p>
        </div>
      </footer>
    </main>
  );
}

const features = [
  {
    icon: '📐',
    title: 'Planning Control',
    description: 'Ensure work follows approved plans and correct versions',
  },
  {
    icon: '📊',
    title: 'Material Control',
    description: 'Track actual consumption vs. planned usage',
  },
  {
    icon: '📅',
    title: 'Schedule Control',
    description: 'Monitor progress against targets and milestones',
  },
  {
    icon: '✅',
    title: 'Quality Control',
    description: 'Track defects, rework, and quality standards',
  },
  {
    icon: '⚠️',
    title: 'Safety Control',
    description: 'Monitor risks, incidents, and near-miss events',
  },
  {
    icon: '👷',
    title: 'Workforce Control',
    description: 'Track attendance and productivity',
  },
  {
    icon: '🔧',
    title: 'Equipment Control',
    description: 'Monitor availability and usage',
  },
  {
    icon: '📋',
    title: 'Documentation',
    description: 'Complete daily logs with no gaps',
  },
  {
    icon: '🏗️',
    title: 'Subcontractor Control',
    description: 'Track performance and deviations',
  },
];
