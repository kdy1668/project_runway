# RunWay DB 테이블 상세 설명서 (v5)

> 목적: AI 코딩 도구 및 팀원이 **DB 테이블의 실제 역할과 컬럼 정의를 정확히 확인**하는 자료. AI 모델 구현, Redis 처리, API 개발 지침은 이 문서의 범위가 아니다.

**기준 스키마:** [`schema.sql`](schema.sql) (PostgreSQL 15+ / PostGIS 3+). 테이블·컬럼·FK·제약사항은 해당 SQL을 기준으로 기술했다.

**총 45개 테이블.** 테이블명/컬럼명은 실제 DDL 표기를 따른다.

## 문서 사용 기준

- **사실:** 컬럼 타입, NULL, FK, CHECK, UNIQUE, 삭제 동작은 DDL에서 확인된 항목만 기록한다.
- **설계 의도:** 역할·데이터 수명 주기는 프로젝트에서 합의한 방향이며, DB 제약으로 강제하지 않는 로직은 별도 표시한다.
- JSONB 내부 키, 이벤트 상태 전이, 실데이터 보존 기간은 DDL만으로 확정되지 않는다. 임의의 스키마를 가정하지 않는다.
- 일부 열의 `DEFAULT`는 DB 기본값이고 실제 `updated_at` 자동 갱신은 트리거 정의가 없다면 서비스 코드 책임이다.

## 도메인별 목록

- **사용자·인증·개인화 (9):** `users`, `auth_identities`, `user_running_profiles`, `user_privacy_settings`, `user_running_baselines`, `environment_types`, `user_environment_preferences`, `runner_parameters`, `bpm_profiles`
- **삼성 헬스·워치·동기화 (12):** `wearable_devices`, `user_consent_events`, `sync_batches`, `sync_stream_progress`, `external_health_records`, `sleep_records`, `sleep_sessions`, `sleep_stages`, `daily_heart_rate_samples`, `daily_activity_summaries`, `daily_health_snapshots`, `readiness_assessments`
- **러닝·AI (12):** `running_sessions`, `running_metric_samples`, `running_route_points`, `running_events`, `running_splits`, `pace_plans`, `pace_plan_segments`, `pace_predictions`, `physiology_predictions`, `cue_predictions`, `canonical_running_samples`, `coaching_events`
- **코스 (3):** `courses`, `course_environment_tags`, `course_bookmarks`
- **그룹런·커뮤니티 (9):** `crews`, `crew_memberships`, `group_runs`, `group_run_participants`, `group_pace_events`, `notifications`, `posts`, `comments`, `post_reactions`

## 테이블 상세 설명

## 사용자·인증·개인화
### `users`

**역할:** RunWay의 내부 사용자 식별자와 기본 계정 상태를 관리.

**생성·변경·삭제 시점(설계 의도):** 회원가입 시 생성, 프로필 수정 시 갱신, 탈퇴 정책에 따라 상태 변경.

**다른 테이블과 구분:** 소셜 인증 주체는 auth_identities에 저장.

**기본 키:** `id`

**컬럼 명세**

| 컬럼 | SQL 타입 | NULL 허용 | 의미 |
|---|---|---|---|
| `id` | `UUID` | 불가 | 행 식별자(UUID); 기본값 `gen_random_uuid()` |
| `nickname` | `VARCHAR(50)` | 불가 | nickname 값 |
| `gender` | `VARCHAR(20)` | 가능 | gender 값 |
| `age_group` | `VARCHAR(20)` | 가능 | age group 값 |
| `status` | `VARCHAR(20)` | 불가 | 현재 처리·진행 상태; 기본값 `'ACTIVE'` |
| `created_at` | `TIMESTAMPTZ` | 불가 | DB 행 생성 시각; 기본값 `now()` |
| `updated_at` | `TIMESTAMPTZ` | 불가 | 마지막 수정 시각; 기본값 `now()` |
| `deleted_at` | `TIMESTAMPTZ` | 가능 | 논리 삭제 시각(NULL이면 미삭제) |

**참조 관계·삭제 동작**

- 이 테이블의 컬럼에 직접 선언된 FK 없음.

**CHECK:** `status IN ('ACTIVE','SUSPENDED','DELETED')`.


### `auth_identities`

**역할:** 외부 인증 제공자 계정을 RunWay 사용자에 연결.

**생성·변경·삭제 시점(설계 의도):** 인증 계정 연결 시 생성, 연결 해제 시 시각 기록.

**다른 테이블과 구분:** (issuer, subject) 유일성으로 외부 계정 중복 연결 방지.

**기본 키:** `id`

**컬럼 명세**

| 컬럼 | SQL 타입 | NULL 허용 | 의미 |
|---|---|---|---|
| `id` | `UUID` | 불가 | 행 식별자(UUID); 기본값 `gen_random_uuid()` |
| `user_id` | `UUID` | 불가 | 내부 사용자 ID |
| `issuer` | `VARCHAR(80)` | 불가 | issuer 값 |
| `subject` | `VARCHAR(255)` | 불가 | subject 값 |
| `linked_at` | `TIMESTAMPTZ` | 불가 | linked 시각; 기본값 `now()` |
| `unlinked_at` | `TIMESTAMPTZ` | 가능 | unlinked 시각 |

**참조 관계·삭제 동작**

- `user_id` → `users(id)`: `ON DELETE RESTRICT` (`fk_auth_identities_user_id`)

**UNIQUE:** `(issuer, subject)`.


### `user_running_profiles`

**역할:** 사용자 입력 수준과 시스템 평가 러닝 수준을 구분.

**생성·변경·삭제 시점(설계 의도):** 온보딩 때 생성, 수준 입력·평가 후 갱신.

**다른 테이블과 구분:** 사용자 자기 평가와 시스템 평가를 혼용하지 않음.

**기본 키:** `user_id`

**컬럼 명세**

| 컬럼 | SQL 타입 | NULL 허용 | 의미 |
|---|---|---|---|
| `user_id` | `UUID` | 불가 | 내부 사용자 ID |
| `self_reported_level` | `VARCHAR(20)` | 불가 | 등급 또는 수준 |
| `assessed_level` | `VARCHAR(20)` | 가능 | 등급 또는 수준 |
| `assessed_at` | `TIMESTAMPTZ` | 가능 | assessed 시각 |
| `created_at` | `TIMESTAMPTZ` | 불가 | DB 행 생성 시각; 기본값 `now()` |
| `updated_at` | `TIMESTAMPTZ` | 불가 | 마지막 수정 시각; 기본값 `now()` |

**참조 관계·삭제 동작**

- `user_id` → `users(id)`: `ON DELETE RESTRICT` (`fk_user_running_profiles_user_id`)

**CHECK:** `self_reported_level IN ('BEGINNER','INTERMEDIATE','ADVANCED')`; `assessed_level IS NULL OR assessed_level IN ('BEGINNER','INTERMEDIATE','ADVANCED')`.


### `user_privacy_settings`

**역할:** 프로필·러닝·위치의 기본 공개 설정 관리.

**생성·변경·삭제 시점(설계 의도):** 기본 설정 생성, 사용자 설정 변경 시 갱신.

**다른 테이블과 구분:** 개별 기록의 visibility와 기본 설정은 별개.

**기본 키:** `user_id`

**컬럼 명세**

| 컬럼 | SQL 타입 | NULL 허용 | 의미 |
|---|---|---|---|
| `user_id` | `UUID` | 불가 | 내부 사용자 ID |
| `profile_visibility` | `VARCHAR(20)` | 불가 | profile visibility 값; 기본값 `'PRIVATE'` |
| `default_session_visibility` | `VARCHAR(20)` | 불가 | default session visibility 값; 기본값 `'PRIVATE'` |
| `default_location_visibility` | `VARCHAR(20)` | 불가 | default location visibility 값; 기본값 `'PRIVATE'` |
| `updated_at` | `TIMESTAMPTZ` | 불가 | 마지막 수정 시각; 기본값 `now()` |

**참조 관계·삭제 동작**

- `user_id` → `users(id)`: `ON DELETE RESTRICT` (`fk_user_privacy_settings_user_id`)

**CHECK:** `profile_visibility IN ('PUBLIC','PRIVATE')`; `default_session_visibility IN ('PUBLIC','PRIVATE')`; `default_location_visibility IN ('PUBLIC','PRIVATE')`.


### `user_running_baselines`

**역할:** 개인화 추천에 활용하는 사용자의 평소 러닝 페이스 또는 기준 거리·완주 시간.

**생성·변경·삭제 시점(설계 의도):** 초기 러닝 프로필 설정 시 생성하고 마이페이지에서 변경할 때 갱신.

**다른 테이블과 구분:** 특정 러닝의 목표가 아니며 `running_sessions`의 최초 목표로 자동 복사하지 않는다. 코스 추천 조건과 세션 목표는 요청별로 별도 관리한다.

**기본 키:** `user_id`

**컬럼 명세**

| 컬럼 | SQL 타입 | NULL 허용 | 의미 |
|---|---|---|---|
| `user_id` | `UUID` | 불가 | 내부 사용자 ID |
| `usual_pace_sec_per_km` | `NUMERIC(10,2)` | 불가 | 입력하거나 기준 거리·시간으로 계산한 평소 페이스 (초/km) |
| `baseline_distance_m` | `INTEGER` | 가능 | `DISTANCE_TIME` 입력 시 평소 러닝 기준 거리 (m) |
| `baseline_duration_sec` | `INTEGER` | 가능 | `DISTANCE_TIME` 입력 시 기준 거리의 평소 완주 시간 (초) |
| `input_type` | `VARCHAR(20)` | 불가 | 입력 방식: `PACE` 또는 `DISTANCE_TIME` |
| `updated_at` | `TIMESTAMPTZ` | 불가 | 마지막 수정 시각; 기본값 `now()` |

**참조 관계·삭제 동작**

- `user_id` → `users(id)`: `ON DELETE RESTRICT` (`fk_user_running_baselines_user_id`)

**CHECK:** `usual_pace_sec_per_km > 0`; 기준 거리·시간은 값이 있으면 양수; `input_type IN ('PACE','DISTANCE_TIME')`; `PACE`이면 기준 거리·시간은 `NULL`, `DISTANCE_TIME`이면 두 값 모두 필수 (`chk_user_running_baselines_input`).


