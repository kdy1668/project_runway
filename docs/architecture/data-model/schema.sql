-- RunWay v5 initial schema: CREATE TABLE with inline PK/FK/UNIQUE/CHECK.
-- PostgreSQL 15+ and PostGIS 3+. Intended for an EMPTY DATABASE.
-- Schema relationships match v5, except cyclic courses.source_session_id reference
-- is enforced by triggers (FK-equivalent insert/update validation and ON DELETE SET NULL).
-- This avoids ALTER TABLE entirely while retaining both directions of the relationship.
-- NOTE: For production, test on PostgreSQL + PostGIS and validate SDK data types.

BEGIN;
CREATE EXTENSION IF NOT EXISTS postgis;

CREATE TABLE users (
id UUID NOT NULL DEFAULT gen_random_uuid(),
    nickname VARCHAR(50) NOT NULL,
    gender VARCHAR(20),
    age_group VARCHAR(20),
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at TIMESTAMPTZ,
    PRIMARY KEY (id),
    CHECK (status IN ('ACTIVE','SUSPENDED','DELETED'))
);

CREATE TABLE auth_identities (
id UUID NOT NULL DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    issuer VARCHAR(80) NOT NULL,
    subject VARCHAR(255) NOT NULL,
    linked_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    unlinked_at TIMESTAMPTZ,
    PRIMARY KEY (id),
    UNIQUE (issuer, subject),
    CONSTRAINT fk_auth_identities_user_id FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE RESTRICT
);

CREATE TABLE user_running_profiles (
user_id UUID NOT NULL,
    self_reported_level VARCHAR(20) NOT NULL,
    assessed_level VARCHAR(20),
    assessed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id),
    CHECK (self_reported_level IN ('BEGINNER','INTERMEDIATE','ADVANCED')),
    CHECK (assessed_level IS NULL OR assessed_level IN ('BEGINNER','INTERMEDIATE','ADVANCED')),
    CONSTRAINT fk_user_running_profiles_user_id FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE RESTRICT
);

CREATE TABLE user_privacy_settings (
user_id UUID NOT NULL,
    profile_visibility VARCHAR(20) NOT NULL DEFAULT 'PRIVATE',
    default_session_visibility VARCHAR(20) NOT NULL DEFAULT 'PRIVATE',
    default_location_visibility VARCHAR(20) NOT NULL DEFAULT 'PRIVATE',
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id),
    CHECK (profile_visibility IN ('PUBLIC','PRIVATE')),
    CHECK (default_session_visibility IN ('PUBLIC','PRIVATE')),
    CHECK (default_location_visibility IN ('PUBLIC','PRIVATE')),
    CONSTRAINT fk_user_privacy_settings_user_id FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE RESTRICT
);

CREATE TABLE user_running_baselines (
user_id UUID NOT NULL,
    usual_pace_sec_per_km NUMERIC(10,2) NOT NULL,
    baseline_distance_m INTEGER,
    baseline_duration_sec INTEGER,
    input_type VARCHAR(20) NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id),
    CHECK (usual_pace_sec_per_km > 0),
    CHECK (baseline_distance_m IS NULL OR baseline_distance_m > 0),
    CHECK (baseline_duration_sec IS NULL OR baseline_duration_sec > 0),
    CHECK (input_type IN ('PACE','DISTANCE_TIME')),
    CONSTRAINT chk_user_running_baselines_input
        CHECK (
            (input_type = 'PACE' AND baseline_distance_m IS NULL AND baseline_duration_sec IS NULL)
            OR
            (input_type = 'DISTANCE_TIME' AND baseline_distance_m IS NOT NULL AND baseline_duration_sec IS NOT NULL)
        ),
    CONSTRAINT fk_user_running_baselines_user_id FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE RESTRICT
);

CREATE TABLE environment_types (
id UUID NOT NULL DEFAULT gen_random_uuid(),
    name VARCHAR(40) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    PRIMARY KEY (id),
    UNIQUE (name)
);

CREATE TABLE user_environment_preferences (
user_id UUID NOT NULL,
    environment_id UUID NOT NULL,
    PRIMARY KEY (user_id, environment_id),
    CONSTRAINT fk_user_environment_preferences_user_id FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE RESTRICT,
    CONSTRAINT fk_user_environment_preferences_environment_id FOREIGN KEY (environment_id) REFERENCES environment_types(id) ON DELETE RESTRICT
);

CREATE TABLE wearable_devices (
id UUID NOT NULL DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    installation_id UUID NOT NULL,
    device_type VARCHAR(20) NOT NULL,
    manufacturer TEXT,
    model TEXT,
    os_version TEXT,
    app_version TEXT,
    capabilities JSONB,
    capabilities_checked_at TIMESTAMPTZ,
    last_seen_at TIMESTAMPTZ,
    unlinked_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (id),
    UNIQUE (user_id, installation_id),
    CHECK (device_type IN ('WATCH','PHONE')),
    CONSTRAINT fk_wearable_devices_user_id FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE RESTRICT
);

