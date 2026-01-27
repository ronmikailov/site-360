export default function DashboardPage() {
  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="border-b bg-white sticky top-0 z-10">
        <div className="container mx-auto px-4 py-4 flex items-center justify-between">
          <h1 className="text-2xl font-bold text-primary-600">Site360</h1>
          <div className="flex items-center gap-4">
            <button className="text-gray-600 hover:text-gray-900">
              Notifications
            </button>
            <button className="rounded-lg bg-primary-600 px-4 py-2 text-sm font-semibold text-white hover:bg-primary-700">
              Profile
            </button>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <div className="container mx-auto px-4 py-8">
        <div className="mb-8">
          <h2 className="text-3xl font-bold text-gray-900">Dashboard</h2>
          <p className="mt-2 text-gray-600">
            Overview of all construction sites and control parameters
          </p>
        </div>

        {/* Stats Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          <StatCard
            title="Active Projects"
            value="12"
            change="+2 this month"
            trend="up"
          />
          <StatCard
            title="Open Issues"
            value="34"
            change="-5 from last week"
            trend="down"
          />
          <StatCard
            title="Material Alerts"
            value="8"
            change="Requires attention"
            trend="neutral"
          />
          <StatCard
            title="Safety Score"
            value="94%"
            change="+3% this month"
            trend="up"
          />
        </div>

        {/* Control Parameters */}
        <div className="rounded-lg border bg-white p-6">
          <h3 className="text-xl font-semibold mb-6">Control Parameters Status</h3>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {controlParams.map((param) => (
              <ControlParamCard key={param.name} {...param} />
            ))}
          </div>
        </div>

        {/* Recent Activity */}
        <div className="mt-8 rounded-lg border bg-white p-6">
          <h3 className="text-xl font-semibold mb-6">Recent Activity</h3>
          <div className="space-y-4">
            {recentActivity.map((activity, index) => (
              <ActivityItem key={index} {...activity} />
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}

function StatCard({
  title,
  value,
  change,
  trend,
}: {
  title: string;
  value: string;
  change: string;
  trend: 'up' | 'down' | 'neutral';
}) {
  const trendColors = {
    up: 'text-green-600',
    down: 'text-red-600',
    neutral: 'text-gray-600',
  };

  return (
    <div className="rounded-lg border bg-white p-6">
      <p className="text-sm text-gray-600">{title}</p>
      <p className="mt-2 text-3xl font-bold">{value}</p>
      <p className={`mt-2 text-sm ${trendColors[trend]}`}>{change}</p>
    </div>
  );
}

function ControlParamCard({
  name,
  status,
}: {
  name: string;
  status: 'good' | 'warning' | 'alert';
}) {
  const statusConfig = {
    good: { bg: 'bg-green-100', text: 'text-green-800', icon: '✓' },
    warning: { bg: 'bg-yellow-100', text: 'text-yellow-800', icon: '⚠' },
    alert: { bg: 'bg-red-100', text: 'text-red-800', icon: '!' },
  };

  const config = statusConfig[status];

  return (
    <div className="flex items-center gap-3 rounded-lg border p-4 hover:bg-gray-50">
      <div className={`flex h-10 w-10 items-center justify-center rounded-full ${config.bg}`}>
        <span className={`text-lg ${config.text}`}>{config.icon}</span>
      </div>
      <div>
        <p className="font-medium text-sm">{name}</p>
        <p className={`text-xs ${config.text} capitalize`}>{status}</p>
      </div>
    </div>
  );
}

function ActivityItem({
  type,
  message,
  time,
}: {
  type: string;
  message: string;
  time: string;
}) {
  return (
    <div className="flex items-start gap-4 border-b pb-4 last:border-0">
      <div className="flex h-8 w-8 items-center justify-center rounded-full bg-primary-100">
        <span className="text-primary-600">•</span>
      </div>
      <div className="flex-1">
        <p className="text-sm font-medium">{type}</p>
        <p className="text-sm text-gray-600">{message}</p>
        <p className="mt-1 text-xs text-gray-400">{time}</p>
      </div>
    </div>
  );
}

const controlParams = [
  { name: 'Planning Control', status: 'good' as const },
  { name: 'Material Control', status: 'warning' as const },
  { name: 'Schedule Control', status: 'good' as const },
  { name: 'Quality Control', status: 'good' as const },
  { name: 'Safety Control', status: 'alert' as const },
  { name: 'Workforce Control', status: 'good' as const },
  { name: 'Equipment Control', status: 'warning' as const },
  { name: 'Documentation', status: 'good' as const },
  { name: 'Subcontractor Control', status: 'good' as const },
];

const recentActivity = [
  {
    type: 'Material Alert',
    message: 'Concrete usage 15% over planned - Site A',
    time: '2 hours ago',
  },
  {
    type: 'Safety Incident',
    message: 'Near-miss reported at Site B - Zone 3',
    time: '4 hours ago',
  },
  {
    type: 'Quality Check',
    message: 'Daily inspection completed - Site C',
    time: '6 hours ago',
  },
  {
    type: 'Schedule Update',
    message: 'Phase 2 ahead of schedule by 3 days',
    time: '1 day ago',
  },
];
