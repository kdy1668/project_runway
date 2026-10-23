# RunWay ERD 설명서

기준: 2026-10-23 · ERD ver.3 · **26개 테이블 / 230개 컬럼 / 45개 FK**

회원이 러닝을 준비하고 기록한 결과를 코스·크루·게시글로 연결하는 데이터 구조다. 이 문서는 팀원이 구조와 정책을 빠르게 파악하기 위한 요약이다. 전체 컬럼·타입·NULL 정의는 SQL을 기준으로 확인한다.

## 1. 기준 파일

| 파일 | 용도 |
| --- | --- |
| [schema.sql](schema.sql) | 전체 테이블·컬럼·PK·FK 정의 |
| [erd.png](erd.png) | 전체 테이블과 관계 이미지 |

[온라인 ERD](https://www.erdcloud.com/d/PMb4s6pJDYReQLMMd)에서 내보낸 같은 시점의 자료다. 코스 지역 FK는 테이블 생성 순서를 고려해 SQL의 후행 ALTER 제약으로 정리했다. PNG에서는 해당 참조를 코스 지역 컬럼의 REFERENCES 정의로 표시한다. SQL은 설계 내보내기 자료이며 실행용 초기화/Flyway 마이그레이션은 아니다. 실제 운영 DB 적용은 수행하지 않았다. 과거 API 명세의 계약은 이번 작업에서 수정하지 않는다.

## 2. 테이블별 역할

### 회원·기기·건강

| 테이블 | 역할과 주요 연결 |
| --- | --- |
| `users` | 회원·로그인 정보. 개인 활동의 기준 ID |
| `user_profiles` | 회원의 러닝 수준·평소 페이스·기준 거리/시간. 이번 러닝 목표와 구분 |
| `user_settings` | 코칭·알림 사용 여부, 위치 수집 모드, 계정의 기록 공개 범위 |
| `user_devices` | 회원의 PHONE/WATCH 연결 관계와 연결·해제 시각 |
| `daily_health_metrics` | 회원·날짜별 수면, 안정시 심박, 운동 부하 등의 건강 요약 |
| `daily_readiness` | 회원·날짜별 준비도 점수와 분석 신뢰도 |

### 러닝·페이스 코칭

| 테이블 | 역할과 주요 연결 |
| --- | --- |
| `running_sessions` | 한 회원의 한 번의 러닝. 초기 목표·상태·실제 결과. course_id가 없으면 자유러닝 |
| `running_metric_samples` | 세션별 측정 시점의 심박·케이던스·속도·누적 거리 등 |
| `running_route_points` | 세션별 측정 시각과 GPS 위치·정확도·고도 |
| `sync_batches` | 기기에서 받은 배치의 식별·해시·수신/반영 상태 |
| `pace_plans` | 세션의 초기 권장 페이스·BPM |
| `pace_plan_segments` | 초기 페이스 계획의 거리 구간별 권장 페이스 |
| `coaching_decisions` | 러닝 도중의 권장 페이스·BPM·미래 심박 예측 |

### 코스·크루·그룹런

| 테이블 | 역할과 주요 연결 |
| --- | --- |
| `courses` | 여러 러닝에서 재사용하는 공용 경로·출발점·거리·지역·상태 |
| `course_environment_tags` | 코스의 환경 코드. PARK/RIVERSIDE/URBAN/BEACH/TRACK |
| `course_bookmarks` | 회원의 코스 저장 관계와 개인 별칭 custom_name |
| `crews` | 지속적인 모임. 크루장·정원·지역·활성 상태 |
| `crew_memberships` | 크루 가입 요청·승인·거절·탈퇴 관계 |
| `group_runs` | 크루에서 여는 개별 러닝 일정·호스트·공동 목표. 코스는 선택 |
| `group_run_participants` | 그룹런 참가 회원과 그 회원의 개인 러닝 세션 연결 |

### 지역·커뮤니티·알림

| 테이블 | 역할과 주요 연결 |
| --- | --- |
| `regions` | 지역 코드와 시·도/시·군·구 이름 |
| `posts` | 회원의 러닝 기록 공유 게시글. session_id는 필수 |
| `comments` | 게시글 댓글. parent_comment_id가 없으면 일반 댓글, 있으면 대댓글 |
| `post_likes` | 회원과 게시글의 좋아요 관계 |
| `user_follows` | 팔로우 요청/성립 관계와 승인 여부 |
| `notifications` | 수신 회원·메시지·발송/읽음 상태·알림 종류·클릭 이동 대상 |

## 3. 핵심 관계와 데이터 흐름

- **개인 러닝:** 회원 → 러닝 세션 → 측정값·GPS 경로·초기 계획·코칭 판단. 최초 목표와 AI가 조정하는 안내 페이스를 구분한다.
- **코스 등록:** 완료된 본인 세션의 경로를 코스로 등록하고, 이후 여러 세션과 북마크가 같은 코스를 참조한다. 코스 원본과 회원별 북마크는 별개다.
- **그룹런:** 크루 → 그룹런 → 참가 관계 → 각 참가자의 개인 세션. 그룹 전체 종료와 개인 러닝 종료는 별개다. 참가 시점에는 개인 세션이 없어도 된다.
- **기록 공유:** 회원 → 게시글 → 연결 러닝 세션. 댓글·좋아요가 게시글에 연결된다. 현재 posts에는 독립 post_type·title·course_id 컬럼이 없다.
- **지역:** 코스·크루·게시글의 region_code는 regions.region_code를 FK로 참조한다. regions.region_code는 UNIQUE이며, 존재하지 않는 지역 코드 저장을 막는다. 코스 지역 미판정 상태의 NULL은 허용한다.

모든 테이블의 PK는 BIGINT다. FK만으로 회원당 프로필 1개, 하루 건강 기록 1개, 회원별 북마크 1개 같은 유일성이 보장되지는 않는다.

## 4. 확정된 표시·접근 정책

### 코스 이름

`courses.region_code`로 `regions`를 조회해 **시·도명 + 시·군·구명 + 코스**로 표시한다. 예: `부산광역시 해운대구 코스`.

공통 courses.name은 추가하지 않는다. 개인 별칭은 course_bookmarks.custom_name이다. 지역 코드는 출발 좌표로 판정하며 판정 전/실패 시 NULL을 허용한다. 좌표를 행정구역으로 바꾸는 로직/자료와 지역 미지정 시 대체 표시명은 별도 구현·정책 사항이다.

### 팔로우와 비공개 기록

`user_follows.follower_id`는 팔로우하는 회원, `followee_id`는 팔로우받는 회원이다. `is_approved BOOLEAN NOT NULL DEFAULT FALSE`를 사용한다.

| 팔로우받는 회원의 account_visibility | 요청 처리 |
| --- | --- |
| PUBLIC | 별도 승인 없이 is_approved=TRUE로 생성하여 즉시 성립 |
| PRIVATE | FALSE로 요청 저장. 상대가 승인하면 TRUE로 변경 |

TRUE인 관계만 팔로워·팔로잉 목록과 인원 집계에 포함한다. 비공개 기록은 **본인 또는 follower_id=열람자, followee_id=기록 소유자, is_approved=TRUE인 회원**만 열람한다. 미승인 요청과 반대 방향 관계는 열람 근거가 아니다. 승인/즉시 성립과 조회 권한 검사는 서비스에서 수행한다.

account_visibility와 location_collection_mode는 **NOT NULL**이다. 설정 행 생성 시 각각 PUBLIC/PRIVATE 및 ALWAYS/RUNNING_ONLY/OFF 중 값을 명시하며 임의 기본값은 두지 않았다. 설정 행이 없는 회원을 PUBLIC으로 자동 간주하지 않는다. 공개 범위 변경 시 기존 관계·대기 요청 처리 정책은 미정이다. 계정 기준 정책이며 기록별 공개 범위 컬럼은 추가하지 않았다. 위치 수집 모드와 기록 공개 범위는 별개다.

### 크루 정원

**크루 최대 정원은 현재 200명으로 예정되어 있다.** 각 크루의 capacity는 상한 내에서 설정하는 방향이며 모든 크루의 정원을 자동 200명으로 한다는 뜻은 아니다. 현재 SQL에는 상한 CHECK가 없다. 승인 시 정원 초과 방지와 동시성 처리가 필요하다. 그룹런 참가 정원과는 별개이며 현재 group_runs에는 capacity가 없다.

## 5. 알림 종류와 화면 이동

`notification_type VARCHAR(50) NOT NULL`과 `target_id BIGINT NOT NULL`를 함께 저장한다. 종류마다 대상이 정해져 있으므로 target_type과 화면 URL은 추가하지 않는다.

| 알림 종류 | notification_type | target_id | 클릭 시 이동 |
| --- | --- | --- | --- |
| 그룹런 참여 취소 | GROUP_RUN_PARTICIPATION_CANCELLED | group_runs.id | 그룹런 상세 |
| 크루 가입 승인 | CREW_JOIN_APPROVED | crews.id | 크루 상세 |
| 크루 가입 거절 | CREW_JOIN_REJECTED | crews.id | 크루 상세 |
| 게시물 댓글 | POST_COMMENT | posts.id | 게시글 상세 |
| 그룹런 시작 임박 | GROUP_RUN_START_REMINDER | group_runs.id | 그룹런 상세 |

앱은 푸시의 종류·대상 ID로 화면을 선택한다. target_id는 여러 테이블을 가리키므로 단일 FK를 두지 않는다. 서비스가 허용 코드와 종류별 대상 조합을 검증하고, 클릭 시 삭제 여부와 현재 열람 권한을 확인한다. 삭제된 대상은 이동 불가로 안내하며 알림 수신이 비공개 기록의 접근 권한을 부여하지는 않는다. 가입 거절 후 크루 상세 조회와 가입자 전용 기능 권한도 구분한다.

참여 취소 알림의 수신자, 시작 임박 알림의 발송 시점·수신 대상은 아직 미정이다. 실제 푸시 전송·화면 이동과 푸시 토큰 저장은 이 두 컬럼 추가만으로 구현되지 않는다.

## 6. 상태·NULL을 읽는 기준

**목표 거리나 시간이 없는 자유러닝을 허용한다.** 개인·그룹런의 goal_distance/goal_duration은 NULL을 유지하며 목표 미설정과 목표값 0을 구분한다. 목표가 없으면 목표 페이스·달성 평가를 임의로 생성하지 않는다. 러닝 목표 명칭은 goal로 통일했으며 목표 도달 운동시간은 moving_duration_to_goal이다. 알림의 target_id는 이동 대상을 뜻하므로 유지한다.

| 대상 | 상태 |
| --- | --- |
| 회원 | ACTIVE / WITHDRAWN |
| 개인 세션 | READY / RUNNING / PAUSED / COMPLETED / CANCELLED / INTERRUPTED |
| 코스 | ACTIVE / MERGED / BLOCKED. 추천·일반 검색은 ACTIVE |
| 크루 | ACTIVE / INACTIVE |
| 크루 가입 | PENDING / APPROVED / REJECTED / LEFT |
| 그룹런 | SCHEDULED / RUNNING / COMPLETED / CANCELLED |
| 동기화 | RECEIVED / COMMITTED / REJECTED |
| 알림 발송 | PENDING / SENT / FAILED. 읽음은 read_at으로 구분 |

NULL은 미측정·아직 발생하지 않음·선택하지 않음을 표현할 수 있다. 센서 결측을 0으로 채우거나, 아직 평가하지 않은 goal_achieved를 FALSE로 바꾸지 않는다. 상태 ENUM만으로 전이와 상태별 필수값은 보장되지 않는다. 230개 컬럼의 NULL 정의를 검토했다. 사용자 확정에 따라 두 설정 컬럼만 NOT NULL로 반영했고 다른 NULL 정의는 유지했다.

## 7. 구현 전에 확인할 제약

- **내보내기 SQL:** 인라인 ENUM 표기와 geography가 포함된다. 실제 PostgreSQL 마이그레이션에는 타입·공간 확장 준비가 필요하다. ID 자동 생성과 updated_at 자동 갱신도 이 SQL만으로 보장되지 않는다.
- **지역 참조:** regions.region_code의 UNIQUE와 코스·크루·게시글의 지역 FK를 정의했다. 지역 마스터를 먼저 준비하고, 기존 데이터를 적용할 때는 중복 코드·미등록 참조를 보정해야 한다.
- **유일성·범위:** 회원별 프로필/설정, 회원·날짜별 지표, 북마크·팔로우·좋아요·태그·그룹 참가 조합의 UNIQUE와 양수·정원·상태별 필수값 CHECK가 없다.
- **댓글:** 같은 게시물 부모·자기 참조 금지·한 단계 대댓글은 주석의 의도이며 실제 복합 FK/CHECK는 없다. 서비스 검증과 물리 제약을 구분한다.
- **동기화·소유권:** 배치/샘플의 중복 방지와 직접 연결, 연결 세션의 회원 일치, 호스트/참가 자격, 삭제·탈퇴 후 보존/조회 정책은 별도 검증이 필요하다.
- **원본 오타:** users.health_data_access의 AGREEE, user_profiles.duraction은 원본 표기다. 이름 변경을 임의 적용하지 않았다.
