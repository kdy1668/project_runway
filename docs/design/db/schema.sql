CREATE TABLE "sync_batches" (
	"id"	BIGINT		NOT NULL,
	"client_batch_id"	VARCHAR(200)		NOT NULL,
	"device_id"	BIGINT		NOT NULL,
	"session_id"	BIGINT		NULL,
	"payload_version"	VARCHAR(50)		NOT NULL,
	"payload_hash"	TEXT		NOT NULL,
	"status"	ENUM('RECEIVED', 'COMMITTED', 'REJECTED')	DEFAULT 'RECEIVED'	NOT NULL,
	"received_at"	TIMESTAMPTZ	DEFAULT now()	NOT NULL,
	"committed_at"	TIMESTAMPTZ		NULL
);

CREATE TABLE "daily_readiness" (
	"id"	BIGINT		NOT NULL,
	"user_id"	BIGINT		NOT NULL,
	"readiness_date"	DATE		NOT NULL,
	"readiness_score"	NUMERIC(7,2)		NOT NULL,
	"readiness_confidence"	ENUM('LOW','MEDIUM','HIGH')		NULL,
	"created_at"	TIMESTAMPTZ	DEFAULT now()	NOT NULL,
	"updated_at"	TIMESTAMPTZ	DEFAULT now()	NOT NULL
);

COMMENT ON COLUMN "daily_readiness"."id" IS '러닝 준비도 ID';

COMMENT ON COLUMN "daily_readiness"."user_id" IS '회원 ID';

COMMENT ON COLUMN "daily_readiness"."readiness_date" IS '준비도 기준일';

COMMENT ON COLUMN "daily_readiness"."readiness_score" IS '러닝 준비도 점수';

COMMENT ON COLUMN "daily_readiness"."readiness_confidence" IS '준비도 신뢰 수준';

COMMENT ON COLUMN "daily_readiness"."created_at" IS '생성일시';

COMMENT ON COLUMN "daily_readiness"."updated_at" IS '수정일시';

CREATE TABLE "users" (
	"id"	BIGINT		NOT NULL,
	"login_id"	VARCHAR(16)		NOT NULL,
	"password"	VARCHAR(255)		NOT NULL,
	"nickname"	VARCHAR(10)		NOT NULL,
	"birth_date"	DATE		NOT NULL,
	"gender"	ENUM('MALE', 'FEMALE')		NOT NULL,
	"profile_image_key"	VARCHAR(1024)		NULL,
	"account_status"	ENUM('ACTIVE', 'WITHDRAWN')	DEFAULT 'ACTIVE'	NOT NULL,
	"withdrawn_at"	TIMESTAMPTZ		NULL,
	"phone_number"	VARCHAR(20)		NOT NULL,
	"health_data_access"	ENUM('AGREEE', 'DISAGREE')		NOT NULL,
	"created_at"	TIMESTAMPTZ	DEFAULT now()	NOT NULL,
	"updated_at"	TIMESTAMPTZ	DEFAULT now()	NOT NULL
);

CREATE TABLE "pace_plans" (
	"id"	BIGINT		NOT NULL,
	"session_id"	BIGINT		NOT NULL,
	"recommended_pace"	NUMERIC(10,2)		NOT NULL,
	"cue_bpm"	NUMERIC(7,2)		NULL,
	"route_progress"	NUMERIC(12,2)		NULL,
	"created_at"	TIMESTAMPTZ	DEFAULT now()	NOT NULL
);

COMMENT ON COLUMN "pace_plans"."recommended_pace" IS '초기 페이스 전략의 추천 페이스(초/km)';

COMMENT ON COLUMN "pace_plans"."cue_bpm" IS '추천 박자(BPM)';

COMMENT ON COLUMN "pace_plans"."route_progress" IS '코스 진행거리(m)';

CREATE TABLE "group_runs" (
	"id"	BIGINT		NOT NULL,
	"crew_id"	BIGINT		NOT NULL,
	"host_id"	BIGINT		NOT NULL,
	"course_id"	BIGINT		NULL,
	"title"	VARCHAR(100)		NOT NULL,
	"description"	TEXT		NULL,
	"scheduled_at"	TIMESTAMPTZ		NOT NULL,
	"meeting_name"	VARCHAR(200)		NULL,
	"meeting_address"	VARCHAR(255)		NULL,
	"meeting_position"	geography(Point,4326)		NULL,
	"goal_distance"	INTEGER		NULL,
	"goal_duration"	INTEGER		NULL,
	"status"	ENUM('SCHEDULED', 'RUNNING', 'COMPLETED', 'CANCELLED')	DEFAULT 'SCHEDULED'	NOT NULL,
	"started_at"	TIMESTAMPTZ		NULL,
	"ended_at"	TIMESTAMPTZ		NULL,
	"cancel_reason"	VARCHAR(50)		NULL,
	"created_at"	TIMESTAMPTZ	DEFAULT now()	NOT NULL,
	"updated_at"	TIMESTAMPTZ	DEFAULT now()	NOT NULL
);

