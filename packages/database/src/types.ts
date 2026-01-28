/**
 * Site360 Database Types
 *
 * TypeScript interfaces for the Supabase database schema.
 * These types match the PostgreSQL schema defined in migrations.
 */

// ============================================================================
// ENUM TYPES
// ============================================================================

export type ProjectStatus = 'planning' | 'active' | 'on_hold' | 'completed' | 'cancelled';
export type SiteStatus = 'setup' | 'active' | 'suspended' | 'completed' | 'closed';
export type UserRole = 'owner' | 'admin' | 'manager' | 'supervisor' | 'worker' | 'viewer';
export type ApprovalStatus = 'pending' | 'approved' | 'rejected' | 'requires_revision';
export type ChangeImpact = 'low' | 'medium' | 'high' | 'critical';
export type SeverityLevel = 'low' | 'medium' | 'high' | 'critical';
export type AlertStatus = 'active' | 'acknowledged' | 'resolved' | 'dismissed';
export type InspectionResult = 'pass' | 'pass_with_notes' | 'fail' | 'pending';
export type DefectStatus = 'open' | 'in_progress' | 'resolved' | 'closed' | 'deferred';
export type IncidentType = 'injury' | 'property_damage' | 'environmental' | 'near_miss' | 'other';
export type PermitStatus = 'pending' | 'active' | 'expired' | 'revoked' | 'renewed';
export type AssignmentStatus = 'scheduled' | 'active' | 'completed' | 'cancelled';
export type EquipmentStatus = 'available' | 'assigned' | 'maintenance' | 'repair' | 'retired';
export type WorkerStatus = 'active' | 'inactive' | 'on_leave' | 'terminated';
export type MaintenanceType = 'preventive' | 'corrective' | 'emergency' | 'inspection';
export type DocumentType = 'drawing' | 'specification' | 'contract' | 'report' | 'certificate' | 'permit' | 'photo' | 'other';
export type WasteType = 'construction' | 'hazardous' | 'recyclable' | 'organic' | 'mixed';
export type ControlDimension =
  | 'planning'
  | 'design_change'
  | 'schedule'
  | 'material'
  | 'loss_prevention'
  | 'quality'
  | 'safety'
  | 'regulatory'
  | 'documentation'
  | 'subcontractor'
  | 'workforce'
  | 'equipment'
  | 'site_organization'
  | 'overall_management';

// ============================================================================
// HELPER TYPES
// ============================================================================

export type Json = string | number | boolean | null | { [key: string]: Json | undefined } | Json[];

export interface Coordinates {
  lat: number;
  lng: number;
}

export interface EmergencyContact {
  name: string;
  relationship: string;
  phone: string;
}

export interface SupplierInfo {
  name?: string;
  contact?: string;
  phone?: string;
  email?: string;
  address?: string;
}

export interface InsuranceInfo {
  provider?: string;
  policy_number?: string;
  coverage_amount?: number;
  expiry_date?: string;
}

export interface Certification {
  name: string;
  issuer?: string;
  issue_date?: string;
  expiry_date?: string;
  number?: string;
}

// ============================================================================
// CORE ENTITIES
// ============================================================================

export interface Organization {
  id: string;
  name: string;
  slug: string;
  settings: Json;
  logo_url: string | null;
  contact_email: string | null;
  contact_phone: string | null;
  address: string | null;
  created_at: string;
  updated_at: string;
}

export interface Profile {
  id: string;
  organization_id: string | null;
  full_name: string;
  email: string | null;
  role: UserRole;
  phone: string | null;
  avatar_url: string | null;
  settings: Json;
  created_at: string;
  updated_at: string;
}

export interface Project {
  id: string;
  organization_id: string;
  name: string;
  description: string | null;
  status: ProjectStatus;
  start_date: string | null;
  end_date: string | null;
  budget: number | null;
  currency: string;
  client_name: string | null;
  client_contact: string | null;
  metadata: Json;
  created_by: string | null;
  created_at: string;
  updated_at: string;
}