### `environment_types`

**역할:** 코스 환경 유형의 공통 코드.

**생성·변경·삭제 시점(설계 의도):** 관리자가 유형을 등록·비활성화.

**다른 테이블과 구분:** 코스 및 사용자 선호의 공통 참조 코드.

**기본 키:** `id`

**컬럼 명세**

| 컬럼 | SQL 타입 | NULL 허용 | 의미 |
|---|---|---|---|
| `id` | `UUID` | 불가 | 행 식별자(UUID); 기본값 `gen_random_uuid()` |
| `name` | `VARCHAR(40)` | 불가 | name 값 |
| `is_active` | `BOOLEAN` | 불가 | is active 값; 기본값 `TRUE` |

**참조 관계·삭제 동작**

- 이 테이블의 컬럼에 직접 선언된 FK 없음.

**UNIQUE:** `(name)`.


### `user_environment_preferences`

**역할:** 사용자가 선호하는 코스 환경 유형 연결.

**생성·변경·삭제 시점(설계 의도):** 선호 선택 시 추가, 선택 해제 시 관계 제거.

**다른 테이블과 구분:** 사용자와 환경 유형 간 다대다.

**기본 키:** `user_id, environment_id`

**컬럼 명세**

| 컬럼 | SQL 타입 | NULL 허용 | 의미 |
|---|---|---|---|
| `user_id` | `UUID` | 불가 | 내부 사용자 ID |
| `environment_id` | `UUID` | 불가 | environment 참조 식별자 |

**참조 관계·삭제 동작**

- `user_id` → `users(id)`: `ON DELETE RESTRICT` (`fk_user_environment_preferences_user_id`)
- `environment_id` → `environment_types(id)`: `ON DELETE RESTRICT` (`fk_user_environment_preferences_environment_id`)


### `runner_parameters`

**역할:** 장기 러너 특성·개인화 파라미터의 적용 이력.

**생성·변경·삭제 시점(설계 의도):** 학습/보정 결과 변경 시 기존 행 수정 대신 INSERT.

**다른 테이블과 구분:** 현재 BPM 보정 진행 상태는 bpm_profiles.

**기본 키:** `id`

**컬럼 명세**

| 컬럼 | SQL 타입 | NULL 허용 | 의미 |
|---|---|---|---|
| `id` | `UUID` | 불가 | 행 식별자(UUID); 기본값 `gen_random_uuid()` |
| `user_id` | `UUID` | 불가 | 내부 사용자 ID |
| `source_session_id` | `UUID` | 가능 | 코스의 원본 러닝 세션 ID (선택) |
| `parameter_data` | `JSONB` | 불가 | parameter data 값 |
| `created_at` | `TIMESTAMPTZ` | 불가 | DB 행 생성 시각; 기본값 `now()` |
| `applied_at` | `TIMESTAMPTZ` | 가능 | 안내·페이스 적용 시각 |

**참조 관계·삭제 동작**

- `user_id` → `users(id)`: `ON DELETE RESTRICT` (`fk_runner_parameters_user_id`)
- `source_session_id` → `running_sessions(id)`: `ON DELETE SET NULL` (`fk_runner_parameters_source_session_id`)


### `bpm_profiles`

**역할:** 사용자별 최신 BPM 보정 상태와 보폭·Cue 반응 특성.

**생성·변경·삭제 시점(설계 의도):** 초기 설정 후 보정 결과에 따라 갱신.

**다른 테이블과 구분:** 장기 파라미터 이력과 현재 상태의 원본 책임 구분.

**기본 키:** `user_id`

**컬럼 명세**

| 컬럼 | SQL 타입 | NULL 허용 | 의미 |
|---|---|---|---|
| `user_id` | `UUID` | 불가 | 내부 사용자 ID |
| `runner_parameter_id` | `UUID` | 가능 | 러너 파라미터 이력 ID |
| `initial_bpm` | `SMALLINT` | 가능 | initial (BPM) |
| `step_length_m` | `NUMERIC(6,3)` | 가능 | step length (m) |
| `preferred_cadence_spm` | `NUMERIC(7,2)` | 가능 | preferred cadence (걸음/분) |
| `calibration_state` | `VARCHAR(20)` | 불가 | calibration state 값; 기본값 `'INITIAL'` |
| `confidence` | `NUMERIC(4,3)` | 가능 | confidence 값 |
| `calibrated_at` | `TIMESTAMPTZ` | 가능 | calibrated 시각 |
| `updated_at` | `TIMESTAMPTZ` | 불가 | 마지막 수정 시각; 기본값 `now()` |

**참조 관계·삭제 동작**

- `user_id` → `users(id)`: `ON DELETE RESTRICT` (`fk_bpm_profiles_user_id`)
- `runner_parameter_id` → `runner_parameters(id)`: `ON DELETE SET NULL` (`fk_bpm_profiles_runner_parameter_id`)

**CHECK:** `calibration_state IN ('INITIAL','CALIBRATING','CALIBRATED')`; `confidence IS NULL OR confidence BETWEEN 0 AND 1`.


## 삼성 헬스·워치·동기화
### `wearable_devices`

**역할:** 앱 설치 단위의 워치·폰 연결 및 지원 기능 관리.

**생성·변경·삭제 시점(설계 의도):** 기기 등록·연결 상태 변경 시 갱신.

**다른 테이블과 구분:** installation_id는 하드웨어 고유 ID가 아님.

**기본 키:** `id`

**컬럼 명세**

| 컬럼 | SQL 타입 | NULL 허용 | 의미 |
|---|---|---|---|
| `id` | `UUID` | 불가 | 행 식별자(UUID); 기본값 `gen_random_uuid()` |
| `user_id` | `UUID` | 불가 | 내부 사용자 ID |
| `installation_id` | `UUID` | 불가 | 클라이언트 앱 설치 식별 UUID |
| `device_type` | `VARCHAR(20)` | 불가 | 데이터 유형 구분값 |
| `manufacturer` | `TEXT` | 가능 | manufacturer 값 |
| `model` | `TEXT` | 가능 | model 값 |
| `os_version` | `TEXT` | 가능 | os version 값 |
| `app_version` | `TEXT` | 가능 | app version 값 |
| `capabilities` | `JSONB` | 가능 | capabilities 값 |
| `capabilities_checked_at` | `TIMESTAMPTZ` | 가능 | capabilities checked 시각 |
| `last_seen_at` | `TIMESTAMPTZ` | 가능 | last seen 시각 |
| `unlinked_at` | `TIMESTAMPTZ` | 가능 | unlinked 시각 |
| `created_at` | `TIMESTAMPTZ` | 불가 | DB 행 생성 시각; 기본값 `now()` |

**참조 관계·삭제 동작**

- `user_id` → `users(id)`: `ON DELETE RESTRICT` (`fk_wearable_devices_user_id`)

**UNIQUE:** `(user_id, installation_id)`.

**CHECK:** `device_type IN ('WATCH','PHONE')`.


### `user_consent_events`

**역할:** 건강·위치 데이터 동의 및 철회 이력.

**생성·변경·삭제 시점(설계 의도):** 동의/철회 동작마다 이벤트 INSERT.

**다른 테이블과 구분:** 최신 동의 상태와 실 데이터 삭제는 별도 정책.

**기본 키:** `id`

**컬럼 명세**

| 컬럼 | SQL 타입 | NULL 허용 | 의미 |
|---|---|---|---|
| `id` | `UUID` | 불가 | 행 식별자(UUID); 기본값 `gen_random_uuid()` |
| `user_id` | `UUID` | 불가 | 내부 사용자 ID |
| `consent_type` | `VARCHAR(30)` | 불가 | 데이터 유형 구분값 |
| `policy_version` | `TEXT` | 불가 | policy version 값 |
| `action` | `VARCHAR(10)` | 불가 | action 값 |
| `recorded_at` | `TIMESTAMPTZ` | 불가 | recorded 시각; 기본값 `now()` |

**참조 관계·삭제 동작**

- `user_id` → `users(id)`: `ON DELETE RESTRICT` (`fk_user_consent_events_user_id`)

**CHECK:** `action IN ('GRANT','REVOKE')`; `consent_type IN ('HEALTH_DATA','LOCATION_DATA')`.


### `sync_batches`

**역할:** 오프라인 수집 데이터의 전송 묶음 및 저장 완료 추적.

**생성·변경·삭제 시점(설계 의도):** 전송 배치 수신 시 생성, 검증·커밋 후 상태 변경.

**다른 테이블과 구분:** 측정값별 ID와 배치 ID는 서로 다른 중복 방지 단위.

**기본 키:** `id`

**컬럼 명세**

| 컬럼 | SQL 타입 | NULL 허용 | 의미 |
|---|---|---|---|
| `id` | `UUID` | 불가 | 행 식별자(UUID) |
| `user_id` | `UUID` | 불가 | 내부 사용자 ID |
| `device_id` | `UUID` | 불가 | 등록 기기 ID |
| `session_id` | `UUID` | 가능 | 러닝 세션 ID |
| `schema_version` | `VARCHAR(40)` | 불가 | schema version 값 |
| `payload_hash` | `TEXT` | 불가 | 전송 배치 내용의 무결성 검사용 해시 |
| `status` | `VARCHAR(20)` | 불가 | 현재 처리·진행 상태; 기본값 `'RECEIVED'` |
| `accepted_count` | `INTEGER` | 불가 | 관련 항목 수; 기본값 `0` |
| `received_at` | `TIMESTAMPTZ` | 불가 | 서버가 측정값을 수신한 시각; 기본값 `now()` |
| `committed_at` | `TIMESTAMPTZ` | 가능 | committed 시각 |

**참조 관계·삭제 동작**

- `user_id` → `users(id)`: `ON DELETE RESTRICT` (`fk_sync_batches_user_id`)
- `device_id` → `wearable_devices(id)`: `ON DELETE RESTRICT` (`fk_sync_batches_device_id`)
- `session_id` → `running_sessions(id)`: `ON DELETE SET NULL` (`fk_sync_batches_session_id`)