CREATE TABLE user_consent_events (
id UUID NOT NULL DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    consent_type VARCHAR(30) NOT NULL,
    policy_version TEXT NOT NULL,
    action VARCHAR(10) NOT NULL,
    recorded_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (id),
    CHECK (action IN ('GRANT','REVOKE')),
    CHECK (consent_type IN ('HEALTH_DATA','LOCATION_DATA')),
    CONSTRAINT fk_user_consent_events_user_id FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE RESTRICT
);

CREATE TABLE sync_stream_progress (
device_id UUID NOT NULL,
    stream_key VARCHAR(100) NOT NULL,
    last_contiguous_sequence BIGINT NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (device_id, stream_key),
    CHECK (last_contiguous_sequence >= 0),
    CONSTRAINT fk_sync_stream_progress_device_id FOREIGN KEY (device_id) REFERENCES wearable_devices(id) ON DELETE CASCADE
);

CREATE TABLE external_health_records (
id UUID NOT NULL DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    provider VARCHAR(40) NOT NULL,
    record_type VARCHAR(40) NOT NULL,
    source_id TEXT NOT NULL,
    source_updated_at TIMESTAMPTZ,
    source_device_identifier TEXT,
    imported_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at TIMESTAMPTZ,
    source_metadata JSONB,
    PRIMARY KEY (id),
    UNIQUE (user_id, provider, record_type, source_id),
    CONSTRAINT fk_external_health_records_user_id FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE RESTRICT
);

CREATE TABLE sleep_records (
id UUID NOT NULL DEFAULT gen_random_uuid(),
    external_record_id UUID NOT NULL,
    started_at TIMESTAMPTZ NOT NULL,
    ended_at TIMESTAMPTZ NOT NULL,
    total_sleep_duration_sec INTEGER,
    sleep_score NUMERIC(5,2),
    PRIMARY KEY (id),
    UNIQUE (external_record_id),
    CHECK (ended_at > started_at),
    CHECK (total_sleep_duration_sec IS NULL OR total_sleep_duration_sec >= 0),
    CONSTRAINT fk_sleep_records_external_record_id FOREIGN KEY (external_record_id) REFERENCES external_health_records(id) ON DELETE RESTRICT
);

CREATE TABLE sleep_sessions (
id UUID NOT NULL DEFAULT gen_random_uuid(),
    sleep_record_id UUID NOT NULL,
    session_index INTEGER NOT NULL,
    started_at TIMESTAMPTZ NOT NULL,
    ended_at TIMESTAMPTZ NOT NULL,
    sleep_duration_sec INTEGER NOT NULL,
    PRIMARY KEY (id),
    UNIQUE (sleep_record_id, session_index),
    CHECK (ended_at > started_at),
    CHECK (sleep_duration_sec >= 0),
    CONSTRAINT fk_sleep_sessions_sleep_record_id FOREIGN KEY (sleep_record_id) REFERENCES sleep_records(id) ON DELETE CASCADE
);

CREATE TABLE sleep_stages (
id UUID NOT NULL DEFAULT gen_random_uuid(),
    sleep_session_id UUID NOT NULL,
    stage_index INTEGER NOT NULL,
    started_at TIMESTAMPTZ NOT NULL,
    ended_at TIMESTAMPTZ NOT NULL,
    stage_type VARCHAR(30) NOT NULL,
    PRIMARY KEY (id),
    UNIQUE (sleep_session_id, stage_index),
    CHECK (ended_at > started_at),
    CONSTRAINT fk_sleep_stages_sleep_session_id FOREIGN KEY (sleep_session_id) REFERENCES sleep_sessions(id) ON DELETE CASCADE
);

CREATE TABLE daily_heart_rate_samples (
external_record_id UUID NOT NULL,
    source_index BIGINT NOT NULL,
    started_at TIMESTAMPTZ NOT NULL,
    ended_at TIMESTAMPTZ NOT NULL,
    heart_rate_bpm NUMERIC(6,2) NOT NULL,
    min_bpm NUMERIC(6,2),
    max_bpm NUMERIC(6,2),
    PRIMARY KEY (external_record_id, source_index),
    CHECK (heart_rate_bpm > 0),
    CHECK (ended_at >= started_at),
    CONSTRAINT fk_daily_heart_rate_samples_external_record_id FOREIGN KEY (external_record_id) REFERENCES external_health_records(id) ON DELETE RESTRICT
);