export interface Site {
  id: string;
  project_id: string;
  name: string;
  address: string | null;
  city: string | null;
  state: string | null;
  country: string | null;
  postal_code: string | null;
  coordinates: string | null; // PostGIS geography type as WKT or GeoJSON string
  status: SiteStatus;
  area_sqm: number | null;
  settings: Json;
  created_by: string | null;
  created_at: string;
  updated_at: string;
}

// ============================================================================
// 1. PLANNING CONTROL
// ============================================================================

export interface Plan {
  id: string;
  site_id: string;
  name: string;
  description: string | null;
  version: string;
  file_url: string;
  file_type: string | null;
  file_size_bytes: number | null;
  status: ApprovalStatus;
  approved_by: string | null;
  approved_at: string | null;
  supersedes_id: string | null;
  metadata: Json;
  created_by: string | null;
  created_at: string;
  updated_at: string;
}

export interface PlanUsageLog {
  id: string;
  plan_id: string;
  user_id: string;
  action: string;
  ip_address: string | null;
  user_agent: string | null;
  accessed_at: string;
}

// ============================================================================
// 2. DESIGN CHANGE CONTROL
// ============================================================================

export interface ChangeRequest {
  id: string;
  site_id: string;
  title: string;
  description: string;
  reason: string | null;
  status: ApprovalStatus;
  impact: ChangeImpact;
  cost_impact: number | null;
  schedule_impact_days: number | null;
  affected_plans: string[] | null;
  requested_by: string;
  reviewed_by: string | null;
  impact_assessment: Json | null;
  attachments: string[] | null;
  created_at: string;
  updated_at: string;
}

export interface ChangeApproval {
  id: string;
  change_request_id: string;
  approved_by: string;
  decision: ApprovalStatus;
  notes: string | null;
  conditions: string | null;
  decided_at: string;
}

// ============================================================================
// 3. SCHEDULE/PACE CONTROL
// ============================================================================

export interface Milestone {
  id: string;
  project_id: string;
  site_id: string | null;
  name: string;
  description: string | null;
  target_date: string;
  actual_date: string | null;
  status: ApprovalStatus;
  progress_percentage: number;
  dependencies: string[] | null;
  is_critical_path: boolean;
  created_by: string | null;
  created_at: string;
  updated_at: string;
}

export interface ProgressLog {
  id: string;
  site_id: string;
  milestone_id: string | null;
  date: string;
  progress_percentage: number | null;
  work_completed: string | null;
  notes: string | null;
  blockers: string | null;
  weather_conditions: string | null;
  logged_by: string;
  photos: string[] | null;
  created_at: string;
}

// ============================================================================
// 4. MATERIAL CONTROL
// ============================================================================

export interface Material {
  id: string;
  organization_id: string;
  name: string;
  description: string | null;
  unit: string;
  category: string | null;
  subcategory: string | null;
  unit_cost: number | null;
  currency: string;
  min_stock: number | null;
  supplier_info: SupplierInfo | null;
  specifications: Json | null;
  created_at: string;
  updated_at: string;
}

export interface MaterialTarget {
  id: string;
  site_id: string;
  material_id: string;
  planned_quantity: number;
  actual_quantity: number;
  unit_cost: number | null;
  notes: string | null;
  created_by: string | null;
  created_at: string;
  updated_at: string;
}

export interface MaterialUsage {
  id: string;
  site_id: string;
  material_id: string;
  quantity: number;
  usage_type: string;
  date: string;
  location_on_site: string | null;
  purpose: string | null;
  notes: string | null;
  logged_by: string;
  created_at: string;
}

// ============================================================================
// 5. LOSS/THEFT PREVENTION
// ============================================================================

export interface MaterialInventory {
  id: string;
  site_id: string;
  material_id: string;
  quantity: number;
  storage_location: string | null;
  last_counted: string | null;
  counted_by: string | null;
  notes: string | null;
  created_at: string;
  updated_at: string;
}