COMMENT ON COLUMN "group_runs"."cancel_reason" IS '그룹런 취소 사유. 취소 전 NULL. 사유 코드 목록은 서비스에서 확정.';

CREATE TABLE "crew_memberships" (
	"id"	BIGINT		NOT NULL,
	"crew_id"	BIGINT		NOT NULL,
	"user_id"	BIGINT		NOT NULL,
	"status"	ENUM('PENDING', 'APPROVED', 'REJECTED', 'LEFT')	DEFAULT 'PENDING'	NOT NULL,
	"requested_at"	TIMESTAMPTZ	DEFAULT now()	NOT NULL,
	"joined_at"	TIMESTAMPTZ		NULL,
	"left_at"	TIMESTAMPTZ		NULL,
	"created_at"	TIMESTAMPTZ	DEFAULT now()	NOT NULL,
	"updated_at"	TIMESTAMPTZ	DEFAULT now()	NOT NULL
);

CREATE TABLE "pace_plan_segments" (
	"id"	BIGINT		NOT NULL,
	"pace_plan_id"	BIGINT		NOT NULL,
	"segment_sequence"	INTEGER		NOT NULL,
	"start_distance"	NUMERIC(12,2)		NOT NULL,
	"end_distance"	NUMERIC(12,2)		NOT NULL,
	"recommended_pace"	NUMERIC(10,2)		NOT NULL,
	"created_at"	TIMESTAMPTZ	DEFAULT now()	NOT NULL
);

COMMENT ON COLUMN "pace_plan_segments"."id" IS '페이스 구간 ID';

COMMENT ON COLUMN "pace_plan_segments"."pace_plan_id" IS '페이스 전략 ID';

COMMENT ON COLUMN "pace_plan_segments"."segment_sequence" IS '구간 순서';

COMMENT ON COLUMN "pace_plan_segments"."start_distance" IS '구간 시작거리(m)';

COMMENT ON COLUMN "pace_plan_segments"."end_distance" IS '구간 종료거리(m)';

COMMENT ON COLUMN "pace_plan_segments"."recommended_pace" IS '구간 추천 페이스(초/km)';

COMMENT ON COLUMN "pace_plan_segments"."created_at" IS '생성일시';

CREATE TABLE "group_run_participants" (
	"id"	BIGINT		NOT NULL,
	"group_run_id"	BIGINT		NOT NULL,
	"user_id"	BIGINT		NOT NULL,
	"session_id"	BIGINT		NULL,
	"joined_at"	TIMESTAMPTZ	DEFAULT now()	NOT NULL
);

CREATE TABLE "running_route_points" (
	"id"	BIGINT		NOT NULL,
	"running_session_id"	BIGINT		NOT NULL,
	"measured_at"	TIMESTAMPTZ		NOT NULL,
	"position"	geography(Point,4326)		NOT NULL,
	"accuracy"	NUMERIC(10,2)		NULL,
	"device_id"	BIGINT		NULL,
	"altitude"	NUMERIC(10,2)		NULL
);

CREATE TABLE "post_likes" (
	"id"	BIGINT		NOT NULL,
	"post_id"	BIGINT		NOT NULL,
	"user_id"	BIGINT		NOT NULL,
	"created_at"	TIMESTAMPTZ	DEFAULT now()	NOT NULL
);

CREATE TABLE "courses" (
	"id"	BIGINT		NOT NULL,
	"creator_id"	BIGINT		NULL,
	"source_session_id"	BIGINT		NULL,
	"description"	TEXT		NULL,
	"route"	geography(LineString,4326)		NOT NULL,
	"start_position"	geography(Point,4326)		NOT NULL,
	"distance"	NUMERIC(12,2)		NOT NULL,
	"elevation_gain"	NUMERIC(10,2)		NULL,
	"elevation_profile"	JSONB		NULL,
	"status"	ENUM('ACTIVE', 'MERGED', 'BLOCKED')	DEFAULT 'ACTIVE'	NOT NULL,
	"merged_into_course_id"	BIGINT		NULL,
	"created_at"	TIMESTAMPTZ	DEFAULT now()	NOT NULL,
	"updated_at"	TIMESTAMPTZ	DEFAULT now()	NOT NULL,
	"region_code"	VARCHAR(40)		NULL
);

COMMENT ON COLUMN "courses"."region_code" IS '출발 좌표 기준 시·군·구 코드. regions.region_code(UNIQUE)를 외래키로 참조한다. 지역 판정 전 또는 실패 시 NULL을 허용한다. 코스 표시명은 시·도명 + 시·군·구명 + 코스로 조합한다.';

CREATE TABLE "course_environment_tags" (
	"id"	BIGINT		NOT NULL,
	"course_id"	BIGINT		NOT NULL,
	"environment_type"	ENUM('PARK', 'RIVERSIDE', 'URBAN', 'BEACH', 'TRACK')		NOT NULL
);