CREATE TABLE daily_activity_summaries (
user_id UUID NOT NULL,
    local_date DATE NOT NULL,
    time_zone TEXT NOT NULL,
    source_policy VARCHAR(40) NOT NULL,
    steps BIGINT,
    active_duration_sec INTEGER,
    distance_m NUMERIC(12,2),
    active_calories_kcal NUMERIC(10,2),
    total_calories_kcal NUMERIC(10,2),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, local_date, time_zone, source_policy),
    CHECK (steps IS NULL OR steps >= 0),
    CONSTRAINT fk_daily_activity_summaries_user_id FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE RESTRICT
);

CREATE TABLE daily_health_snapshots (
id UUID NOT NULL DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    measured_at TIMESTAMPTZ NOT NULL,
    sleep_duration_min INTEGER,
    daily_steps INTEGER,
    activity_duration_min INTEGER,
    resting_heart_rate SMALLINT,
    source_data JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (id),
    CONSTRAINT fk_daily_health_snapshots_user_id FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE RESTRICT
);

CREATE TABLE courses (
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    creator_id UUID,
    source_session_id UUID,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    route geography(LineString,4326) NOT NULL,
    start_position geography(Point,4326) NOT NULL,
    distance_m NUMERIC(12,2) NOT NULL,
    elevation_gain_m NUMERIC(9,2),
    elevation_profile JSONB,
    source_type VARCHAR(20) NOT NULL DEFAULT 'USER_RUN',

    -- 공용 코스 상태
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',

    -- 중복 코스 병합 시 대표 코스 ID
    merged_into_course_id UUID,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    PRIMARY KEY (id),

    CHECK (distance_m > 0),
    CHECK (source_type IN ('USER_RUN', 'GENERATED')),

    CONSTRAINT chk_courses_status
        CHECK (status IN ('ACTIVE', 'MERGED', 'BLOCKED')),

    CONSTRAINT chk_courses_merge
        CHECK (
            (status = 'MERGED' AND merged_into_course_id IS NOT NULL)
            OR
            (status <> 'MERGED' AND merged_into_course_id IS NULL)
        ),

    CONSTRAINT chk_courses_no_self_merge
        CHECK (
            merged_into_course_id IS NULL
            OR merged_into_course_id <> id
        ),

    CONSTRAINT fk_courses_creator_id
        FOREIGN KEY (creator_id)
        REFERENCES users(id)
        ON DELETE SET NULL,

    CONSTRAINT fk_courses_merged_into
        FOREIGN KEY (merged_into_course_id)
        REFERENCES courses(id)
        ON DELETE RESTRICT
);

CREATE TABLE running_sessions (
id UUID NOT NULL DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    course_id UUID,
    status VARCHAR(20) NOT NULL DEFAULT 'READY',
    target_distance_m INTEGER NOT NULL,
    target_duration_sec INTEGER NOT NULL,
    started_at TIMESTAMPTZ,
    ended_at TIMESTAMPTZ,
    moving_duration_sec INTEGER,
    elapsed_duration_sec INTEGER,
    total_distance_m NUMERIC(12,2),
    average_pace_sec_per_km NUMERIC(10,2),
    average_heart_rate NUMERIC(6,2),
    average_cadence NUMERIC(6,2),
    goal_achieved BOOLEAN,
    visibility VARCHAR(20) NOT NULL DEFAULT 'PRIVATE',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at TIMESTAMPTZ,
    PRIMARY KEY (id),
    UNIQUE (id, user_id),
    CHECK (status IN ('READY','RUNNING','PAUSED','COMPLETED','CANCELLED')),
    CHECK (target_distance_m > 0),
    CHECK (target_duration_sec > 0),
    CHECK (visibility IN ('PRIVATE','PUBLIC')),
    CONSTRAINT fk_running_sessions_user_id FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE RESTRICT,
    CONSTRAINT fk_running_sessions_course_id FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE SET NULL
);

CREATE TABLE sync_batches (
id UUID NOT NULL,
    user_id UUID NOT NULL,
    device_id UUID NOT NULL,
    session_id UUID,
    schema_version VARCHAR(40) NOT NULL,
    payload_hash TEXT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'RECEIVED',
    accepted_count INTEGER NOT NULL DEFAULT 0,
    received_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    committed_at TIMESTAMPTZ,
    PRIMARY KEY (id),
    CHECK (status IN ('RECEIVED','COMMITTED','REJECTED')),
    CHECK (accepted_count >= 0),
    CONSTRAINT fk_sync_batches_user_id FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE RESTRICT,
    CONSTRAINT fk_sync_batches_device_id FOREIGN KEY (device_id) REFERENCES wearable_devices(id) ON DELETE RESTRICT,
    CONSTRAINT fk_sync_batches_session_id FOREIGN KEY (session_id) REFERENCES running_sessions(id) ON DELETE SET NULL
);

