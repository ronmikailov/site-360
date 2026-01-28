-- Migration: 004_fix_rls_performance.sql
-- Description: Fix RLS policy performance issues and consolidate overlapping policies
--
-- Issues Fixed:
-- 1. Replace auth.uid() with (select auth.uid()) for better query planning
-- 2. Consolidate multiple permissive UPDATE policies on profiles and daily_logs
-- 3. Move PostGIS extension to dedicated schema (if possible)

-- ============================================================================
-- FIX 1: Create extensions schema and move PostGIS (optional - may require superuser)
-- ============================================================================

-- Create extensions schema if not exists
CREATE SCHEMA IF NOT EXISTS extensions;

-- Note: Moving PostGIS extension requires superuser privileges
-- If you have access, run: ALTER EXTENSION postgis SET SCHEMA extensions;
-- For now, we'll leave it in public as it's a WARN, not an ERROR

-- ============================================================================
-- FIX 2: Drop and recreate RLS policies with (select auth.uid()) for performance
-- ============================================================================

-- Helper function to get current user ID with caching
CREATE OR REPLACE FUNCTION public.current_user_id()
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT auth.uid()
$$;

-- ============================================================================
-- FIX: organizations policies
-- ============================================================================

DROP POLICY IF EXISTS organizations_insert_authenticated ON public.organizations;

CREATE POLICY organizations_insert_authenticated ON public.organizations
  FOR INSERT TO authenticated
  WITH CHECK (true);

-- ============================================================================
-- FIX: profiles policies - consolidate UPDATE policies
-- ============================================================================

-- Drop overlapping UPDATE policies
DROP POLICY IF EXISTS profiles_update_own ON public.profiles;
DROP POLICY IF EXISTS profiles_update_admin ON public.profiles;
DROP POLICY IF EXISTS profiles_select_org ON public.profiles;
DROP POLICY IF EXISTS profiles_insert_own ON public.profiles;

-- Recreate with (select auth.uid()) for performance
CREATE POLICY profiles_select_org ON public.profiles
  FOR SELECT TO authenticated
  USING (
    organization_id IS NULL
    OR user_belongs_to_org(organization_id)
  );

CREATE POLICY profiles_insert_own ON public.profiles
  FOR INSERT TO authenticated
  WITH CHECK (id = (SELECT auth.uid()));

-- Single consolidated UPDATE policy for profiles
CREATE POLICY profiles_update ON public.profiles
  FOR UPDATE TO authenticated
  USING (
    -- Can update own profile
    id = (SELECT auth.uid())
    -- Or admin can update profiles in their org
    OR (
      user_has_role('admin'::user_role)
      AND organization_id = get_user_organization_id()
    )
  )
  WITH CHECK (
    id = (SELECT auth.uid())
    OR (
      user_has_role('admin'::user_role)
      AND organization_id = get_user_organization_id()
    )
  );

-- ============================================================================
-- FIX: plan_usage_logs policies
-- ============================================================================

DROP POLICY IF EXISTS plan_usage_logs_insert_authenticated ON public.plan_usage_logs;

CREATE POLICY plan_usage_logs_insert_authenticated ON public.plan_usage_logs
  FOR INSERT TO authenticated
  WITH CHECK (user_id = (SELECT auth.uid()));

-- ============================================================================
-- FIX: daily_logs policies - consolidate UPDATE policies
-- ============================================================================

-- Drop overlapping UPDATE policies
DROP POLICY IF EXISTS daily_logs_update_worker ON public.daily_logs;
DROP POLICY IF EXISTS daily_logs_update_supervisor ON public.daily_logs;

-- Single consolidated UPDATE policy for daily_logs
CREATE POLICY daily_logs_update ON public.daily_logs
  FOR UPDATE TO authenticated
  USING (
    -- Workers can update their own logs from today
    (
      logged_by = (SELECT auth.uid())
      AND date = CURRENT_DATE
    )
    -- Supervisors+ can update any log in their org's sites
    OR (
      user_has_role('supervisor'::user_role)
      AND get_site_org_id(site_id) = get_user_organization_id()
    )
  )
  WITH CHECK (
    (
      logged_by = (SELECT auth.uid())
      AND date = CURRENT_DATE
    )
    OR (
      user_has_role('supervisor'::user_role)
      AND get_site_org_id(site_id) = get_user_organization_id()
    )
  );

-- ============================================================================
-- FIX 3: Update helper functions to use STABLE and proper caching
-- ============================================================================

-- Recreate get_user_organization_id with better caching
CREATE OR REPLACE FUNCTION public.get_user_organization_id()
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT organization_id
  FROM public.profiles
  WHERE id = (SELECT auth.uid())
  LIMIT 1
$$;

-- Recreate user_belongs_to_org with better caching
CREATE OR REPLACE FUNCTION public.user_belongs_to_org(org_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.profiles
    WHERE id = (SELECT auth.uid())
    AND organization_id = org_id
  )
$$;

-- Recreate user_has_role with better caching
CREATE OR REPLACE FUNCTION public.user_has_role(required_role user_role)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.profiles
    WHERE id = (SELECT auth.uid())
    AND role::text <= required_role::text  -- Role hierarchy comparison
  )
$$;

-- ============================================================================
-- Add comment explaining the spatial_ref_sys warning
-- ============================================================================

COMMENT ON SCHEMA public IS 'Standard public schema. Note: spatial_ref_sys table from PostGIS extension cannot have RLS enabled as it is owned by the postgres superuser. This is expected and not a security concern as it only contains coordinate system reference data.';

-- ============================================================================
-- Grant execute on helper functions
-- ============================================================================

GRANT EXECUTE ON FUNCTION public.current_user_id() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_organization_id() TO authenticated;
GRANT EXECUTE ON FUNCTION public.user_belongs_to_org(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.user_has_role(user_role) TO authenticated;