**CHECK:** `status IN ('RECEIVED','COMMITTED','REJECTED')`; `accepted_count >= 0`.


### `sync_stream_progress`

**역할:** 기기별 수신 스트림의 연속 처리 위치 추적.

**생성·변경·삭제 시점(설계 의도):** 영속 저장이 확인된 연속 순서가 진행될 때 갱신.

**다른 테이블과 구분:** 배치 상태와 별도로 누락 구간 판별에 활용.

**기본 키:** `device_id, stream_key`

**컬럼 명세**

| 컬럼 | SQL 타입 | NULL 허용 | 의미 |
|---|---|---|---|
| `device_id` | `UUID` | 불가 | 등록 기기 ID |
| `stream_key` | `VARCHAR(100)` | 불가 | stream key 값 |
| `last_contiguous_sequence` | `BIGINT` | 불가 | 해당 스트림에서 누락 없이 처리한 마지막 연속 순서; 기본값 `0` |
| `updated_at` | `TIMESTAMPTZ` | 불가 | 마지막 수정 시각; 기본값 `now()` |

**참조 관계·삭제 동작**

- `device_id` → `wearable_devices(id)`: `ON DELETE CASCADE` (`fk_sync_stream_progress_device_id`)

**CHECK:** `last_contiguous_sequence >= 0`.


### `external_health_records`

**역할:** Samsung Health 등 외부 원천 건강 기록의 출처·중복 식별.

**생성·변경·삭제 시점(설계 의도):** 외부 기록 반입 시 생성, 변경/삭제 반영 시 갱신.

**다른 테이블과 구분:** 건강 지표별 상세 내용은 하위 테이블에 저장.

**기본 키:** `id`

**컬럼 명세**

| 컬럼 | SQL 타입 | NULL 허용 | 의미 |
|---|---|---|---|
| `id` | `UUID` | 불가 | 행 식별자(UUID); 기본값 `gen_random_uuid()` |
| `user_id` | `UUID` | 불가 | 내부 사용자 ID |
| `provider` | `VARCHAR(40)` | 불가 | provider 값 |
| `record_type` | `VARCHAR(40)` | 불가 | 데이터 유형 구분값 |
| `source_id` | `TEXT` | 불가 | 외부 제공자가 부여한 원천 기록 식별자 |
| `source_updated_at` | `TIMESTAMPTZ` | 가능 | source updated 시각 |
| `source_device_identifier` | `TEXT` | 가능 | source device identifier 값 |
| `imported_at` | `TIMESTAMPTZ` | 불가 | imported 시각; 기본값 `now()` |
| `deleted_at` | `TIMESTAMPTZ` | 가능 | 논리 삭제 시각(NULL이면 미삭제) |
| `source_metadata` | `JSONB` | 가능 | 외부 원본 데이터의 출처·기타 메타데이터 (JSONB) |

**참조 관계·삭제 동작**

- `user_id` → `users(id)`: `ON DELETE RESTRICT` (`fk_external_health_records_user_id`)

**UNIQUE:** `(user_id, provider, record_type, source_id)`.


### `sleep_records`

**역할:** 외부 수면 기록의 상위 단위 및 수면 요약.

**생성·변경·삭제 시점(설계 의도):** 수면 기록 동기화 시 생성·갱신.

**다른 테이블과 구분:** sleep_sessions / sleep_stages와 구별.

**기본 키:** `id`

**컬럼 명세**

| 컬럼 | SQL 타입 | NULL 허용 | 의미 |
|---|---|---|---|
| `id` | `UUID` | 불가 | 행 식별자(UUID); 기본값 `gen_random_uuid()` |
| `external_record_id` | `UUID` | 불가 | external record 참조 식별자 |
| `started_at` | `TIMESTAMPTZ` | 불가 | 시작 시각 |
| `ended_at` | `TIMESTAMPTZ` | 불가 | 종료 시각 |
| `total_sleep_duration_sec` | `INTEGER` | 가능 | total sleep duration (초) |
| `sleep_score` | `NUMERIC(5,2)` | 가능 | 점수 (산식·범위는 구현 확인) |

**참조 관계·삭제 동작**

- `external_record_id` → `external_health_records(id)`: `ON DELETE RESTRICT` (`fk_sleep_records_external_record_id`)

**UNIQUE:** `(external_record_id)`.

**CHECK:** `ended_at > started_at`; `total_sleep_duration_sec IS NULL OR total_sleep_duration_sec >= 0`.


### `sleep_sessions`

**역할:** 하나의 수면 기록을 구성하는 실제 수면 구간.

**생성·변경·삭제 시점(설계 의도):** 수면 기록 동기화 시 생성·갱신.

**다른 테이블과 구분:** 수면 단계보다 큰 시간 구간.

**기본 키:** `id`

**컬럼 명세**

| 컬럼 | SQL 타입 | NULL 허용 | 의미 |
|---|---|---|---|
| `id` | `UUID` | 불가 | 행 식별자(UUID); 기본값 `gen_random_uuid()` |
| `sleep_record_id` | `UUID` | 불가 | sleep record 참조 식별자 |
| `session_index` | `INTEGER` | 불가 | session index 값 |
| `started_at` | `TIMESTAMPTZ` | 불가 | 시작 시각 |
| `ended_at` | `TIMESTAMPTZ` | 불가 | 종료 시각 |
| `sleep_duration_sec` | `INTEGER` | 불가 | sleep duration (초) |

**참조 관계·삭제 동작**

- `sleep_record_id` → `sleep_records(id)`: `ON DELETE CASCADE` (`fk_sleep_sessions_sleep_record_id`)

**UNIQUE:** `(sleep_record_id, session_index)`.

**CHECK:** `ended_at > started_at`; `sleep_duration_sec >= 0`.


### `sleep_stages`

**역할:** 수면 세션 안의 수면 단계별 구간 기록.

**생성·변경·삭제 시점(설계 의도):** 수면 단계 동기화 시 생성·갱신.

**다른 테이블과 구분:** 수면 시간 및 단계 특성 추출의 원천.

**기본 키:** `id`

**컬럼 명세**

| 컬럼 | SQL 타입 | NULL 허용 | 의미 |
|---|---|---|---|
| `id` | `UUID` | 불가 | 행 식별자(UUID); 기본값 `gen_random_uuid()` |
| `sleep_session_id` | `UUID` | 불가 | sleep session 참조 식별자 |
| `stage_index` | `INTEGER` | 불가 | stage index 값 |
| `started_at` | `TIMESTAMPTZ` | 불가 | 시작 시각 |
| `ended_at` | `TIMESTAMPTZ` | 불가 | 종료 시각 |
| `stage_type` | `VARCHAR(30)` | 불가 | 데이터 유형 구분값 |

**참조 관계·삭제 동작**

- `sleep_session_id` → `sleep_sessions(id)`: `ON DELETE CASCADE` (`fk_sleep_stages_sleep_session_id`)

**UNIQUE:** `(sleep_session_id, stage_index)`.

**CHECK:** `ended_at > started_at`.


### `daily_heart_rate_samples`

**역할:** 일상 생활 심박 측정 기록 보관.

**생성·변경·삭제 시점(설계 의도):** 외부 심박 데이터 동기화 시 생성·갱신.

**다른 테이블과 구분:** 운동 중 HR은 running_metric_samples에 별도 기록.

**기본 키:** `external_record_id, source_index`

**컬럼 명세**

| 컬럼 | SQL 타입 | NULL 허용 | 의미 |
|---|---|---|---|
| `external_record_id` | `UUID` | 불가 | external record 참조 식별자 |
| `source_index` | `BIGINT` | 불가 | source index 값 |
| `started_at` | `TIMESTAMPTZ` | 불가 | 시작 시각 |
| `ended_at` | `TIMESTAMPTZ` | 불가 | 종료 시각 |
| `heart_rate_bpm` | `NUMERIC(6,2)` | 불가 | 심박수 (bpm) |
| `min_bpm` | `NUMERIC(6,2)` | 가능 | min (BPM) |
| `max_bpm` | `NUMERIC(6,2)` | 가능 | max (BPM) |

**참조 관계·삭제 동작**

- `external_record_id` → `external_health_records(id)`: `ON DELETE RESTRICT` (`fk_daily_heart_rate_samples_external_record_id`)

**CHECK:** `heart_rate_bpm > 0`; `ended_at >= started_at`.


### `daily_activity_summaries`

**역할:** 일자·시간대 기준 일상 활동량 집계.

**생성·변경·삭제 시점(설계 의도):** 외부 일간 집계 수신·갱신 시 반영.

**다른 테이블과 구분:** 여러 기기 중복 합산 정책은 코드에서 정의해야 함.

**기본 키:** `user_id, local_date, time_zone, source_policy`

**컬럼 명세**

| 컬럼 | SQL 타입 | NULL 허용 | 의미 |
|---|---|---|---|
| `user_id` | `UUID` | 불가 | 내부 사용자 ID |
| `local_date` | `DATE` | 불가 | local date 값 |
| `time_zone` | `TEXT` | 불가 | time zone 값 |
| `source_policy` | `VARCHAR(40)` | 불가 | source policy 값 |
| `steps` | `BIGINT` | 가능 | steps 값 |
| `active_duration_sec` | `INTEGER` | 가능 | active duration (초) |
| `distance_m` | `NUMERIC(12,2)` | 가능 | 거리 (m) |
| `active_calories_kcal` | `NUMERIC(10,2)` | 가능 | active calories (kcal) |
| `total_calories_kcal` | `NUMERIC(10,2)` | 가능 | total calories (kcal) |
| `updated_at` | `TIMESTAMPTZ` | 불가 | 마지막 수정 시각; 기본값 `now()` |

**참조 관계·삭제 동작**

- `user_id` → `users(id)`: `ON DELETE RESTRICT` (`fk_daily_activity_summaries_user_id`)

**CHECK:** `steps IS NULL OR steps >= 0`.


### `daily_health_snapshots`

**역할:** 준비도 계산에 필요한 하루 건강 요약값.

**생성·변경·삭제 시점(설계 의도):** 건강 원천 집계 결과 생성·갱신.

**다른 테이블과 구분:** 상세 수면/심박 원본을 대체하지 않음.

**기본 키:** `id`