export interface InventoryAnomaly {
  id: string;
  inventory_id: string;
  expected_quantity: number;
  actual_quantity: number;
  variance: number;
  variance_percentage: number | null;
  detected_at: string;
  status: DefectStatus;
  investigation_notes: string | null;
  resolution: string | null;
  resolved_by: string | null;
  resolved_at: string | null;
  reported_by: string;
}

// ============================================================================
// 6. QUALITY CONTROL
// ============================================================================

export interface Inspection {
  id: string;
  site_id: string;
  type: string;
  name: string | null;
  scheduled_date: string | null;
  completed_date: string | null;
  inspector_id: string | null;
  external_inspector: string | null;
  result: InspectionResult;
  score: number | null;
  notes: string | null;
  checklist: Json | null;
  photos: string[] | null;
  documents: string[] | null;
  created_by: string | null;
  created_at: string;
  updated_at: string;
}

export interface Defect {
  id: string;
  site_id: string;
  inspection_id: string | null;
  title: string;
  description: string;
  location: string | null;
  coordinates: string | null;
  severity: SeverityLevel;
  category: string | null;
  photos: string[] | null;
  status: DefectStatus;
  assigned_to: string | null;
  due_date: string | null;
  resolution: string | null;
  resolved_by: string | null;
  resolved_at: string | null;
  reported_by: string;
  created_at: string;
  updated_at: string;
}

// ============================================================================
// 7. SAFETY CONTROL
// ============================================================================

export interface SafetyIncident {
  id: string;
  site_id: string;
  type: IncidentType;
  severity: SeverityLevel;
  title: string;
  description: string;
  location: string | null;
  coordinates: string | null;
  incident_date: string;
  workers_involved: string[] | null;
  injuries_count: number;
  property_damage_cost: number | null;
  root_cause: string | null;
  corrective_actions: string | null;
  preventive_measures: string | null;
  photos: string[] | null;
  documents: string[] | null;
  reported_by: string;
  reported_at: string;
  investigated_by: string | null;
  investigated_at: string | null;
  resolved_at: string | null;
  status: DefectStatus;
}

export interface NearMiss {
  id: string;
  site_id: string;
  description: string;
  location: string | null;
  potential_severity: SeverityLevel;
  contributing_factors: string | null;
  preventive_actions: string | null;
  reported_by: string;
  reported_at: string;
  reviewed_by: string | null;
  reviewed_at: string | null;
}

export interface RiskAssessment {
  id: string;
  site_id: string;
  area: string;
  activity: string | null;
  hazard_description: string;
  risk_level: SeverityLevel;
  likelihood: number | null;
  consequence: number | null;
  risk_score: number | null;
  existing_controls: string | null;
  additional_controls: string | null;
  residual_risk_level: SeverityLevel | null;
  assessed_by: string;
  assessed_at: string;
  next_review_date: string | null;
  status: string;
}

// ============================================================================
// 8. REGULATORY COMPLIANCE
// ============================================================================

export interface Regulation {
  id: string;
  organization_id: string;
  name: string;
  code: string | null;
  description: string | null;
  authority: string;
  jurisdiction: string | null;
  effective_date: string | null;
  expiry_date: string | null;
  requirements: Json | null;
  document_url: string | null;
  created_at: string;
  updated_at: string;
}

export interface Permit {
  id: string;
  site_id: string;
  type: string;
  name: string;
  permit_number: string | null;
  issuing_authority: string | null;
  issued_date: string | null;
  expiry_date: string | null;
  status: PermitStatus;
  conditions: string | null;
  fee: number | null;
  document_url: string | null;
  renewal_reminder_days: number;
  created_by: string | null;
  created_at: string;
  updated_at: string;
}

export interface ComplianceCheck {
  id: string;
  site_id: string;
  regulation_id: string | null;
  permit_id: string | null;
  check_type: string;
  status: ApprovalStatus;
  findings: string | null;
  evidence: string[] | null;
  corrective_actions: string | null;
  checked_by: string;
  checked_at: string;
  next_check_date: string | null;
  notes: string | null;
}

// ============================================================================
// 9. DOCUMENTATION CONTROL
// ============================================================================