CREATE TABLE "regions" (
	"id"	BIGINT		NOT NULL,
	"region_code"	VARCHAR(40) UNIQUE		NOT NULL,
	"sido_name"	VARCHAR(100)		NOT NULL,
	"sigungu_name"	VARCHAR(100)		NOT NULL
);

COMMENT ON COLUMN "regions"."region_code" IS '시·군·구 코드. 중복 금지 UNIQUE 참조 키. courses/crews/posts의 지역 코드가 참조한다.';

CREATE TABLE "user_profiles" (
	"id"	BIGINT		NOT NULL,
	"user_id"	BIGINT		NOT NULL,
	"running_level"	ENUM('BEGINNER', 'INTERMEDIATE', 'ADVANCED')		NOT NULL,
	"average_pace"	NUMERIC(10,2)		NOT NULL,
	"distance"	INTEGER		NULL,
	"duraction"	INTEGER		NULL,
	"created_at"	TIMESTAMPTZ	DEFAULT now()	NOT NULL,
	"updated_at"	TIMESTAMPTZ	DEFAULT now()	NOT NULL
);

CREATE TABLE "daily_health_metrics" (
	"id"	BIGINT		NOT NULL,
	"user_id"	BIGINT		NOT NULL,
	"metric_date"	DATE		NOT NULL,
	"sleep_duration_min"	NUMERIC(7,2)		NULL,
	"rhr_bpm"	NUMERIC(7,2)		NULL,
	"daily_training_load"	NUMERIC(12,4)		NULL,
	"max_heart_rate"	NUMERIC(7,2)		NULL,
	"created_at"	TIMESTAMPTZ	DEFAULT now()	NOT NULL,
	"updated_at"	TIMESTAMPTZ	DEFAULT now()	NOT NULL
);

COMMENT ON COLUMN "daily_health_metrics"."id" IS '일별 건강 ID';

COMMENT ON COLUMN "daily_health_metrics"."user_id" IS '회원 ID';

COMMENT ON COLUMN "daily_health_metrics"."metric_date" IS '건강 정보 기준일';

COMMENT ON COLUMN "daily_health_metrics"."sleep_duration_min" IS '수면시간(분)';

COMMENT ON COLUMN "daily_health_metrics"."rhr_bpm" IS '안정시 심박수(bpm)';

COMMENT ON COLUMN "daily_health_metrics"."daily_training_load" IS '하루 운동 부하';

COMMENT ON COLUMN "daily_health_metrics"."max_heart_rate" IS '준비도 계산용 최대 심박수(bpm)';

COMMENT ON COLUMN "daily_health_metrics"."created_at" IS '생성일시';

COMMENT ON COLUMN "daily_health_metrics"."updated_at" IS '수정일시';

CREATE TABLE "posts" (
	"id"	BIGINT		NOT NULL,
	"author_id"	BIGINT		NOT NULL,
	"session_id"	BIGINT		NOT NULL,
	"body"	TEXT		NULL,
	"image_key"	VARCHAR(1024)		NULL,
	"region_code"	VARCHAR(40)		NULL,
	"deleted_at"	TIMESTAMPTZ		NULL,
	"created_at"	TIMESTAMPTZ	DEFAULT now()	NOT NULL,
	"updated_at"	TIMESTAMPTZ	DEFAULT now()	NOT NULL
);

COMMENT ON COLUMN "posts"."region_code" IS '게시물 지역 코드. regions.region_code 참조. 시·군·구 단위. 미지정 시 NULL.';

CREATE TABLE "coaching_decisions" (
	"id"	BIGINT		NOT NULL,
	"session_id"	BIGINT		NOT NULL,
	"elapsed_duration"	INTEGER		NOT NULL,
	"recommended_pace"	NUMERIC(10,2)		NOT NULL,
	"cue_bpm"	NUMERIC(7,2)		NULL,
	"predicted_hr_30_bpm"	NUMERIC(7,2)		NULL,
	"predicted_hr_60_bpm"	NUMERIC(7,2)		NULL,
	"predicted_hr_120_bpm"	NUMERIC(7,2)		NULL,
	"route_progress"	NUMERIC(12,2)		NULL,
	"created_at"	TIMESTAMPTZ	DEFAULT now()	NOT NULL
);

COMMENT ON COLUMN "coaching_decisions"."elapsed_duration" IS '러닝 경과시간(초)';

COMMENT ON COLUMN "coaching_decisions"."recommended_pace" IS '추천 페이스(초/km)';

COMMENT ON COLUMN "coaching_decisions"."cue_bpm" IS '추천 박자(BPM)';

COMMENT ON COLUMN "coaching_decisions"."predicted_hr_30_bpm" IS '30초 뒤 예측 심박수(bpm)';

COMMENT ON COLUMN "coaching_decisions"."predicted_hr_60_bpm" IS '60초 뒤 예측 심박수(bpm)';