**컬럼 명세**

| 컬럼 | SQL 타입 | NULL 허용 | 의미 |
|---|---|---|---|
| `id` | `UUID` | 불가 | 행 식별자(UUID); 기본값 `gen_random_uuid()` |
| `user_id` | `UUID` | 불가 | 내부 사용자 ID |
| `measured_at` | `TIMESTAMPTZ` | 불가 | 센서가 실제로 측정한 시각 |
| `sleep_duration_min` | `INTEGER` | 가능 | sleep duration min 값 |
| `daily_steps` | `INTEGER` | 가능 | daily steps 값 |
| `activity_duration_min` | `INTEGER` | 가능 | activity duration min 값 |
| `resting_heart_rate` | `SMALLINT` | 가능 | resting heart rate 값 |
| `source_data` | `JSONB` | 가능 | source data 값 |
| `created_at` | `TIMESTAMPTZ` | 불가 | DB 행 생성 시각; 기본값 `now()` |

**참조 관계·삭제 동작**

- `user_id` → `users(id)`: `ON DELETE RESTRICT` (`fk_daily_health_snapshots_user_id`)


### `readiness_assessments`

**역할:** 운동 준비도 점수·평가 근거 기록.

**생성·변경·삭제 시점(설계 의도):** 사용자 상태 평가를 수행할 때 생성.

**다른 테이블과 구분:** 점수와 실제 원천 입력은 분리.

**기본 키:** `id`

**컬럼 명세**

| 컬럼 | SQL 타입 | NULL 허용 | 의미 |
|---|---|---|---|
| `id` | `UUID` | 불가 | 행 식별자(UUID); 기본값 `gen_random_uuid()` |
| `user_id` | `UUID` | 불가 | 내부 사용자 ID |
| `health_snapshot_id` | `UUID` | 가능 | health snapshot 참조 식별자 |
| `session_id` | `UUID` | 가능 | 러닝 세션 ID |
| `subjective_condition` | `VARCHAR(30)` | 가능 | subjective condition 값 |
| `readiness_score` | `NUMERIC(5,2)` | 가능 | 점수 (산식·범위는 구현 확인) |
| `readiness_level` | `VARCHAR(30)` | 가능 | 등급 또는 수준 |
| `feature_snapshot` | `JSONB` | 불가 | feature snapshot 값; 기본값 `'{}'::jsonb` |
| `reason_details` | `JSONB` | 가능 | 부가 구조화 정보 (JSONB인 경우 내부 키 별도 정의 필요) |
| `assessed_at` | `TIMESTAMPTZ` | 불가 | assessed 시각; 기본값 `now()` |

**참조 관계·삭제 동작**

- `user_id` → `users(id)`: `ON DELETE RESTRICT` (`fk_readiness_assessments_user_id`)
- `health_snapshot_id` → `daily_health_snapshots(id)`: `ON DELETE SET NULL` (`fk_readiness_assessments_health_snapshot_id`)
- `session_id` → `running_sessions(id)`: `ON DELETE SET NULL` (`fk_readiness_assessments_session_id`)

**CHECK:** `readiness_score IS NULL OR readiness_score BETWEEN 0 AND 100`.


## 러닝·AI
### `running_sessions`

**역할:** 개인·그룹 공통 개별 러닝 세션과 최초 목표·집계.

**생성·변경·삭제 시점(설계 의도):** 러닝 시작 시 생성, 진행·종료 시 상태/결과 갱신.

**다른 테이블과 구분:** 그룹 참가자와 연결되더라도 사용자별 세션은 별도.

**기본 키:** `id`

**컬럼 명세**

| 컬럼 | SQL 타입 | NULL 허용 | 의미 |
|---|---|---|---|
| `id` | `UUID` | 불가 | 행 식별자(UUID); 기본값 `gen_random_uuid()` |
| `user_id` | `UUID` | 불가 | 내부 사용자 ID |
| `course_id` | `UUID` | 가능 | 코스 ID |
| `status` | `VARCHAR(20)` | 불가 | 현재 처리·진행 상태; 기본값 `'READY'` |
| `target_distance_m` | `INTEGER` | 불가 | 목표 거리 (m) |
| `target_duration_sec` | `INTEGER` | 불가 | 목표 완주 시간 (초) |
| `started_at` | `TIMESTAMPTZ` | 가능 | 시작 시각 |
| `ended_at` | `TIMESTAMPTZ` | 가능 | 종료 시각 |
| `moving_duration_sec` | `INTEGER` | 가능 | moving duration (초) |
| `elapsed_duration_sec` | `INTEGER` | 가능 | elapsed duration (초) |
| `total_distance_m` | `NUMERIC(12,2)` | 가능 | total distance (m) |
| `average_pace_sec_per_km` | `NUMERIC(10,2)` | 가능 | average pace sec per km 값 |
| `average_heart_rate` | `NUMERIC(6,2)` | 가능 | average heart rate 값 |
| `average_cadence` | `NUMERIC(6,2)` | 가능 | average cadence 값 |
| `goal_achieved` | `BOOLEAN` | 가능 | goal achieved 값 |
| `visibility` | `VARCHAR(20)` | 불가 | visibility 값; 기본값 `'PRIVATE'` |
| `created_at` | `TIMESTAMPTZ` | 불가 | DB 행 생성 시각; 기본값 `now()` |
| `deleted_at` | `TIMESTAMPTZ` | 가능 | 논리 삭제 시각(NULL이면 미삭제) |

**참조 관계·삭제 동작**

- `user_id` → `users(id)`: `ON DELETE RESTRICT` (`fk_running_sessions_user_id`)
- `course_id` → `courses(id)`: `ON DELETE SET NULL` (`fk_running_sessions_course_id`)

**UNIQUE:** `(id, user_id)`.

**CHECK:** `status IN ('READY','RUNNING','PAUSED','COMPLETED','CANCELLED')`; `target_distance_m > 0`; `target_duration_sec > 0`; `visibility IN ('PRIVATE','PUBLIC')`.


### `running_metric_samples`

**역할:** 러닝 중 심박·케이던스·속도 등 숫자 센서의 원천 표본.

**생성·변경·삭제 시점(설계 의도):** 측정값 수신 시 멱등 INSERT.

**다른 테이블과 구분:** GPS는 running_route_points, 정제 표본은 canonical_running_samples.

**기본 키:** `id`

**컬럼 명세**

| 컬럼 | SQL 타입 | NULL 허용 | 의미 |
|---|---|---|---|
| `id` | `UUID` | 불가 | 행 식별자(UUID) |
| `session_id` | `UUID` | 불가 | 러닝 세션 ID |
| `device_id` | `UUID` | 가능 | 등록 기기 ID |
| `metric_type` | `VARCHAR(40)` | 불가 | 데이터 유형 구분값 |
| `measured_at` | `TIMESTAMPTZ` | 불가 | 센서가 실제로 측정한 시각 |
| `received_at` | `TIMESTAMPTZ` | 불가 | 서버가 측정값을 수신한 시각; 기본값 `now()` |
| `sequence_no` | `BIGINT` | 가능 | sequence no 값 |
| `value` | `NUMERIC(14,4)` | 가능 | value 값 |
| `unit` | `VARCHAR(30)` | 불가 | unit 값 |
| `quality_status` | `VARCHAR(20)` | 불가 | 현재 처리·진행 상태; 기본값 `'VALID'` |
| `source_metadata` | `JSONB` | 가능 | 외부 원본 데이터의 출처·기타 메타데이터 (JSONB) |

**참조 관계·삭제 동작**

- `session_id` → `running_sessions(id)`: `ON DELETE CASCADE` (`fk_running_metric_samples_session_id`)
- `device_id` → `wearable_devices(id)`: `ON DELETE SET NULL` (`fk_running_metric_samples_device_id`)

**CHECK:** `quality_status IN ('VALID','MISSING','STALE','INVALID')`.


### `running_route_points`

**역할:** 러닝 중 측정한 개별 GPS 좌표·고도·정확도 원천.

**생성·변경·삭제 시점(설계 의도):** GPS 측정 수신 시 멱등 INSERT.

**다른 테이블과 구분:** 코스 LineString이 아니라 Point 단위 이동 기록.

**기본 키:** `id`

**컬럼 명세**

| 컬럼 | SQL 타입 | NULL 허용 | 의미 |
|---|---|---|---|
| `id` | `UUID` | 불가 | 행 식별자(UUID) |
| `session_id` | `UUID` | 불가 | 러닝 세션 ID |
| `device_id` | `UUID` | 가능 | 등록 기기 ID |
| `measured_at` | `TIMESTAMPTZ` | 불가 | 센서가 실제로 측정한 시각 |
| `received_at` | `TIMESTAMPTZ` | 불가 | 서버가 측정값을 수신한 시각; 기본값 `now()` |
| `sequence_no` | `BIGINT` | 가능 | sequence no 값 |
| `position` | `geography(Point,4326)` | 불가 | PostGIS 위치 Point, SRID 4326 |
| `altitude_m` | `NUMERIC(9,2)` | 가능 | altitude (m) |
| `horizontal_accuracy_m` | `NUMERIC(9,2)` | 가능 | horizontal accuracy (m) |
| `quality_status` | `VARCHAR(20)` | 불가 | 현재 처리·진행 상태; 기본값 `'VALID'` |
| `source_metadata` | `JSONB` | 가능 | 외부 원본 데이터의 출처·기타 메타데이터 (JSONB) |

**참조 관계·삭제 동작**

- `session_id` → `running_sessions(id)`: `ON DELETE CASCADE` (`fk_running_route_points_session_id`)
- `device_id` → `wearable_devices(id)`: `ON DELETE SET NULL` (`fk_running_route_points_device_id`)

**CHECK:** `quality_status IN ('VALID','MISSING','STALE','INVALID')`.


### `running_events`

**역할:** 러닝 시작·일시정지·재개·종료 이벤트.

**생성·변경·삭제 시점(설계 의도):** 세션 상태 전이 때 INSERT.

**다른 테이블과 구분:** 측정 시계열의 유효 운동 구간을 판별.

**기본 키:** `id`

**컬럼 명세**

