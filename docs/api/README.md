# RunWay API 명세 — 1차 MVP

RunWay 서비스의 **클라이언트 공개 API 설계 초안**이다. 저장소의 [1차 MVP 요구사항](../requirements/detailed-requirements.md)과 [최신 ERD](../architecture/data-model/README.md)를 기준으로 정리했으며, README 공통 규약 → 도메인별 색인 → API별 상세 명세 구조를 따른다.

> **상태: 초안.** 미정 정책을 임의 확정하지 않았다. 예시 JSON은 형식을 설명하기 위한 가상 값이며, 자료형·필드 이름·동기화 정책·HTTP 상태 코드는 구현 전에 팀 검토가 필요하다. 다른 프로젝트인 FEELM의 ID·영화 도메인 규칙을 RunWay에 복사하지 않았다.

## 문서 구성

| 문서 | 도메인 | API 수 |
|---|---|---:|
| [인증·사용자·러닝 프로필](./users.md) | 인증·사용자·러닝 프로필 | 14 |
| [워치·건강 데이터](./devices-health.md) | 워치·건강 데이터 | 8 |
| [운동 준비도](./readiness.md) | 운동 준비도 | 2 |
| [러닝 코스](./courses.md) | 러닝 코스 | 7 |
| [러닝 세션](./sessions.md) | 러닝 세션 | 7 |
| [AI 페이스·실시간 분석·BPM](./pace-coaching.md) | AI 페이스·실시간 분석·BPM | 7 |
| [러닝 기록·분석](./running-records.md) | 러닝 기록·분석 | 5 |
| [그룹런](./group-runs.md) | 그룹런 | 14 |
| [크루](./crews.md) | 크루 | 9 |
| [커뮤니티](./community.md) | 커뮤니티 | 11 |

총 **84개 API 후보**. 크루 멤버 내보내기(M09)는 선택 기능이다.

Wear OS 실험 앱의 원본 업로드 계약은 [워치 실험 기록 업로드 계약](./wear-upload-api.md)에서 별도로 관리한다. 서비스 API 구현 시 `W07`의 배치 동기화 계약과 함께 검토해야 한다.

## 공통 규약

### 기본 URL 및 콘텐츠

- Base path: `/api/v1`
- `Content-Type: application/json; charset=utf-8`
- 키: `camelCase`; 식별자: UUID 문자열(ERD 기준); 시간: ISO 8601 UTC 문자열
- 거리: m; 구간·경과 시간: sec; 페이스: sec/km; 심박수: bpm; 케이던스: spm
- 좌표: WGS84, GeoJSON 좌표 순서 `[longitude, latitude]`
- JWT Bearer 방식은 설계 제안이다. 소셜 제공자·토큰 저장/회전 정책은 미정.

### 성공·오류 응답

- 성공 응답은 **각 엔드포인트의 Response JSON**을 우선한다. 공통 `{data: ...}` 래퍼 도입 여부는 미정이다. 본 파일 예시는 래퍼 없는 응답으로 작성했다.
- 목록 응답은 `items`/`page` 패턴을 제안하지만 `cursor` 형식, `limit` 상한과 정확한 페이지 정보는 미정이다.
- 오류는 HTTP 상태와 오류 코드·설명으로 반환한다. 공통 오류 형태(제안):

```json
{
  "code": "VALIDATION_ERROR",
  "message": "요청 값이 유효하지 않습니다.",
  "details": {}
}
```

- 공통 HTTP 오류 후보: `400` 요청 유효성 실패, `401` 인증 실패, `403` 권한·동의 부족, `404` 리소스 없음, `409` 상태 충돌, `422` 의미적 검증 실패, `500` 서버 오류.
- 사용자·건강·GPS 개인정보 접근은 동의·공개 범위·소유자 및 참가자 권한을 확인한다.

### 러닝 목표와 세션 상태