CREATE TABLE readiness_assessments (
id UUID NOT NULL DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    health_snapshot_id UUID,
    session_id UUID,
    subjective_condition VARCHAR(30),
    readiness_score NUMERIC(5,2),
    readiness_level VARCHAR(30),
    feature_snapshot JSONB NOT NULL DEFAULT '{}'::jsonb,
    reason_details JSONB,
    assessed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (id),
    CHECK (readiness_score IS NULL OR readiness_score BETWEEN 0 AND 100),
    CONSTRAINT fk_readiness_assessments_user_id FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE RESTRICT,
    CONSTRAINT fk_readiness_assessments_health_snapshot_id FOREIGN KEY (health_snapshot_id) REFERENCES daily_health_snapshots(id) ON DELETE SET NULL,
    CONSTRAINT fk_readiness_assessments_session_id FOREIGN KEY (session_id) REFERENCES running_sessions(id) ON DELETE SET NULL
);

CREATE TABLE running_metric_samples (
id UUID NOT NULL,
    session_id UUID NOT NULL,
    device_id UUID,
    metric_type VARCHAR(40) NOT NULL,
    measured_at TIMESTAMPTZ NOT NULL,
    received_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    sequence_no BIGINT,
    value NUMERIC(14,4),
    unit VARCHAR(30) NOT NULL,
    quality_status VARCHAR(20) NOT NULL DEFAULT 'VALID',
    source_metadata JSONB,
    PRIMARY KEY (id),
    CHECK (quality_status IN ('VALID','MISSING','STALE','INVALID')),
    CONSTRAINT fk_running_metric_samples_session_id FOREIGN KEY (session_id) REFERENCES running_sessions(id) ON DELETE CASCADE,
    CONSTRAINT fk_running_metric_samples_device_id FOREIGN KEY (device_id) REFERENCES wearable_devices(id) ON DELETE SET NULL
);

CREATE TABLE running_route_points (
id UUID NOT NULL,
    session_id UUID NOT NULL,
    device_id UUID,
    measured_at TIMESTAMPTZ NOT NULL,
    received_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    sequence_no BIGINT,
    position geography(Point,4326) NOT NULL,
    altitude_m NUMERIC(9,2),
    horizontal_accuracy_m NUMERIC(9,2),
    quality_status VARCHAR(20) NOT NULL DEFAULT 'VALID',
    source_metadata JSONB,
    PRIMARY KEY (id),
    CHECK (quality_status IN ('VALID','MISSING','STALE','INVALID')),
    CONSTRAINT fk_running_route_points_session_id FOREIGN KEY (session_id) REFERENCES running_sessions(id) ON DELETE CASCADE,
    CONSTRAINT fk_running_route_points_device_id FOREIGN KEY (device_id) REFERENCES wearable_devices(id) ON DELETE SET NULL
);

CREATE TABLE running_events (
id UUID NOT NULL DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL,
    event_type VARCHAR(20) NOT NULL,
    occurred_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (id),
    CHECK (event_type IN ('START','PAUSE','RESUME','END')),
    CONSTRAINT fk_running_events_session_id FOREIGN KEY (session_id) REFERENCES running_sessions(id) ON DELETE CASCADE
);

CREATE TABLE running_splits (
session_id UUID NOT NULL,
    split_index INTEGER NOT NULL,
    start_distance_m NUMERIC(12,2) NOT NULL,
    end_distance_m NUMERIC(12,2) NOT NULL,
    active_duration_sec INTEGER NOT NULL,
    average_pace_sec_per_km NUMERIC(10,2),
    average_heart_rate NUMERIC(6,2),
    average_cadence NUMERIC(6,2),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (session_id, split_index),
    CHECK (end_distance_m > start_distance_m),
    CHECK (active_duration_sec >= 0),
    CONSTRAINT fk_running_splits_session_id FOREIGN KEY (session_id) REFERENCES running_sessions(id) ON DELETE CASCADE
);

CREATE TABLE course_environment_tags (
course_id UUID NOT NULL,
    environment_id UUID NOT NULL,
    PRIMARY KEY (course_id, environment_id),
    CONSTRAINT fk_course_environment_tags_course_id FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE CASCADE,
    CONSTRAINT fk_course_environment_tags_environment_id FOREIGN KEY (environment_id) REFERENCES environment_types(id) ON DELETE CASCADE
);

CREATE TABLE course_bookmarks (
user_id UUID NOT NULL,
    course_id UUID NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, course_id),
    CONSTRAINT fk_course_bookmarks_user_id FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_course_bookmarks_course_id FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE CASCADE
);