COMMENT ON COLUMN "coaching_decisions"."predicted_hr_120_bpm" IS '120초 뒤 예측 심박수(bpm)';

COMMENT ON COLUMN "coaching_decisions"."route_progress" IS '코스 진행거리(m)';

COMMENT ON COLUMN "coaching_decisions"."created_at" IS '생성일시';

CREATE TABLE "crews" (
	"id"	BIGINT		NOT NULL,
	"owner_id"	BIGINT		NOT NULL,
	"name"	VARCHAR(100)		NOT NULL,
	"description"	TEXT		NULL,
	"image_key"	VARCHAR(1024)		NULL,
	"capacity"	INTEGER		NOT NULL,
	"status"	ENUM('ACTIVE', 'INACTIVE')	DEFAULT 'ACTIVE'	NOT NULL,
	"region_code"	VARCHAR(40)		NULL,
	"created_at"	TIMESTAMPTZ	DEFAULT now()	NOT NULL,
	"updated_at"	TIMESTAMPTZ	DEFAULT now()	NOT NULL
);

CREATE TABLE "running_sessions" (
	"id"	BIGINT		NOT NULL,
	"user_id"	BIGINT		NOT NULL,
	"course_id"	BIGINT		NULL,
	"comparison_session_id"	BIGINT		NULL,
	"status"	ENUM('READY', 'RUNNING', 'PAUSED', 'COMPLETED', 'CANCELLED', 'INTERRUPTED')	DEFAULT 'READY'	NOT NULL,
	"goal_distance"	INTEGER		NULL,
	"goal_duration"	INTEGER		NULL,
	"goal_pace"	NUMERIC(10,2)		NULL,
	"started_at"	TIMESTAMPTZ		NULL,
	"ended_at"	TIMESTAMPTZ		NULL,
	"total_distance"	NUMERIC(12,2)		NULL,
	"moving_duration"	INTEGER		NULL,
	"elapsed_duration"	INTEGER		NULL,
	"moving_duration_to_goal"	INTEGER		NULL,
	"goal_achieved"	BOOLEAN		NULL,
	"average_pace"	NUMERIC(10,2)		NULL,
	"average_heart_rate"	NUMERIC(7,2)		NULL,
	"average_cadence"	NUMERIC(8,2)		NULL,
	"deleted_at"	TIMESTAMPTZ		NULL,
	"max_heart_rate"	NUMERIC(7,2)		NULL,
	"created_at"	TIMESTAMPTZ	DEFAULT now()	NOT NULL,
	"updated_at"	TIMESTAMPTZ	DEFAULT now()	NOT NULL
);

COMMENT ON COLUMN "running_sessions"."max_heart_rate" IS '최대 심박수(bpm)';

CREATE TABLE "comments" (
	"id"	BIGINT		NOT NULL,
	"post_id"	BIGINT		NOT NULL,
	"parent_comment_id"	BIGINT		NULL,
	"author_id"	BIGINT		NOT NULL,
	"body"	TEXT		NOT NULL,
	"deleted_at"	TIMESTAMPTZ		NULL,
	"created_at"	TIMESTAMPTZ	DEFAULT now()	NOT NULL,
	"updated_at"	TIMESTAMPTZ	DEFAULT now()	NOT NULL
);

COMMENT ON COLUMN "comments"."post_id" IS 'posts.id 참조. 대댓글은 부모와 게시물이 같아야 함: (post_id,parent_comment_id) → comments(post_id,id). 정확한 DB 제약은 제공 SQL 참조.';

COMMENT ON COLUMN "comments"."parent_comment_id" IS '일반 댓글은 NULL. 대댓글 부모는 같은 게시물이어야 함. 복합 FK (post_id,parent_comment_id) REFERENCES comments(post_id,id); UNIQUE(post_id,id); CHECK(parent_comment_id IS NULL OR parent_comment_id <> id). 한 단계 대댓글 깊이는 서비스에서 검사.';

CREATE TABLE "course_bookmarks" (
	"id"	BIGINT		NOT NULL,
	"user_id"	BIGINT		NOT NULL,
	"course_id"	BIGINT		NOT NULL,
	"custom_name"	VARCHAR(50)		NULL,
	"created_at"	TIMESTAMPTZ	DEFAULT now()	NOT NULL,
	"updated_at"	TIMESTAMPTZ	DEFAULT now()	NOT NULL
);

CREATE TABLE "user_devices" (
	"id"	BIGINT		NOT NULL,
	"user_id"	BIGINT		NOT NULL,
	"device_type"	ENUM('PHONE', 'WATCH')		NOT NULL,
	"linked_at"	TIMESTAMPTZ		NOT NULL,
	"unlinked_at"	TIMESTAMPTZ		NULL
);

