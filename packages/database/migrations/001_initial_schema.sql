-- ============================================================================
-- Site360 Database Schema - Initial Setup
-- Construction Site Management Platform
-- ============================================================================
-- This migration creates the complete database schema for Site360,
-- including all 14 control dimensions for construction site management.
-- ============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

-- Trigger function for updated_at timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to get current user's organization_id from JWT
CREATE OR REPLACE FUNCTION get_user_organization_id()
RETURNS UUID AS $$
BEGIN
    RETURN (
        SELECT organization_id
        FROM profiles
        WHERE id = auth.uid()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- ENUM TYPES
-- ============================================================================

-- Project and site statuses
CREATE TYPE project_status AS ENUM ('planning', 'active', 'on_hold', 'completed', 'cancelled');
CREATE TYPE site_status AS ENUM ('setup', 'active', 'suspended', 'completed', 'closed');

-- User roles
CREATE TYPE user_role AS ENUM ('owner', 'admin', 'manager', 'supervisor', 'worker', 'viewer');

-- Control-related enums
CREATE TYPE approval_status AS ENUM ('pending', 'approved', 'rejected', 'requires_revision');
CREATE TYPE change_impact AS ENUM ('low', 'medium', 'high', 'critical');
CREATE TYPE severity_level AS ENUM ('low', 'medium', 'high', 'critical');
CREATE TYPE alert_status AS ENUM ('active', 'acknowledged', 'resolved', 'dismissed');
CREATE TYPE inspection_result AS ENUM ('pass', 'pass_with_notes', 'fail', 'pending');
CREATE TYPE defect_status AS ENUM ('open', 'in_progress', 'resolved', 'closed', 'deferred');
CREATE TYPE incident_type AS ENUM ('injury', 'property_damage', 'environmental', 'near_miss', 'other');
CREATE TYPE permit_status AS ENUM ('pending', 'active', 'expired', 'revoked', 'renewed');
CREATE TYPE assignment_status AS ENUM ('scheduled', 'active', 'completed', 'cancelled');
CREATE TYPE equipment_status AS ENUM ('available', 'assigned', 'maintenance', 'repair', 'retired');
CREATE TYPE worker_status AS ENUM ('active', 'inactive', 'on_leave', 'terminated');
CREATE TYPE maintenance_type AS ENUM ('preventive', 'corrective', 'emergency', 'inspection');
CREATE TYPE document_type AS ENUM ('drawing', 'specification', 'contract', 'report', 'certificate', 'permit', 'photo', 'other');
CREATE TYPE waste_type AS ENUM ('construction', 'hazardous', 'recyclable', 'organic', 'mixed');

-- Control dimensions enum for scoring
CREATE TYPE control_dimension AS ENUM (
    'planning', 'design_change', 'schedule', 'material',
    'loss_prevention', 'quality', 'safety', 'regulatory',
    'documentation', 'subcontractor', 'workforce', 'equipment',
    'site_organization', 'overall_management'
);

-- ============================================================================
-- CORE ENTITIES
-- ============================================================================

-- Organizations (Multi-tenant support)
-- Top-level tenant container for all site data
CREATE TABLE organizations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    slug TEXT UNIQUE NOT NULL,
    settings JSONB DEFAULT '{}',
    logo_url TEXT,
    contact_email TEXT,
    contact_phone TEXT,
    address TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
COMMENT ON TABLE organizations IS 'Multi-tenant organizations - top level container';

-- Profiles (extends auth.users)
-- User profiles with organization membership and roles
CREATE TABLE profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    organization_id UUID REFERENCES organizations(id) ON DELETE SET NULL,
    full_name TEXT NOT NULL,
    email TEXT,
    role user_role DEFAULT 'viewer',
    phone TEXT,
    avatar_url TEXT,
    settings JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
COMMENT ON TABLE profiles IS 'User profiles extending auth.users with org membership';

-- Projects (Construction projects)
-- Major construction initiatives within an organization
CREATE TABLE projects (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    status project_status DEFAULT 'planning',
    start_date DATE,
    end_date DATE,
    budget DECIMAL(15, 2),
    currency TEXT DEFAULT 'USD',
    client_name TEXT,
    client_contact TEXT,
    metadata JSONB DEFAULT '{}',
    created_by UUID REFERENCES profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
COMMENT ON TABLE projects IS 'Construction projects within an organization';

-- Sites (Physical construction sites)
-- Physical locations where construction work occurs
CREATE TABLE sites (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    address TEXT,
    city TEXT,
    state TEXT,
    country TEXT,
    postal_code TEXT,
    coordinates GEOGRAPHY(POINT, 4326),
    status site_status DEFAULT 'setup',
    area_sqm DECIMAL(12, 2),
    settings JSONB DEFAULT '{}',
    created_by UUID REFERENCES profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
COMMENT ON TABLE sites IS 'Physical construction sites within projects';

-- ============================================================================
-- 1. PLANNING CONTROL
-- ============================================================================

-- Plans (Construction plans and drawings)
CREATE TABLE plans (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    site_id UUID NOT NULL REFERENCES sites(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    version TEXT NOT NULL DEFAULT '1.0',
    file_url TEXT NOT NULL,
    file_type TEXT,
    file_size_bytes BIGINT,
    status approval_status DEFAULT 'pending',
    approved_by UUID REFERENCES profiles(id),
    approved_at TIMESTAMPTZ,
    supersedes_id UUID REFERENCES plans(id),
    metadata JSONB DEFAULT '{}',
    created_by UUID REFERENCES profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
COMMENT ON TABLE plans IS 'Construction plans and drawings with version control';

-- Plan usage logs (Audit trail for plan access)
CREATE TABLE plan_usage_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    plan_id UUID NOT NULL REFERENCES plans(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    action TEXT NOT NULL, -- 'view', 'download', 'print', 'share'
    ip_address INET,
    user_agent TEXT,
    accessed_at TIMESTAMPTZ DEFAULT NOW()
);
COMMENT ON TABLE plan_usage_logs IS 'Audit trail for plan access and usage';

-- ============================================================================
-- 2. DESIGN CHANGE CONTROL
-- ============================================================================

-- Change requests
CREATE TABLE change_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    site_id UUID NOT NULL REFERENCES sites(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    reason TEXT,
    status approval_status DEFAULT 'pending',
    impact change_impact DEFAULT 'medium',
    cost_impact DECIMAL(12, 2),
    schedule_impact_days INTEGER,
    affected_plans UUID[],
    requested_by UUID NOT NULL REFERENCES profiles(id),
    reviewed_by UUID REFERENCES profiles(id),
    impact_assessment JSONB,
    attachments TEXT[],
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
COMMENT ON TABLE change_requests IS 'Design and scope change requests';

-- Change approvals
CREATE TABLE change_approvals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    change_request_id UUID NOT NULL REFERENCES change_requests(id) ON DELETE CASCADE,
    approved_by UUID NOT NULL REFERENCES profiles(id),
    decision approval_status NOT NULL,
    notes TEXT,
    conditions TEXT,
    decided_at TIMESTAMPTZ DEFAULT NOW()
);
COMMENT ON TABLE change_approvals IS 'Approval decisions for change requests';

-- ============================================================================
-- 3. SCHEDULE/PACE CONTROL
-- ============================================================================

-- Milestones
CREATE TABLE milestones (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    site_id UUID REFERENCES sites(id) ON DELETE SET NULL,
    name TEXT NOT NULL,
    description TEXT,
    target_date DATE NOT NULL,
    actual_date DATE,
    status approval_status DEFAULT 'pending',
    progress_percentage INTEGER DEFAULT 0 CHECK (progress_percentage >= 0 AND progress_percentage <= 100),
    dependencies UUID[],
    is_critical_path BOOLEAN DEFAULT FALSE,
    created_by UUID REFERENCES profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
COMMENT ON TABLE milestones IS 'Project milestones and key dates';

-- Progress logs
CREATE TABLE progress_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    site_id UUID NOT NULL REFERENCES sites(id) ON DELETE CASCADE,
    milestone_id UUID REFERENCES milestones(id) ON DELETE SET NULL,
    date DATE NOT NULL,
    progress_percentage INTEGER CHECK (progress_percentage >= 0 AND progress_percentage <= 100),
    work_completed TEXT,
    notes TEXT,
    blockers TEXT,
    weather_conditions TEXT,
    logged_by UUID NOT NULL REFERENCES profiles(id),
    photos TEXT[],
    created_at TIMESTAMPTZ DEFAULT NOW()
);
COMMENT ON TABLE progress_logs IS 'Daily/periodic progress tracking';

-- ============================================================================
-- 4. MATERIAL CONTROL
-- ============================================================================

-- Materials (Master list)
CREATE TABLE materials (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    unit TEXT NOT NULL, -- 'kg', 'm3', 'units', etc.
    category TEXT,
    subcategory TEXT,
    unit_cost DECIMAL(12, 2),
    currency TEXT DEFAULT 'USD',
    min_stock DECIMAL(12, 2),
    supplier_info JSONB,
    specifications JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(organization_id, name)
);
COMMENT ON TABLE materials IS 'Master list of construction materials';

-- Material targets (Planned quantities per site)
CREATE TABLE material_targets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    site_id UUID NOT NULL REFERENCES sites(id) ON DELETE CASCADE,
    material_id UUID NOT NULL REFERENCES materials(id) ON DELETE CASCADE,
    planned_quantity DECIMAL(12, 2) NOT NULL,
    actual_quantity DECIMAL(12, 2) DEFAULT 0,
    unit_cost DECIMAL(12, 2),
    notes TEXT,
    created_by UUID REFERENCES profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(site_id, material_id)
);
COMMENT ON TABLE material_targets IS 'Planned material quantities per site';

-- Material usage (Consumption tracking)
CREATE TABLE material_usage (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    site_id UUID NOT NULL REFERENCES sites(id) ON DELETE CASCADE,
    material_id UUID NOT NULL REFERENCES materials(id) ON DELETE CASCADE,
    quantity DECIMAL(12, 2) NOT NULL,
    usage_type TEXT DEFAULT 'consumption', -- 'consumption', 'delivery', 'transfer', 'waste'
    date DATE NOT NULL,
    location_on_site TEXT,
    purpose TEXT,
    notes TEXT,
    logged_by UUID NOT NULL REFERENCES profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);
COMMENT ON TABLE material_usage IS 'Material consumption and delivery tracking';

-- ============================================================================
-- 5. LOSS/THEFT PREVENTION
-- ============================================================================

-- Material inventory (Current stock levels)
CREATE TABLE material_inventory (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    site_id UUID NOT NULL REFERENCES sites(id) ON DELETE CASCADE,
    material_id UUID NOT NULL REFERENCES materials(id) ON DELETE CASCADE,
    quantity DECIMAL(12, 2) NOT NULL,
    storage_location TEXT,
    last_counted TIMESTAMPTZ,
    counted_by UUID REFERENCES profiles(id),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(site_id, material_id)
);
COMMENT ON TABLE material_inventory IS 'Current material stock levels per site';

-- Inventory anomalies (Discrepancies and potential theft)
CREATE TABLE inventory_anomalies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    inventory_id UUID NOT NULL REFERENCES material_inventory(id) ON DELETE CASCADE,
    expected_quantity DECIMAL(12, 2) NOT NULL,
    actual_quantity DECIMAL(12, 2) NOT NULL,
    variance DECIMAL(12, 2) NOT NULL,
    variance_percentage DECIMAL(5, 2),
    detected_at TIMESTAMPTZ DEFAULT NOW(),
    status defect_status DEFAULT 'open',
    investigation_notes TEXT,
    resolution TEXT,
    resolved_by UUID REFERENCES profiles(id),
    resolved_at TIMESTAMPTZ,
    reported_by UUID NOT NULL REFERENCES profiles(id)
);
COMMENT ON TABLE inventory_anomalies IS 'Material discrepancies and loss tracking';

-- ============================================================================
-- 6. QUALITY CONTROL
-- ============================================================================

-- Inspections
CREATE TABLE inspections (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    site_id UUID NOT NULL REFERENCES sites(id) ON DELETE CASCADE,
    type TEXT NOT NULL, -- 'structural', 'electrical', 'plumbing', 'safety', etc.
    name TEXT,
    scheduled_date TIMESTAMPTZ,
    completed_date TIMESTAMPTZ,
    inspector_id UUID REFERENCES profiles(id),
    external_inspector TEXT,
    result inspection_result DEFAULT 'pending',
    score INTEGER CHECK (score >= 0 AND score <= 100),
    notes TEXT,
    checklist JSONB,
    photos TEXT[],
    documents TEXT[],
    created_by UUID REFERENCES profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
COMMENT ON TABLE inspections IS 'Quality inspections and audits';

-- Defects
CREATE TABLE defects (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    site_id UUID NOT NULL REFERENCES sites(id) ON DELETE CASCADE,
    inspection_id UUID REFERENCES inspections(id) ON DELETE SET NULL,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    location TEXT,
    coordinates GEOGRAPHY(POINT, 4326),
    severity severity_level DEFAULT 'medium',
    category TEXT,
    photos TEXT[],
    status defect_status DEFAULT 'open',
    assigned_to UUID REFERENCES profiles(id),
    due_date DATE,
    resolution TEXT,
    resolved_by UUID REFERENCES profiles(id),
    resolved_at TIMESTAMPTZ,
    reported_by UUID NOT NULL REFERENCES profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
COMMENT ON TABLE defects IS 'Quality defects and non-conformances';

-- ============================================================================
-- 7. SAFETY CONTROL
-- ============================================================================

-- Safety incidents
CREATE TABLE safety_incidents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    site_id UUID NOT NULL REFERENCES sites(id) ON DELETE CASCADE,
    type incident_type NOT NULL,
    severity severity_level NOT NULL,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    location TEXT,
    coordinates GEOGRAPHY(POINT, 4326),
    incident_date TIMESTAMPTZ NOT NULL,
    workers_involved UUID[],
    injuries_count INTEGER DEFAULT 0,
    property_damage_cost DECIMAL(12, 2),
    root_cause TEXT,
    corrective_actions TEXT,
    preventive_measures TEXT,
    photos TEXT[],
    documents TEXT[],
    reported_by UUID NOT NULL REFERENCES profiles(id),
    reported_at TIMESTAMPTZ DEFAULT NOW(),
    investigated_by UUID REFERENCES profiles(id),
    investigated_at TIMESTAMPTZ,
    resolved_at TIMESTAMPTZ,
    status defect_status DEFAULT 'open'
);
COMMENT ON TABLE safety_incidents IS 'Safety incidents and accidents';

-- Near misses
CREATE TABLE near_misses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    site_id UUID NOT NULL REFERENCES sites(id) ON DELETE CASCADE,
    description TEXT NOT NULL,
    location TEXT,
    potential_severity severity_level NOT NULL,
    contributing_factors TEXT,
    preventive_actions TEXT,
    reported_by UUID NOT NULL REFERENCES profiles(id),
    reported_at TIMESTAMPTZ DEFAULT NOW(),
    reviewed_by UUID REFERENCES profiles(id),
    reviewed_at TIMESTAMPTZ
);
COMMENT ON TABLE near_misses IS 'Near miss incidents for proactive safety';

-- Risk assessments
CREATE TABLE risk_assessments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    site_id UUID NOT NULL REFERENCES sites(id) ON DELETE CASCADE,
    area TEXT NOT NULL,
    activity TEXT,
    hazard_description TEXT NOT NULL,
    risk_level severity_level NOT NULL,
    likelihood INTEGER CHECK (likelihood >= 1 AND likelihood <= 5),
    consequence INTEGER CHECK (consequence >= 1 AND consequence <= 5),
    risk_score INTEGER GENERATED ALWAYS AS (likelihood * consequence) STORED,
    existing_controls TEXT,
    additional_controls TEXT,
    residual_risk_level severity_level,
    assessed_by UUID NOT NULL REFERENCES profiles(id),
    assessed_at TIMESTAMPTZ DEFAULT NOW(),
    next_review_date DATE,
    status TEXT DEFAULT 'active'
);
COMMENT ON TABLE risk_assessments IS 'Safety risk assessments by area';

-- ============================================================================
-- 8. REGULATORY COMPLIANCE
-- ============================================================================

-- Regulations (Master list)
CREATE TABLE regulations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    code TEXT,
    description TEXT,
    authority TEXT NOT NULL,
    jurisdiction TEXT,
    effective_date DATE,
    expiry_date DATE,
    requirements JSONB,
    document_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
COMMENT ON TABLE regulations IS 'Regulatory requirements and standards';

-- Permits
CREATE TABLE permits (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    site_id UUID NOT NULL REFERENCES sites(id) ON DELETE CASCADE,
    type TEXT NOT NULL,
    name TEXT NOT NULL,
    permit_number TEXT,
    issuing_authority TEXT,
    issued_date DATE,
    expiry_date DATE,
    status permit_status DEFAULT 'pending',
    conditions TEXT,
    fee DECIMAL(10, 2),
    document_url TEXT,
    renewal_reminder_days INTEGER DEFAULT 30,
    created_by UUID REFERENCES profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
COMMENT ON TABLE permits IS 'Site permits and licenses';

-- Compliance checks
CREATE TABLE compliance_checks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    site_id UUID NOT NULL REFERENCES sites(id) ON DELETE CASCADE,
    regulation_id UUID REFERENCES regulations(id) ON DELETE SET NULL,
    permit_id UUID REFERENCES permits(id) ON DELETE SET NULL,
    check_type TEXT NOT NULL,
    status approval_status DEFAULT 'pending',
    findings TEXT,
    evidence TEXT[],
    corrective_actions TEXT,
    checked_by UUID NOT NULL REFERENCES profiles(id),
    checked_at TIMESTAMPTZ DEFAULT NOW(),
    next_check_date DATE,
    notes TEXT
);
COMMENT ON TABLE compliance_checks IS 'Regulatory compliance verification';

-- ============================================================================
-- 9. DOCUMENTATION CONTROL
-- ============================================================================

-- Daily logs
CREATE TABLE daily_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    site_id UUID NOT NULL REFERENCES sites(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    weather TEXT,
    temperature_high DECIMAL(4, 1),
    temperature_low DECIMAL(4, 1),
    precipitation TEXT,
    summary TEXT NOT NULL,
    work_performed TEXT,
    delays TEXT,
    visitor_count INTEGER DEFAULT 0,
    workforce_count INTEGER,
    equipment_on_site TEXT[],
    issues TEXT,
    logged_by UUID NOT NULL REFERENCES profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(site_id, date)
);
COMMENT ON TABLE daily_logs IS 'Daily site activity logs';

-- Photos
CREATE TABLE photos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    site_id UUID NOT NULL REFERENCES sites(id) ON DELETE CASCADE,
    daily_log_id UUID REFERENCES daily_logs(id) ON DELETE SET NULL,
    url TEXT NOT NULL,
    thumbnail_url TEXT,
    caption TEXT,
    category TEXT,
    location TEXT,
    coordinates GEOGRAPHY(POINT, 4326),
    taken_at TIMESTAMPTZ,
    taken_by UUID REFERENCES profiles(id),
    file_size_bytes BIGINT,
    metadata JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
COMMENT ON TABLE photos IS 'Site photos and images';

-- Documents
CREATE TABLE documents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    site_id UUID REFERENCES sites(id) ON DELETE CASCADE,
    project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
    organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    type document_type NOT NULL,
    category TEXT,
    file_url TEXT NOT NULL,
    file_type TEXT,
    file_size_bytes BIGINT,
    version TEXT DEFAULT '1.0',
    description TEXT,
    tags TEXT[],
    uploaded_by UUID NOT NULL REFERENCES profiles(id),
    uploaded_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ,
    metadata JSONB,
    CHECK (site_id IS NOT NULL OR project_id IS NOT NULL OR organization_id IS NOT NULL)
);
COMMENT ON TABLE documents IS 'Project and site documents';

-- ============================================================================
-- 10. SUBCONTRACTOR CONTROL
-- ============================================================================

-- Subcontractors
CREATE TABLE subcontractors (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    company_name TEXT NOT NULL,
    legal_name TEXT,
    tax_id TEXT,
    contact_name TEXT,
    phone TEXT,
    email TEXT,
    address TEXT,
    trade TEXT NOT NULL,
    specializations TEXT[],
    certifications TEXT[],
    insurance_info JSONB,
    rating DECIMAL(3, 2) CHECK (rating >= 0 AND rating <= 5),
    status worker_status DEFAULT 'active',
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
COMMENT ON TABLE subcontractors IS 'Subcontractor companies';

-- Subcontractor assignments
CREATE TABLE subcontractor_assignments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    site_id UUID NOT NULL REFERENCES sites(id) ON DELETE CASCADE,
    subcontractor_id UUID NOT NULL REFERENCES subcontractors(id) ON DELETE CASCADE,
    scope TEXT NOT NULL,
    contract_value DECIMAL(12, 2),
    start_date DATE NOT NULL,
    end_date DATE,
    status assignment_status DEFAULT 'scheduled',
    payment_terms TEXT,
    milestones JSONB,
    documents TEXT[],
    created_by UUID REFERENCES profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
COMMENT ON TABLE subcontractor_assignments IS 'Subcontractor work assignments';

-- Subcontractor performance
CREATE TABLE subcontractor_performance (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    assignment_id UUID NOT NULL REFERENCES subcontractor_assignments(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    output_description TEXT,
    output_quantity DECIMAL(12, 2),
    output_unit TEXT,
    quality_score INTEGER CHECK (quality_score >= 0 AND quality_score <= 100),
    safety_score INTEGER CHECK (safety_score >= 0 AND safety_score <= 100),
    timeliness_score INTEGER CHECK (timeliness_score >= 0 AND timeliness_score <= 100),
    notes TEXT,
    issues TEXT,
    logged_by UUID NOT NULL REFERENCES profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);
COMMENT ON TABLE subcontractor_performance IS 'Subcontractor performance tracking';

-- ============================================================================
-- 11. WORKFORCE CONTROL
-- ============================================================================

-- Workers
CREATE TABLE workers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    subcontractor_id UUID REFERENCES subcontractors(id) ON DELETE SET NULL,
    profile_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    name TEXT NOT NULL,
    employee_id TEXT,
    role TEXT NOT NULL,
    skills TEXT[],
    certifications JSONB,
    phone TEXT,
    email TEXT,
    emergency_contact JSONB,
    hourly_rate DECIMAL(8, 2),
    status worker_status DEFAULT 'active',
    hire_date DATE,
    termination_date DATE,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
COMMENT ON TABLE workers IS 'Construction workers and labor';

-- Attendance
CREATE TABLE attendance (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    site_id UUID NOT NULL REFERENCES sites(id) ON DELETE CASCADE,
    worker_id UUID NOT NULL REFERENCES workers(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    check_in TIMESTAMPTZ,
    check_out TIMESTAMPTZ,
    hours_worked DECIMAL(4, 2),
    overtime_hours DECIMAL(4, 2) DEFAULT 0,
    break_duration_minutes INTEGER DEFAULT 0,
    status TEXT DEFAULT 'present', -- 'present', 'absent', 'late', 'half_day'
    notes TEXT,
    logged_by UUID REFERENCES profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(site_id, worker_id, date)
);
COMMENT ON TABLE attendance IS 'Worker attendance tracking';

-- Productivity logs
CREATE TABLE productivity_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    site_id UUID NOT NULL REFERENCES sites(id) ON DELETE CASCADE,
    worker_id UUID NOT NULL REFERENCES workers(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    task_description TEXT,
    output_quantity DECIMAL(12, 2),
    output_unit TEXT,
    area_covered TEXT,
    quality_rating INTEGER CHECK (quality_rating >= 1 AND quality_rating <= 5),
    notes TEXT,
    logged_by UUID NOT NULL REFERENCES profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);
COMMENT ON TABLE productivity_logs IS 'Worker productivity tracking';

-- ============================================================================
-- 12. EQUIPMENT CONTROL
-- ============================================================================

-- Equipment
CREATE TABLE equipment (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    type TEXT NOT NULL,
    category TEXT,
    make TEXT,
    model TEXT,
    serial_number TEXT,
    purchase_date DATE,
    purchase_cost DECIMAL(12, 2),
    current_value DECIMAL(12, 2),
    status equipment_status DEFAULT 'available',
    condition TEXT,
    location TEXT,
    hourly_rate DECIMAL(8, 2),
    fuel_type TEXT,
    specifications JSONB,
    documents TEXT[],
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
COMMENT ON TABLE equipment IS 'Construction equipment inventory';

-- Equipment assignments
CREATE TABLE equipment_assignments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    site_id UUID NOT NULL REFERENCES sites(id) ON DELETE CASCADE,
    equipment_id UUID NOT NULL REFERENCES equipment(id) ON DELETE CASCADE,
    assigned_date DATE NOT NULL,
    return_date DATE,
    actual_return_date DATE,
    status assignment_status DEFAULT 'scheduled',
    operator_id UUID REFERENCES workers(id),
    purpose TEXT,
    notes TEXT,
    assigned_by UUID REFERENCES profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
COMMENT ON TABLE equipment_assignments IS 'Equipment site assignments';

-- Equipment usage
CREATE TABLE equipment_usage (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    assignment_id UUID NOT NULL REFERENCES equipment_assignments(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    hours_used DECIMAL(4, 2) NOT NULL,
    fuel_consumed DECIMAL(8, 2),
    meter_reading DECIMAL(12, 2),
    condition TEXT,
    operator_id UUID REFERENCES workers(id),
    task_performed TEXT,
    issues TEXT,
    notes TEXT,
    logged_by UUID NOT NULL REFERENCES profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);
COMMENT ON TABLE equipment_usage IS 'Daily equipment usage tracking';

-- Maintenance logs
CREATE TABLE maintenance_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    equipment_id UUID NOT NULL REFERENCES equipment(id) ON DELETE CASCADE,
    type maintenance_type NOT NULL,
    scheduled_date DATE,
    completed_date DATE,
    description TEXT NOT NULL,
    parts_used JSONB,
    labor_hours DECIMAL(4, 2),
    cost DECIMAL(10, 2),
    performed_by TEXT,
    vendor TEXT,
    next_maintenance_date DATE,
    notes TEXT,
    documents TEXT[],
    created_by UUID REFERENCES profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);
COMMENT ON TABLE maintenance_logs IS 'Equipment maintenance records';

-- ============================================================================
-- 13. SITE ORGANIZATION CONTROL
-- ============================================================================

-- Site conditions
CREATE TABLE site_conditions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    site_id UUID NOT NULL REFERENCES sites(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    cleanliness_score INTEGER CHECK (cleanliness_score >= 0 AND cleanliness_score <= 100),
    organization_score INTEGER CHECK (organization_score >= 0 AND organization_score <= 100),
    safety_score INTEGER CHECK (safety_score >= 0 AND safety_score <= 100),
    access_score INTEGER CHECK (access_score >= 0 AND access_score <= 100),
    overall_score INTEGER GENERATED ALWAYS AS (
        (COALESCE(cleanliness_score, 0) + COALESCE(organization_score, 0) +
         COALESCE(safety_score, 0) + COALESCE(access_score, 0)) / 4
    ) STORED,
    notes TEXT,
    issues TEXT,
    photos TEXT[],
    checked_by UUID NOT NULL REFERENCES profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);
COMMENT ON TABLE site_conditions IS 'Site cleanliness and organization assessments';

-- Waste logs
CREATE TABLE waste_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    site_id UUID NOT NULL REFERENCES sites(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    waste_type waste_type NOT NULL,
    quantity DECIMAL(10, 2) NOT NULL,
    unit TEXT DEFAULT 'kg',
    disposal_method TEXT,
    disposal_vendor TEXT,
    disposal_cost DECIMAL(10, 2),
    manifest_number TEXT,
    notes TEXT,
    logged_by UUID NOT NULL REFERENCES profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);
COMMENT ON TABLE waste_logs IS 'Waste generation and disposal tracking';

-- ============================================================================
-- 14. OVERALL MANAGEMENT CONTROL
-- ============================================================================

-- Control scores (Aggregated dimension scores)
CREATE TABLE control_scores (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    site_id UUID NOT NULL REFERENCES sites(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    dimension control_dimension NOT NULL,
    score INTEGER NOT NULL CHECK (score >= 0 AND score <= 100),
    factors JSONB,
    trend TEXT, -- 'improving', 'stable', 'declining'
    recommendations TEXT,
    calculated_at TIMESTAMPTZ DEFAULT NOW(),
    calculated_by TEXT DEFAULT 'system',
    UNIQUE(site_id, date, dimension)
);
COMMENT ON TABLE control_scores IS 'Aggregated control dimension scores';

-- Alerts
CREATE TABLE alerts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    site_id UUID NOT NULL REFERENCES sites(id) ON DELETE CASCADE,
    dimension control_dimension,
    severity severity_level NOT NULL,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    source_table TEXT,
    source_id UUID,
    status alert_status DEFAULT 'active',
    action_required TEXT,
    action_taken TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    acknowledged_at TIMESTAMPTZ,
    acknowledged_by UUID REFERENCES profiles(id),
    resolved_at TIMESTAMPTZ,
    resolved_by UUID REFERENCES profiles(id)
);
COMMENT ON TABLE alerts IS 'System alerts and notifications';

-- ============================================================================
-- INDEXES FOR PERFORMANCE
-- ============================================================================

-- Organizations
CREATE INDEX idx_organizations_slug ON organizations(slug);

-- Profiles
CREATE INDEX idx_profiles_organization ON profiles(organization_id);
CREATE INDEX idx_profiles_role ON profiles(role);

-- Projects
CREATE INDEX idx_projects_organization ON projects(organization_id);
CREATE INDEX idx_projects_status ON projects(status);
CREATE INDEX idx_projects_dates ON projects(start_date, end_date);

-- Sites
CREATE INDEX idx_sites_project ON sites(project_id);
CREATE INDEX idx_sites_status ON sites(status);
CREATE INDEX idx_sites_coordinates ON sites USING GIST(coordinates);

-- Plans
CREATE INDEX idx_plans_site ON plans(site_id);
CREATE INDEX idx_plans_status ON plans(status);

-- Plan usage logs
CREATE INDEX idx_plan_usage_plan ON plan_usage_logs(plan_id);
CREATE INDEX idx_plan_usage_user ON plan_usage_logs(user_id);
CREATE INDEX idx_plan_usage_accessed ON plan_usage_logs(accessed_at DESC);

-- Change requests
CREATE INDEX idx_change_requests_site ON change_requests(site_id);
CREATE INDEX idx_change_requests_status ON change_requests(status);

-- Milestones
CREATE INDEX idx_milestones_project ON milestones(project_id);
CREATE INDEX idx_milestones_site ON milestones(site_id);
CREATE INDEX idx_milestones_target_date ON milestones(target_date);

-- Progress logs
CREATE INDEX idx_progress_logs_site ON progress_logs(site_id);
CREATE INDEX idx_progress_logs_date ON progress_logs(date DESC);

-- Materials
CREATE INDEX idx_materials_organization ON materials(organization_id);
CREATE INDEX idx_materials_category ON materials(category);

-- Material targets
CREATE INDEX idx_material_targets_site ON material_targets(site_id);

-- Material usage
CREATE INDEX idx_material_usage_site ON material_usage(site_id);
CREATE INDEX idx_material_usage_date ON material_usage(date DESC);

-- Material inventory
CREATE INDEX idx_material_inventory_site ON material_inventory(site_id);

-- Inventory anomalies
CREATE INDEX idx_inventory_anomalies_status ON inventory_anomalies(status);

-- Inspections
CREATE INDEX idx_inspections_site ON inspections(site_id);
CREATE INDEX idx_inspections_type ON inspections(type);
CREATE INDEX idx_inspections_scheduled ON inspections(scheduled_date);

-- Defects
CREATE INDEX idx_defects_site ON defects(site_id);
CREATE INDEX idx_defects_status ON defects(status);
CREATE INDEX idx_defects_severity ON defects(severity);

-- Safety incidents
CREATE INDEX idx_safety_incidents_site ON safety_incidents(site_id);
CREATE INDEX idx_safety_incidents_type ON safety_incidents(type);
CREATE INDEX idx_safety_incidents_severity ON safety_incidents(severity);

-- Near misses
CREATE INDEX idx_near_misses_site ON near_misses(site_id);

-- Risk assessments
CREATE INDEX idx_risk_assessments_site ON risk_assessments(site_id);
CREATE INDEX idx_risk_assessments_level ON risk_assessments(risk_level);

-- Regulations
CREATE INDEX idx_regulations_organization ON regulations(organization_id);

-- Permits
CREATE INDEX idx_permits_site ON permits(site_id);
CREATE INDEX idx_permits_status ON permits(status);
CREATE INDEX idx_permits_expiry ON permits(expiry_date);

-- Compliance checks
CREATE INDEX idx_compliance_checks_site ON compliance_checks(site_id);
CREATE INDEX idx_compliance_checks_status ON compliance_checks(status);

-- Daily logs
CREATE INDEX idx_daily_logs_site ON daily_logs(site_id);
CREATE INDEX idx_daily_logs_date ON daily_logs(date DESC);

-- Photos
CREATE INDEX idx_photos_site ON photos(site_id);
CREATE INDEX idx_photos_daily_log ON photos(daily_log_id);
CREATE INDEX idx_photos_taken_at ON photos(taken_at DESC);

-- Documents
CREATE INDEX idx_documents_site ON documents(site_id);
CREATE INDEX idx_documents_project ON documents(project_id);
CREATE INDEX idx_documents_organization ON documents(organization_id);
CREATE INDEX idx_documents_type ON documents(type);

-- Subcontractors
CREATE INDEX idx_subcontractors_organization ON subcontractors(organization_id);
CREATE INDEX idx_subcontractors_trade ON subcontractors(trade);

-- Subcontractor assignments
CREATE INDEX idx_subcontractor_assignments_site ON subcontractor_assignments(site_id);
CREATE INDEX idx_subcontractor_assignments_subcontractor ON subcontractor_assignments(subcontractor_id);

-- Subcontractor performance
CREATE INDEX idx_subcontractor_performance_assignment ON subcontractor_performance(assignment_id);
CREATE INDEX idx_subcontractor_performance_date ON subcontractor_performance(date DESC);

-- Workers
CREATE INDEX idx_workers_organization ON workers(organization_id);
CREATE INDEX idx_workers_subcontractor ON workers(subcontractor_id);
CREATE INDEX idx_workers_status ON workers(status);

-- Attendance
CREATE INDEX idx_attendance_site ON attendance(site_id);
CREATE INDEX idx_attendance_worker ON attendance(worker_id);
CREATE INDEX idx_attendance_date ON attendance(date DESC);

-- Productivity logs
CREATE INDEX idx_productivity_logs_site ON productivity_logs(site_id);
CREATE INDEX idx_productivity_logs_worker ON productivity_logs(worker_id);
CREATE INDEX idx_productivity_logs_date ON productivity_logs(date DESC);

-- Equipment
CREATE INDEX idx_equipment_organization ON equipment(organization_id);
CREATE INDEX idx_equipment_status ON equipment(status);
CREATE INDEX idx_equipment_type ON equipment(type);

-- Equipment assignments
CREATE INDEX idx_equipment_assignments_site ON equipment_assignments(site_id);
CREATE INDEX idx_equipment_assignments_equipment ON equipment_assignments(equipment_id);

-- Equipment usage
CREATE INDEX idx_equipment_usage_assignment ON equipment_usage(assignment_id);
CREATE INDEX idx_equipment_usage_date ON equipment_usage(date DESC);

-- Maintenance logs
CREATE INDEX idx_maintenance_logs_equipment ON maintenance_logs(equipment_id);
CREATE INDEX idx_maintenance_logs_type ON maintenance_logs(type);
CREATE INDEX idx_maintenance_logs_scheduled ON maintenance_logs(scheduled_date);

-- Site conditions
CREATE INDEX idx_site_conditions_site ON site_conditions(site_id);
CREATE INDEX idx_site_conditions_date ON site_conditions(date DESC);

-- Waste logs
CREATE INDEX idx_waste_logs_site ON waste_logs(site_id);
CREATE INDEX idx_waste_logs_date ON waste_logs(date DESC);
CREATE INDEX idx_waste_logs_type ON waste_logs(waste_type);

-- Control scores
CREATE INDEX idx_control_scores_site ON control_scores(site_id);
CREATE INDEX idx_control_scores_date ON control_scores(date DESC);
CREATE INDEX idx_control_scores_dimension ON control_scores(dimension);

-- Alerts
CREATE INDEX idx_alerts_site ON alerts(site_id);
CREATE INDEX idx_alerts_status ON alerts(status);
CREATE INDEX idx_alerts_severity ON alerts(severity);
CREATE INDEX idx_alerts_dimension ON alerts(dimension);
CREATE INDEX idx_alerts_created ON alerts(created_at DESC);

-- ============================================================================
-- TRIGGERS FOR UPDATED_AT
-- ============================================================================

CREATE TRIGGER update_organizations_updated_at BEFORE UPDATE ON organizations FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_projects_updated_at BEFORE UPDATE ON projects FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_sites_updated_at BEFORE UPDATE ON sites FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_plans_updated_at BEFORE UPDATE ON plans FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_change_requests_updated_at BEFORE UPDATE ON change_requests FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_milestones_updated_at BEFORE UPDATE ON milestones FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_materials_updated_at BEFORE UPDATE ON materials FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_material_targets_updated_at BEFORE UPDATE ON material_targets FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_material_inventory_updated_at BEFORE UPDATE ON material_inventory FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_inspections_updated_at BEFORE UPDATE ON inspections FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_defects_updated_at BEFORE UPDATE ON defects FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_regulations_updated_at BEFORE UPDATE ON regulations FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_permits_updated_at BEFORE UPDATE ON permits FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_daily_logs_updated_at BEFORE UPDATE ON daily_logs FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_subcontractors_updated_at BEFORE UPDATE ON subcontractors FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_subcontractor_assignments_updated_at BEFORE UPDATE ON subcontractor_assignments FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_workers_updated_at BEFORE UPDATE ON workers FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_equipment_updated_at BEFORE UPDATE ON equipment FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_equipment_assignments_updated_at BEFORE UPDATE ON equipment_assignments FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