CREATE TABLE runner_parameters (
id UUID NOT NULL DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    source_session_id UUID,
    parameter_data JSONB NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    applied_at TIMESTAMPTZ,
    PRIMARY KEY (id),
    CONSTRAINT fk_runner_parameters_user_id FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE RESTRICT,
    CONSTRAINT fk_runner_parameters_source_session_id FOREIGN KEY (source_session_id) REFERENCES running_sessions(id) ON DELETE SET NULL
);

CREATE TABLE bpm_profiles (
user_id UUID NOT NULL,
    runner_parameter_id UUID,
    initial_bpm SMALLINT,
    step_length_m NUMERIC(6,3),
    preferred_cadence_spm NUMERIC(7,2),
    calibration_state VARCHAR(20) NOT NULL DEFAULT 'INITIAL',
    confidence NUMERIC(4,3),
    calibrated_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id),
    CHECK (calibration_state IN ('INITIAL','CALIBRATING','CALIBRATED')),
    CHECK (confidence IS NULL OR confidence BETWEEN 0 AND 1),
    CONSTRAINT fk_bpm_profiles_user_id FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE RESTRICT,
    CONSTRAINT fk_bpm_profiles_runner_parameter_id FOREIGN KEY (runner_parameter_id) REFERENCES runner_parameters(id) ON DELETE SET NULL
);

CREATE TABLE pace_plans (
id UUID NOT NULL DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL,
    revision INTEGER NOT NULL,
    plan_kind VARCHAR(20) NOT NULL,
    initial_pace_sec_per_km NUMERIC(10,2) NOT NULL,
    strategy_context JSONB,
    initial_target_bpm SMALLINT,
    estimated_duration_sec INTEGER,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    effective_at TIMESTAMPTZ NOT NULL,
    PRIMARY KEY (id),
    UNIQUE (session_id, revision),
    CHECK (revision >= 1),
    CHECK (plan_kind IN ('INITIAL','ADJUSTED')),
    CHECK (initial_pace_sec_per_km > 0),
    CONSTRAINT fk_pace_plans_session_id FOREIGN KEY (session_id) REFERENCES running_sessions(id) ON DELETE CASCADE
);

CREATE TABLE pace_plan_segments (
plan_id UUID NOT NULL,
    segment_index INTEGER NOT NULL,
    start_distance_m NUMERIC(12,2) NOT NULL,
    end_distance_m NUMERIC(12,2) NOT NULL,
    target_pace_sec_per_km NUMERIC(10,2) NOT NULL,
    target_bpm SMALLINT,
    PRIMARY KEY (plan_id, segment_index),
    CHECK (end_distance_m > start_distance_m),
    CHECK (target_pace_sec_per_km > 0),
    CONSTRAINT fk_pace_plan_segments_plan_id FOREIGN KEY (plan_id) REFERENCES pace_plans(id) ON DELETE CASCADE
);

CREATE TABLE pace_predictions (
id UUID NOT NULL DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL,
    runner_parameter_id UUID,
    predicted_at TIMESTAMPTZ NOT NULL,
    distance_at_prediction_m NUMERIC(12,2) NOT NULL,
    predicted_finish_duration_sec INTEGER,
    predicted_pace_sec_per_km NUMERIC(10,2),
    load_level VARCHAR(30),
    overpace_detected BOOLEAN,
    pace_drop_detected BOOLEAN,
    prediction_details JSONB,
    PRIMARY KEY (id),
    CONSTRAINT fk_pace_predictions_session_id FOREIGN KEY (session_id) REFERENCES running_sessions(id) ON DELETE CASCADE,
    CONSTRAINT fk_pace_predictions_runner_parameter_id FOREIGN KEY (runner_parameter_id) REFERENCES runner_parameters(id) ON DELETE SET NULL
);

CREATE TABLE crews (
id UUID NOT NULL DEFAULT gen_random_uuid(),
    owner_id UUID NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    join_policy VARCHAR(20) NOT NULL DEFAULT 'APPROVAL',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at TIMESTAMPTZ,
    PRIMARY KEY (id),
    CHECK (join_policy IN ('OPEN','APPROVAL')),
    CONSTRAINT fk_crews_owner_id FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE RESTRICT
);

