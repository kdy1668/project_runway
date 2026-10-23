# RunWay API 명세 — 1차 MVP

> **2026-10-23 동작 결정 반영:** [자동 처리 요구사항](../requirements.md)에 따라 공개 요청과 내부 자동 처리를 분리했다. 자동 평가·전략 생성·코칭·종료 후 분석은 API 목록에서 제외되더라도 필수 구현 대상이다. 전송 기술과 미정 정책은 각 상세 문서에서 별도 표시한다.

RunWay 서비스의 **클라이언트 공개 API 설계 초안**이다. 저장소의 [1차 MVP 요구사항](../requirements.md)과 [최신 ERD](../db/erd.md)를 기준으로 정리했으며, 이 문서의 공통 규약과 색인에서 도메인별 상세 명세로 연결한다.

> **상태: 초안.** 미정 정책을 임의 확정하지 않았다. 예시 JSON은 형식을 설명하기 위한 가상 값이며, 자료형·필드 이름·동기화 정책·HTTP 상태 코드는 구현 전에 팀 검토가 필요하다. 다른 프로젝트인 FEELM의 ID·영화 도메인 규칙을 RunWay에 복사하지 않았다.

## 문서 구성

| 문서 | 도메인 | API 수 |
|---|---|---:|
| [인증·사용자·러닝 프로필](./users.md) | 인증·사용자·러닝 프로필 | 25 |
| [워치·건강 데이터](./devices-health.md) | 워치·건강 데이터 | 8 |
| [운동 준비도](./readiness.md) | 운동 준비도 | 1 |
| [러닝 코스](./courses.md) | 러닝 코스 | 5 |
| [러닝 세션](./sessions.md) | 러닝 세션 | 8 |
| [AI 페이스·실시간 분석·BPM](./pace-coaching.md) | AI 페이스·실시간 분석·BPM | 1 |
| [러닝 기록·분석](./running-records.md) | 러닝 기록·분석 | 5 |
| [그룹런](./group-runs.md) | 그룹런 | 13 |
| [크루](./crews.md) | 크루 | 10 |
| [커뮤니티](./community.md) | 커뮤니티 | 13 |
| [공통 파일](./files.md) | 이미지 업로드 | 1 |

총 **90개 공개 API 후보**. 크루 멤버 내보내기(M09)는 선택 기능이다. 내부 자동 처리와 실시간 이벤트는 이 수에 포함하지 않는다.

Wear OS 앱의 원본 업로드 계약은 [워치 기록 업로드 계약](wear-upload-api.md)에서 별도로 관리한다. 서비스 API 구현 시 `W07`의 배치 동기화 계약과 함께 검토해야 한다.

