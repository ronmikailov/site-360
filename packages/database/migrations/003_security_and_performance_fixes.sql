-- ============================================================================
-- Site360 Database Schema - Security and Performance Fixes
-- ============================================================================
-- This migration addresses security advisories and performance recommendations.
-- ============================================================================

-- ============================================================================
-- FIX: Function Search Path Mutable
-- Set explicit search_path for all security definer functions
-- ============================================================================

-- Recreate update_updated_at_column with secure search_path
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Recreate get_user_organization_id with secure search_path
CREATE OR REPLACE FUNCTION get_user_organization_id()
RETURNS UUID AS $$
BEGIN
    RETURN (
        SELECT organization_id
        FROM public.profiles
        WHERE id = auth.uid()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Recreate user_belongs_to_org with secure search_path
CREATE OR REPLACE FUNCTION user_belongs_to_org(org_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid()
        AND organization_id = org_id
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Recreate user_has_role with secure search_path
CREATE OR REPLACE FUNCTION user_has_role(required_role user_role)
RETURNS BOOLEAN AS $$
DECLARE
    user_role_val user_role;
    role_order TEXT[] := ARRAY['viewer', 'worker', 'supervisor', 'manager', 'admin', 'owner'];
BEGIN
    SELECT role INTO user_role_val FROM public.profiles WHERE id = auth.uid();
    RETURN array_position(role_order, user_role_val::TEXT) >= array_position(role_order, required_role::TEXT);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Recreate get_site_org_id with secure search_path
CREATE OR REPLACE FUNCTION get_site_org_id(site_id UUID)
RETURNS UUID AS $$
BEGIN
    RETURN (
        SELECT p.organization_id
        FROM public.sites s
        JOIN public.projects p ON s.project_id = p.id
        WHERE s.id = site_id
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Recreate get_project_org_id with secure search_path
CREATE OR REPLACE FUNCTION get_project_org_id(project_id UUID)
RETURNS UUID AS $$
BEGIN
    RETURN (
        SELECT organization_id
        FROM public.projects
        WHERE id = project_id
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ============================================================================
-- NOTE: spatial_ref_sys table
-- This table is created by PostGIS extension and owned by postgres superuser.
-- RLS cannot be modified by regular users. This is a known limitation.
-- The table only contains reference data and poses minimal security risk.
-- ============================================================================

-- ============================================================================
-- PERFORMANCE: Add indexes for unindexed foreign keys
-- These indexes improve JOIN performance and CASCADE operations
-- ============================================================================

-- Alerts table
CREATE INDEX IF NOT EXISTS idx_alerts_acknowledged_by ON alerts(acknowledged_by);
CREATE INDEX IF NOT EXISTS idx_alerts_resolved_by ON alerts(resolved_by);

-- Attendance table
CREATE INDEX IF NOT EXISTS idx_attendance_logged_by ON attendance(logged_by);

-- Change approvals table
CREATE INDEX IF NOT EXISTS idx_change_approvals_approved_by ON change_approvals(approved_by);
CREATE INDEX IF NOT EXISTS idx_change_approvals_change_request_id ON change_approvals(change_request_id);

-- Change requests table
CREATE INDEX IF NOT EXISTS idx_change_requests_requested_by ON change_requests(requested_by);
CREATE INDEX IF NOT EXISTS idx_change_requests_reviewed_by ON change_requests(reviewed_by);

-- Compliance checks table
CREATE INDEX IF NOT EXISTS idx_compliance_checks_checked_by ON compliance_checks(checked_by);
CREATE INDEX IF NOT EXISTS idx_compliance_checks_regulation_id ON compliance_checks(regulation_id);
CREATE INDEX IF NOT EXISTS idx_compliance_checks_permit_id ON compliance_checks(permit_id);

-- Daily logs table
CREATE INDEX IF NOT EXISTS idx_daily_logs_logged_by ON daily_logs(logged_by);

-- Defects table
CREATE INDEX IF NOT EXISTS idx_defects_inspection_id ON defects(inspection_id);
CREATE INDEX IF NOT EXISTS idx_defects_assigned_to ON defects(assigned_to);
CREATE INDEX IF NOT EXISTS idx_defects_resolved_by ON defects(resolved_by);
CREATE INDEX IF NOT EXISTS idx_defects_reported_by ON defects(reported_by);

-- Documents table
CREATE INDEX IF NOT EXISTS idx_documents_uploaded_by ON documents(uploaded_by);

-- Equipment assignments table
CREATE INDEX IF NOT EXISTS idx_equipment_assignments_operator_id ON equipment_assignments(operator_id);
CREATE INDEX IF NOT EXISTS idx_equipment_assignments_assigned_by ON equipment_assignments(assigned_by);

-- Equipment usage table
CREATE INDEX IF NOT EXISTS idx_equipment_usage_operator_id ON equipment_usage(operator_id);
CREATE INDEX IF NOT EXISTS idx_equipment_usage_logged_by ON equipment_usage(logged_by);

-- Inspections table
CREATE INDEX IF NOT EXISTS idx_inspections_inspector_id ON inspections(inspector_id);
CREATE INDEX IF NOT EXISTS idx_inspections_created_by ON inspections(created_by);

-- Inventory anomalies table
CREATE INDEX IF NOT EXISTS idx_inventory_anomalies_inventory_id ON inventory_anomalies(inventory_id);
CREATE INDEX IF NOT EXISTS idx_inventory_anomalies_resolved_by ON inventory_anomalies(resolved_by);
CREATE INDEX IF NOT EXISTS idx_inventory_anomalies_reported_by ON inventory_anomalies(reported_by);

-- Maintenance logs table
CREATE INDEX IF NOT EXISTS idx_maintenance_logs_created_by ON maintenance_logs(created_by);

-- Material inventory table
CREATE INDEX IF NOT EXISTS idx_material_inventory_material_id ON material_inventory(material_id);
CREATE INDEX IF NOT EXISTS idx_material_inventory_counted_by ON material_inventory(counted_by);

-- Material targets table
CREATE INDEX IF NOT EXISTS idx_material_targets_material_id ON material_targets(material_id);
CREATE INDEX IF NOT EXISTS idx_material_targets_created_by ON material_targets(created_by);

-- Material usage table
CREATE INDEX IF NOT EXISTS idx_material_usage_material_id ON material_usage(material_id);
CREATE INDEX IF NOT EXISTS idx_material_usage_logged_by ON material_usage(logged_by);

-- Milestones table
CREATE INDEX IF NOT EXISTS idx_milestones_created_by ON milestones(created_by);

-- Near misses table
CREATE INDEX IF NOT EXISTS idx_near_misses_reported_by ON near_misses(reported_by);
CREATE INDEX IF NOT EXISTS idx_near_misses_reviewed_by ON near_misses(reviewed_by);

-- Permits table
CREATE INDEX IF NOT EXISTS idx_permits_created_by ON permits(created_by);

-- Photos table
CREATE INDEX IF NOT EXISTS idx_photos_taken_by ON photos(taken_by);

-- Plans table
CREATE INDEX IF NOT EXISTS idx_plans_approved_by ON plans(approved_by);
CREATE INDEX IF NOT EXISTS idx_plans_supersedes_id ON plans(supersedes_id);
CREATE INDEX IF NOT EXISTS idx_plans_created_by ON plans(created_by);

-- Productivity logs table
CREATE INDEX IF NOT EXISTS idx_productivity_logs_logged_by ON productivity_logs(logged_by);

-- Progress logs table
CREATE INDEX IF NOT EXISTS idx_progress_logs_milestone_id ON progress_logs(milestone_id);
CREATE INDEX IF NOT EXISTS idx_progress_logs_logged_by ON progress_logs(logged_by);

-- Projects table
CREATE INDEX IF NOT EXISTS idx_projects_created_by ON projects(created_by);

-- Risk assessments table
CREATE INDEX IF NOT EXISTS idx_risk_assessments_assessed_by ON risk_assessments(assessed_by);

-- Safety incidents table
CREATE INDEX IF NOT EXISTS idx_safety_incidents_reported_by ON safety_incidents(reported_by);
CREATE INDEX IF NOT EXISTS idx_safety_incidents_investigated_by ON safety_incidents(investigated_by);

-- Site conditions table
CREATE INDEX IF NOT EXISTS idx_site_conditions_checked_by ON site_conditions(checked_by);

-- Sites table
CREATE INDEX IF NOT EXISTS idx_sites_created_by ON sites(created_by);

-- Subcontractor assignments table
CREATE INDEX IF NOT EXISTS idx_subcontractor_assignments_created_by ON subcontractor_assignments(created_by);

-- Subcontractor performance table
CREATE INDEX IF NOT EXISTS idx_subcontractor_performance_logged_by ON subcontractor_performance(logged_by);

-- Waste logs table
CREATE INDEX IF NOT EXISTS idx_waste_logs_logged_by ON waste_logs(logged_by);

-- Workers table
CREATE INDEX IF NOT EXISTS idx_workers_profile_id ON workers(profile_id);
