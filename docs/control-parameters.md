# Site360 Control Parameters

Site360 provides comprehensive monitoring and control across 14 critical dimensions of construction site management.

---

## 1. Planning Control (בקרה תכנונית)

**Objective**: Ensure all work follows the approved plan and correct version

### Key Features
- Version control for building plans
- Real-time plan viewing and comparison
- Alerts when working from outdated plans
- Digital plan distribution to all team members

### Metrics Tracked
- Current plan version in use
- Deviations from approved plans
- Plan update history and audit trail

---

## 2. Design Change Control (בקרה על שינויי תכנון)

**Objective**: Track and validate all design changes

### Key Features
- Change request submission workflow
- Approval tracking (requested vs. approved vs. implemented)
- Visual change comparison (before/after)
- Impact analysis on schedule and budget

### Metrics Tracked
- Pending change requests
- Approved changes not yet implemented
- Unauthorized changes detected
- Change implementation timeline

---

## 3. Schedule/Pace Control (בקרת לו״ז / קצב)

**Objective**: Monitor progress against targets and milestones

### Key Features
- Milestone tracking and progress visualization
- Critical path analysis
- Pace calculation (actual vs. planned)
- Predictive completion date analysis

### Metrics Tracked
- Completion percentage by area/phase
- Days ahead/behind schedule
- Activity completion rate
- Bottleneck identification

---

## 4. Material Control (בקרת חומרים)

**Objective**: Monitor actual consumption vs. planned usage

### Key Features
- Material quantity tracking by type and location
- Consumption rate analysis
- Automatic variance alerts (over/under usage)
- Integration with building plan quantities

### Metrics Tracked
- Planned vs. actual consumption
- Consumption rate per day/week
- Material variance percentage
- Waste/excess identification

---

## 5. Loss/Theft Prevention (בקרת אובדן / גניבות חומרים)

**Objective**: Detect and prevent material loss and theft

### Key Features
- Material inventory tracking
- Anomaly detection (unexpected decreases)
- Location-based material monitoring
- Access and movement logging

### Metrics Tracked
- Unexplained inventory changes
- High-risk material locations
- Historical loss patterns
- Security incident correlation

---

## 6. Quality Control (בקרת איכות ביצוע)

**Objective**: Monitor defects, rework, and quality standards

### Key Features
- Defect reporting with photos and location
- Rework tracking and cost analysis
- Quality checklist compliance
- Inspection scheduling and results

### Metrics Tracked
- Defect count by type and location
- Rework percentage
- Quality inspection pass/fail rates
- Time to defect resolution

---

## 7. Safety Control (בקרת בטיחות)

**Objective**: Track risks, incidents, and near-miss events

### Key Features
- Safety incident reporting
- Near-miss documentation and analysis
- Risk assessment by zone
- Safety briefing tracking
- PPE compliance monitoring

### Metrics Tracked
- Incident rate (per 1000 work hours)
- Near-miss reports
- High-risk areas identification
- Safety training compliance

---

## 8. Regulatory Compliance (בקרה רגולטורית)

**Objective**: Ensure compliance with regulations and legal requirements

### Key Features
- Regulatory checklist management
- Permit and approval tracking
- Inspection readiness verification
- Compliance documentation storage

### Metrics Tracked
- Outstanding regulatory requirements
- Inspection pass/fail history
- Permit expiration alerts
- Non-compliance incidents

---

## 9. Documentation Control (בקרת תיעוד)

**Objective**: Maintain complete daily logs, photos, and records

### Key Features
- Digital daily logs with timestamps
- Photo documentation with geolocation
- Gap detection (missing daily records)
- Document version control
- Search and retrieval system

### Metrics Tracked
- Documentation completeness (no gaps)
- Photo coverage by area
- Daily log submission rate
- Missing documentation alerts

---

## 10. Subcontractor Control (בקרת קבלני משנה)

**Objective**: Monitor subcontractor output, deviations, and reliability