알림 발생 계기·수신자와 추가 후보는 [알림 정책](../requirements.md#알림-정책)에 정리했다. 미확정 제안은 해당 절에서 구분하며 알림함·조회 API를 자동으로 추가하지 않는다.

## 공통 규약

### 기본 URL 및 콘텐츠

- Base path: `/api/v1`
- `Content-Type: application/json; charset=utf-8` (예외: [F01 이미지 업로드](./files.md#f01-이미지-업로드)는 `multipart/form-data`)
- 키: `camelCase`; 식별자: UUID 문자열(ERD 기준); 시간: ISO 8601 UTC 문자열
- 거리: m; 구간·경과 시간: sec; 페이스: sec/km; 심박수: bpm; 케이던스: spm
- 좌표: WGS84, GeoJSON 좌표 순서 `[longitude, latitude]`
- 로그인은 아이디·비밀번호 방식이다(화면 설계 v10). JWT Bearer 방식은 설계 제안이며 토큰 저장/회전 정책은 미정.

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
- 목표는 출발 전 S08로 수정 가능하며 실제 운동 시작 시 고정. 러닝 중 AI가 갱신하는 것은 **안내 페이스·코칭**이다.
- 개인런·그룹런 모두 코스 지정과 자유러닝 허용(`courseId = null`).
- 개인 세션은 S06으로 종료한다. 실제 시작 참가자 전원 개인 종료 시 그룹은 자동 종료하며, G12는 그룹장만 실행하는 예외 상황의 그룹 전체 강제 종료다.
- 같은 코스 과거 기록의 **동일 거리 도달 시간**을 비교한다. 여러 과거 기록 중 기본 선택 정책은 미정.
- 지정 코스 그룹은 코스 진행률을, 자유 그룹은 선두의 실제 주행 경로를 기준으로 순위 산정을 검토한다. GPS만으로 동일 선상 선후 관계가 자동 확정되는 것은 아니다.
- 삼성 헬스 과거 운동 기록의 세부 저장 구조, 실시간 전송 수단 및 동기화 빈도는 미정이다.

### 공용 코스 상태와 사용자 저장 목록

- 코스 추천 조건 필터에는 `ACTIVE` 상태의 공용 코스만 사용한다. 공용 이름 검색은 없으며 저장 별명은 사용자 북마크에만 둔다.
- `MERGED`, `BLOCKED` 코스는 추천에서 제외한다. 저장한 코스가 `MERGED`이면 대표 코스를 함께 안내한다.
- 러닝 경로가 공용 코스로 자동 등록되어도 코스 원본을 직접 수정하거나 삭제할 수 없다.
- 코스 저장 해제는 사용자의 북마크 관계만 삭제하며 공용 코스 원본과 상태를 변경하지 않는다.

### 문서 표기

- ID는 기존 v2 후보 ID(U01, W01, … CMT11)를 유지하며 재사용하지 않는다.
- `O`는 필수, `X`는 선택, `조건부`는 다른 필드 값에 따라 필수임을 뜻한다. 예시 필드 중 타입을 확인할 수 없는 경우 `(확인 필요)`라고 표시한다.
- 상세 응답 JSON의 값은 **구조 예시**이지 실데이터 계약 완료를 의미하지 않는다.
- `M09`는 1차 MVP 필수 범위 밖 선택 기능이다.

## 전체 API 목록

| ID | 이름 | Method | Endpoint | 문서 |
|---|---|---|---|---|
| U01 | [로그인](./users.md#u01-로그인) | POST | `/auth/login` | [users.md](./users.md) |
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
| U15 | [회원가입](./users.md#u15-회원가입) | POST | `/auth/signup` | [users.md](./users.md) |
| U16 | [아이디 사용 가능 여부 확인](./users.md#u16-아이디-사용-가능-여부-확인) | GET | `/auth/login-id/availability` | [users.md](./users.md) |
| U17 | [회원탈퇴 사전 정보 조회](./users.md#u17-회원탈퇴-사전-정보-조회) | GET | `/users/me/withdrawal-summary` | [users.md](./users.md) |
| U18 | [회원탈퇴](./users.md#u18-회원탈퇴) | DELETE | `/users/me` | [users.md](./users.md) |
| U19 | [앱 설정 조회](./users.md#u19-앱-설정-조회) | GET | `/users/me/settings` | [users.md](./users.md) |
| U20 | [앱 설정 변경](./users.md#u20-앱-설정-변경) | PATCH | `/users/me/settings` | [users.md](./users.md) |
| U21 | [러너 프로필 조회](./users.md#u21-러너-프로필-조회) | GET | `/users/{userId}/profile` | [users.md](./users.md) |
| U22 | [러너 팔로우·요청](./users.md#u22-러너-팔로우요청) | PUT | `/users/{userId}/follow` | [users.md](./users.md) |
| U23 | [러너 팔로우·요청 취소](./users.md#u23-러너-팔로우요청-취소) | DELETE | `/users/{userId}/follow` | [users.md](./users.md) |
| U24 | [받은 팔로우 요청 목록](./users.md#u24-받은-팔로우-요청-목록) | GET | `/users/me/follow-requests` | [users.md](./users.md) |
| U25 | [팔로우 요청 승인·거절](./users.md#u25-팔로우-요청-승인거절) | PATCH | `/users/me/follow-requests/{requesterId}` | [users.md](./users.md) |
| W01 | [기기 등록](./devices-health.md#w01-기기-등록) | POST | `/devices` | [devices-health.md](./devices-health.md) |
| W02 | [등록 기기 조회](./devices-health.md#w02-등록-기기-조회) | GET | `/devices` | [devices-health.md](./devices-health.md) |
| W03 | [기기 연결 해제](./devices-health.md#w03-기기-연결-해제) | DELETE | `/devices/{deviceId}` | [devices-health.md](./devices-health.md) |
| W04 | [수집 동의·철회](./devices-health.md#w04-수집-동의철회) | POST | `/consents` | [devices-health.md](./devices-health.md) |
| W05 | [동의 상태 조회](./devices-health.md#w05-동의-상태-조회) | GET | `/consents` | [devices-health.md](./devices-health.md) |
| W06 | [Samsung Health 데이터 동기화](./devices-health.md#w06-samsung-health-데이터-동기화) | POST | `/health-records/sync` | [devices-health.md](./devices-health.md) |
| W07 | [워치 운동 배치 동기화](./devices-health.md#w07-워치-운동-배치-동기화) | POST | `/sync/batches` | [devices-health.md](./devices-health.md) |
| W08 | [동기화 진행 상태 조회](./devices-health.md#w08-동기화-진행-상태-조회) | GET | `/devices/{deviceId}/sync/streams/{streamKey}/progress` | [devices-health.md](./devices-health.md) |
| R02 | [최신 준비도 조회](./readiness.md#r02-최신-준비도-조회) | GET | `/readiness-assessments/latest` | [readiness.md](./readiness.md) |
| C01 | [코스 추천](./courses.md#c01-코스-추천) | POST | `/courses/recommendations` | [courses.md](./courses.md) |
| C03 | [코스 상세 조회](./courses.md#c03-코스-상세-조회) | GET | `/courses/{courseId}` | [courses.md](./courses.md) |
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
| S08 | [출발 전 러닝 설정 수정](./sessions.md#s08-출발-전-러닝-설정-수정) | PATCH | `/running-sessions/{sessionId}` | [sessions.md](./sessions.md) |
| P07 | [세션 BPM 조절](./pace-coaching.md#p07-세션-bpm-조절) | PUT | `/running-sessions/{sessionId}/bpm` | [pace-coaching.md](./pace-coaching.md) |
| H01 | [러닝 기록 목록](./running-records.md#h01-러닝-기록-목록) | GET | `/running-records` | [running-records.md](./running-records.md) |
| H02 | [러닝 기록 상세](./running-records.md#h02-러닝-기록-상세) | GET | `/running-records/{sessionId}` | [running-records.md](./running-records.md) |
| H03 | [구간별 러닝 분석 결과 조회](./running-records.md#h03-구간별-러닝-분석-결과-조회) | GET | `/running-records/{sessionId}/splits` | [running-records.md](./running-records.md) |
| H06 | [러닝 통계 요약](./running-records.md#h06-러닝-통계-요약) | GET | `/running-records/statistics` | [running-records.md](./running-records.md) |
| H07 | [평균 페이스 추이](./running-records.md#h07-평균-페이스-추이) | GET | `/running-records/statistics/pace-trend` | [running-records.md](./running-records.md) |
| G01 | [그룹런 생성](./group-runs.md#g01-그룹런-생성) | POST | `/group-runs` | [group-runs.md](./group-runs.md) |
| G02 | [그룹런 검색](./group-runs.md#g02-그룹런-검색) | GET | `/group-runs` | [group-runs.md](./group-runs.md) |
| G03 | [그룹런 상세](./group-runs.md#g03-그룹런-상세) | GET | `/group-runs/{groupRunId}` | [group-runs.md](./group-runs.md) |
| G04 | [그룹런 정보 수정](./group-runs.md#g04-그룹런-정보-수정) | PATCH | `/group-runs/{groupRunId}` | [group-runs.md](./group-runs.md) |
| G05 | [그룹런 참가](./group-runs.md#g05-그룹런-참가) | POST | `/group-runs/{groupRunId}/join` | [group-runs.md](./group-runs.md) |
| G06 | [그룹런 참가 취소](./group-runs.md#g06-그룹런-참가-취소) | DELETE | `/group-runs/{groupRunId}/participants/me` | [group-runs.md](./group-runs.md) |
| G07 | [그룹런 참가자 조회](./group-runs.md#g07-그룹런-참가자-조회) | GET | `/group-runs/{groupRunId}/participants` | [group-runs.md](./group-runs.md) |
| G09 | [그룹런 시작](./group-runs.md#g09-그룹런-시작) | POST | `/group-runs/{groupRunId}/start` | [group-runs.md](./group-runs.md) |
| G10 | [그룹런 실시간 현황·순위](./group-runs.md#g10-그룹런-실시간-현황순위) | GET | `/group-runs/{groupRunId}/live` | [group-runs.md](./group-runs.md) |
| G12 | [그룹런 전체 강제 종료](./group-runs.md#g12-그룹런-전체-강제-종료) | POST | `/group-runs/{groupRunId}/force-finish` | [group-runs.md](./group-runs.md) |
| G13 | [그룹런 취소](./group-runs.md#g13-그룹런-취소) | POST | `/group-runs/{groupRunId}/cancel` | [group-runs.md](./group-runs.md) |
| G14 | [그룹런 결과 조회](./group-runs.md#g14-그룹런-결과-조회) | GET | `/group-runs/{groupRunId}/results` | [group-runs.md](./group-runs.md) |
| G16 | [그룹런 대기방 준비 완료](./group-runs.md#g16-그룹런-대기방-준비-완료) | POST | `/group-runs/{groupRunId}/participants/me/ready` | [group-runs.md](./group-runs.md) |
| M01 | [크루 검색](./crews.md#m01-크루-검색) | GET | `/crews` | [crews.md](./crews.md) |
| M02 | [크루 상세](./crews.md#m02-크루-상세) | GET | `/crews/{crewId}` | [crews.md](./crews.md) |
| M03 | [크루 생성](./crews.md#m03-크루-생성) | POST | `/crews` | [crews.md](./crews.md) |
| M04 | [크루 가입 신청](./crews.md#m04-크루-가입-신청) | POST | `/crews/{crewId}/join-requests` | [crews.md](./crews.md) |
| M05 | [크루 가입 신청 목록](./crews.md#m05-크루-가입-신청-목록) | GET | `/crews/{crewId}/join-requests` | [crews.md](./crews.md) |
| M06 | [크루 가입 승인·거절](./crews.md#m06-크루-가입-승인거절) | PATCH | `/crews/{crewId}/join-requests/{userId}` | [crews.md](./crews.md) |
| M07 | [크루 멤버 목록](./crews.md#m07-크루-멤버-목록) | GET | `/crews/{crewId}/members` | [crews.md](./crews.md) |
| M08 | [크루 탈퇴](./crews.md#m08-크루-탈퇴) | DELETE | `/crews/{crewId}/members/me` | [crews.md](./crews.md) |
| M09 | [크루 멤버 내보내기](./crews.md#m09-크루-멤버-내보내기) | DELETE | `/crews/{crewId}/members/{userId}` | [crews.md](./crews.md) |
| M10 | [내 크루 목록](./crews.md#m10-내-크루-목록) | GET | `/users/me/crews` | [crews.md](./crews.md) |
| CMT01 | [게시물 작성](./community.md#cmt01-게시물-작성) | POST | `/posts` | [community.md](./community.md) |
| CMT02 | [게시물 목록](./community.md#cmt02-게시물-목록) | GET | `/posts` | [community.md](./community.md) |
| CMT03 | [게시물 상세](./community.md#cmt03-게시물-상세) | GET | `/posts/{postId}` | [community.md](./community.md) |
| CMT04 | [게시물 수정](./community.md#cmt04-게시물-수정) | PATCH | `/posts/{postId}` | [community.md](./community.md) |
| CMT05 | [게시물 삭제](./community.md#cmt05-게시물-삭제) | DELETE | `/posts/{postId}` | [community.md](./community.md) |
| CMT06 | [댓글 목록](./community.md#cmt06-댓글-목록) | GET | `/posts/{postId}/comments` | [community.md](./community.md) |
| CMT07 | [댓글 작성](./community.md#cmt07-댓글-작성) | POST | `/posts/{postId}/comments` | [community.md](./community.md) |
| CMT08 | [댓글 수정](./community.md#cmt08-댓글-수정) | PATCH | `/comments/{commentId}` | [community.md](./community.md) |
| CMT09 | [댓글 삭제](./community.md#cmt09-댓글-삭제) | DELETE | `/comments/{commentId}` | [community.md](./community.md) |
| CMT10 | [반응 등록·변경](./community.md#cmt10-반응-등록변경) | PUT | `/posts/{postId}/reactions/me` | [community.md](./community.md) |
| CMT11 | [반응 취소](./community.md#cmt11-반응-취소) | DELETE | `/posts/{postId}/reactions/me` | [community.md](./community.md) |
| CMT12 | [커뮤니티 지역 목록](./community.md#cmt12-커뮤니티-지역-목록) | GET | `/regions` | [community.md](./community.md) |
| CMT13 | [통합 검색](./community.md#cmt13-통합-검색) | GET | `/search` | [community.md](./community.md) |
| F01 | [이미지 업로드](./files.md#f01-이미지-업로드) | POST | `/images` | [files.md](./files.md) |

## 화면 설계 v10 대조 (2026-10-23)

화면 설계서 `RUNWAY 화면 맵 v10`과 대조해 빠진 API를 추가하고 부족한 파라미터를 보완했다. 추가·수정한 API에는 `관련 화면` 항목을 달았다. **응답 형식은 ERD 수정 중이라 화면 표시 항목 기준 후보로만 적었으며 ERD 확정 후 갱신한다.**

| 구분 | API | 내용 |
|---|---|---|
| 방식 변경 | U01 | 외부 제공자 토큰 로그인 → 아이디·비밀번호 로그인, 5회 실패 시 10분 제한 |
| 필드 변경 | U04·U05 | `ageGroup` → `birthDate`(생년월일), 프로필 사진 `profileImageId` |
| 신규 | U15~U23 | 회원가입, 아이디 중복 확인, 회원탈퇴(사전 정보·실행), 앱 설정 조회·변경, 러너 프로필, 팔로우·취소 |
| 신규 | H06·H07 | 러닝 통계 요약(주·월·년), 평균 페이스 추이 |
| 신규 | G16 | 대기방 준비 완료. 화면 v10에 있던 불참 기능은 사용자 결정에 따라 제외 |
| 신규 | M10 | 내 크루 목록(승인 대기 포함). M11 크루 자주 만난 장소는 사용자 결정으로 제외 |
| 신규 | CMT12·CMT13·F01 | 커뮤니티 지역 목록, 통합 검색, 이미지 업로드 |
| 파라미터 보완 | W01·W04 | 푸시 토큰, 이용약관·개인정보 동의 유형 |
| 파라미터 보완 | C01·C07·C09 | 준비도 자동 반영, 개인 저장 별명, 조건·난이도 필터 |
| 파라미터 보완 | S01 | 자유 러닝 목표 생략 허용, 경쟁 모드 비교 기록 |
| 파라미터 보완 | H01 | 개인/그룹런 탭, 정렬 |
| 파라미터 보완 | G01·G02·G13 | 만남 장소 상세·응답 마감·반복, 내 근처·내 참가·레벨 필터, 취소 사유·남길 말 |
| 파라미터 보완 | M01·M03 | 내 근처·레벨 필터, 대표 사진·지역·레벨·정원 |
| 파라미터 보완 | CMT01·CMT02·CMT04 | 사진·계정 공개 정책, 지역·팔로잉 필터, 코스 공유 수정 |

화면과 기존 정책이 충돌해 결정이 필요한 항목:

- [x] C04 수동 코스 등록 제외. 러닝 경로 자동 등록으로 변경, 개인 코스 저장 유지
- [ ] 8.2 프로필 수정 '연령대' UI ↔ 생년월일 입력 (U05)
- [x] 크루 가입 방식 — 크루장 승인 필수로 확정 (M03·M04)
- [x] 그룹런은 참가·참가 취소만 제공. 별도 불참 응답 제외
- [ ] 7.1 검색창 유지 여부 (CMT13)

## 미정 사항 우선 검토

- [ ] 토큰 정책, 로그인 실패 제한 저장 방식
- [ ] Samsung Health 과거 운동 기록 데이터 계약
- [ ] 개인 세션과 그룹 참가자 연결 및 그룹 상태 전이
- [ ] 실시간 센서/코칭/워치 이벤트 전달 방식
- [ ] 동일 코스 다회 완주 시 기록 기본 비교 대상
- [ ] 자유 그룹런 선두·GPS 경로·순위 산정 및 선두 교체 규칙
- [ ] 개인정보 공개 범위·삭제 및 알림 정책

## 자동 처리 분리 결과 (2026-10-23)

| 기존 ID | 공개 API에서 제외한 이유 | 기능 제공 방식 |
|---|---|---|
| R01 | 컨디션 입력·평가 실행 요청 없음 | 건강·활동 데이터 변경 시 자동 평가, R02 결과 조회 |
| P01 | 세션 준비 후 별도 전략 생성 요청 불필요 | 내부 자동 생성, 세션 준비 결과·갱신 전달 |
| P05 | 운동 중 기록 비교는 자동 계산 | 세션 복구 상태와 지속 전달에 포함 |
| P06 | 내부 개인화 프로필 조회 화면 없음 | 모델 내부 관리, 필요한 목표 BPM만 전달 |
| G08 | 별도 공동 페이스 계산 요청 없음 | 내부 자동 계산, G03 대기방 조회 및 변경 전달 |
| G11 | 알림 목록 조회 화면 없음 | 페이스·격차 등 조건 충족 시 알림 전송 |
| G15 | 사용자 결정에 따라 불참 기능 제외 | G05 참가·G06 참가 취소 |

제외한 ID는 재사용하지 않는다. G10은 그룹 상태 복구용 조회이며 코칭·순위 계산의 실행 조건이 아니다.
P07은 세션 BPM 조절, G12는 그룹장 전용 전체 강제 종료로 변경했다. 경로·필드의 구체적 형식은 설계 제안이며 구현 완료를 뜻하지 않는다.

## 추가 검토 반영 — 코스·지속 수집·계정 공개 정책

| ID | 반영 내용 |
|---|---|
| C02 | 별도 공용 이름 검색 제외. C01 추천 조건 필터로 통합 |
| C04 | 수동 등록 API 제거. 러닝 경로 확정 후 자동 코스 반영 |
| C07·C09 | 공용 코스 이름 없이 본인 저장 관계의 별명 설정·변경·조회 |
| M11 | 크루 자주 만난 장소 기능 제거 |
| W06·W07 | 앱 서비스의 자동 업로드 API. 서버 내부 계산과 구분. W07은 실시간 소량 배치·오프라인 재전송 통합 |
| P02·P03·P04 | 별도 REST 요청 제외. 전략·코칭은 세션 준비·갱신·복구로 제공, 측정값은 W07 자동 전송 |
| H04 | 원본 GPS 별도 조회 제거. H02·공유 게시물에 표시용 경로 그림 제공 |
| H05 | 기록별 공개 설정 제거. 원본 기록은 본인, 공유 게시물·프로필은 계정 정책 적용 |
| U13·U14 | 계정 공개 여부로 통일. 공개는 전체, 비공개는 본인·승인된 팔로워. 공개 전환 시 유효한 대기 요청 전부 자동 승인 |
| U22·U23 | 공개 계정 즉시 팔로우 / 비공개 계정 요청 생성, 팔로우·대기 요청 취소 |
| U24·U25 | 받은 요청 목록, 본인에게 들어온 요청 승인·거절 추가 |
| CMT13 | 공용 코스 이름 검색 제외. 러너·크루 검색만 유지 |

계정 정책은 [계정 공개·팔로우 명세](./users.md)를 따른다. 기존 ERD와 화면 맵의 이름·공개 필드·조회 전제는 해당 사용자 결정에 맞춰 후속 정리가 필요하다.

## API·자동 실행 재점검

남은 기술 계약은 아래 구현 전 검토 항목에 정리했다. 현재 90개 API는 구현 완료 명세가 아닌 후보 초안이며 실시간 전달·오프라인 이벤트·결과 준비 상태의 세부 계약이 남아 있다.

최신 사용자 결정: 출발 전 목표 수정(S08)·출발 후 고정, 자유러닝 목표는 선택 입력이며 모드별 AI 동작 확정([상세 정책](../requirements.md#러닝-모드별-ai-동작)), 실제 시작 참가자만 그룹 진행 판정, 강제 종료 시각까지 기록 반영, 러닝 경로 자동 코스 등록(C04 제거).

## 구현 전에 구체화할 기술 계약

- **실시간 전달:** 연결·인증·구독·대상 세션, 전략·코칭·그룹·종료 메시지 구조, 버전·적용 시각, 재연결·중복·만료 정책. REST 조회 삭제만으로 전달 계약이 완성되지 않는다.
- **오프라인 운동 제어:** S03~S06의 commandId만으로 원래 발생 시각·명령 순서가 표현되지 않는다. W07 제어 이벤트 스키마와 연결해 실제 운동 시각·정지 구간·종료를 복구해야 한다.
- **분석 준비·실패 상태:** S01/S02/S06/H02/H03/G14의 준비 중·실패·잠정·완료 및 결과 버전을 정의해야 한다. `{}` 응답 예시는 완성 계약이 아니다.
- **W07·W08:** 스트림별 연속 sequence의 범위·재설치·세션 경계, 타입별 items, ACK 영속성·누락·해시 충돌과 원본 워치 업로드 v2 매핑이 필요하다. W07 초안의 문자열 schemaVersion과 원본 기록의 정수 schemaVersion은 같다고 가정하지 않는다.
- **W06 지표 가용성:** 삼성헬스·직접 워치 수집·계산 지표의 출처, HRV·안정시 심박 등의 SDK·권한·기기 가용성을 실제 대상 버전으로 검증해야 한다. 이번 검토에서 추가 SDK 검증은 하지 않았다.
- **후속 작업 복구:** 원본 저장 성공과 분석·알림 전달 성공을 구분하고 실패 재시도·중복 반영 방지·재집계 시 이전 집계 대체를 정의해야 한다.
- **푸시 수신 등록:** W01은 최초 pushToken만 설명한다. 토큰 교체·로그아웃·계정 전환·기기 해제 시 수신 매핑 갱신·폐기 계약이 필요하다. 별도 갱신 API 또는 W01 재등록 동작 중 선택은 미정이다.
- **알림 설정:** U19/U20의 groupRun/coaching/community 분류만으로 크루 가입·팔로우 알림 설정을 설명하지 못한다. 새 분류·기본값·필수 상태 전달과의 분리를 정의해야 한다.
- **개인정보·ERD:** 계정 공개·팔로우 요청, 개인 별명, 주관적 컨디션·기록별 공개 필드 정리는 ERD 후속 검토 대상이다. 승인되지 않은 데이터 모델 변경은 수행하지 않았다.