| 컬럼 | SQL 타입 | NULL 허용 | 의미 |
|---|---|---|---|
| `id` | `UUID` | 불가 | 행 식별자(UUID); 기본값 `gen_random_uuid()` |
| `session_id` | `UUID` | 불가 | 러닝 세션 ID |
| `event_type` | `VARCHAR(20)` | 불가 | 데이터 유형 구분값 |
| `occurred_at` | `TIMESTAMPTZ` | 불가 | 이벤트가 발생하거나 판단한 시각 |
| `created_at` | `TIMESTAMPTZ` | 불가 | DB 행 생성 시각; 기본값 `now()` |

**참조 관계·삭제 동작**

- `session_id` → `running_sessions(id)`: `ON DELETE CASCADE` (`fk_running_events_session_id`)

**CHECK:** `event_type IN ('START','PAUSE','RESUME','END')`.


### `running_splits`

**역할:** 실제 달린 거리 구간별 평균 페이스·심박·케이던스 집계.

**생성·변경·삭제 시점(설계 의도):** 운동 진행/종료 후 파생 계산으로 생성·재집계.

**다른 테이블과 구분:** 계획 구간인 pace_plan_segments와 구분.

**기본 키:** `session_id, split_index`

**컬럼 명세**

| 컬럼 | SQL 타입 | NULL 허용 | 의미 |
|---|---|---|---|
| `session_id` | `UUID` | 불가 | 러닝 세션 ID |
| `split_index` | `INTEGER` | 불가 | split index 값 |
| `start_distance_m` | `NUMERIC(12,2)` | 불가 | start distance (m) |
| `end_distance_m` | `NUMERIC(12,2)` | 불가 | end distance (m) |
| `active_duration_sec` | `INTEGER` | 불가 | active duration (초) |
| `average_pace_sec_per_km` | `NUMERIC(10,2)` | 가능 | average pace sec per km 값 |
| `average_heart_rate` | `NUMERIC(6,2)` | 가능 | average heart rate 값 |
| `average_cadence` | `NUMERIC(6,2)` | 가능 | average cadence 값 |
| `created_at` | `TIMESTAMPTZ` | 불가 | DB 행 생성 시각; 기본값 `now()` |

**참조 관계·삭제 동작**

- `session_id` → `running_sessions(id)`: `ON DELETE CASCADE` (`fk_running_splits_session_id`)

**CHECK:** `end_distance_m > start_distance_m`; `active_duration_sec >= 0`.


### `pace_plans`

**역할:** 러닝의 초기·재계산된 전체 페이스 계획.

**생성·변경·삭제 시점(설계 의도):** 최초 생성 및 전략 변경마다 새로운 revision INSERT.

**다른 테이블과 구분:** 최초 목표는 running_sessions에 고정.

**기본 키:** `id`

**컬럼 명세**

| 컬럼 | SQL 타입 | NULL 허용 | 의미 |
|---|---|---|---|
| `id` | `UUID` | 불가 | 행 식별자(UUID); 기본값 `gen_random_uuid()` |
| `session_id` | `UUID` | 불가 | 러닝 세션 ID |
| `revision` | `INTEGER` | 불가 | 계획·이력의 개정 순서 |
| `plan_kind` | `VARCHAR(20)` | 불가 | plan kind 값 |
| `initial_pace_sec_per_km` | `NUMERIC(10,2)` | 불가 | initial pace sec per km 값 |
| `strategy_context` | `JSONB` | 가능 | strategy context 값 |
| `initial_target_bpm` | `SMALLINT` | 가능 | initial target (BPM) |
| `estimated_duration_sec` | `INTEGER` | 가능 | estimated duration (초) |
| `created_at` | `TIMESTAMPTZ` | 불가 | DB 행 생성 시각; 기본값 `now()` |
| `effective_at` | `TIMESTAMPTZ` | 불가 | effective 시각 |

**참조 관계·삭제 동작**

- `session_id` → `running_sessions(id)`: `ON DELETE CASCADE` (`fk_pace_plans_session_id`)

**UNIQUE:** `(session_id, revision)`.

**CHECK:** `revision >= 1`; `plan_kind IN ('INITIAL','ADJUSTED')`; `initial_pace_sec_per_km > 0`.


### `pace_plan_segments`

**역할:** 특정 페이스 계획의 거리 구간별 목표 페이스.

**생성·변경·삭제 시점(설계 의도):** pace_plan 생성 시 구간들 INSERT.

**다른 테이블과 구분:** 실제 기록 구간 running_splits가 아님.

**기본 키:** `plan_id, segment_index`

**컬럼 명세**

| 컬럼 | SQL 타입 | NULL 허용 | 의미 |
|---|---|---|---|
| `plan_id` | `UUID` | 불가 | 페이스 계획 ID |
| `segment_index` | `INTEGER` | 불가 | segment index 값 |
| `start_distance_m` | `NUMERIC(12,2)` | 불가 | start distance (m) |
| `end_distance_m` | `NUMERIC(12,2)` | 불가 | end distance (m) |
| `target_pace_sec_per_km` | `NUMERIC(10,2)` | 불가 | 목표 페이스 (초/km) |
| `target_bpm` | `SMALLINT` | 가능 | target (BPM) |

**참조 관계·삭제 동작**

- `plan_id` → `pace_plans(id)`: `ON DELETE CASCADE` (`fk_pace_plan_segments_plan_id`)

**CHECK:** `end_distance_m > start_distance_m`; `target_pace_sec_per_km > 0`.


### `pace_predictions`

**역할:** 완주시간·부하 등 기존 러닝 전망의 선택적 저장.

**생성·변경·삭제 시점(설계 의도):** 중요 예측 시점에만 INSERT.

**다른 테이블과 구분:** 후보 HR 예측은 physiology_predictions.

**기본 키:** `id`

**컬럼 명세**

| 컬럼 | SQL 타입 | NULL 허용 | 의미 |
|---|---|---|---|
| `id` | `UUID` | 불가 | 행 식별자(UUID); 기본값 `gen_random_uuid()` |
| `session_id` | `UUID` | 불가 | 러닝 세션 ID |
| `runner_parameter_id` | `UUID` | 가능 | 러너 파라미터 이력 ID |
| `predicted_at` | `TIMESTAMPTZ` | 불가 | AI 예측을 수행한 시각 |
| `distance_at_prediction_m` | `NUMERIC(12,2)` | 불가 | distance at prediction (m) |
| `predicted_finish_duration_sec` | `INTEGER` | 가능 | predicted finish duration (초) |
| `predicted_pace_sec_per_km` | `NUMERIC(10,2)` | 가능 | predicted pace sec per km 값 |
| `load_level` | `VARCHAR(30)` | 가능 | 등급 또는 수준 |
| `overpace_detected` | `BOOLEAN` | 가능 | overpace detected 값 |
| `pace_drop_detected` | `BOOLEAN` | 가능 | pace drop detected 값 |
| `prediction_details` | `JSONB` | 가능 | 부가 구조화 정보 (JSONB인 경우 내부 키 별도 정의 필요) |

**참조 관계·삭제 동작**

- `session_id` → `running_sessions(id)`: `ON DELETE CASCADE` (`fk_pace_predictions_session_id`)
- `runner_parameter_id` → `runner_parameters(id)`: `ON DELETE SET NULL` (`fk_pace_predictions_runner_parameter_id`)


### `physiology_predictions`

**역할:** 선택적으로 보존하는 후보 Pace별 미래 HR 예측 스냅샷.

**생성·변경·삭제 시점(설계 의도):** 중요한 모델 예측·페이스 변경 판단 시 INSERT.

**다른 테이블과 구분:** 후보별 +30/+60/+120초 HR 값은 JSONB 배열.

**기본 키:** `id`

**컬럼 명세**

| 컬럼 | SQL 타입 | NULL 허용 | 의미 |
|---|---|---|---|
| `id` | `UUID` | 불가 | 행 식별자(UUID); 기본값 `gen_random_uuid()` |
| `session_id` | `UUID` | 불가 | 러닝 세션 ID |
| `runner_parameter_id` | `UUID` | 가능 | 러너 파라미터 이력 ID |
| `predicted_at` | `TIMESTAMPTZ` | 불가 | AI 예측을 수행한 시각 |
| `elapsed_time_sec` | `NUMERIC(12,3)` | 가능 | elapsed time (초) |
| `input_snapshot` | `JSONB` | 불가 | 예측·판단 당시 입력값 스냅샷 (JSONB) |
| `candidate_hr_forecasts` | `JSONB` | 불가 | 후보 페이스별 미래 심박 예측 배열 (JSONB) |
| `selected_target_pace_sec_per_km` | `NUMERIC(10,2)` | 가능 | selected target pace sec per km 값 |
| `selection_reason` | `JSONB` | 가능 | selection reason 값 |
| `created_at` | `TIMESTAMPTZ` | 불가 | DB 행 생성 시각; 기본값 `now()` |

**참조 관계·삭제 동작**

- `session_id` → `running_sessions(id)`: `ON DELETE CASCADE` (`fk_physiology_predictions_session_id`)
- `runner_parameter_id` → `runner_parameters(id)`: `ON DELETE SET NULL` (`fk_physiology_predictions_runner_parameter_id`)

**CHECK:** `elapsed_time_sec IS NULL OR elapsed_time_sec >= 0`; `selected_target_pace_sec_per_km IS NULL OR selected_target_pace_sec_per_km > 0`; `jsonb_typeof(candidate_hr_forecasts) = 'array'`.


### `cue_predictions`

**역할:** 선택적으로 보존하는 후보 BPM별 미래 SPM/Pace 예측.

**생성·변경·삭제 시점(설계 의도):** 중요한 BPM 선택 시 INSERT.

**다른 테이블과 구분:** 실제 안내/적용 결과는 coaching_events에 저장.

**기본 키:** `id`

**컬럼 명세**