CREATE TABLE crew_memberships (
crew_id UUID NOT NULL,
    user_id UUID NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    role VARCHAR(20) NOT NULL DEFAULT 'MEMBER',
    requested_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    resolved_at TIMESTAMPTZ,
    left_at TIMESTAMPTZ,
    PRIMARY KEY (crew_id, user_id),
    CHECK (status IN ('PENDING','APPROVED','REJECTED','LEFT')),
    CHECK (role IN ('OWNER','ADMIN','MEMBER')),
    CONSTRAINT fk_crew_memberships_crew_id FOREIGN KEY (crew_id) REFERENCES crews(id) ON DELETE CASCADE,
    CONSTRAINT fk_crew_memberships_user_id FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE group_runs (
id UUID NOT NULL DEFAULT gen_random_uuid(),
    crew_id UUID,
    course_id UUID NULL,
    host_id UUID NOT NULL,
    title VARCHAR(100) NOT NULL,
    description TEXT,
    scheduled_at TIMESTAMPTZ,
    meeting_position geography(Point,4326),
    capacity INTEGER,
    status VARCHAR(20) NOT NULL DEFAULT 'RECRUITING',
    target_distance_m INTEGER NOT NULL,
    target_duration_sec INTEGER NOT NULL,
    goal_input_type VARCHAR(10) NOT NULL,
    started_at TIMESTAMPTZ,
    ended_at TIMESTAMPTZ,
    goal_achieved BOOLEAN,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (id),
    CHECK (target_distance_m > 0),
    CHECK (target_duration_sec > 0),
    CHECK (capacity IS NULL OR capacity > 0),
    CHECK (goal_input_type IN ('TIME','PACE')),
    CHECK (status IN ('RECRUITING','READY','RUNNING','COMPLETED','CANCELLED')),
    CONSTRAINT fk_group_runs_crew_id FOREIGN KEY (crew_id) REFERENCES crews(id) ON DELETE SET NULL,
    CONSTRAINT fk_group_runs_host_id FOREIGN KEY (host_id) REFERENCES users(id) ON DELETE RESTRICT,
    CONSTRAINT fk_group_runs_course FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE SET NULL
);

CREATE TABLE group_run_participants (
group_run_id UUID NOT NULL,
    user_id UUID NOT NULL,
    session_id UUID,
    status VARCHAR(20) NOT NULL DEFAULT 'JOINED',
    role VARCHAR(20) NOT NULL DEFAULT 'MEMBER',
    location_sharing_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    joined_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    cancelled_at TIMESTAMPTZ,
    PRIMARY KEY (group_run_id, user_id),
    CHECK (status IN ('JOINED','CANCELLED','RUNNING','COMPLETED')),
    CHECK (role IN ('HOST','MEMBER')),
    CONSTRAINT fk_group_run_participants_group_run_id FOREIGN KEY (group_run_id) REFERENCES group_runs(id) ON DELETE CASCADE,
    CONSTRAINT fk_group_run_participants_user_id FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_group_run_participants_session_id_user_id FOREIGN KEY (session_id, user_id) REFERENCES running_sessions(id, user_id) ON DELETE SET NULL (session_id)
);

CREATE TABLE group_pace_events (
id UUID NOT NULL DEFAULT gen_random_uuid(),
    group_run_id UUID NOT NULL,
    revision INTEGER NOT NULL,
    target_pace_sec_per_km NUMERIC(10,2) NOT NULL,
    participant_snapshot JSONB,
    reason_codes JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (id),
    UNIQUE (group_run_id, revision),
    CHECK (revision >= 1),
    CHECK (target_pace_sec_per_km > 0),
    CONSTRAINT fk_group_pace_events_group_run_id FOREIGN KEY (group_run_id) REFERENCES group_runs(id) ON DELETE RESTRICT
);

CREATE TABLE notifications (
id UUID NOT NULL DEFAULT gen_random_uuid(),
    recipient_user_id UUID NOT NULL,
    group_run_id UUID NOT NULL,
    group_pace_event_id UUID,
    notification_type VARCHAR(40) NOT NULL,
    payload JSONB NOT NULL DEFAULT '{}'::jsonb,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    sent_at TIMESTAMPTZ,
    read_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ,
    PRIMARY KEY (id),
    CHECK (status IN ('PENDING','SENT','FAILED','EXPIRED','READ')),
    CHECK (notification_type IN ('GROUP_PACE_CHANGED','GROUP_GAP','GROUP_STATUS')),
    CONSTRAINT fk_notifications_recipient_user_id FOREIGN KEY (recipient_user_id) REFERENCES users(id) ON DELETE RESTRICT,
    CONSTRAINT fk_notifications_group_run_id FOREIGN KEY (group_run_id) REFERENCES group_runs(id) ON DELETE RESTRICT,
    CONSTRAINT fk_notifications_group_pace_event_id FOREIGN KEY (group_pace_event_id) REFERENCES group_pace_events(id) ON DELETE SET NULL
);

CREATE TABLE posts (
id UUID NOT NULL DEFAULT gen_random_uuid(),
    author_id UUID NOT NULL,
    session_id UUID,
    course_id UUID,
    post_type VARCHAR(20) NOT NULL DEFAULT 'GENERAL',
    title VARCHAR(200),
    body TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at TIMESTAMPTZ,
    PRIMARY KEY (id),
    CHECK (post_type IN ('GENERAL','RUNNING_RECORD','COURSE')),
    CHECK ((post_type <> 'RUNNING_RECORD' OR session_id IS NOT NULL) AND (post_type <> 'COURSE' OR course_id IS NOT NULL)),
    CONSTRAINT fk_posts_author_id FOREIGN KEY (author_id) REFERENCES users(id) ON DELETE RESTRICT,
    CONSTRAINT fk_posts_session_id FOREIGN KEY (session_id) REFERENCES running_sessions(id) ON DELETE SET NULL,
    CONSTRAINT fk_posts_course_id FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE SET NULL
);

CREATE TABLE comments (
id UUID NOT NULL DEFAULT gen_random_uuid(),
    post_id UUID NOT NULL,
    author_id UUID NOT NULL,
    body TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at TIMESTAMPTZ,
    PRIMARY KEY (id),
    CONSTRAINT fk_comments_post_id FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
    CONSTRAINT fk_comments_author_id FOREIGN KEY (author_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE post_reactions (
post_id UUID NOT NULL,
    user_id UUID NOT NULL,
    reaction_type VARCHAR(20) NOT NULL DEFAULT 'LIKE',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (post_id, user_id),
    CONSTRAINT fk_post_reactions_post_id FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
    CONSTRAINT fk_post_reactions_user_id FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE physiology_predictions (
id UUID NOT NULL DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL,
    runner_parameter_id UUID,
    predicted_at TIMESTAMPTZ NOT NULL,
    elapsed_time_sec NUMERIC(12,3),
    input_snapshot JSONB NOT NULL,
    candidate_hr_forecasts JSONB NOT NULL,
    selected_target_pace_sec_per_km NUMERIC(10,2),
    selection_reason JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (id),
    CHECK (elapsed_time_sec IS NULL OR elapsed_time_sec >= 0),
    CHECK (selected_target_pace_sec_per_km IS NULL OR selected_target_pace_sec_per_km > 0),
    CHECK (jsonb_typeof(candidate_hr_forecasts) = 'array'),
    CONSTRAINT fk_physiology_predictions_session_id FOREIGN KEY (session_id) REFERENCES running_sessions(id) ON DELETE CASCADE,
    CONSTRAINT fk_physiology_predictions_runner_parameter_id FOREIGN KEY (runner_parameter_id) REFERENCES runner_parameters(id) ON DELETE SET NULL
);

CREATE TABLE cue_predictions (
id UUID NOT NULL DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL,
    physiology_prediction_id UUID,
    runner_parameter_id UUID,
    predicted_at TIMESTAMPTZ NOT NULL,
    current_bpm NUMERIC(6,2),
    current_spm NUMERIC(8,2),
    current_speed_mps NUMERIC(10,4),
    target_pace_sec_per_km NUMERIC(10,2) NOT NULL,
    candidate_cue_responses JSONB NOT NULL,
    selected_bpm NUMERIC(6,2),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (id),
    CHECK (target_pace_sec_per_km > 0),
    CHECK (jsonb_typeof(candidate_cue_responses) = 'array'),
    CONSTRAINT fk_cue_predictions_session_id FOREIGN KEY (session_id) REFERENCES running_sessions(id) ON DELETE CASCADE,
    CONSTRAINT fk_cue_predictions_physiology_prediction_id FOREIGN KEY (physiology_prediction_id) REFERENCES physiology_predictions(id) ON DELETE RESTRICT,
    CONSTRAINT fk_cue_predictions_runner_parameter_id FOREIGN KEY (runner_parameter_id) REFERENCES runner_parameters(id) ON DELETE SET NULL
);

CREATE TABLE coaching_events (
id UUID NOT NULL DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL,
    plan_id UUID,
    prediction_id UUID,
    physiology_prediction_id UUID,
    cue_prediction_id UUID,
    device_applied_at TIMESTAMPTZ,
    event_type VARCHAR(40) NOT NULL,
    reason_code VARCHAR(60),
    previous_pace_sec_per_km NUMERIC(10,2),
    new_pace_sec_per_km NUMERIC(10,2),
    previous_bpm SMALLINT,
    new_bpm SMALLINT,
    occurred_at TIMESTAMPTZ NOT NULL,
    applied_at TIMESTAMPTZ,
    delivery_status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    delivered_at TIMESTAMPTZ,
    input_snapshot JSONB,
    PRIMARY KEY (id),
    CHECK (delivery_status IN ('PENDING','SENT','FAILED')),
    CONSTRAINT fk_coaching_events_session_id FOREIGN KEY (session_id) REFERENCES running_sessions(id) ON DELETE CASCADE,
    CONSTRAINT fk_coaching_events_plan_id FOREIGN KEY (plan_id) REFERENCES pace_plans(id) ON DELETE SET NULL,
    CONSTRAINT fk_coaching_events_prediction_id FOREIGN KEY (prediction_id) REFERENCES pace_predictions(id) ON DELETE SET NULL,
    CONSTRAINT fk_coaching_events_physiology_prediction_id FOREIGN KEY (physiology_prediction_id) REFERENCES physiology_predictions(id) ON DELETE SET NULL,
    CONSTRAINT fk_coaching_events_cue_prediction_id FOREIGN KEY (cue_prediction_id) REFERENCES cue_predictions(id) ON DELETE SET NULL
);

CREATE TABLE canonical_running_samples (
id UUID NOT NULL DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL,
    sampled_at TIMESTAMPTZ NOT NULL,
    elapsed_time_sec NUMERIC(12,3),
    heart_rate_bpm NUMERIC(7,2),
    cadence_spm NUMERIC(8,2),
    speed_mps NUMERIC(10,4),
    pace_sec_per_km NUMERIC(10,2),
    applied_bpm NUMERIC(7,2),
    grade_percent NUMERIC(8,3),
    distance_m NUMERIC(12,2),
    quality_flags JSONB NOT NULL DEFAULT '{}'::jsonb,
    etl_profile TEXT NOT NULL,
    processed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (id),
    UNIQUE (session_id, sampled_at, etl_profile),
    CHECK (elapsed_time_sec IS NULL OR elapsed_time_sec >= 0),
    CHECK (speed_mps IS NULL OR speed_mps >= 0),
    CHECK (distance_m IS NULL OR distance_m >= 0),
    CONSTRAINT fk_canonical_running_samples_session_id FOREIGN KEY (session_id) REFERENCES running_sessions(id) ON DELETE CASCADE
);

-- Circular relation: courses.source_session_id -> running_sessions.id.
-- Real FK cannot be declared inline when both tables reference each other.
-- This trigger validates source_session_id on INSERT/UPDATE.
-- Use a row lock to coordinate concurrent deletion of the referenced session.
CREATE FUNCTION runway_validate_course_source_session() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.source_session_id IS NOT NULL THEN
        PERFORM 1 FROM running_sessions WHERE id = NEW.source_session_id FOR KEY SHARE;
        IF NOT FOUND THEN
            RAISE EXCEPTION 'source_session_id % does not exist', NEW.source_session_id
                USING ERRCODE = '23503';
        END IF;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_course_source_session_check
BEFORE INSERT OR UPDATE OF source_session_id ON courses
FOR EACH ROW EXECUTE FUNCTION runway_validate_course_source_session();

-- Behaves like ON DELETE SET NULL for the source-session link.
-- AFTER DELETE avoids a transient row-lock conflict when deleting a session.
CREATE FUNCTION runway_null_course_source_session() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE courses SET source_session_id = NULL WHERE source_session_id = OLD.id;
    RETURN OLD;
END;
$$;

CREATE TRIGGER trg_session_course_source_cleanup
AFTER DELETE ON running_sessions
FOR EACH ROW EXECUTE FUNCTION runway_null_course_source_session();

CREATE UNIQUE INDEX uq_group_run_participant_session ON group_run_participants(session_id) WHERE session_id IS NOT NULL;
CREATE INDEX idx_courses_start_position ON courses USING GIST (start_position);
CREATE INDEX idx_courses_route ON courses USING GIST (route);
CREATE INDEX idx_running_route_points_position ON running_route_points USING GIST (position);
CREATE INDEX idx_running_route_points_session_id_measured_at ON running_route_points (session_id, measured_at);
CREATE INDEX idx_running_metric_samples_session_id_metric_type_measured_at ON running_metric_samples (session_id, metric_type, measured_at);
CREATE INDEX idx_pace_predictions_session_id_predicted_at ON pace_predictions (session_id, predicted_at);
CREATE INDEX idx_physiology_predictions_session_id_predicted_at ON physiology_predictions (session_id, predicted_at);
CREATE INDEX idx_cue_predictions_session_id_predicted_at ON cue_predictions (session_id, predicted_at);
CREATE INDEX idx_canonical_running_samples_session_id_sampled_at ON canonical_running_samples (session_id, sampled_at);
CREATE INDEX idx_notifications_recipient_user_id_created_at ON notifications (recipient_user_id, created_at);
CREATE INDEX idx_running_sessions_user_id_created_at ON running_sessions (user_id, created_at);

-- Business invariants (event state transitions, group membership/recipient checks,
-- stable client-generated measurement UUIDs, offline commit ACK) require application tests.
COMMIT;
