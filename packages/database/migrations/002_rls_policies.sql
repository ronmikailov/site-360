-- ============================================================================
-- Site360 Database Schema - Row Level Security Policies
-- ============================================================================
-- This migration creates comprehensive RLS policies for multi-tenant security.
-- All data is isolated by organization, with role-based access control.
-- ============================================================================

-- ============================================================================
-- ENABLE RLS ON ALL TABLES
-- ============================================================================

ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE sites ENABLE ROW LEVEL SECURITY;
ALTER TABLE plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE plan_usage_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE change_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE change_approvals ENABLE ROW LEVEL SECURITY;
ALTER TABLE milestones ENABLE ROW LEVEL SECURITY;
ALTER TABLE progress_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE materials ENABLE ROW LEVEL SECURITY;
ALTER TABLE material_targets ENABLE ROW LEVEL SECURITY;
ALTER TABLE material_usage ENABLE ROW LEVEL SECURITY;
ALTER TABLE material_inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory_anomalies ENABLE ROW LEVEL SECURITY;
ALTER TABLE inspections ENABLE ROW LEVEL SECURITY;
ALTER TABLE defects ENABLE ROW LEVEL SECURITY;
ALTER TABLE safety_incidents ENABLE ROW LEVEL SECURITY;
ALTER TABLE near_misses ENABLE ROW LEVEL SECURITY;
ALTER TABLE risk_assessments ENABLE ROW LEVEL SECURITY;
ALTER TABLE regulations ENABLE ROW LEVEL SECURITY;
ALTER TABLE permits ENABLE ROW LEVEL SECURITY;
ALTER TABLE compliance_checks ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE subcontractors ENABLE ROW LEVEL SECURITY;
ALTER TABLE subcontractor_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE subcontractor_performance ENABLE ROW LEVEL SECURITY;
ALTER TABLE workers ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE productivity_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE equipment ENABLE ROW LEVEL SECURITY;
ALTER TABLE equipment_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE equipment_usage ENABLE ROW LEVEL SECURITY;
ALTER TABLE maintenance_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE site_conditions ENABLE ROW LEVEL SECURITY;
ALTER TABLE waste_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE control_scores ENABLE ROW LEVEL SECURITY;
ALTER TABLE alerts ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- HELPER FUNCTIONS FOR RLS
-- ============================================================================