CREATE TABLE "user_settings" (
	"id"	BIGINT		NOT NULL,
	"user_id"	BIGINT		NOT NULL,
	"voice_coaching_enabled"	BOOLEAN		NOT NULL,
	"bpm_guide_enabled"	BOOLEAN		NOT NULL,
	"group_notifications_enabled"	BOOLEAN		NOT NULL,
	"community_notifications_enabled"	BOOLEAN		NOT NULL,
	"location_collection_mode"	ENUM('ALWAYS', 'RUNNING_ONLY', 'OFF')		NOT NULL,
	"account_visibility"	ENUM('PUBLIC', 'PRIVATE')		NOT NULL,
	"created_at"	TIMESTAMPTZ	DEFAULT now()	NOT NULL,
	"updated_at"	TIMESTAMPTZ	DEFAULT now()	NOT NULL
);

COMMENT ON COLUMN "user_settings"."location_collection_mode" IS '위치 수집 모드. ALWAYS/RUNNING_ONLY/OFF 중 하나를 설정 행 생성 시 명시한다. NULL 불가. 위치 수집 모드와 기록 공개 범위는 별개다.';

COMMENT ON COLUMN "user_settings"."account_visibility" IS '계정의 기록 공개 범위. PUBLIC 또는 PRIVATE를 설정 행 생성 시 명시하며 NULL 불가. PUBLIC은 기록 공개 및 즉시 팔로우, PRIVATE는 팔로우 승인 후 성립하며 기록은 본인 및 승인된 팔로워만 열람 가능. 승인 관계는 user_follows.follower_id=열람자, followee_id=기록 소유자, is_approved=TRUE로 판정한다.';

CREATE TABLE "user_follows" (
	"id"	BIGINT		NOT NULL,
	"follower_id"	BIGINT		NOT NULL,
	"followee_id"	BIGINT		NOT NULL,
	"created_at"	TIMESTAMPTZ	DEFAULT now()	NOT NULL,
	"is_approved"	BOOLEAN	DEFAULT FALSE	NOT NULL
);

COMMENT ON COLUMN "user_follows"."is_approved" IS '팔로우 성립 여부. 공개(PUBLIC) 계정은 별도 승인 없이 요청 생성 시 TRUE로 저장한다. 비공개(PRIVATE) 계정은 FALSE로 요청을 저장하고 상대가 승인하면 TRUE로 변경한다. FALSE는 미승인 요청이며 팔로워 집계와 비공개 기록 열람에서 제외한다. 비공개 기록은 본인 또는 follower_id=열람자, followee_id=기록 소유자, is_approved=TRUE인 경우에만 열람한다.';

CREATE TABLE "notifications" (
	"id"	BIGINT		NOT NULL,
	"user_id"	BIGINT		NOT NULL,
	"sent_at"	TIMESTAMPTZ		NULL,
	"read_at"	TIMESTAMPTZ		NULL,
	"delivery_status"	ENUM('PENDING', 'SENT', 'FAILED')	DEFAULT 'PENDING'	NOT NULL,
	"message"	VARCHAR(100)		NOT NULL,
	"created_at"	TIMESTAMPTZ	DEFAULT now()	NOT NULL,
	"notification_type"	VARCHAR(50)		NOT NULL,
	"target_id"	BIGINT		NOT NULL
);

COMMENT ON COLUMN "notifications"."notification_type" IS '알림 종류 코드. GROUP_RUN_PARTICIPATION_CANCELLED: 그룹런 참여 취소, CREW_JOIN_APPROVED: 크루 가입 승인, CREW_JOIN_REJECTED: 크루 가입 거절, POST_COMMENT: 게시물 댓글, GROUP_RUN_START_REMINDER: 그룹런 시작 임박. 알림 종류로 target_id의 대상과 이동 화면을 결정하며 별도 target_type은 두지 않는다.';

COMMENT ON COLUMN "notifications"."target_id" IS '알림 클릭 시 이동 대상 ID. GROUP_RUN_PARTICIPATION_CANCELLED/GROUP_RUN_START_REMINDER는 group_runs.id(그룹런 상세), CREW_JOIN_APPROVED/CREW_JOIN_REJECTED는 crews.id(크루 상세), POST_COMMENT는 posts.id(게시글 상세). 여러 테이블을 가리키므로 단일 FK는 두지 않고 서비스에서 종류별 대상 존재와 현재 열람 권한을 검증한다. 삭제된 대상은 이동 불가로 안내한다.';

CREATE TABLE "running_metric_samples" (
	"id"	BIGINT		NOT NULL,
	"running_session_id"	BIGINT		NOT NULL,
	"device_id"	BIGINT		NULL,
	"measured_at"	TIMESTAMPTZ		NOT NULL,
	"elapsed_duration"	INTEGER		NOT NULL,
	"heart_rate"	NUMERIC(7,2)		NULL,
	"cadence"	NUMERIC(8,2)		NULL,
	"speed"	NUMERIC(10,3)		NULL,
	"grade"	NUMERIC(7,3)		NULL,
	"total_distance"	NUMERIC(12,2)		NULL,
	"route_progress"	NUMERIC(12,2)		NULL,
	"is_hr_measured"	BOOLEAN		NOT NULL,
	"created_at"	TIMESTAMPTZ	DEFAULT now()	NOT NULL
);