- 평소 러닝 정보는 개인화 추천용 기준값이며 특정 세션의 목표가 아니다.
- 이번 러닝 목표는 코스 추천 조건에서 입력하고 러닝 세션 생성 시 전달한다.
- 초기 러닝 목표(거리·시간)는 세션 생성 시 고정. 러닝 중 AI가 갱신하는 것은 **안내 페이스·코칭**이다.
- 개인런·그룹런 모두 코스 지정과 자유러닝 허용(`courseId = null`).
- 개인 세션 종료와 그룹런 전체 종료는 별개 API다.
- 같은 코스 과거 기록의 **동일 거리 도달 시간**을 비교한다. 여러 과거 기록 중 기본 선택 정책은 미정.
- 지정 코스 그룹은 코스 진행률을, 자유 그룹은 선두의 실제 주행 경로를 기준으로 순위 산정을 검토한다. GPS만으로 동일 선상 선후 관계가 자동 확정되는 것은 아니다.
- 삼성 헬스 과거 운동 기록의 세부 저장 구조, 실시간 전송 수단 및 동기화 빈도는 미정이다.

### 공용 코스 상태와 사용자 저장 목록

- 코스 추천과 일반 검색에는 `ACTIVE` 상태의 서비스 공용 코스만 사용한다.
- `MERGED`, `BLOCKED` 코스는 추천에서 제외한다. 저장한 코스가 `MERGED`이면 대표 코스를 함께 안내한다.
- 사용자가 완료 경로를 공용 코스로 등록해도 코스 원본을 직접 수정하거나 삭제할 수 없다.
- 코스 저장 해제는 사용자의 북마크 관계만 삭제하며 공용 코스 원본과 상태를 변경하지 않는다.

### 문서 표기

- ID는 기존 v2 후보 ID(U01, W01, … CMT11)를 유지하며 재사용하지 않는다.
- `O`는 필수, `X`는 선택, `조건부`는 다른 필드 값에 따라 필수임을 뜻한다. 예시 필드 중 타입을 확인할 수 없는 경우 `(확인 필요)`라고 표시한다.
- 상세 응답 JSON의 값은 **구조 예시**이지 실데이터 계약 완료를 의미하지 않는다.
- `M09`는 1차 MVP 필수 범위 밖 선택 기능이다.

## 전체 API 목록