export interface DailyLog {
  id: string;
  site_id: string;
  date: string;
  weather: string | null;
  temperature_high: number | null;
  temperature_low: number | null;
  precipitation: string | null;
  summary: string;
  work_performed: string | null;
  delays: string | null;
  visitor_count: number;
  workforce_count: number | null;
  equipment_on_site: string[] | null;
  issues: string | null;
  logged_by: string;
  created_at: string;
  updated_at: string;
}

export interface Photo {
  id: string;
  site_id: string;
  daily_log_id: string | null;
  url: string;
  thumbnail_url: string | null;
  caption: string | null;
  category: string | null;
  location: string | null;
  coordinates: string | null;
  taken_at: string | null;
  taken_by: string | null;
  file_size_bytes: number | null;
  metadata: Json | null;
  created_at: string;
}

export interface Document {
  id: string;
  site_id: string | null;
  project_id: string | null;
  organization_id: string | null;
  name: string;
  type: DocumentType;
  category: string | null;
  file_url: string;
  file_type: string | null;
  file_size_bytes: number | null;
  version: string;
  description: string | null;
  tags: string[] | null;
  uploaded_by: string;
  uploaded_at: string;
  expires_at: string | null;
  metadata: Json | null;
}

// ============================================================================
// 10. SUBCONTRACTOR CONTROL
// ============================================================================

export interface Subcontractor {
  id: string;
  organization_id: string;
  company_name: string;
  legal_name: string | null;
  tax_id: string | null;
  contact_name: string | null;
  phone: string | null;
  email: string | null;
  address: string | null;
  trade: string;
  specializations: string[] | null;
  certifications: string[] | null;
  insurance_info: InsuranceInfo | null;
  rating: number | null;
  status: WorkerStatus;
  notes: string | null;
  created_at: string;
  updated_at: string;
}

export interface SubcontractorAssignment {
  id: string;
  site_id: string;
  subcontractor_id: string;
  scope: string;
  contract_value: number | null;
  start_date: string;
  end_date: string | null;
  status: AssignmentStatus;
  payment_terms: string | null;
  milestones: Json | null;
  documents: string[] | null;
  created_by: string | null;
  created_at: string;
  updated_at: string;
}

export interface SubcontractorPerformance {
  id: string;
  assignment_id: string;
  date: string;
  output_description: string | null;
  output_quantity: number | null;
  output_unit: string | null;
  quality_score: number | null;
  safety_score: number | null;
  timeliness_score: number | null;
  notes: string | null;
  issues: string | null;
  logged_by: string;
  created_at: string;
}

// ============================================================================
// 11. WORKFORCE CONTROL
// ============================================================================

export interface Worker {
  id: string;
  organization_id: string;
  subcontractor_id: string | null;
  profile_id: string | null;
  name: string;
  employee_id: string | null;
  role: string;
  skills: string[] | null;
  certifications: Certification[] | null;
  phone: string | null;
  email: string | null;
  emergency_contact: EmergencyContact | null;
  hourly_rate: number | null;
  status: WorkerStatus;
  hire_date: string | null;
  termination_date: string | null;
  notes: string | null;
  created_at: string;
  updated_at: string;
}

export interface Attendance {
  id: string;
  site_id: string;
  worker_id: string;
  date: string;
  check_in: string | null;
  check_out: string | null;
  hours_worked: number | null;
  overtime_hours: number;
  break_duration_minutes: number;
  status: string;
  notes: string | null;
  logged_by: string | null;
  created_at: string;
}

export interface ProductivityLog {
  id: string;
  site_id: string;
  worker_id: string;
  date: string;
  task_description: string | null;
  output_quantity: number | null;
  output_unit: string | null;
  area_covered: string | null;
  quality_rating: number | null;
  notes: string | null;
  logged_by: string;
  created_at: string;
}

// ============================================================================
// 12. EQUIPMENT CONTROL
// ============================================================================

