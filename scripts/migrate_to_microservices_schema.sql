-- Migration Script: Django Monolith to Microservices Architecture
-- Migrates data from federated_imputation (Django) to separate microservices databases
-- Date: October 7, 2025
--
-- IMPORTANT: Run this inside the PostgreSQL container
-- Usage: psql -U postgres -f migrate_to_microservices_schema.sql

\echo '==================================='
\echo 'Microservices Database Migration'
\echo 'From: federated_imputation (Django)'
\echo 'To: service_registry_db, user_management_db, job_processing_db'
\echo '==================================='
\echo ''

-- ============================================================================
-- PART 1: MIGRATE SERVICES TO service_registry_db
-- ============================================================================

\echo '📦 Step 1: Migrating Imputation Services...'
\c service_registry_db

INSERT INTO imputation_services (
    name,
    slug,
    service_type,
    api_type,
    base_url,
    description,
    version,
    requires_auth,
    auth_type,
    max_file_size_mb,
    supported_formats,
    supported_builds,
    api_config,
    is_active,
    is_available,
    created_at,
    updated_at
)
SELECT
    name,
    LOWER(REPLACE(name, ' ', '-')) as slug,
    service_type,
    CASE
        WHEN service_type = 'h3africa' THEN 'michigan'
        WHEN service_type = 'michigan' THEN 'michigan'
        WHEN service_type = 'dnastack' THEN 'dnastack'
        ELSE 'michigan'
    END as api_type,
    api_url as base_url,
    description,
    NULL as version,
    api_key_required as requires_auth,
    CASE WHEN api_key_required THEN 'token' ELSE NULL END as auth_type,
    500 as max_file_size_mb,
    '["vcf", "vcf.gz", "23andme"]'::json as supported_formats,
    '["hg19", "hg38", "hg37"]'::json as supported_builds,
    '{}'::json as api_config,
    is_active,
    is_active as is_available,
    created_at,
    updated_at
FROM federated_imputation.imputation_imputationservice
ON CONFLICT DO NOTHING;

\echo '✓ Services migrated'

-- ============================================================================
-- PART 2: MIGRATE REFERENCE PANELS TO service_registry_db
-- ============================================================================

\echo '📦 Step 2: Migrating Reference Panels...'

INSERT INTO reference_panels (
    name,
    build,
    population,
    description,
    sample_count,
    variant_count,
    service_id,
    is_public,
    created_at,
    updated_at
)
SELECT
    rp.name,
    COALESCE(rp.build, 'hg19') as build,
    COALESCE(rp.population, 'MIXED') as population,
    COALESCE(rp.description, '') as description,
    rp.sample_count,
    rp.variant_count,
    rp.service_id,
    COALESCE(rp.is_public, true) as is_public,
    COALESCE(rp.created_at, NOW()) as created_at,
    COALESCE(rp.updated_at, NOW()) as updated_at
FROM federated_imputation.imputation_referencepanel rp
ON CONFLICT DO NOTHING;

\echo '✓ Reference panels migrated'

-- ============================================================================
-- PART 3: MIGRATE USERS TO user_management_db
-- ============================================================================

\echo '📦 Step 3: Migrating Users...'
\c user_management_db

INSERT INTO users (
    username,
    email,
    password_hash,
    first_name,
    last_name,
    is_active,
    is_staff,
    is_superuser,
    date_joined,
    last_login
)
SELECT
    username,
    email,
    password as password_hash,
    first_name,
    last_name,
    is_active,
    is_staff,
    is_superuser,
    date_joined,
    last_login
FROM federated_imputation.auth_user
ON CONFLICT (username) DO NOTHING;

\echo '✓ Users migrated'

-- ============================================================================
-- PART 4: MIGRATE JOBS TO job_processing_db
-- ============================================================================

\echo '📦 Step 4: Migrating Imputation Jobs...'
\c job_processing_db

-- First, ensure the job_processing_db tables exist
-- (They should be created by the job-processor service)

INSERT INTO imputation_jobs (
    id,
    name,
    user_id,
    service_id,
    reference_panel_id,
    input_format,
    build,
    phasing,
    population,
    mode,
    status,
    progress,
    external_job_id,
    submission_data,
    created_at,
    updated_at,
    started_at,
    completed_at,
    error_message
)
SELECT
    id,
    COALESCE(name, 'Imported Job') as name,
    user_id,
    service_id,
    reference_panel_id,
    COALESCE(input_format, 'vcf') as input_format,
    COALESCE(build, 'hg19') as build,
    COALESCE(phasing, false) as phasing,
    COALESCE(population, 'mixed') as population,
    COALESCE(mode, 'imputation') as mode,
    status,
    COALESCE(progress, 0) as progress,
    external_job_id,
    '{}'::jsonb as submission_data,
    created_at,
    updated_at,
    started_at,
    completed_at,
    error_message
FROM federated_imputation.imputation_imputationjob
ON CONFLICT (id) DO UPDATE SET
    status = EXCLUDED.status,
    progress = EXCLUDED.progress,
    updated_at = EXCLUDED.updated_at;

\echo '✓ Jobs migrated'

-- ============================================================================
-- PART 5: MIGRATE JOB STATUS UPDATES
-- ============================================================================

\echo '📦 Step 5: Migrating Job Status Updates...'

INSERT INTO job_status_updates (
    job_id,
    status,
    progress,
    message,
    created_at
)
SELECT
    job_id,
    status,
    COALESCE(progress, 0) as progress,
    COALESCE(message, '') as message,
    timestamp as created_at
FROM federated_imputation.imputation_jobstatusupdate
ON CONFLICT DO NOTHING;

\echo '✓ Job status updates migrated'

-- ============================================================================
-- VERIFICATION
-- ============================================================================

\echo ''
\echo '==================================='
\echo 'Migration Verification'
\echo '==================================='
\echo ''

\echo 'Services in service_registry_db:'
\c service_registry_db
SELECT COUNT(*) as total_services FROM imputation_services;
SELECT id, name, service_type FROM imputation_services ORDER BY id;

\echo ''
\echo 'Reference Panels in service_registry_db:'
SELECT COUNT(*) as total_panels FROM reference_panels;

\echo ''
\echo 'Users in user_management_db:'
\c user_management_db
SELECT COUNT(*) as total_users FROM users;
SELECT id, username, email FROM users ORDER BY id LIMIT 10;

\echo ''
\echo 'Jobs in job_processing_db:'
\c job_processing_db
SELECT COUNT(*) as total_jobs FROM imputation_jobs;
SELECT id, name, status FROM imputation_jobs ORDER BY created_at DESC LIMIT 5;

\echo ''
\echo '==================================='
\echo '✅ Migration Complete!'
\echo '==================================='
\echo ''
\echo 'Next steps:'
\echo '1. Verify data in each database'
\echo '2. Test API endpoints'
\echo '3. Update application configuration to use new databases'
\echo '4. Backup the old federated_imputation database (keep for reference)'
\echo ''