| ID | 이름 | Method | Endpoint | 문서 |
|---|---|---|---|---|
| U01 | [로그인 및 계정 생성](./users.md#u01-로그인-및-계정-생성) | POST | `/auth/login` | [users.md](./users.md) |
| U02 | [토큰 갱신](./users.md#u02-토큰-갱신) | POST | `/auth/refresh` | [users.md](./users.md) |
| U03 | [로그아웃](./users.md#u03-로그아웃) | POST | `/auth/logout` | [users.md](./users.md) |
| U04 | [내 프로필 조회](./users.md#u04-내-프로필-조회) | GET | `/users/me` | [users.md](./users.md) |
| U05 | [내 프로필 수정](./users.md#u05-내-프로필-수정) | PATCH | `/users/me` | [users.md](./users.md) |
| U06 | [러닝 수준 조회](./users.md#u06-러닝-수준-조회) | GET | `/users/me/running-profile` | [users.md](./users.md) |
| U07 | [러닝 수준 설정](./users.md#u07-러닝-수준-설정) | PUT | `/users/me/running-profile` | [users.md](./users.md) |
| U08 | [평소 러닝 정보 조회](./users.md#u08-평소-러닝-정보-조회) | GET | `/users/me/running-baseline` | [users.md](./users.md) |
| U09 | [평소 러닝 정보 설정](./users.md#u09-평소-러닝-정보-설정) | PUT | `/users/me/running-baseline` | [users.md](./users.md) |
| U10 | [러닝 환경 유형 조회](./users.md#u10-러닝-환경-유형-조회) | GET | `/environments` | [users.md](./users.md) |
| U11 | [선호 환경 조회](./users.md#u11-선호-환경-조회) | GET | `/users/me/preferences` | [users.md](./users.md) |
| U12 | [선호 환경 설정](./users.md#u12-선호-환경-설정) | PUT | `/users/me/preferences` | [users.md](./users.md) |
| U13 | [개인 공개 설정 조회](./users.md#u13-개인-공개-설정-조회) | GET | `/users/me/privacy-settings` | [users.md](./users.md) |
| U14 | [개인 공개 설정 변경](./users.md#u14-개인-공개-설정-변경) | PATCH | `/users/me/privacy-settings` | [users.md](./users.md) |
| W01 | [기기 등록](./devices-health.md#w01-기기-등록) | POST | `/devices` | [devices-health.md](./devices-health.md) |
| W02 | [등록 기기 조회](./devices-health.md#w02-등록-기기-조회) | GET | `/devices` | [devices-health.md](./devices-health.md) |
| W03 | [기기 연결 해제](./devices-health.md#w03-기기-연결-해제) | DELETE | `/devices/{deviceId}` | [devices-health.md](./devices-health.md) |
| W04 | [수집 동의·철회](./devices-health.md#w04-수집-동의-철회) | POST | `/consents` | [devices-health.md](./devices-health.md) |
| W05 | [동의 상태 조회](./devices-health.md#w05-동의-상태-조회) | GET | `/consents` | [devices-health.md](./devices-health.md) |
| W06 | [Samsung Health 데이터 동기화](./devices-health.md#w06-samsung-health-데이터-동기화) | POST | `/health-records/sync` | [devices-health.md](./devices-health.md) |
| W07 | [워치 운동 배치 동기화](./devices-health.md#w07-워치-운동-배치-동기화) | POST | `/sync/batches` | [devices-health.md](./devices-health.md) |
| W08 | [동기화 진행 상태 조회](./devices-health.md#w08-동기화-진행-상태-조회) | GET | `/devices/{deviceId}/sync/streams/{streamKey}/progress` | [devices-health.md](./devices-health.md) |
| R01 | [운동 준비도 평가](./readiness.md#r01-운동-준비도-평가) | POST | `/readiness-assessments` | [readiness.md](./readiness.md) |
| R02 | [최신 준비도 조회](./readiness.md#r02-최신-준비도-조회) | GET | `/readiness-assessments/latest` | [readiness.md](./readiness.md) |
| C01 | [AI 코스 추천](./courses.md#c01-ai-코스-추천) | POST | `/courses/recommendations` | [courses.md](./courses.md) |
| C02 | [공용 코스 검색](./courses.md#c02-공용-코스-검색) | GET | `/courses` | [courses.md](./courses.md) |
| C03 | [코스 상세 조회](./courses.md#c03-코스-상세-조회) | GET | `/courses/{courseId}` | [courses.md](./courses.md) |
| C04 | [완료 경로 코스 등록](./courses.md#c04-완료-경로-코스-등록) | POST | `/courses` | [courses.md](./courses.md) |
| C07 | [코스 저장](./courses.md#c07-코스-저장) | PUT | `/courses/{courseId}/bookmark` | [courses.md](./courses.md) |
| C08 | [코스 저장 해제](./courses.md#c08-코스-저장-해제) | DELETE | `/courses/{courseId}/bookmark` | [courses.md](./courses.md) |
| C09 | [저장 코스 목록](./courses.md#c09-저장-코스-목록) | GET | `/users/me/bookmarked-courses` | [courses.md](./courses.md) |
| S01 | [러닝 세션 생성](./sessions.md#s01-러닝-세션-생성) | POST | `/running-sessions` | [sessions.md](./sessions.md) |
| S02 | [러닝 세션 조회](./sessions.md#s02-러닝-세션-조회) | GET | `/running-sessions/{sessionId}` | [sessions.md](./sessions.md) |
| S03 | [러닝 시작](./sessions.md#s03-러닝-시작) | POST | `/running-sessions/{sessionId}/start` | [sessions.md](./sessions.md) |
| S04 | [러닝 일시정지](./sessions.md#s04-러닝-일시정지) | POST | `/running-sessions/{sessionId}/pause` | [sessions.md](./sessions.md) |
| S05 | [러닝 재개](./sessions.md#s05-러닝-재개) | POST | `/running-sessions/{sessionId}/resume` | [sessions.md](./sessions.md) |
| S06 | [개인 러닝 종료](./sessions.md#s06-개인-러닝-종료) | POST | `/running-sessions/{sessionId}/finish` | [sessions.md](./sessions.md) |
| S07 | [러닝 취소](./sessions.md#s07-러닝-취소) | POST | `/running-sessions/{sessionId}/cancel` | [sessions.md](./sessions.md) |
| P01 | [초기 페이스 계획 생성](./pace-coaching.md#p01-초기-페이스-계획-생성) | POST | `/running-sessions/{sessionId}/pace-plans` | [pace-coaching.md](./pace-coaching.md) |
| P02 | [현재 페이스 계획 조회](./pace-coaching.md#p02-현재-페이스-계획-조회) | GET | `/running-sessions/{sessionId}/pace-plans/current` | [pace-coaching.md](./pace-coaching.md) |
| P03 | [러닝 측정값 수신](./pace-coaching.md#p03-러닝-측정값-수신) | POST | `/running-sessions/{sessionId}/metrics` | [pace-coaching.md](./pace-coaching.md) |
| P04 | [실시간 운동·코칭 상태](./pace-coaching.md#p04-실시간-운동-코칭-상태) | GET | `/running-sessions/{sessionId}/live` | [pace-coaching.md](./pace-coaching.md) |
| P05 | [과거 동일 코스 기록 비교](./pace-coaching.md#p05-과거-동일-코스-기록-비교) | GET | `/running-sessions/{sessionId}/past-record-comparison` | [pace-coaching.md](./pace-coaching.md) |
| P06 | [BPM 프로필 조회](./pace-coaching.md#p06-bpm-프로필-조회) | GET | `/users/me/bpm-profile` | [pace-coaching.md](./pace-coaching.md) |
| P07 | [BPM 초기값 설정](./pace-coaching.md#p07-bpm-초기값-설정) | PUT | `/users/me/bpm-profile` | [pace-coaching.md](./pace-coaching.md) |
| H01 | [러닝 기록 목록](./running-records.md#h01-러닝-기록-목록) | GET | `/running-records` | [running-records.md](./running-records.md) |
| H02 | [러닝 기록 상세](./running-records.md#h02-러닝-기록-상세) | GET | `/running-records/{sessionId}` | [running-records.md](./running-records.md) |
| H03 | [구간별 러닝 분석](./running-records.md#h03-구간별-러닝-분석) | GET | `/running-records/{sessionId}/splits` | [running-records.md](./running-records.md) |
| H04 | [러닝 GPS 경로](./running-records.md#h04-러닝-gps-경로) | GET | `/running-records/{sessionId}/route` | [running-records.md](./running-records.md) |
| H05 | [러닝 기록 공개 설정](./running-records.md#h05-러닝-기록-공개-설정) | PATCH | `/running-records/{sessionId}/visibility` | [running-records.md](./running-records.md) |
| G01 | [그룹런 생성](./group-runs.md#g01-그룹런-생성) | POST | `/group-runs` | [group-runs.md](./group-runs.md) |
| G02 | [그룹런 검색](./group-runs.md#g02-그룹런-검색) | GET | `/group-runs` | [group-runs.md](./group-runs.md) |
| G03 | [그룹런 상세](./group-runs.md#g03-그룹런-상세) | GET | `/group-runs/{groupRunId}` | [group-runs.md](./group-runs.md) |
| G04 | [그룹런 정보 수정](./group-runs.md#g04-그룹런-정보-수정) | PATCH | `/group-runs/{groupRunId}` | [group-runs.md](./group-runs.md) |
| G05 | [그룹런 참가](./group-runs.md#g05-그룹런-참가) | POST | `/group-runs/{groupRunId}/join` | [group-runs.md](./group-runs.md) |
| G06 | [그룹런 참가 취소](./group-runs.md#g06-그룹런-참가-취소) | DELETE | `/group-runs/{groupRunId}/participants/me` | [group-runs.md](./group-runs.md) |
| G07 | [그룹런 참가자 조회](./group-runs.md#g07-그룹런-참가자-조회) | GET | `/group-runs/{groupRunId}/participants` | [group-runs.md](./group-runs.md) |
| G08 | [그룹 초기 페이스 추천](./group-runs.md#g08-그룹-초기-페이스-추천) | POST | `/group-runs/{groupRunId}/pace-recommendations` | [group-runs.md](./group-runs.md) |
| G09 | [그룹런 시작](./group-runs.md#g09-그룹런-시작) | POST | `/group-runs/{groupRunId}/start` | [group-runs.md](./group-runs.md) |
| G10 | [그룹런 실시간 현황·순위](./group-runs.md#g10-그룹런-실시간-현황-순위) | GET | `/group-runs/{groupRunId}/live` | [group-runs.md](./group-runs.md) |
| G11 | [그룹런 알림 조회](./group-runs.md#g11-그룹런-알림-조회) | GET | `/group-runs/{groupRunId}/notifications` | [group-runs.md](./group-runs.md) |
| G12 | [그룹런 전체 종료](./group-runs.md#g12-그룹런-전체-종료) | POST | `/group-runs/{groupRunId}/finish` | [group-runs.md](./group-runs.md) |
| G13 | [그룹런 취소](./group-runs.md#g13-그룹런-취소) | POST | `/group-runs/{groupRunId}/cancel` | [group-runs.md](./group-runs.md) |
| G14 | [그룹런 결과 조회](./group-runs.md#g14-그룹런-결과-조회) | GET | `/group-runs/{groupRunId}/results` | [group-runs.md](./group-runs.md) |
| M01 | [크루 검색](./crews.md#m01-크루-검색) | GET | `/crews` | [crews.md](./crews.md) |
| M02 | [크루 상세](./crews.md#m02-크루-상세) | GET | `/crews/{crewId}` | [crews.md](./crews.md) |
| M03 | [크루 생성](./crews.md#m03-크루-생성) | POST | `/crews` | [crews.md](./crews.md) |
| M04 | [크루 가입 신청](./crews.md#m04-크루-가입-신청) | POST | `/crews/{crewId}/join-requests` | [crews.md](./crews.md) |
| M05 | [크루 가입 신청 목록](./crews.md#m05-크루-가입-신청-목록) | GET | `/crews/{crewId}/join-requests` | [crews.md](./crews.md) |
| M06 | [크루 가입 승인·거절](./crews.md#m06-크루-가입-승인-거절) | PATCH | `/crews/{crewId}/join-requests/{userId}` | [crews.md](./crews.md) |
| M07 | [크루 멤버 목록](./crews.md#m07-크루-멤버-목록) | GET | `/crews/{crewId}/members` | [crews.md](./crews.md) |
| M08 | [크루 탈퇴](./crews.md#m08-크루-탈퇴) | DELETE | `/crews/{crewId}/members/me` | [crews.md](./crews.md) |
| M09 | [크루 멤버 내보내기](./crews.md#m09-크루-멤버-내보내기) | DELETE | `/crews/{crewId}/members/{userId}` | [crews.md](./crews.md) |
| CMT01 | [게시물 작성](./community.md#cmt01-게시물-작성) | POST | `/posts` | [community.md](./community.md) |
| CMT02 | [게시물 목록](./community.md#cmt02-게시물-목록) | GET | `/posts` | [community.md](./community.md) |
| CMT03 | [게시물 상세](./community.md#cmt03-게시물-상세) | GET | `/posts/{postId}` | [community.md](./community.md) |
| CMT04 | [게시물 수정](./community.md#cmt04-게시물-수정) | PATCH | `/posts/{postId}` | [community.md](./community.md) |
| CMT05 | [게시물 삭제](./community.md#cmt05-게시물-삭제) | DELETE | `/posts/{postId}` | [community.md](./community.md) |
| CMT06 | [댓글 목록](./community.md#cmt06-댓글-목록) | GET | `/posts/{postId}/comments` | [community.md](./community.md) |
| CMT07 | [댓글 작성](./community.md#cmt07-댓글-작성) | POST | `/posts/{postId}/comments` | [community.md](./community.md) |
| CMT08 | [댓글 수정](./community.md#cmt08-댓글-수정) | PATCH | `/comments/{commentId}` | [community.md](./community.md) |
| CMT09 | [댓글 삭제](./community.md#cmt09-댓글-삭제) | DELETE | `/comments/{commentId}` | [community.md](./community.md) |
| CMT10 | [반응 등록·변경](./community.md#cmt10-반응-등록-변경) | PUT | `/posts/{postId}/reactions/me` | [community.md](./community.md) |
| CMT11 | [반응 취소](./community.md#cmt11-반응-취소) | DELETE | `/posts/{postId}/reactions/me` | [community.md](./community.md) |

## 미정 사항 우선 검토

- [ ] 인증 제공자·토큰 정책
- [ ] Samsung Health 과거 운동 기록 데이터 계약
- [ ] 개인 세션과 그룹 참가자 연결 및 그룹 상태 전이
- [ ] 실시간 센서/코칭/워치 이벤트 전달 방식
- [ ] 동일 코스 다회 완주 시 기록 기본 비교 대상
- [ ] 자유 그룹런 선두·GPS 경로·순위 산정 및 선두 교체 규칙
- [ ] 개인정보 공개 범위·삭제 및 알림 정책