-- Check if user belongs to an organization
CREATE OR REPLACE FUNCTION user_belongs_to_org(org_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM profiles
        WHERE id = auth.uid()
        AND organization_id = org_id
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Check if user has minimum role level
CREATE OR REPLACE FUNCTION user_has_role(required_role user_role)
RETURNS BOOLEAN AS $$
DECLARE
    user_role_val user_role;
    role_order TEXT[] := ARRAY['viewer', 'worker', 'supervisor', 'manager', 'admin', 'owner'];
BEGIN
    SELECT role INTO user_role_val FROM profiles WHERE id = auth.uid();
    RETURN array_position(role_order, user_role_val::TEXT) >= array_position(role_order, required_role::TEXT);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Get organization ID for a site
CREATE OR REPLACE FUNCTION get_site_org_id(site_id UUID)
RETURNS UUID AS $$
BEGIN
    RETURN (
        SELECT p.organization_id
        FROM sites s
        JOIN projects p ON s.project_id = p.id
        WHERE s.id = site_id
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Get organization ID for a project
CREATE OR REPLACE FUNCTION get_project_org_id(project_id UUID)
RETURNS UUID AS $$
BEGIN
    RETURN (
        SELECT organization_id
        FROM projects
        WHERE id = project_id
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ============================================================================
-- ORGANIZATIONS POLICIES
-- ============================================================================

-- Users can view their own organization
CREATE POLICY "organizations_select_own"
    ON organizations FOR SELECT
    USING (user_belongs_to_org(id));

-- Only owners/admins can update organization
CREATE POLICY "organizations_update_admin"
    ON organizations FOR UPDATE
    USING (user_belongs_to_org(id) AND user_has_role('admin'))
    WITH CHECK (user_belongs_to_org(id) AND user_has_role('admin'));

-- Only owners can delete organization
CREATE POLICY "organizations_delete_owner"
    ON organizations FOR DELETE
    USING (user_belongs_to_org(id) AND user_has_role('owner'));

-- Authenticated users can create organizations (become owner)
CREATE POLICY "organizations_insert_authenticated"
    ON organizations FOR INSERT
    WITH CHECK (auth.uid() IS NOT NULL);

-- ============================================================================
-- PROFILES POLICIES
-- ============================================================================

-- Users can view profiles in their organization
CREATE POLICY "profiles_select_org"
    ON profiles FOR SELECT
    USING (
        organization_id IS NULL
        OR organization_id = get_user_organization_id()
        OR id = auth.uid()
    );

-- Users can update their own profile
CREATE POLICY "profiles_update_own"
    ON profiles FOR UPDATE
    USING (id = auth.uid())
    WITH CHECK (id = auth.uid());

-- Admins can update any profile in their org
CREATE POLICY "profiles_update_admin"
    ON profiles FOR UPDATE
    USING (
        organization_id = get_user_organization_id()
        AND user_has_role('admin')
    )
    WITH CHECK (
        organization_id = get_user_organization_id()
        AND user_has_role('admin')
    );

-- Profile is created on user signup (via trigger or app)
CREATE POLICY "profiles_insert_own"
    ON profiles FOR INSERT
    WITH CHECK (id = auth.uid());

-- ============================================================================
-- PROJECTS POLICIES
-- ============================================================================

-- Users can view projects in their organization
CREATE POLICY "projects_select_org"
    ON projects FOR SELECT
    USING (user_belongs_to_org(organization_id));

-- Managers+ can create projects
CREATE POLICY "projects_insert_manager"
    ON projects FOR INSERT
    WITH CHECK (
        user_belongs_to_org(organization_id)
        AND user_has_role('manager')
    );

-- Managers+ can update projects
CREATE POLICY "projects_update_manager"
    ON projects FOR UPDATE
    USING (
        user_belongs_to_org(organization_id)
        AND user_has_role('manager')
    )
    WITH CHECK (
        user_belongs_to_org(organization_id)
        AND user_has_role('manager')
    );

-- Admins+ can delete projects
CREATE POLICY "projects_delete_admin"
    ON projects FOR DELETE
    USING (
        user_belongs_to_org(organization_id)
        AND user_has_role('admin')
    );

-- ============================================================================
-- SITES POLICIES
-- ============================================================================

-- Users can view sites in their organization's projects
CREATE POLICY "sites_select_org"
    ON sites FOR SELECT
    USING (user_belongs_to_org(get_project_org_id(project_id)));

-- Managers+ can create sites
CREATE POLICY "sites_insert_manager"
    ON sites FOR INSERT
    WITH CHECK (
        user_belongs_to_org(get_project_org_id(project_id))
        AND user_has_role('manager')
    );

-- Supervisors+ can update sites
CREATE POLICY "sites_update_supervisor"
    ON sites FOR UPDATE
    USING (
        user_belongs_to_org(get_project_org_id(project_id))
        AND user_has_role('supervisor')
    )
    WITH CHECK (
        user_belongs_to_org(get_project_org_id(project_id))
        AND user_has_role('supervisor')
    );

-- Admins+ can delete sites
CREATE POLICY "sites_delete_admin"
    ON sites FOR DELETE
    USING (
        user_belongs_to_org(get_project_org_id(project_id))
        AND user_has_role('admin')
    );

-- ============================================================================
-- PLANS POLICIES (Planning Control)
-- ============================================================================

CREATE POLICY "plans_select_org"
    ON plans FOR SELECT
    USING (user_belongs_to_org(get_site_org_id(site_id)));

CREATE POLICY "plans_insert_supervisor"
    ON plans FOR INSERT
    WITH CHECK (
        user_belongs_to_org(get_site_org_id(site_id))
        AND user_has_role('supervisor')
    );

CREATE POLICY "plans_update_supervisor"
    ON plans FOR UPDATE
    USING (
        user_belongs_to_org(get_site_org_id(site_id))
        AND user_has_role('supervisor')
    );

CREATE POLICY "plans_delete_manager"
    ON plans FOR DELETE
    USING (
        user_belongs_to_org(get_site_org_id(site_id))
        AND user_has_role('manager')
    );

-- Plan usage logs - all org members can view, system/app inserts
CREATE POLICY "plan_usage_logs_select_org"
    ON plan_usage_logs FOR SELECT
    USING (
        user_belongs_to_org(get_site_org_id((SELECT site_id FROM plans WHERE id = plan_id)))
    );

CREATE POLICY "plan_usage_logs_insert_authenticated"
    ON plan_usage_logs FOR INSERT
    WITH CHECK (user_id = auth.uid());

-- ============================================================================
-- CHANGE REQUESTS POLICIES (Design Change Control)
-- ============================================================================

CREATE POLICY "change_requests_select_org"
    ON change_requests FOR SELECT
    USING (user_belongs_to_org(get_site_org_id(site_id)));

-- Workers+ can create change requests
CREATE POLICY "change_requests_insert_worker"
    ON change_requests FOR INSERT
    WITH CHECK (
        user_belongs_to_org(get_site_org_id(site_id))
        AND user_has_role('worker')
    );

-- Supervisors+ can update change requests
CREATE POLICY "change_requests_update_supervisor"
    ON change_requests FOR UPDATE
    USING (
        user_belongs_to_org(get_site_org_id(site_id))
        AND user_has_role('supervisor')
    );

CREATE POLICY "change_approvals_select_org"
    ON change_approvals FOR SELECT
    USING (
        user_belongs_to_org(get_site_org_id((SELECT site_id FROM change_requests WHERE id = change_request_id)))
    );

-- Managers+ can create approvals
CREATE POLICY "change_approvals_insert_manager"
    ON change_approvals FOR INSERT
    WITH CHECK (
        user_belongs_to_org(get_site_org_id((SELECT site_id FROM change_requests WHERE id = change_request_id)))
        AND user_has_role('manager')
    );

-- ============================================================================
-- MILESTONES & PROGRESS POLICIES (Schedule Control)
-- ============================================================================

CREATE POLICY "milestones_select_org"
    ON milestones FOR SELECT
    USING (user_belongs_to_org(get_project_org_id(project_id)));

CREATE POLICY "milestones_insert_manager"
    ON milestones FOR INSERT
    WITH CHECK (
        user_belongs_to_org(get_project_org_id(project_id))
        AND user_has_role('manager')
    );

CREATE POLICY "milestones_update_supervisor"
    ON milestones FOR UPDATE
    USING (
        user_belongs_to_org(get_project_org_id(project_id))
        AND user_has_role('supervisor')
    );

CREATE POLICY "progress_logs_select_org"
    ON progress_logs FOR SELECT
    USING (user_belongs_to_org(get_site_org_id(site_id)));

CREATE POLICY "progress_logs_insert_worker"
    ON progress_logs FOR INSERT
    WITH CHECK (
        user_belongs_to_org(get_site_org_id(site_id))
        AND user_has_role('worker')
    );

-- ============================================================================
-- MATERIALS POLICIES (Material Control)
-- ============================================================================

CREATE POLICY "materials_select_org"
    ON materials FOR SELECT
    USING (user_belongs_to_org(organization_id));

CREATE POLICY "materials_insert_manager"
    ON materials FOR INSERT
    WITH CHECK (
        user_belongs_to_org(organization_id)
        AND user_has_role('manager')
    );

CREATE POLICY "materials_update_supervisor"
    ON materials FOR UPDATE
    USING (
        user_belongs_to_org(organization_id)
        AND user_has_role('supervisor')
    );

CREATE POLICY "material_targets_select_org"
    ON material_targets FOR SELECT
    USING (user_belongs_to_org(get_site_org_id(site_id)));

CREATE POLICY "material_targets_insert_supervisor"
    ON material_targets FOR INSERT
    WITH CHECK (
        user_belongs_to_org(get_site_org_id(site_id))
        AND user_has_role('supervisor')
    );

CREATE POLICY "material_targets_update_supervisor"
    ON material_targets FOR UPDATE
    USING (
        user_belongs_to_org(get_site_org_id(site_id))
        AND user_has_role('supervisor')
    );

CREATE POLICY "material_usage_select_org"
    ON material_usage FOR SELECT
    USING (user_belongs_to_org(get_site_org_id(site_id)));

CREATE POLICY "material_usage_insert_worker"
    ON material_usage FOR INSERT
    WITH CHECK (
        user_belongs_to_org(get_site_org_id(site_id))
        AND user_has_role('worker')
    );

-- ============================================================================
-- INVENTORY POLICIES (Loss/Theft Prevention)
-- ============================================================================

CREATE POLICY "material_inventory_select_org"
    ON material_inventory FOR SELECT
    USING (user_belongs_to_org(get_site_org_id(site_id)));

CREATE POLICY "material_inventory_insert_supervisor"
    ON material_inventory FOR INSERT
    WITH CHECK (
        user_belongs_to_org(get_site_org_id(site_id))
        AND user_has_role('supervisor')
    );

CREATE POLICY "material_inventory_update_supervisor"
    ON material_inventory FOR UPDATE
    USING (
        user_belongs_to_org(get_site_org_id(site_id))
        AND user_has_role('supervisor')
    );

CREATE POLICY "inventory_anomalies_select_org"
    ON inventory_anomalies FOR SELECT
    USING (
        user_belongs_to_org(get_site_org_id((SELECT site_id FROM material_inventory WHERE id = inventory_id)))
    );

CREATE POLICY "inventory_anomalies_insert_supervisor"
    ON inventory_anomalies FOR INSERT
    WITH CHECK (
        user_belongs_to_org(get_site_org_id((SELECT site_id FROM material_inventory WHERE id = inventory_id)))
        AND user_has_role('supervisor')
    );

CREATE POLICY "inventory_anomalies_update_supervisor"
    ON inventory_anomalies FOR UPDATE
    USING (
        user_belongs_to_org(get_site_org_id((SELECT site_id FROM material_inventory WHERE id = inventory_id)))
        AND user_has_role('supervisor')
    );

-- ============================================================================
-- QUALITY CONTROL POLICIES
-- ============================================================================

CREATE POLICY "inspections_select_org"
    ON inspections FOR SELECT
    USING (user_belongs_to_org(get_site_org_id(site_id)));

CREATE POLICY "inspections_insert_supervisor"
    ON inspections FOR INSERT
    WITH CHECK (
        user_belongs_to_org(get_site_org_id(site_id))
        AND user_has_role('supervisor')
    );

CREATE POLICY "inspections_update_supervisor"
    ON inspections FOR UPDATE
    USING (
        user_belongs_to_org(get_site_org_id(site_id))
        AND user_has_role('supervisor')
    );

CREATE POLICY "defects_select_org"
    ON defects FOR SELECT
    USING (user_belongs_to_org(get_site_org_id(site_id)));

CREATE POLICY "defects_insert_worker"
    ON defects FOR INSERT
    WITH CHECK (
        user_belongs_to_org(get_site_org_id(site_id))
        AND user_has_role('worker')
    );

CREATE POLICY "defects_update_worker"
    ON defects FOR UPDATE
    USING (
        user_belongs_to_org(get_site_org_id(site_id))
        AND user_has_role('worker')
    );

-- ============================================================================
-- SAFETY CONTROL POLICIES
-- ============================================================================

CREATE POLICY "safety_incidents_select_org"
    ON safety_incidents FOR SELECT
    USING (user_belongs_to_org(get_site_org_id(site_id)));

-- Anyone can report safety incidents
CREATE POLICY "safety_incidents_insert_worker"
    ON safety_incidents FOR INSERT
    WITH CHECK (
        user_belongs_to_org(get_site_org_id(site_id))
        AND user_has_role('worker')
    );

CREATE POLICY "safety_incidents_update_supervisor"
    ON safety_incidents FOR UPDATE
    USING (
        user_belongs_to_org(get_site_org_id(site_id))
        AND user_has_role('supervisor')
    );

CREATE POLICY "near_misses_select_org"
    ON near_misses FOR SELECT
    USING (user_belongs_to_org(get_site_org_id(site_id)));

CREATE POLICY "near_misses_insert_worker"
    ON near_misses FOR INSERT
    WITH CHECK (
        user_belongs_to_org(get_site_org_id(site_id))
        AND user_has_role('worker')
    );

CREATE POLICY "risk_assessments_select_org"
    ON risk_assessments FOR SELECT
    USING (user_belongs_to_org(get_site_org_id(site_id)));

CREATE POLICY "risk_assessments_insert_supervisor"
    ON risk_assessments FOR INSERT
    WITH CHECK (
        user_belongs_to_org(get_site_org_id(site_id))
        AND user_has_role('supervisor')
    );

CREATE POLICY "risk_assessments_update_supervisor"
    ON risk_assessments FOR UPDATE
    USING (
        user_belongs_to_org(get_site_org_id(site_id))
        AND user_has_role('supervisor')
    );

-- ============================================================================
-- REGULATORY COMPLIANCE POLICIES
-- ============================================================================

CREATE POLICY "regulations_select_org"
    ON regulations FOR SELECT
    USING (user_belongs_to_org(organization_id));

CREATE POLICY "regulations_insert_manager"
    ON regulations FOR INSERT
    WITH CHECK (
        user_belongs_to_org(organization_id)
        AND user_has_role('manager')
    );

CREATE POLICY "regulations_update_manager"
    ON regulations FOR UPDATE
    USING (
        user_belongs_to_org(organization_id)
        AND user_has_role('manager')
    );

CREATE POLICY "permits_select_org"
    ON permits FOR SELECT
    USING (user_belongs_to_org(get_site_org_id(site_id)));

CREATE POLICY "permits_insert_manager"
    ON permits FOR INSERT
    WITH CHECK (
        user_belongs_to_org(get_site_org_id(site_id))
        AND user_has_role('manager')
    );

CREATE POLICY "permits_update_manager"
    ON permits FOR UPDATE
    USING (
        user_belongs_to_org(get_site_org_id(site_id))
        AND user_has_role('manager')
    );

CREATE POLICY "compliance_checks_select_org"
    ON compliance_checks FOR SELECT
    USING (user_belongs_to_org(get_site_org_id(site_id)));

CREATE POLICY "compliance_checks_insert_supervisor"
    ON compliance_checks FOR INSERT
    WITH CHECK (
        user_belongs_to_org(get_site_org_id(site_id))
        AND user_has_role('supervisor')
    );

CREATE POLICY "compliance_checks_update_supervisor"
    ON compliance_checks FOR UPDATE
    USING (
        user_belongs_to_org(get_site_org_id(site_id))
        AND user_has_role('supervisor')
    );

-- ============================================================================
-- DOCUMENTATION POLICIES
-- ============================================================================

CREATE POLICY "daily_logs_select_org"
    ON daily_logs FOR SELECT
    USING (user_belongs_to_org(get_site_org_id(site_id)));

CREATE POLICY "daily_logs_insert_worker"
    ON daily_logs FOR INSERT
    WITH CHECK (
        user_belongs_to_org(get_site_org_id(site_id))
        AND user_has_role('worker')
    );

CREATE POLICY "daily_logs_update_worker"
    ON daily_logs FOR UPDATE
    USING (
        user_belongs_to_org(get_site_org_id(site_id))
        AND user_has_role('worker')
        AND logged_by = auth.uid()
    );

-- Supervisors can update any daily log
CREATE POLICY "daily_logs_update_supervisor"
    ON daily_logs FOR UPDATE
    USING (
        user_belongs_to_org(get_site_org_id(site_id))
        AND user_has_role('supervisor')
    );

CREATE POLICY "photos_select_org"
    ON photos FOR SELECT
    USING (user_belongs_to_org(get_site_org_id(site_id)));

CREATE POLICY "photos_insert_worker"
    ON photos FOR INSERT
    WITH CHECK (
        user_belongs_to_org(get_site_org_id(site_id))
        AND user_has_role('worker')
    );

CREATE POLICY "documents_select_org"
    ON documents FOR SELECT
    USING (
        (site_id IS NOT NULL AND user_belongs_to_org(get_site_org_id(site_id)))
        OR (project_id IS NOT NULL AND user_belongs_to_org(get_project_org_id(project_id)))
        OR (organization_id IS NOT NULL AND user_belongs_to_org(organization_id))
    );

CREATE POLICY "documents_insert_worker"
    ON documents FOR INSERT
    WITH CHECK (
        (site_id IS NOT NULL AND user_belongs_to_org(get_site_org_id(site_id)) AND user_has_role('worker'))
        OR (project_id IS NOT NULL AND user_belongs_to_org(get_project_org_id(project_id)) AND user_has_role('worker'))
        OR (organization_id IS NOT NULL AND user_belongs_to_org(organization_id) AND user_has_role('worker'))
    );

CREATE POLICY "documents_update_supervisor"
    ON documents FOR UPDATE
    USING (
        (site_id IS NOT NULL AND user_belongs_to_org(get_site_org_id(site_id)) AND user_has_role('supervisor'))
        OR (project_id IS NOT NULL AND user_belongs_to_org(get_project_org_id(project_id)) AND user_has_role('supervisor'))
        OR (organization_id IS NOT NULL AND user_belongs_to_org(organization_id) AND user_has_role('supervisor'))
    );

CREATE POLICY "documents_delete_manager"
    ON documents FOR DELETE
    USING (
        (site_id IS NOT NULL AND user_belongs_to_org(get_site_org_id(site_id)) AND user_has_role('manager'))
        OR (project_id IS NOT NULL AND user_belongs_to_org(get_project_org_id(project_id)) AND user_has_role('manager'))
        OR (organization_id IS NOT NULL AND user_belongs_to_org(organization_id) AND user_has_role('manager'))
    );

-- ============================================================================
-- SUBCONTRACTOR POLICIES
-- ============================================================================

CREATE POLICY "subcontractors_select_org"
    ON subcontractors FOR SELECT
    USING (user_belongs_to_org(organization_id));

CREATE POLICY "subcontractors_insert_manager"
    ON subcontractors FOR INSERT
    WITH CHECK (
        user_belongs_to_org(organization_id)
        AND user_has_role('manager')
    );

CREATE POLICY "subcontractors_update_manager"
    ON subcontractors FOR UPDATE
    USING (
        user_belongs_to_org(organization_id)
        AND user_has_role('manager')
    );

CREATE POLICY "subcontractor_assignments_select_org"
    ON subcontractor_assignments FOR SELECT
    USING (user_belongs_to_org(get_site_org_id(site_id)));

CREATE POLICY "subcontractor_assignments_insert_manager"
    ON subcontractor_assignments FOR INSERT
    WITH CHECK (
        user_belongs_to_org(get_site_org_id(site_id))
        AND user_has_role('manager')
    );

CREATE POLICY "subcontractor_assignments_update_supervisor"
    ON subcontractor_assignments FOR UPDATE
    USING (
        user_belongs_to_org(get_site_org_id(site_id))
        AND user_has_role('supervisor')
    );

CREATE POLICY "subcontractor_performance_select_org"
    ON subcontractor_performance FOR SELECT
    USING (
        user_belongs_to_org(get_site_org_id((SELECT site_id FROM subcontractor_assignments WHERE id = assignment_id)))
    );

CREATE POLICY "subcontractor_performance_insert_supervisor"
    ON subcontractor_performance FOR INSERT
    WITH CHECK (
        user_belongs_to_org(get_site_org_id((SELECT site_id FROM subcontractor_assignments WHERE id = assignment_id)))
        AND user_has_role('supervisor')
    );

-- ============================================================================
-- WORKFORCE POLICIES
-- ============================================================================

CREATE POLICY "workers_select_org"
    ON workers FOR SELECT
    USING (user_belongs_to_org(organization_id));

CREATE POLICY "workers_insert_manager"
    ON workers FOR INSERT
    WITH CHECK (
        user_belongs_to_org(organization_id)
        AND user_has_role('manager')
    );

CREATE POLICY "workers_update_supervisor"
    ON workers FOR UPDATE
    USING (
        user_belongs_to_org(organization_id)
        AND user_has_role('supervisor')
    );

CREATE POLICY "attendance_select_org"
    ON attendance FOR SELECT
    USING (user_belongs_to_org(get_site_org_id(site_id)));

CREATE POLICY "attendance_insert_supervisor"
    ON attendance FOR INSERT
    WITH CHECK (
        user_belongs_to_org(get_site_org_id(site_id))
        AND user_has_role('supervisor')
    );

CREATE POLICY "attendance_update_supervisor"
    ON attendance FOR UPDATE
    USING (
        user_belongs_to_org(get_site_org_id(site_id))
        AND user_has_role('supervisor')
    );

CREATE POLICY "productivity_logs_select_org"
    ON productivity_logs FOR SELECT
    USING (user_belongs_to_org(get_site_org_id(site_id)));

CREATE POLICY "productivity_logs_insert_supervisor"
    ON productivity_logs FOR INSERT
    WITH CHECK (
        user_belongs_to_org(get_site_org_id(site_id))
        AND user_has_role('supervisor')
    );

-- ============================================================================
-- EQUIPMENT POLICIES
-- ============================================================================

CREATE POLICY "equipment_select_org"
    ON equipment FOR SELECT
    USING (user_belongs_to_org(organization_id));

CREATE POLICY "equipment_insert_manager"
    ON equipment FOR INSERT
    WITH CHECK (
        user_belongs_to_org(organization_id)
        AND user_has_role('manager')
    );

CREATE POLICY "equipment_update_supervisor"
    ON equipment FOR UPDATE
    USING (
        user_belongs_to_org(organization_id)
        AND user_has_role('supervisor')
    );

CREATE POLICY "equipment_assignments_select_org"
    ON equipment_assignments FOR SELECT
    USING (user_belongs_to_org(get_site_org_id(site_id)));

CREATE POLICY "equipment_assignments_insert_supervisor"
    ON equipment_assignments FOR INSERT
    WITH CHECK (
        user_belongs_to_org(get_site_org_id(site_id))
        AND user_has_role('supervisor')
    );

CREATE POLICY "equipment_assignments_update_supervisor"
    ON equipment_assignments FOR UPDATE
    USING (
        user_belongs_to_org(get_site_org_id(site_id))
        AND user_has_role('supervisor')
    );

CREATE POLICY "equipment_usage_select_org"
    ON equipment_usage FOR SELECT
    USING (
        user_belongs_to_org(get_site_org_id((SELECT site_id FROM equipment_assignments WHERE id = assignment_id)))
    );

CREATE POLICY "equipment_usage_insert_worker"
    ON equipment_usage FOR INSERT
    WITH CHECK (
        user_belongs_to_org(get_site_org_id((SELECT site_id FROM equipment_assignments WHERE id = assignment_id)))
        AND user_has_role('worker')
    );

CREATE POLICY "maintenance_logs_select_org"
    ON maintenance_logs FOR SELECT
    USING (
        user_belongs_to_org((SELECT organization_id FROM equipment WHERE id = equipment_id))
    );

CREATE POLICY "maintenance_logs_insert_supervisor"
    ON maintenance_logs FOR INSERT
    WITH CHECK (
        user_belongs_to_org((SELECT organization_id FROM equipment WHERE id = equipment_id))
        AND user_has_role('supervisor')
    );

CREATE POLICY "maintenance_logs_update_supervisor"
    ON maintenance_logs FOR UPDATE
    USING (
        user_belongs_to_org((SELECT organization_id FROM equipment WHERE id = equipment_id))
        AND user_has_role('supervisor')
    );

-- ============================================================================
-- SITE ORGANIZATION POLICIES
-- ============================================================================

CREATE POLICY "site_conditions_select_org"
    ON site_conditions FOR SELECT
    USING (user_belongs_to_org(get_site_org_id(site_id)));

CREATE POLICY "site_conditions_insert_supervisor"
    ON site_conditions FOR INSERT
    WITH CHECK (
        user_belongs_to_org(get_site_org_id(site_id))
        AND user_has_role('supervisor')
    );

CREATE POLICY "waste_logs_select_org"
    ON waste_logs FOR SELECT
    USING (user_belongs_to_org(get_site_org_id(site_id)));

CREATE POLICY "waste_logs_insert_worker"
    ON waste_logs FOR INSERT
    WITH CHECK (
        user_belongs_to_org(get_site_org_id(site_id))
        AND user_has_role('worker')
    );

-- ============================================================================
-- MANAGEMENT CONTROL POLICIES
-- ============================================================================

CREATE POLICY "control_scores_select_org"
    ON control_scores FOR SELECT
    USING (user_belongs_to_org(get_site_org_id(site_id)));

-- Only system/admins can insert control scores
CREATE POLICY "control_scores_insert_admin"
    ON control_scores FOR INSERT
    WITH CHECK (
        user_belongs_to_org(get_site_org_id(site_id))
        AND user_has_role('admin')
    );

CREATE POLICY "alerts_select_org"
    ON alerts FOR SELECT
    USING (user_belongs_to_org(get_site_org_id(site_id)));

-- System generates alerts, admins can also create
CREATE POLICY "alerts_insert_admin"
    ON alerts FOR INSERT
    WITH CHECK (
        user_belongs_to_org(get_site_org_id(site_id))
        AND user_has_role('admin')
    );

-- Supervisors+ can acknowledge/update alerts
CREATE POLICY "alerts_update_supervisor"
    ON alerts FOR UPDATE
    USING (
        user_belongs_to_org(get_site_org_id(site_id))
        AND user_has_role('supervisor')
    );

-- ============================================================================
-- SERVICE ROLE BYPASS
-- ============================================================================
-- Note: The service_role key bypasses RLS by default in Supabase.
-- This is used for backend services, Edge Functions, and scheduled jobs.
-- No additional policies needed for service role access.