export interface Equipment {
  id: string;
  organization_id: string;
  name: string;
  type: string;
  category: string | null;
  make: string | null;
  model: string | null;
  serial_number: string | null;
  purchase_date: string | null;
  purchase_cost: number | null;
  current_value: number | null;
  status: EquipmentStatus;
  condition: string | null;
  location: string | null;
  hourly_rate: number | null;
  fuel_type: string | null;
  specifications: Json | null;
  documents: string[] | null;
  created_at: string;
  updated_at: string;
}

export interface EquipmentAssignment {
  id: string;
  site_id: string;
  equipment_id: string;
  assigned_date: string;
  return_date: string | null;
  actual_return_date: string | null;
  status: AssignmentStatus;
  operator_id: string | null;
  purpose: string | null;
  notes: string | null;
  assigned_by: string | null;
  created_at: string;
  updated_at: string;
}

export interface EquipmentUsage {
  id: string;
  assignment_id: string;
  date: string;
  hours_used: number;
  fuel_consumed: number | null;
  meter_reading: number | null;
  condition: string | null;
  operator_id: string | null;
  task_performed: string | null;
  issues: string | null;
  notes: string | null;
  logged_by: string;
  created_at: string;
}

export interface MaintenanceLog {
  id: string;
  equipment_id: string;
  type: MaintenanceType;
  scheduled_date: string | null;
  completed_date: string | null;
  description: string;
  parts_used: Json | null;
  labor_hours: number | null;
  cost: number | null;
  performed_by: string | null;
  vendor: string | null;
  next_maintenance_date: string | null;
  notes: string | null;
  documents: string[] | null;
  created_by: string | null;
  created_at: string;
}

// ============================================================================
// 13. SITE ORGANIZATION CONTROL
// ============================================================================

export interface SiteCondition {
  id: string;
  site_id: string;
  date: string;
  cleanliness_score: number | null;
  organization_score: number | null;
  safety_score: number | null;
  access_score: number | null;
  overall_score: number | null;
  notes: string | null;
  issues: string | null;
  photos: string[] | null;
  checked_by: string;
  created_at: string;
}

export interface WasteLog {
  id: string;
  site_id: string;
  date: string;
  waste_type: WasteType;
  quantity: number;
  unit: string;
  disposal_method: string | null;
  disposal_vendor: string | null;
  disposal_cost: number | null;
  manifest_number: string | null;
  notes: string | null;
  logged_by: string;
  created_at: string;
}

// ============================================================================
// 14. OVERALL MANAGEMENT CONTROL
// ============================================================================

export interface ControlScore {
  id: string;
  site_id: string;
  date: string;
  dimension: ControlDimension;
  score: number;
  factors: Json | null;
  trend: string | null;
  recommendations: string | null;
  calculated_at: string;
  calculated_by: string;
}

export interface Alert {
  id: string;
  site_id: string;
  dimension: ControlDimension | null;
  severity: SeverityLevel;
  title: string;
  message: string;
  source_table: string | null;
  source_id: string | null;
  status: AlertStatus;
  action_required: string | null;
  action_taken: string | null;
  created_at: string;
  acknowledged_at: string | null;
  acknowledged_by: string | null;
  resolved_at: string | null;
  resolved_by: string | null;
}

// ============================================================================
// DATABASE SCHEMA TYPE (for Supabase client)
// ============================================================================