COMMENT ON COLUMN "running_metric_samples"."id" IS '러닝 측정값 ID';

COMMENT ON COLUMN "running_metric_samples"."running_session_id" IS '러닝 ID';

COMMENT ON COLUMN "running_metric_samples"."device_id" IS '측정 기기 ID';

COMMENT ON COLUMN "running_metric_samples"."measured_at" IS '측정 기준일시';

COMMENT ON COLUMN "running_metric_samples"."elapsed_duration" IS '러닝 경과시간(초)';

COMMENT ON COLUMN "running_metric_samples"."heart_rate" IS '심박수(bpm)';

COMMENT ON COLUMN "running_metric_samples"."cadence" IS '측정 시점의 분당 걸음 수(spm). 미측정 시 NULL. 세션 평균과 구분.';

COMMENT ON COLUMN "running_metric_samples"."speed" IS '속도(m/s)';

COMMENT ON COLUMN "running_metric_samples"."grade" IS '경사도(%)';

COMMENT ON COLUMN "running_metric_samples"."total_distance" IS '누적 이동거리(m)';

COMMENT ON COLUMN "running_metric_samples"."route_progress" IS '코스 진행거리(m)';

COMMENT ON COLUMN "running_metric_samples"."is_hr_measured" IS '심박 실제 측정 여부';

COMMENT ON COLUMN "running_metric_samples"."created_at" IS '생성일시';

ALTER TABLE "sync_batches" ADD CONSTRAINT "PK_SYNC_BATCHES" PRIMARY KEY (
	"id"
);

ALTER TABLE "daily_readiness" ADD CONSTRAINT "PK_DAILY_READINESS" PRIMARY KEY (
	"id"
);

ALTER TABLE "users" ADD CONSTRAINT "PK_USERS" PRIMARY KEY (
	"id"
);

ALTER TABLE "pace_plans" ADD CONSTRAINT "PK_PACE_PLANS" PRIMARY KEY (
	"id"
);

ALTER TABLE "group_runs" ADD CONSTRAINT "PK_GROUP_RUNS" PRIMARY KEY (
	"id"
);

ALTER TABLE "crew_memberships" ADD CONSTRAINT "PK_CREW_MEMBERSHIPS" PRIMARY KEY (
	"id"
);

ALTER TABLE "pace_plan_segments" ADD CONSTRAINT "PK_PACE_PLAN_SEGMENTS" PRIMARY KEY (
	"id"
);

ALTER TABLE "group_run_participants" ADD CONSTRAINT "PK_GROUP_RUN_PARTICIPANTS" PRIMARY KEY (
	"id"
);

ALTER TABLE "running_route_points" ADD CONSTRAINT "PK_RUNNING_ROUTE_POINTS" PRIMARY KEY (
	"id"
);

ALTER TABLE "post_likes" ADD CONSTRAINT "PK_POST_LIKES" PRIMARY KEY (
	"id"
);

ALTER TABLE "courses" ADD CONSTRAINT "PK_COURSES" PRIMARY KEY (
	"id"
);

ALTER TABLE "course_environment_tags" ADD CONSTRAINT "PK_COURSE_ENVIRONMENT_TAGS" PRIMARY KEY (
	"id"
);

ALTER TABLE "regions" ADD CONSTRAINT "PK_REGIONS" PRIMARY KEY (
	"id"
);

ALTER TABLE "user_profiles" ADD CONSTRAINT "PK_USER_PROFILES" PRIMARY KEY (
	"id"
);

ALTER TABLE "daily_health_metrics" ADD CONSTRAINT "PK_DAILY_HEALTH_METRICS" PRIMARY KEY (
	"id"
);

ALTER TABLE "posts" ADD CONSTRAINT "PK_POSTS" PRIMARY KEY (
	"id"
);

ALTER TABLE "coaching_decisions" ADD CONSTRAINT "PK_COACHING_DECISIONS" PRIMARY KEY (
	"id"
);

ALTER TABLE "crews" ADD CONSTRAINT "PK_CREWS" PRIMARY KEY (
	"id"
);

ALTER TABLE "running_sessions" ADD CONSTRAINT "PK_RUNNING_SESSIONS" PRIMARY KEY (
	"id"
);

ALTER TABLE "comments" ADD CONSTRAINT "PK_COMMENTS" PRIMARY KEY (
	"id"
);

ALTER TABLE "course_bookmarks" ADD CONSTRAINT "PK_COURSE_BOOKMARKS" PRIMARY KEY (
	"id"
);

ALTER TABLE "user_devices" ADD CONSTRAINT "PK_USER_DEVICES" PRIMARY KEY (
	"id"
);

ALTER TABLE "user_settings" ADD CONSTRAINT "PK_USER_SETTINGS" PRIMARY KEY (
	"id"
);