| 컬럼 | SQL 타입 | NULL 허용 | 의미 |
|---|---|---|---|
| `id` | `UUID` | 불가 | 행 식별자(UUID); 기본값 `gen_random_uuid()` |
| `session_id` | `UUID` | 불가 | 러닝 세션 ID |
| `physiology_prediction_id` | `UUID` | 가능 | physiology prediction 참조 식별자 |
| `runner_parameter_id` | `UUID` | 가능 | 러너 파라미터 이력 ID |
| `predicted_at` | `TIMESTAMPTZ` | 불가 | AI 예측을 수행한 시각 |
| `current_bpm` | `NUMERIC(6,2)` | 가능 | current (BPM) |
| `current_spm` | `NUMERIC(8,2)` | 가능 | current (걸음/분) |
| `current_speed_mps` | `NUMERIC(10,4)` | 가능 | current speed mps 값 |
| `target_pace_sec_per_km` | `NUMERIC(10,2)` | 불가 | 목표 페이스 (초/km) |
| `candidate_cue_responses` | `JSONB` | 불가 | 후보 BPM별 미래 SPM/페이스 예측 배열 (JSONB) |
| `selected_bpm` | `NUMERIC(6,2)` | 가능 | selected (BPM) |
| `created_at` | `TIMESTAMPTZ` | 불가 | DB 행 생성 시각; 기본값 `now()` |

**참조 관계·삭제 동작**

- `session_id` → `running_sessions(id)`: `ON DELETE CASCADE` (`fk_cue_predictions_session_id`)
- `physiology_prediction_id` → `physiology_predictions(id)`: `ON DELETE RESTRICT` (`fk_cue_predictions_physiology_prediction_id`)
- `runner_parameter_id` → `runner_parameters(id)`: `ON DELETE SET NULL` (`fk_cue_predictions_runner_parameter_id`)

**CHECK:** `target_pace_sec_per_km > 0`; `jsonb_typeof(candidate_cue_responses) = 'array'`.


### `canonical_running_samples`

**역할:** 러닝 원천 측정을 ETL한 재사용 가능한 시간 정렬 시계열.

**생성·변경·삭제 시점(설계 의도):** 러닝 종료 후 ETL 산출 INSERT·재처리.

**다른 테이블과 구분:** 원본을 덮어쓰지 않고 etl_profile로 산출물 구분.

**기본 키:** `id`

**컬럼 명세**

| 컬럼 | SQL 타입 | NULL 허용 | 의미 |
|---|---|---|---|
| `id` | `UUID` | 불가 | 행 식별자(UUID); 기본값 `gen_random_uuid()` |
| `session_id` | `UUID` | 불가 | 러닝 세션 ID |
| `sampled_at` | `TIMESTAMPTZ` | 불가 | 정제 시계열의 기준 시각 |
| `elapsed_time_sec` | `NUMERIC(12,3)` | 가능 | elapsed time (초) |
| `heart_rate_bpm` | `NUMERIC(7,2)` | 가능 | 심박수 (bpm) |
| `cadence_spm` | `NUMERIC(8,2)` | 가능 | 케이던스 (걸음/분) |
| `speed_mps` | `NUMERIC(10,4)` | 가능 | 속도 (m/s) |
| `pace_sec_per_km` | `NUMERIC(10,2)` | 가능 | 페이스 (초/km) |
| `applied_bpm` | `NUMERIC(7,2)` | 가능 | 실제 적용된 음악/메트로놈 BPM |
| `grade_percent` | `NUMERIC(8,3)` | 가능 | 경사도 (%) |
| `distance_m` | `NUMERIC(12,2)` | 가능 | 거리 (m) |
| `quality_flags` | `JSONB` | 불가 | 정제·결측·이상치 품질 표시 (JSONB); 기본값 `'{}'::jsonb` |
| `etl_profile` | `TEXT` | 불가 | 정제 작업의 처리 방식 식별자 (모델 버전과 별개) |
| `processed_at` | `TIMESTAMPTZ` | 불가 | processed 시각; 기본값 `now()` |

**참조 관계·삭제 동작**

- `session_id` → `running_sessions(id)`: `ON DELETE CASCADE` (`fk_canonical_running_samples_session_id`)

**UNIQUE:** `(session_id, sampled_at, etl_profile)`.

**CHECK:** `elapsed_time_sec IS NULL OR elapsed_time_sec >= 0`; `speed_mps IS NULL OR speed_mps >= 0`; `distance_m IS NULL OR distance_m >= 0`.


### `coaching_events`

**역할:** 개인 페이스·BPM 조정 판단 및 적용·전달 이력.

**생성·변경·삭제 시점(설계 의도):** AI 판단 발생 시 INSERT, 전달·워치 적용 확인 시 상태 갱신.

**다른 테이블과 구분:** 단순 SENT와 실제 워치 적용/확인 구분.

**기본 키:** `id`

**컬럼 명세**

| 컬럼 | SQL 타입 | NULL 허용 | 의미 |
|---|---|---|---|
| `id` | `UUID` | 불가 | 행 식별자(UUID); 기본값 `gen_random_uuid()` |
| `session_id` | `UUID` | 불가 | 러닝 세션 ID |
| `plan_id` | `UUID` | 가능 | 페이스 계획 ID |
| `prediction_id` | `UUID` | 가능 | prediction 참조 식별자 |
| `physiology_prediction_id` | `UUID` | 가능 | physiology prediction 참조 식별자 |
| `cue_prediction_id` | `UUID` | 가능 | cue prediction 참조 식별자 |
| `device_applied_at` | `TIMESTAMPTZ` | 가능 | 기기에서 실제 적용했다고 기록한 시각 |
| `event_type` | `VARCHAR(40)` | 불가 | 데이터 유형 구분값 |
| `reason_code` | `VARCHAR(60)` | 가능 | reason code 값 |
| `previous_pace_sec_per_km` | `NUMERIC(10,2)` | 가능 | previous pace sec per km 값 |
| `new_pace_sec_per_km` | `NUMERIC(10,2)` | 가능 | new pace sec per km 값 |
| `previous_bpm` | `SMALLINT` | 가능 | previous (BPM) |
| `new_bpm` | `SMALLINT` | 가능 | new (BPM) |
| `occurred_at` | `TIMESTAMPTZ` | 불가 | 이벤트가 발생하거나 판단한 시각 |
| `applied_at` | `TIMESTAMPTZ` | 가능 | 안내·페이스 적용 시각 |
| `delivery_status` | `VARCHAR(20)` | 불가 | 현재 처리·진행 상태; 기본값 `'PENDING'` |
| `delivered_at` | `TIMESTAMPTZ` | 가능 | 알림 전송 완료 시각 (사용자 확인과 다름) |
| `input_snapshot` | `JSONB` | 가능 | 예측·판단 당시 입력값 스냅샷 (JSONB) |

**참조 관계·삭제 동작**

- `session_id` → `running_sessions(id)`: `ON DELETE CASCADE` (`fk_coaching_events_session_id`)
- `plan_id` → `pace_plans(id)`: `ON DELETE SET NULL` (`fk_coaching_events_plan_id`)
- `prediction_id` → `pace_predictions(id)`: `ON DELETE SET NULL` (`fk_coaching_events_prediction_id`)
- `physiology_prediction_id` → `physiology_predictions(id)`: `ON DELETE SET NULL` (`fk_coaching_events_physiology_prediction_id`)
- `cue_prediction_id` → `cue_predictions(id)`: `ON DELETE SET NULL` (`fk_coaching_events_cue_prediction_id`)

**CHECK:** `delivery_status IN ('PENDING','SENT','FAILED')`.


## 코스
### `courses`

**역할:** 추천·저장·공유 대상인 정제된 코스 경로.

**생성·변경·삭제 시점(설계 의도):** 코스 등록 또는 생성 시 추가하고, 운영 상태 변경이나 중복 코스 병합 시 갱신.

**다른 테이블과 구분:** 원본 러닝 GPS와 별개인 PostGIS 연속 경로.

**기본 키:** `id`

**컬럼 명세**

| 컬럼 | SQL 타입 | NULL 허용 | 의미 |
|---|---|---|---|
| `id` | `UUID` | 불가 | 행 식별자(UUID); 기본값 `gen_random_uuid()` |
| `creator_id` | `UUID` | 가능 | 코스 생성 사용자 ID. 사용자가 삭제되면 NULL로 변경 |
| `source_session_id` | `UUID` | 가능 | 코스의 원본 러닝 세션 ID (선택) |
| `name` | `VARCHAR(100)` | 불가 | name 값 |
| `description` | `TEXT` | 가능 | description 값 |
| `route` | `geography(LineString,4326)` | 불가 | 코스 경로 (PostGIS LineString, SRID 4326) |
| `start_position` | `geography(Point,4326)` | 불가 | 코스 출발점 (PostGIS Point, SRID 4326) |
| `distance_m` | `NUMERIC(12,2)` | 불가 | 거리 (m) |
| `elevation_gain_m` | `NUMERIC(9,2)` | 가능 | elevation gain (m) |
| `elevation_profile` | `JSONB` | 가능 | elevation profile 값 |
| `source_type` | `VARCHAR(20)` | 불가 | 데이터 유형 구분값; 기본값 `'USER_RUN'` |
| `status` | `VARCHAR(20)` | 불가 | 공용 코스 운영 상태; 기본값 `'ACTIVE'` |
| `merged_into_course_id` | `UUID` | 가능 | 중복 병합 시 대표 코스 ID |
| `created_at` | `TIMESTAMPTZ` | 불가 | DB 행 생성 시각; 기본값 `now()` |
| `updated_at` | `TIMESTAMPTZ` | 불가 | 마지막 수정 시각; 기본값 `now()` |

**참조 관계·삭제 동작**

- `creator_id` → `users(id)`: `ON DELETE SET NULL` (`fk_courses_creator_id`)
- `merged_into_course_id` → `courses(id)`: `ON DELETE RESTRICT` (`fk_courses_merged_into`)
- **예외:** `source_session_id` → `running_sessions(id)`는 순환 참조 때문에 정규 FK가 아니라 `trg_course_source_session_check` / `trg_session_course_source_cleanup` 트리거로 검증·참조 해제를 처리한다.

**CHECK:**

- `distance_m > 0`
- `source_type IN ('USER_RUN','GENERATED')`
- `chk_courses_status`: `status IN ('ACTIVE','MERGED','BLOCKED')`
- `chk_courses_merge`: `MERGED` 상태일 때만 `merged_into_course_id`가 존재한다.
- `chk_courses_no_self_merge`: 자기 자신을 대표 코스로 지정할 수 없다.