export interface Database {
  public: {
    Tables: {
      organizations: {
        Row: Organization;
        Insert: Omit<Organization, 'id' | 'created_at' | 'updated_at'> & {
          id?: string;
          created_at?: string;
          updated_at?: string;
        };
        Update: Partial<Omit<Organization, 'id'>>;
      };
      profiles: {
        Row: Profile;
        Insert: Omit<Profile, 'created_at' | 'updated_at'> & {
          created_at?: string;
          updated_at?: string;
        };
        Update: Partial<Omit<Profile, 'id'>>;
      };
      projects: {
        Row: Project;
        Insert: Omit<Project, 'id' | 'created_at' | 'updated_at'> & {
          id?: string;
          created_at?: string;
          updated_at?: string;
        };
        Update: Partial<Omit<Project, 'id'>>;
      };
      sites: {
        Row: Site;
        Insert: Omit<Site, 'id' | 'created_at' | 'updated_at'> & {
          id?: string;
          created_at?: string;
          updated_at?: string;
        };
        Update: Partial<Omit<Site, 'id'>>;
      };
      plans: {
        Row: Plan;
        Insert: Omit<Plan, 'id' | 'created_at' | 'updated_at'> & {
          id?: string;
          created_at?: string;
          updated_at?: string;
        };
        Update: Partial<Omit<Plan, 'id'>>;
      };
      plan_usage_logs: {
        Row: PlanUsageLog;
        Insert: Omit<PlanUsageLog, 'id' | 'accessed_at'> & {
          id?: string;
          accessed_at?: string;
        };
        Update: Partial<Omit<PlanUsageLog, 'id'>>;
      };
      change_requests: {
        Row: ChangeRequest;
        Insert: Omit<ChangeRequest, 'id' | 'created_at' | 'updated_at'> & {
          id?: string;
          created_at?: string;
          updated_at?: string;
        };
        Update: Partial<Omit<ChangeRequest, 'id'>>;
      };
      change_approvals: {
        Row: ChangeApproval;
        Insert: Omit<ChangeApproval, 'id' | 'decided_at'> & {
          id?: string;
          decided_at?: string;
        };
        Update: Partial<Omit<ChangeApproval, 'id'>>;
      };
      milestones: {
        Row: Milestone;
        Insert: Omit<Milestone, 'id' | 'created_at' | 'updated_at'> & {
          id?: string;
          created_at?: string;
          updated_at?: string;
        };
        Update: Partial<Omit<Milestone, 'id'>>;
      };
      progress_logs: {
        Row: ProgressLog;
        Insert: Omit<ProgressLog, 'id' | 'created_at'> & {
          id?: string;
          created_at?: string;
        };
        Update: Partial<Omit<ProgressLog, 'id'>>;
      };
      materials: {
        Row: Material;
        Insert: Omit<Material, 'id' | 'created_at' | 'updated_at'> & {
          id?: string;
          created_at?: string;
          updated_at?: string;
        };
        Update: Partial<Omit<Material, 'id'>>;
      };
      material_targets: {
        Row: MaterialTarget;
        Insert: Omit<MaterialTarget, 'id' | 'created_at' | 'updated_at'> & {
          id?: string;
          created_at?: string;
          updated_at?: string;
        };
        Update: Partial<Omit<MaterialTarget, 'id'>>;
      };
      material_usage: {
        Row: MaterialUsage;
        Insert: Omit<MaterialUsage, 'id' | 'created_at'> & {
          id?: string;
          created_at?: string;
        };
        Update: Partial<Omit<MaterialUsage, 'id'>>;
      };
      material_inventory: {
        Row: MaterialInventory;
        Insert: Omit<MaterialInventory, 'id' | 'created_at' | 'updated_at'> & {
          id?: string;
          created_at?: string;
          updated_at?: string;
        };
        Update: Partial<Omit<MaterialInventory, 'id'>>;
      };
      inventory_anomalies: {
        Row: InventoryAnomaly;
        Insert: Omit<InventoryAnomaly, 'id' | 'detected_at'> & {
          id?: string;
          detected_at?: string;
        };
        Update: Partial<Omit<InventoryAnomaly, 'id'>>;
      };
      inspections: {
        Row: Inspection;
        Insert: Omit<Inspection, 'id' | 'created_at' | 'updated_at'> & {
          id?: string;
          created_at?: string;
          updated_at?: string;
        };
        Update: Partial<Omit<Inspection, 'id'>>;
      };
      defects: {
        Row: Defect;
        Insert: Omit<Defect, 'id' | 'created_at' | 'updated_at'> & {
          id?: string;
          created_at?: string;
          updated_at?: string;
        };
        Update: Partial<Omit<Defect, 'id'>>;
      };
      safety_incidents: {
        Row: SafetyIncident;
        Insert: Omit<SafetyIncident, 'id' | 'reported_at'> & {
          id?: string;
          reported_at?: string;
        };
        Update: Partial<Omit<SafetyIncident, 'id'>>;
      };
      near_misses: {
        Row: NearMiss;
        Insert: Omit<NearMiss, 'id' | 'reported_at'> & {
          id?: string;
          reported_at?: string;
        };
        Update: Partial<Omit<NearMiss, 'id'>>;
      };
      risk_assessments: {
        Row: RiskAssessment;
        Insert: Omit<RiskAssessment, 'id' | 'assessed_at' | 'risk_score'> & {
          id?: string;
          assessed_at?: string;
        };
        Update: Partial<Omit<RiskAssessment, 'id' | 'risk_score'>>;
      };
      regulations: {
        Row: Regulation;
        Insert: Omit<Regulation, 'id' | 'created_at' | 'updated_at'> & {
          id?: string;
          created_at?: string;
          updated_at?: string;
        };
        Update: Partial<Omit<Regulation, 'id'>>;
      };
      permits: {
        Row: Permit;
        Insert: Omit<Permit, 'id' | 'created_at' | 'updated_at'> & {
          id?: string;
          created_at?: string;
          updated_at?: string;
        };
        Update: Partial<Omit<Permit, 'id'>>;
      };
      compliance_checks: {
        Row: ComplianceCheck;
        Insert: Omit<ComplianceCheck, 'id' | 'checked_at'> & {
          id?: string;
          checked_at?: string;
        };
        Update: Partial<Omit<ComplianceCheck, 'id'>>;
      };
      daily_logs: {
        Row: DailyLog;
        Insert: Omit<DailyLog, 'id' | 'created_at' | 'updated_at'> & {
          id?: string;
          created_at?: string;
          updated_at?: string;
        };
        Update: Partial<Omit<DailyLog, 'id'>>;
      };
      photos: {
        Row: Photo;
        Insert: Omit<Photo, 'id' | 'created_at'> & {
          id?: string;
          created_at?: string;
        };
        Update: Partial<Omit<Photo, 'id'>>;
      };
      documents: {
        Row: Document;
        Insert: Omit<Document, 'id' | 'uploaded_at'> & {
          id?: string;
          uploaded_at?: string;
        };
        Update: Partial<Omit<Document, 'id'>>;
      };
      subcontractors: {
        Row: Subcontractor;
        Insert: Omit<Subcontractor, 'id' | 'created_at' | 'updated_at'> & {
          id?: string;
          created_at?: string;
          updated_at?: string;
        };
        Update: Partial<Omit<Subcontractor, 'id'>>;
      };
      subcontractor_assignments: {
        Row: SubcontractorAssignment;
        Insert: Omit<SubcontractorAssignment, 'id' | 'created_at' | 'updated_at'> & {
          id?: string;
          created_at?: string;
          updated_at?: string;
        };
        Update: Partial<Omit<SubcontractorAssignment, 'id'>>;
      };
      subcontractor_performance: {
        Row: SubcontractorPerformance;
        Insert: Omit<SubcontractorPerformance, 'id' | 'created_at'> & {
          id?: string;
          created_at?: string;
        };
        Update: Partial<Omit<SubcontractorPerformance, 'id'>>;
      };
      workers: {
        Row: Worker;
        Insert: Omit<Worker, 'id' | 'created_at' | 'updated_at'> & {
          id?: string;
          created_at?: string;
          updated_at?: string;
        };
        Update: Partial<Omit<Worker, 'id'>>;
      };
      attendance: {
        Row: Attendance;
        Insert: Omit<Attendance, 'id' | 'created_at'> & {
          id?: string;
          created_at?: string;
        };
        Update: Partial<Omit<Attendance, 'id'>>;
      };
      productivity_logs: {
        Row: ProductivityLog;
        Insert: Omit<ProductivityLog, 'id' | 'created_at'> & {
          id?: string;
          created_at?: string;
        };
        Update: Partial<Omit<ProductivityLog, 'id'>>;
      };
      equipment: {
        Row: Equipment;
        Insert: Omit<Equipment, 'id' | 'created_at' | 'updated_at'> & {
          id?: string;
          created_at?: string;
          updated_at?: string;
        };
        Update: Partial<Omit<Equipment, 'id'>>;
      };
      equipment_assignments: {
        Row: EquipmentAssignment;
        Insert: Omit<EquipmentAssignment, 'id' | 'created_at' | 'updated_at'> & {
          id?: string;
          created_at?: string;
          updated_at?: string;
        };
        Update: Partial<Omit<EquipmentAssignment, 'id'>>;
      };
      equipment_usage: {
        Row: EquipmentUsage;
        Insert: Omit<EquipmentUsage, 'id' | 'created_at'> & {
          id?: string;
          created_at?: string;
        };
        Update: Partial<Omit<EquipmentUsage, 'id'>>;
      };
      maintenance_logs: {
        Row: MaintenanceLog;
        Insert: Omit<MaintenanceLog, 'id' | 'created_at'> & {
          id?: string;
          created_at?: string;
        };
        Update: Partial<Omit<MaintenanceLog, 'id'>>;
      };
      site_conditions: {
        Row: SiteCondition;
        Insert: Omit<SiteCondition, 'id' | 'created_at' | 'overall_score'> & {
          id?: string;
          created_at?: string;
        };
        Update: Partial<Omit<SiteCondition, 'id' | 'overall_score'>>;
      };
      waste_logs: {
        Row: WasteLog;
        Insert: Omit<WasteLog, 'id' | 'created_at'> & {
          id?: string;
          created_at?: string;
        };
        Update: Partial<Omit<WasteLog, 'id'>>;
      };
      control_scores: {
        Row: ControlScore;
        Insert: Omit<ControlScore, 'id' | 'calculated_at'> & {
          id?: string;
          calculated_at?: string;
        };
        Update: Partial<Omit<ControlScore, 'id'>>;
      };
      alerts: {
        Row: Alert;
        Insert: Omit<Alert, 'id' | 'created_at'> & {
          id?: string;
          created_at?: string;
        };
        Update: Partial<Omit<Alert, 'id'>>;
      };
    };
    Views: {
      [_ in never]: never;
    };
    Functions: {
      get_user_organization_id: {
        Args: Record<PropertyKey, never>;
        Returns: string;
      };
      user_belongs_to_org: {
        Args: { org_id: string };
        Returns: boolean;
      };
      user_has_role: {
        Args: { required_role: UserRole };
        Returns: boolean;
      };
      get_site_org_id: {
        Args: { site_id: string };
        Returns: string;
      };
      get_project_org_id: {
        Args: { project_id: string };
        Returns: string;
      };
    };
    Enums: {
      project_status: ProjectStatus;
      site_status: SiteStatus;
      user_role: UserRole;
      approval_status: ApprovalStatus;
      change_impact: ChangeImpact;
      severity_level: SeverityLevel;
      alert_status: AlertStatus;
      inspection_result: InspectionResult;
      defect_status: DefectStatus;
      incident_type: IncidentType;
      permit_status: PermitStatus;
      assignment_status: AssignmentStatus;
      equipment_status: EquipmentStatus;
      worker_status: WorkerStatus;
      maintenance_type: MaintenanceType;
      document_type: DocumentType;
      waste_type: WasteType;
      control_dimension: ControlDimension;
    };
  };
}

// ============================================================================
// UTILITY TYPES
// ============================================================================

/** Extract the row type for a table */
export type TableRow<T extends keyof Database['public']['Tables']> =
  Database['public']['Tables'][T]['Row'];

/** Extract the insert type for a table */
export type TableInsert<T extends keyof Database['public']['Tables']> =
  Database['public']['Tables'][T]['Insert'];

/** Extract the update type for a table */
export type TableUpdate<T extends keyof Database['public']['Tables']> =
  Database['public']['Tables'][T]['Update'];

/** All table names */
export type TableName = keyof Database['public']['Tables'];

/** All enum names */
export type EnumName = keyof Database['public']['Enums'];