### Key Features
- Subcontractor performance scoring
- Output vs. contract tracking
- Deviation and issue logging
- Payment milestone validation
- Historical performance analysis

### Metrics Tracked
- Completion rate vs. schedule
- Quality issues per subcontractor
- Repeat issues/patterns
- Contract compliance percentage

---

## 11. Workforce Control (בקרת כוח אדם)

**Objective**: Track attendance and correlate with productivity

### Key Features
- Digital attendance logging
- Workforce vs. pace correlation
- Skill tracking and allocation
- Productivity analysis by team/area

### Metrics Tracked
- Attendance rate
- Workforce productivity (output per worker)
- Optimal team size analysis
- Labor cost vs. progress

---

## 12. Equipment Control (בקרת ציוד)

**Objective**: Monitor availability, usage, and capacity

### Key Features
- Equipment inventory and location tracking
- Utilization monitoring
- Maintenance scheduling
- Shortage/surplus alerts
- Equipment performance tracking

### Metrics Tracked
- Equipment utilization rate
- Idle time analysis
- Maintenance compliance
- Equipment shortage impact on schedule

---

## 13. Site Organization Control (בקרת סדר, ניקיון וסביבה)

**Objective**: Maintain order, cleanliness, and environmental standards

### Key Features
- Daily site condition checklists
- Photo documentation of site conditions
- Waste management tracking
- Environmental compliance monitoring
- 5S methodology implementation

### Metrics Tracked
- Site cleanliness score
- Waste disposal compliance
- Environmental incidents
- Improvement trends over time

---

## 14. Overall Management Control (בקרה ניהולית כוללת)

**Objective**: Identify blind spots and areas lacking control

### Key Features
- Comprehensive dashboard with all control parameters
- Blind spot detection (areas without recent data)
- Cross-parameter correlation analysis
- Risk aggregation and prioritization
- Executive summary reporting

### Metrics Tracked
- Control coverage percentage
- High-risk areas requiring attention
- Overall project health score
- Trend analysis across all parameters

---

## Integration & Automation

### Data Collection
- **Mobile App**: On-site data entry optimized for field use
- **Photo Capture**: Automatic geotagging and timestamping
- **Offline Mode**: Data collection without internet connection
- **Automatic Sync**: Real-time synchronization when connected

### Alerts & Notifications
- Real-time push notifications for critical deviations
- Configurable alert thresholds per parameter
- Escalation workflows for unresolved issues
- Daily/weekly summary reports

### Analytics & Reporting
- Customizable dashboards per role (site manager, project manager, executive)
- Historical trend analysis
- Predictive analytics for schedule and material usage
- Export to PDF/Excel for stakeholder sharing

### AI Integration
- Anomaly detection using machine learning
- Predictive alerts for potential issues
- Natural language queries via MCP integration
- Automated report generation

---

## Implementation Roadmap

### Phase 1: Foundation (Planned)
- Planning control
- Material control
- Documentation control
- Basic mobile and web apps

### Phase 2: Progress & Safety (Planned)
- Schedule/pace control
- Quality control
- Safety control
- Enhanced analytics

### Phase 3: Resources & Compliance (Planned)
- Subcontractor control
- Workforce control
- Equipment control
- Regulatory compliance

### Phase 4: Advanced Features (Planned)
- Loss/theft prevention
- Site organization control
- Overall management dashboard
- AI-powered insights

---

## Technical Architecture

### Data Model
Each control parameter has:
- **Target/Baseline**: Approved plans, schedules, budgets
- **Actual Data**: Real-time field data and measurements
- **Variance Calculation**: Automatic deviation detection
- **Historical Tracking**: Trend analysis and reporting

### Real-time Processing
- Supabase Realtime for instant data synchronization
- Serverless functions for variance calculations
- Push notifications via mobile platform services
- WebSocket connections for web dashboard

### Security & Access Control
- Role-based access control (RBAC)
- Field-level permissions
- Audit logging for all changes
- Data encryption at rest and in transit

---

*This document will be updated as features are implemented and refined based on user feedback.*