### `course_environment_tags`

**역할:** 코스와 환경 유형의 연결.

**생성·변경·삭제 시점(설계 의도):** 코스 환경 태그 추가·제거 시 변경.

**다른 테이블과 구분:** 코스와 환경 유형 간 다대다.

**기본 키:** `course_id, environment_id`

**컬럼 명세**

| 컬럼 | SQL 타입 | NULL 허용 | 의미 |
|---|---|---|---|
| `course_id` | `UUID` | 불가 | 코스 ID |
| `environment_id` | `UUID` | 불가 | environment 참조 식별자 |

**참조 관계·삭제 동작**

- `course_id` → `courses(id)`: `ON DELETE CASCADE` (`fk_course_environment_tags_course_id`)
- `environment_id` → `environment_types(id)`: `ON DELETE CASCADE` (`fk_course_environment_tags_environment_id`)


### `course_bookmarks`

**역할:** 사용자가 저장한 코스의 관계.

**생성·변경·삭제 시점(설계 의도):** 저장 시 추가, 저장 취소 시 제거.

**다른 테이블과 구분:** 코스 상태 변경과 별개로 저장 관계는 유지되며, 코스 행이 삭제되면 함께 삭제된다.

**기본 키:** `user_id, course_id`

**컬럼 명세**

| 컬럼 | SQL 타입 | NULL 허용 | 의미 |
|---|---|---|---|
| `user_id` | `UUID` | 불가 | 내부 사용자 ID |
| `course_id` | `UUID` | 불가 | 코스 ID |
| `created_at` | `TIMESTAMPTZ` | 불가 | DB 행 생성 시각; 기본값 `now()` |

**참조 관계·삭제 동작**

- `user_id` → `users(id)`: `ON DELETE CASCADE` (`fk_course_bookmarks_user_id`)
- `course_id` → `courses(id)`: `ON DELETE CASCADE` (`fk_course_bookmarks_course_id`)


## 그룹런·커뮤니티
### `crews`

**역할:** 지속적인 러닝 크루 정보.

**생성·변경·삭제 시점(설계 의도):** 크루 생성·운영 정보 수정 시 반영.

**다른 테이블과 구분:** 개별 공동 러닝 이벤트 group_runs와 구분.

**기본 키:** `id`

**컬럼 명세**

| 컬럼 | SQL 타입 | NULL 허용 | 의미 |
|---|---|---|---|
| `id` | `UUID` | 불가 | 행 식별자(UUID); 기본값 `gen_random_uuid()` |
| `owner_id` | `UUID` | 불가 | owner 참조 식별자 |
| `name` | `VARCHAR(100)` | 불가 | name 값 |
| `description` | `TEXT` | 가능 | description 값 |
| `join_policy` | `VARCHAR(20)` | 불가 | join policy 값; 기본값 `'APPROVAL'` |
| `created_at` | `TIMESTAMPTZ` | 불가 | DB 행 생성 시각; 기본값 `now()` |
| `deleted_at` | `TIMESTAMPTZ` | 가능 | 논리 삭제 시각(NULL이면 미삭제) |

**참조 관계·삭제 동작**

- `owner_id` → `users(id)`: `ON DELETE RESTRICT` (`fk_crews_owner_id`)

**CHECK:** `join_policy IN ('OPEN','APPROVAL')`.


### `crew_memberships`

**역할:** 크루 가입 신청·승인·멤버 상태 관리.

**생성·변경·삭제 시점(설계 의도):** 가입 신청 시 생성, 승인·탈퇴 시 갱신.

**다른 테이블과 구분:** 그룹런 개별 참여자와는 별개.

**기본 키:** `crew_id, user_id`

**컬럼 명세**

| 컬럼 | SQL 타입 | NULL 허용 | 의미 |
|---|---|---|---|
| `crew_id` | `UUID` | 불가 | 크루 ID |
| `user_id` | `UUID` | 불가 | 내부 사용자 ID |
| `status` | `VARCHAR(20)` | 불가 | 현재 처리·진행 상태; 기본값 `'PENDING'` |
| `role` | `VARCHAR(20)` | 불가 | role 값; 기본값 `'MEMBER'` |
| `requested_at` | `TIMESTAMPTZ` | 불가 | requested 시각; 기본값 `now()` |
| `resolved_at` | `TIMESTAMPTZ` | 가능 | resolved 시각 |
| `left_at` | `TIMESTAMPTZ` | 가능 | left 시각 |

**참조 관계·삭제 동작**

- `crew_id` → `crews(id)`: `ON DELETE CASCADE` (`fk_crew_memberships_crew_id`)
- `user_id` → `users(id)`: `ON DELETE CASCADE` (`fk_crew_memberships_user_id`)

**CHECK:** `status IN ('PENDING','APPROVED','REJECTED','LEFT')`; `role IN ('OWNER','ADMIN','MEMBER')`.


### `group_runs`

**역할:** 정해진 공동 목표를 갖는 그룹런 모집·진행 이벤트.

**생성·변경·삭제 시점(설계 의도):** 그룹런 생성 시 추가, 모집·시작·종료 시 갱신.

**다른 테이블과 구분:** 하나의 Crew가 여러 GroupRun을 열 수 있음.

**기본 키:** `id`

**컬럼 명세**

| 컬럼 | SQL 타입 | NULL 허용 | 의미 |
|---|---|---|---|
| `id` | `UUID` | 불가 | 행 식별자(UUID); 기본값 `gen_random_uuid()` |
| `crew_id` | `UUID` | 가능 | 크루 ID |
| `course_id` | `UUID` | 가능 | 그룹런에서 사용할 코스 ID |
| `host_id` | `UUID` | 불가 | host 참조 식별자 |
| `title` | `VARCHAR(100)` | 불가 | title 값 |
| `description` | `TEXT` | 가능 | description 값 |
| `scheduled_at` | `TIMESTAMPTZ` | 가능 | scheduled 시각 |
| `meeting_position` | `geography(Point,4326)` | 가능 | meeting position 값 |
| `capacity` | `INTEGER` | 가능 | capacity 값 |
| `status` | `VARCHAR(20)` | 불가 | 현재 처리·진행 상태; 기본값 `'RECRUITING'` |
| `target_distance_m` | `INTEGER` | 불가 | 목표 거리 (m) |
| `target_duration_sec` | `INTEGER` | 불가 | 목표 완주 시간 (초) |
| `goal_input_type` | `VARCHAR(10)` | 불가 | 데이터 유형 구분값 |
| `started_at` | `TIMESTAMPTZ` | 가능 | 시작 시각 |
| `ended_at` | `TIMESTAMPTZ` | 가능 | 종료 시각 |
| `goal_achieved` | `BOOLEAN` | 가능 | goal achieved 값 |
| `created_at` | `TIMESTAMPTZ` | 불가 | DB 행 생성 시각; 기본값 `now()` |

**참조 관계·삭제 동작**

- `crew_id` → `crews(id)`: `ON DELETE SET NULL` (`fk_group_runs_crew_id`)
- `course_id` → `courses(id)`: `ON DELETE SET NULL` (`fk_group_runs_course`)
- `host_id` → `users(id)`: `ON DELETE RESTRICT` (`fk_group_runs_host_id`)

**CHECK:** `target_distance_m > 0`; `target_duration_sec > 0`; `capacity IS NULL OR capacity > 0`; `goal_input_type IN ('TIME','PACE')`; `status IN ('RECRUITING','READY','RUNNING','COMPLETED','CANCELLED')`.


### `group_run_participants`

**역할:** 그룹런 사용자별 참여 및 개인 세션 연결.

**생성·변경·삭제 시점(설계 의도):** 참여 신청/취소/시작/종료에 따라 갱신.

**다른 테이블과 구분:** 위치 공유 기본 FALSE, session 소유자 일치.

**기본 키:** `group_run_id, user_id`

**컬럼 명세**

| 컬럼 | SQL 타입 | NULL 허용 | 의미 |
|---|---|---|---|
| `group_run_id` | `UUID` | 불가 | 그룹런 ID |
| `user_id` | `UUID` | 불가 | 내부 사용자 ID |
| `session_id` | `UUID` | 가능 | 러닝 세션 ID |
| `status` | `VARCHAR(20)` | 불가 | 현재 처리·진행 상태; 기본값 `'JOINED'` |
| `role` | `VARCHAR(20)` | 불가 | role 값; 기본값 `'MEMBER'` |
| `location_sharing_enabled` | `BOOLEAN` | 불가 | 그룹런에서 본인 실시간 위치 공유 여부; 기본값 `FALSE` |
| `joined_at` | `TIMESTAMPTZ` | 불가 | joined 시각; 기본값 `now()` |
| `cancelled_at` | `TIMESTAMPTZ` | 가능 | cancelled 시각 |

**참조 관계·삭제 동작**

- `group_run_id` → `group_runs(id)`: `ON DELETE CASCADE` (`fk_group_run_participants_group_run_id`)
- `user_id` → `users(id)`: `ON DELETE CASCADE` (`fk_group_run_participants_user_id`)
- `session_id, user_id` → `running_sessions(id, user_id)`: `ON DELETE SET NULL (session_id)` (`fk_group_run_participants_session_id_user_id`, 복합 FK의 컬럼 지정형 SET NULL).

**UNIQUE:** `session_id`가 NULL이 아닐 때 하나의 러닝 세션은 한 그룹런 참가자에만 연결된다 (`uq_group_run_participant_session`).

**CHECK:** `status IN ('JOINED','CANCELLED','RUNNING','COMPLETED')`; `role IN ('HOST','MEMBER')`.


### `group_pace_events`

**역할:** 그룹 공동 페이스 권고 변경 이력.

**생성·변경·삭제 시점(설계 의도):** 공동 페이스 조정 시 INSERT.

**다른 테이블과 구분:** 개별 AI 안내 coaching_events와 구분.

**기본 키:** `id`

**컬럼 명세**