ALTER TABLE "user_follows" ADD CONSTRAINT "PK_USER_FOLLOWS" PRIMARY KEY (
	"id"
);

ALTER TABLE "notifications" ADD CONSTRAINT "PK_NOTIFICATIONS" PRIMARY KEY (
	"id"
);

ALTER TABLE "running_metric_samples" ADD CONSTRAINT "PK_RUNNING_METRIC_SAMPLES" PRIMARY KEY (
	"id"
);

ALTER TABLE "sync_batches" ADD CONSTRAINT "FK_user_devices_TO_sync_batches_1" FOREIGN KEY (
	"device_id"
)
REFERENCES "user_devices" (
	"id"
);

ALTER TABLE "sync_batches" ADD CONSTRAINT "FK_running_sessions_TO_sync_batches_1" FOREIGN KEY (
	"session_id"
)
REFERENCES "running_sessions" (
	"id"
);

ALTER TABLE "daily_readiness" ADD CONSTRAINT "FK_users_TO_daily_readiness_1" FOREIGN KEY (
	"user_id"
)
REFERENCES "users" (
	"id"
);

ALTER TABLE "pace_plans" ADD CONSTRAINT "FK_running_sessions_TO_pace_plans_1" FOREIGN KEY (
	"session_id"
)
REFERENCES "running_sessions" (
	"id"
);

ALTER TABLE "group_runs" ADD CONSTRAINT "FK_crews_TO_group_runs_1" FOREIGN KEY (
	"crew_id"
)
REFERENCES "crews" (
	"id"
);

ALTER TABLE "group_runs" ADD CONSTRAINT "FK_users_TO_group_runs_1" FOREIGN KEY (
	"host_id"
)
REFERENCES "users" (
	"id"
);

ALTER TABLE "group_runs" ADD CONSTRAINT "FK_courses_TO_group_runs_1" FOREIGN KEY (
	"course_id"
)
REFERENCES "courses" (
	"id"
);

ALTER TABLE "crew_memberships" ADD CONSTRAINT "FK_crews_TO_crew_memberships_1" FOREIGN KEY (
	"crew_id"
)
REFERENCES "crews" (
	"id"
);

ALTER TABLE "crew_memberships" ADD CONSTRAINT "FK_users_TO_crew_memberships_1" FOREIGN KEY (
	"user_id"
)
REFERENCES "users" (
	"id"
);

ALTER TABLE "pace_plan_segments" ADD CONSTRAINT "FK_pace_plans_TO_pace_plan_segments_1" FOREIGN KEY (
	"pace_plan_id"
)
REFERENCES "pace_plans" (
	"id"
);

ALTER TABLE "group_run_participants" ADD CONSTRAINT "FK_group_runs_TO_group_run_participants_1" FOREIGN KEY (
	"group_run_id"
)
REFERENCES "group_runs" (
	"id"
);

ALTER TABLE "group_run_participants" ADD CONSTRAINT "FK_users_TO_group_run_participants_1" FOREIGN KEY (
	"user_id"
)
REFERENCES "users" (
	"id"
);

ALTER TABLE "group_run_participants" ADD CONSTRAINT "FK_running_sessions_TO_group_run_participants_1" FOREIGN KEY (
	"session_id"
)
REFERENCES "running_sessions" (
	"id"
);

ALTER TABLE "running_route_points" ADD CONSTRAINT "FK_running_sessions_TO_running_route_points_1" FOREIGN KEY (
	"running_session_id"
)
REFERENCES "running_sessions" (
	"id"
);

ALTER TABLE "running_route_points" ADD CONSTRAINT "FK_user_devices_TO_running_route_points_1" FOREIGN KEY (
	"device_id"
)
REFERENCES "user_devices" (
	"id"
);

ALTER TABLE "post_likes" ADD CONSTRAINT "FK_posts_TO_post_likes_1" FOREIGN KEY (
	"post_id"
)
REFERENCES "posts" (
	"id"
);

ALTER TABLE "post_likes" ADD CONSTRAINT "FK_users_TO_post_likes_1" FOREIGN KEY (
	"user_id"
)
REFERENCES "users" (
	"id"
);

ALTER TABLE "courses" ADD CONSTRAINT "FK_users_TO_courses_1" FOREIGN KEY (
	"creator_id"
)
REFERENCES "users" (
	"id"
);

ALTER TABLE "courses" ADD CONSTRAINT "FK_running_sessions_TO_courses_1" FOREIGN KEY (
	"source_session_id"
)
REFERENCES "running_sessions" (
	"id"
);

ALTER TABLE "courses" ADD CONSTRAINT "FK_courses_TO_courses_1" FOREIGN KEY (
	"merged_into_course_id"
)
REFERENCES "courses" (
	"id"
);

ALTER TABLE "course_environment_tags" ADD CONSTRAINT "FK_courses_TO_course_environment_tags_1" FOREIGN KEY (
	"course_id"
)
REFERENCES "courses" (
	"id"
);