| 컬럼 | SQL 타입 | NULL 허용 | 의미 |
|---|---|---|---|
| `id` | `UUID` | 불가 | 행 식별자(UUID); 기본값 `gen_random_uuid()` |
| `group_run_id` | `UUID` | 불가 | 그룹런 ID |
| `revision` | `INTEGER` | 불가 | 계획·이력의 개정 순서 |
| `target_pace_sec_per_km` | `NUMERIC(10,2)` | 불가 | 목표 페이스 (초/km) |
| `participant_snapshot` | `JSONB` | 가능 | participant snapshot 값 |
| `reason_codes` | `JSONB` | 가능 | reason codes 값 |
| `created_at` | `TIMESTAMPTZ` | 불가 | DB 행 생성 시각; 기본값 `now()` |

**참조 관계·삭제 동작**

- `group_run_id` → `group_runs(id)`: `ON DELETE RESTRICT` (`fk_group_pace_events_group_run_id`)

**UNIQUE:** `(group_run_id, revision)`.

**CHECK:** `revision >= 1`; `target_pace_sec_per_km > 0`.


### `notifications`

**역할:** 그룹런 관련 사용자별 알림과 기본 전달 상태.

**생성·변경·삭제 시점(설계 의도):** 그룹 이벤트 발생 시 수신자별 생성, 전송 상태 갱신.

**다른 테이블과 구분:** 기기별 전달 ledger는 별도 운영하지 않음.

**기본 키:** `id`

**컬럼 명세**

| 컬럼 | SQL 타입 | NULL 허용 | 의미 |
|---|---|---|---|
| `id` | `UUID` | 불가 | 행 식별자(UUID); 기본값 `gen_random_uuid()` |
| `recipient_user_id` | `UUID` | 불가 | recipient user 참조 식별자 |
| `group_run_id` | `UUID` | 불가 | 그룹런 ID |
| `group_pace_event_id` | `UUID` | 가능 | group pace event 참조 식별자 |
| `notification_type` | `VARCHAR(40)` | 불가 | 데이터 유형 구분값 |
| `payload` | `JSONB` | 불가 | payload 값; 기본값 `'{}'::jsonb` |
| `status` | `VARCHAR(20)` | 불가 | 현재 처리·진행 상태; 기본값 `'PENDING'` |
| `created_at` | `TIMESTAMPTZ` | 불가 | DB 행 생성 시각; 기본값 `now()` |
| `sent_at` | `TIMESTAMPTZ` | 가능 | sent 시각 |
| `read_at` | `TIMESTAMPTZ` | 가능 | read 시각 |
| `expires_at` | `TIMESTAMPTZ` | 가능 | expires 시각 |

**참조 관계·삭제 동작**

- `recipient_user_id` → `users(id)`: `ON DELETE RESTRICT` (`fk_notifications_recipient_user_id`)
- `group_run_id` → `group_runs(id)`: `ON DELETE RESTRICT` (`fk_notifications_group_run_id`)
- `group_pace_event_id` → `group_pace_events(id)`: `ON DELETE SET NULL` (`fk_notifications_group_pace_event_id`)

**CHECK:** `status IN ('PENDING','SENT','FAILED','EXPIRED','READ')`; `notification_type IN ('GROUP_PACE_CHANGED','GROUP_GAP','GROUP_STATUS')`.


### `posts`

**역할:** 일반 글·러닝 기록·코스 공유 게시물.

**생성·변경·삭제 시점(설계 의도):** 게시물 작성/수정/삭제 시 반영.

**다른 테이블과 구분:** 러닝/코스 원본과 공유 게시물은 별개.

**기본 키:** `id`

**컬럼 명세**

| 컬럼 | SQL 타입 | NULL 허용 | 의미 |
|---|---|---|---|
| `id` | `UUID` | 불가 | 행 식별자(UUID); 기본값 `gen_random_uuid()` |
| `author_id` | `UUID` | 불가 | author 참조 식별자 |
| `session_id` | `UUID` | 가능 | 러닝 세션 ID |
| `course_id` | `UUID` | 가능 | 코스 ID |
| `post_type` | `VARCHAR(20)` | 불가 | 데이터 유형 구분값; 기본값 `'GENERAL'` |
| `title` | `VARCHAR(200)` | 가능 | title 값 |
| `body` | `TEXT` | 불가 | body 값 |
| `created_at` | `TIMESTAMPTZ` | 불가 | DB 행 생성 시각; 기본값 `now()` |
| `updated_at` | `TIMESTAMPTZ` | 불가 | 마지막 수정 시각; 기본값 `now()` |
| `deleted_at` | `TIMESTAMPTZ` | 가능 | 논리 삭제 시각(NULL이면 미삭제) |

**참조 관계·삭제 동작**

- `author_id` → `users(id)`: `ON DELETE RESTRICT` (`fk_posts_author_id`)
- `session_id` → `running_sessions(id)`: `ON DELETE SET NULL` (`fk_posts_session_id`)
- `course_id` → `courses(id)`: `ON DELETE SET NULL` (`fk_posts_course_id`)

**CHECK:** `post_type IN ('GENERAL','RUNNING_RECORD','COURSE')`; `(post_type <> 'RUNNING_RECORD' OR session_id IS NOT NULL) AND (post_type <> 'COURSE' OR course_id IS NOT NULL)`.


### `comments`

**역할:** 게시물 댓글.

**생성·변경·삭제 시점(설계 의도):** 작성/수정/삭제 시 반영.

**다른 테이블과 구분:** 삭제 컬럼 있는 경우 논리 삭제 처리 가능.

**기본 키:** `id`

**컬럼 명세**

| 컬럼 | SQL 타입 | NULL 허용 | 의미 |
|---|---|---|---|
| `id` | `UUID` | 불가 | 행 식별자(UUID); 기본값 `gen_random_uuid()` |
| `post_id` | `UUID` | 불가 | 게시물 ID |
| `author_id` | `UUID` | 불가 | author 참조 식별자 |
| `body` | `TEXT` | 불가 | body 값 |
| `created_at` | `TIMESTAMPTZ` | 불가 | DB 행 생성 시각; 기본값 `now()` |
| `updated_at` | `TIMESTAMPTZ` | 불가 | 마지막 수정 시각; 기본값 `now()` |
| `deleted_at` | `TIMESTAMPTZ` | 가능 | 논리 삭제 시각(NULL이면 미삭제) |

**참조 관계·삭제 동작**

- `post_id` → `posts(id)`: `ON DELETE CASCADE` (`fk_comments_post_id`)
- `author_id` → `users(id)`: `ON DELETE CASCADE` (`fk_comments_author_id`)


### `post_reactions`

**역할:** 게시물 사용자별 반응.

**생성·변경·삭제 시점(설계 의도):** 반응 추가/취소 시 변경.

**다른 테이블과 구분:** 사용자별 중복 반응 제약 확인.

**기본 키:** `post_id, user_id`

**컬럼 명세**

| 컬럼 | SQL 타입 | NULL 허용 | 의미 |
|---|---|---|---|
| `post_id` | `UUID` | 불가 | 게시물 ID |
| `user_id` | `UUID` | 불가 | 내부 사용자 ID |
| `reaction_type` | `VARCHAR(20)` | 불가 | 데이터 유형 구분값; 기본값 `'LIKE'` |
| `created_at` | `TIMESTAMPTZ` | 불가 | DB 행 생성 시각; 기본값 `now()` |

**참조 관계·삭제 동작**

- `post_id` → `posts(id)`: `ON DELETE CASCADE` (`fk_post_reactions_post_id`)
- `user_id` → `users(id)`: `ON DELETE CASCADE` (`fk_post_reactions_user_id`)


## 추가 인덱스

| 인덱스 | 대상 |
| --- | --- |
| `uq_group_run_participant_session` | `group_run_participants(session_id)` — NULL이 아닌 세션의 중복 연결 방지 |
| `idx_courses_start_position` | `courses.start_position` — GiST 공간 인덱스 |
| `idx_courses_route` | `courses.route` — GiST 공간 인덱스 |
| `idx_running_route_points_position` | `running_route_points.position` — GiST 공간 인덱스 |
| `idx_running_route_points_session_id_measured_at` | `running_route_points(session_id, measured_at)` |
| `idx_running_metric_samples_session_id_metric_type_measured_at` | `running_metric_samples(session_id, metric_type, measured_at)` |
| `idx_pace_predictions_session_id_predicted_at` | `pace_predictions(session_id, predicted_at)` |
| `idx_physiology_predictions_session_id_predicted_at` | `physiology_predictions(session_id, predicted_at)` |
| `idx_cue_predictions_session_id_predicted_at` | `cue_predictions(session_id, predicted_at)` |
| `idx_canonical_running_samples_session_id_sampled_at` | `canonical_running_samples(session_id, sampled_at)` |
| `idx_notifications_recipient_user_id_created_at` | `notifications(recipient_user_id, created_at)` |
| `idx_running_sessions_user_id_created_at` | `running_sessions(user_id, created_at)` |


## DB 차원의 교차 검토 메모

- **원본/정제 구분:** `running_metric_samples`·`running_route_points`는 센서/GPS 원본, `canonical_running_samples`는 후처리된 정제 결과이다.
- **경로 형식:** `running_route_points.position`은 개별 Point, `courses.route`는 LineString이다. SRID 4326의 `geography` 타입이다.
- **실제/계획 구간:** `running_splits`는 실제 측정 기반 구간 통계이고 `pace_plan_segments`는 계획상 구간 목표이다.
- **예측/적용:** `physiology_predictions`, `cue_predictions`는 선택적 예측 저장이며 `coaching_events`가 실제 판단/전달/적용 시점을 관리한다.
- **동기화:** `sync_batches`는 전송 묶음, `sync_stream_progress`는 기기·스트림의 연속 커밋 위치이다.
- **데이터 삭제:** CASCADE/RESTRICT/SET NULL은 각 테이블 FK 정의대로 작동한다. 소프트 삭제·동의 철회·Redis 정리는 SQL만으로 자동 보장되지 않는다.
- **DDL 제약:** PostgreSQL+PostGIS에서 실제 실행 검증을 수행했다고 주장할 수 없다. 특히 순환 참조 트리거의 동시성·삭제 트랜잭션은 통합 테스트가 필요하다.
- **문서 변경:** 테이블 또는 컬럼을 추가·변경할 때 이 문서와 DDL을 함께 갱신한다.