ALTER TABLE "user_profiles" ADD CONSTRAINT "FK_users_TO_user_profiles_1" FOREIGN KEY (
	"user_id"
)
REFERENCES "users" (
	"id"
);

ALTER TABLE "daily_health_metrics" ADD CONSTRAINT "FK_users_TO_daily_health_metrics_1" FOREIGN KEY (
	"user_id"
)
REFERENCES "users" (
	"id"
);

ALTER TABLE "posts" ADD CONSTRAINT "FK_users_TO_posts_1" FOREIGN KEY (
	"author_id"
)
REFERENCES "users" (
	"id"
);

ALTER TABLE "posts" ADD CONSTRAINT "FK_running_sessions_TO_posts_1" FOREIGN KEY (
	"session_id"
)
REFERENCES "running_sessions" (
	"id"
);

ALTER TABLE "posts" ADD CONSTRAINT "FK_regions_TO_posts_1" FOREIGN KEY (
	"region_code"
)
REFERENCES "regions" (
	"region_code"
);

ALTER TABLE "coaching_decisions" ADD CONSTRAINT "FK_running_sessions_TO_coaching_decisions_1" FOREIGN KEY (
	"session_id"
)
REFERENCES "running_sessions" (
	"id"
);

ALTER TABLE "crews" ADD CONSTRAINT "FK_users_TO_crews_1" FOREIGN KEY (
	"owner_id"
)
REFERENCES "users" (
	"id"
);

ALTER TABLE "crews" ADD CONSTRAINT "FK_regions_TO_crews_1" FOREIGN KEY (
	"region_code"
)
REFERENCES "regions" (
	"region_code"
);

ALTER TABLE "running_sessions" ADD CONSTRAINT "FK_users_TO_running_sessions_1" FOREIGN KEY (
	"user_id"
)
REFERENCES "users" (
	"id"
);

ALTER TABLE "running_sessions" ADD CONSTRAINT "FK_courses_TO_running_sessions_1" FOREIGN KEY (
	"course_id"
)
REFERENCES "courses" (
	"id"
);

ALTER TABLE "running_sessions" ADD CONSTRAINT "FK_running_sessions_TO_running_sessions_1" FOREIGN KEY (
	"comparison_session_id"
)
REFERENCES "running_sessions" (
	"id"
);

ALTER TABLE "comments" ADD CONSTRAINT "FK_posts_TO_comments_1" FOREIGN KEY (
	"post_id"
)
REFERENCES "posts" (
	"id"
);

ALTER TABLE "comments" ADD CONSTRAINT "FK_comments_TO_comments_1" FOREIGN KEY (
	"parent_comment_id"
)
REFERENCES "comments" (
	"id"
);

ALTER TABLE "comments" ADD CONSTRAINT "FK_users_TO_comments_1" FOREIGN KEY (
	"author_id"
)
REFERENCES "users" (
	"id"
);

ALTER TABLE "course_bookmarks" ADD CONSTRAINT "FK_users_TO_course_bookmarks_1" FOREIGN KEY (
	"user_id"
)
REFERENCES "users" (
	"id"
);

ALTER TABLE "course_bookmarks" ADD CONSTRAINT "FK_courses_TO_course_bookmarks_1" FOREIGN KEY (
	"course_id"
)
REFERENCES "courses" (
	"id"
);

ALTER TABLE "user_devices" ADD CONSTRAINT "FK_users_TO_user_devices_1" FOREIGN KEY (
	"user_id"
)
REFERENCES "users" (
	"id"
);

ALTER TABLE "user_settings" ADD CONSTRAINT "FK_users_TO_user_settings_1" FOREIGN KEY (
	"user_id"
)
REFERENCES "users" (
	"id"
);

ALTER TABLE "user_follows" ADD CONSTRAINT "FK_users_TO_user_follows_1" FOREIGN KEY (
	"follower_id"
)
REFERENCES "users" (
	"id"
);

ALTER TABLE "user_follows" ADD CONSTRAINT "FK_users_TO_user_follows_2" FOREIGN KEY (
	"followee_id"
)
REFERENCES "users" (
	"id"
);

ALTER TABLE "notifications" ADD CONSTRAINT "FK_users_TO_notifications_1" FOREIGN KEY (
	"user_id"
)
REFERENCES "users" (
	"id"
);

ALTER TABLE "running_metric_samples" ADD CONSTRAINT "FK_running_sessions_TO_running_metric_samples_1" FOREIGN KEY (
	"running_session_id"
)
REFERENCES "running_sessions" (
	"id"
);

ALTER TABLE "running_metric_samples" ADD CONSTRAINT "FK_user_devices_TO_running_metric_samples_1" FOREIGN KEY (
	"device_id"
)
REFERENCES "user_devices" (
	"id"
);

ALTER TABLE "courses" ADD CONSTRAINT "FK_regions_TO_courses_1" FOREIGN KEY (
	"region_code"
)
REFERENCES "regions" (
	"region_code"
);
