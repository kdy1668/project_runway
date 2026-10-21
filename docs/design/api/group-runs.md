# API 명세 — 그룹런

[API 명세 색인](README.md)으로 돌아가기. 공통 규약은 [API 명세](README.md#공통-규약)를 따른다.

| ID | 이름 | Method | Endpoint | 단계 | 인증 |
|---|---|---|---|---|---|
| [G01](#g01-그룹런-생성) | 그룹런 생성 | POST | `/group-runs` | 1차 MVP | 회원 |
| [G02](#g02-그룹런-검색) | 그룹런 검색 | GET | `/group-runs` | 1차 MVP | 회원 |
| [G03](#g03-그룹런-상세) | 그룹런 상세 | GET | `/group-runs/{groupRunId}` | 1차 MVP | 회원 |
| [G04](#g04-그룹런-정보-수정) | 그룹런 정보 수정 | PATCH | `/group-runs/{groupRunId}` | 1차 MVP | 회원 |
| [G05](#g05-그룹런-참가) | 그룹런 참가 | POST | `/group-runs/{groupRunId}/join` | 1차 MVP | 회원 |
| [G06](#g06-그룹런-참가-취소) | 그룹런 참가 취소 | DELETE | `/group-runs/{groupRunId}/participants/me` | 1차 MVP | 회원 |
| [G07](#g07-그룹런-참가자-조회) | 그룹런 참가자 조회 | GET | `/group-runs/{groupRunId}/participants` | 1차 MVP | 회원 |
| [G08](#g08-그룹-초기-페이스-추천) | 그룹 초기 페이스 추천 | POST | `/group-runs/{groupRunId}/pace-recommendations` | 1차 MVP | 회원 |
| [G09](#g09-그룹런-시작) | 그룹런 시작 | POST | `/group-runs/{groupRunId}/start` | 1차 MVP | 회원 |
| [G10](#g10-그룹런-실시간-현황-순위) | 그룹런 실시간 현황·순위 | GET | `/group-runs/{groupRunId}/live` | 1차 MVP | 회원 |
| [G11](#g11-그룹런-알림-조회) | 그룹런 알림 조회 | GET | `/group-runs/{groupRunId}/notifications` | 1차 MVP | 회원 |
| [G12](#g12-그룹런-전체-종료) | 그룹런 전체 종료 | POST | `/group-runs/{groupRunId}/finish` | 1차 MVP | 회원 |
| [G13](#g13-그룹런-취소) | 그룹런 취소 | POST | `/group-runs/{groupRunId}/cancel` | 1차 MVP | 회원 |
| [G14](#g14-그룹런-결과-조회) | 그룹런 결과 조회 | GET | `/group-runs/{groupRunId}/results` | 1차 MVP | 회원 |

## G01 그룹런 생성

`POST` `/api/v1/group-runs`

| 항목 | 값 |
|---|---|
| 단계 | 1차 MVP |
| 인증 | 회원 |
| 관련 요구사항 | GRP-001~004, GRP-006~008 / MAT-004 |
| 미정 사항 | 있음 |
| 비고 | API 요청/응답 필드와 값 제한은 검토용 제안 |

### 설명

코스 지정 또는 선두를 따르는 자유그룹런, 시간/페이스 상호 환산.

### 인증 및 권한

- 로그인 사용자 본인 또는 서비스 리소스 접근 권한 검사.
- 건강정보·실시간 위치·타인 기록 조회 시 동의 상태 및 공개 범위가 우선한다.

### Path Parameters

없음

### Query Parameters

없음

### Request Body

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `title` | string / object (확인 필요) | O | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `description` | string / object (확인 필요) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `crewId` | string (UUID) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `courseId` | string (UUID) | X | 선택한 코스 식별자. 개인·그룹 자유러닝은 null/생략 가능 |
| `scheduledAt` | string (ISO 8601) | X | 그룹런 예정 시작시각(UTC) |
| `meetingPosition` | GeoJSON | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `capacity` | number | X | 참가 인원 상한(허용 범위 미정) |
| `targetDistanceM` | number | O | 목표 거리, 미터, 양수 |
| `goalInputType` | string (제안) | O | TIME/PACE 중 하나 |
| `targetDurationSec` | number | X | 목표 완주 시간, 초, 양수 |
| `targetPaceSecPerKm` | number | X | 목표 페이스, 초/km, 양수 |

```json
{
  "title": "러닝 모임",
  "targetDistanceM": 5000,
  "goalInputType": "TIME",
  "targetDurationSec": 1800
}
```

### Response

`201 Created (제안)`

```json
{}
```

응답 필드 정의(상세 객체는 미정 정책 확정 후 보완):

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `id` | string (UUID) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `hostId` | string (UUID) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `status` | string (제안) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `courseId` | string (UUID) | X | 선택한 코스 식별자. 개인·그룹 자유러닝은 null/생략 가능 |
| `targetDistanceM` | number | X | 목표 거리, 미터, 양수 |
| `targetDurationSec` | number | X | 목표 완주 시간, 초, 양수 |
| `capacity` | number | X | 참가 인원 상한(허용 범위 미정) |

### 오류 응답

- `403 COURSE_INACCESSIBLE`
- `422 INVALID_GOAL`
- 공통 인증 오류 `401 UNAUTHORIZED`, 권한 오류 `403 FORBIDDEN`, 요청 형식 오류 `400 VALIDATION_ERROR` (해당 시).

### 처리 규칙

- 코스 지정 또는 선두를 따르는 자유그룹런, 시간/페이스 상호 환산.
- 사용자 소유권·그룹 참가 권한·상태 전이·재요청 여부를 검증한다(적용 범위는 API별로 결정).
- 예시는 **명세 구조를 보여주는 가상 값**이며, 확정되지 않은 제한·동기화 주기·AI 호출 주기를 의미하지 않는다.

### 상태값

- RECRUITING / READY / RUNNING / COMPLETED / CANCELLED (허용 전이 검토).

### 미정 사항

- [ ] 요청·응답의 세부 필드 타입, 허용 범위, nullable 규칙 및 실제 JSON 구조 검토
- [ ] HTTP 성공 코드 및 각 예외의 오류 코드 최종 확정
- [ ] 실시간 전달 채널, 선두 경로 기준 순위·동기화 처리 확정

## G02 그룹런 검색

`GET` `/api/v1/group-runs`

| 항목 | 값 |
|---|---|
| 단계 | 1차 MVP |
| 인증 | 회원 |
| 관련 요구사항 | GRP-001~004, GRP-006~008 / MAT-004 |
| 미정 사항 | 있음 |
| 비고 | API 요청/응답 필드와 값 제한은 검토용 제안 |

### 설명

모집 중 그룹런 탐색.

### 인증 및 권한

- 로그인 사용자 본인 또는 서비스 리소스 접근 권한 검사.
- 건강정보·실시간 위치·타인 기록 조회 시 동의 상태 및 공개 범위가 우선한다.

### Path Parameters

없음

### Query Parameters

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `status` | string (제안) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `crewId` | string (UUID) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `scheduledFrom` | string / object (확인 필요) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `cursor` | string / object (확인 필요) | X | 서버 발급 불투명 페이지 커서 |
| `limit` | number | X | 조회 결과 최대 개수(최대값 미정) |

### Request Body

없음


### Response

`200 OK (제안)`

```json
{}
```

응답 필드 정의(상세 객체는 미정 정책 확정 후 보완):

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `items` | array | X | 수집된 이벤트/측정 배치 목록. 상세 타입별 구성 미정 |
| `page` | string / object (확인 필요) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |

### 오류 응답

- `400 INVALID_FILTER`
- 공통 인증 오류 `401 UNAUTHORIZED`, 권한 오류 `403 FORBIDDEN`, 요청 형식 오류 `400 VALIDATION_ERROR` (해당 시).

### 처리 규칙

- 모집 중 그룹런 탐색.
- 사용자 소유권·그룹 참가 권한·상태 전이·재요청 여부를 검증한다(적용 범위는 API별로 결정).
- 예시는 **명세 구조를 보여주는 가상 값**이며, 확정되지 않은 제한·동기화 주기·AI 호출 주기를 의미하지 않는다.

### 상태값

- RECRUITING / READY / RUNNING / COMPLETED / CANCELLED (허용 전이 검토).

### 미정 사항

- [ ] 요청·응답의 세부 필드 타입, 허용 범위, nullable 규칙 및 실제 JSON 구조 검토
- [ ] HTTP 성공 코드 및 각 예외의 오류 코드 최종 확정
- [ ] 실시간 전달 채널, 선두 경로 기준 순위·동기화 처리 확정


## G03 그룹런 상세

`GET` `/api/v1/group-runs/{groupRunId}`

| 항목 | 값 |
|---|---|
| 단계 | 1차 MVP |
| 인증 | 회원 |
| 관련 요구사항 | GRP-001~004, GRP-006~008 / MAT-004 |
| 미정 사항 | 있음 |
| 비고 | API 요청/응답 필드와 값 제한은 검토용 제안 |

### 설명

코스 없는 그룹런은 선두 추종 자유러닝.

### 인증 및 권한

- 로그인 사용자 본인 또는 서비스 리소스 접근 권한 검사.
- 건강정보·실시간 위치·타인 기록 조회 시 동의 상태 및 공개 범위가 우선한다.

### Path Parameters

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `groupRunId` | string (UUID) | O | 그룹런 식별자 |

### Query Parameters

없음

### Request Body

없음


### Response

`200 OK (제안)`

```json
{}
```

응답 필드 정의(상세 객체는 미정 정책 확정 후 보완):

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `id` | string (UUID) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `title` | string / object (확인 필요) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `description` | string / object (확인 필요) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `hostId` | string (UUID) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `crewId` | string (UUID) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `courseId` | string (UUID) | X | 선택한 코스 식별자. 개인·그룹 자유러닝은 null/생략 가능 |
| `scheduledAt` | string (ISO 8601) | X | 그룹런 예정 시작시각(UTC) |
| `meetingPosition` | GeoJSON | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `capacity` | number | X | 참가 인원 상한(허용 범위 미정) |
| `participantCount` | number | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `status` | string (제안) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `targetDistanceM` | number | X | 목표 거리, 미터, 양수 |
| `targetDurationSec` | number | X | 목표 완주 시간, 초, 양수 |
| `goalPaceSecPerKm` | string / object (확인 필요) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |

### 오류 응답

- `404 GROUP_NOT_FOUND`
- 공통 인증 오류 `401 UNAUTHORIZED`, 권한 오류 `403 FORBIDDEN`, 요청 형식 오류 `400 VALIDATION_ERROR` (해당 시).

### 처리 규칙

- 코스 없는 그룹런은 선두 추종 자유러닝.
- 사용자 소유권·그룹 참가 권한·상태 전이·재요청 여부를 검증한다(적용 범위는 API별로 결정).
- 예시는 **명세 구조를 보여주는 가상 값**이며, 확정되지 않은 제한·동기화 주기·AI 호출 주기를 의미하지 않는다.

### 상태값

- RECRUITING / READY / RUNNING / COMPLETED / CANCELLED (허용 전이 검토).

### 미정 사항

- [ ] 요청·응답의 세부 필드 타입, 허용 범위, nullable 규칙 및 실제 JSON 구조 검토
- [ ] HTTP 성공 코드 및 각 예외의 오류 코드 최종 확정
- [ ] 실시간 전달 채널, 선두 경로 기준 순위·동기화 처리 확정


## G04 그룹런 정보 수정

`PATCH` `/api/v1/group-runs/{groupRunId}`

| 항목 | 값 |
|---|---|
| 단계 | 1차 MVP |
| 인증 | 회원 |
| 관련 요구사항 | GRP-001~004, GRP-006~008 / MAT-004 |
| 미정 사항 | 있음 |
| 비고 | API 요청/응답 필드와 값 제한은 검토용 제안 |

### 설명

그룹 호스트, 시작 전 수정. 공동 최초 목표 변경 허용 정책 미정.

### 인증 및 권한

- 로그인 사용자 본인 또는 서비스 리소스 접근 권한 검사.
- 건강정보·실시간 위치·타인 기록 조회 시 동의 상태 및 공개 범위가 우선한다.

### Path Parameters

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `groupRunId` | string (UUID) | O | 그룹런 식별자 |

### Query Parameters

없음

### Request Body

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `title` | string / object (확인 필요) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `description` | string / object (확인 필요) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `scheduledAt` | string (ISO 8601) | X | 그룹런 예정 시작시각(UTC) |
| `meetingPosition` | GeoJSON | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `capacity` | number | X | 참가 인원 상한(허용 범위 미정) |
| `courseId` | string (UUID) | X | 선택한 코스 식별자. 개인·그룹 자유러닝은 null/생략 가능 |

```json
{}
```

### Response

`200 OK (제안)`

```json
{}
```

응답 필드 정의(상세 객체는 미정 정책 확정 후 보완):

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `id` | string (UUID) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `title` | string / object (확인 필요) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `status` | string (제안) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `courseId` | string (UUID) | X | 선택한 코스 식별자. 개인·그룹 자유러닝은 null/생략 가능 |
| `updatedAt` | string (ISO 8601) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |

### 오류 응답

- `403 NOT_HOST`
- `409 EDIT_NOT_ALLOWED`
- 공통 인증 오류 `401 UNAUTHORIZED`, 권한 오류 `403 FORBIDDEN`, 요청 형식 오류 `400 VALIDATION_ERROR` (해당 시).

### 처리 규칙

- 그룹 호스트, 시작 전 수정. 공동 최초 목표 변경 허용 정책 미정.
- 사용자 소유권·그룹 참가 권한·상태 전이·재요청 여부를 검증한다(적용 범위는 API별로 결정).
- 예시는 **명세 구조를 보여주는 가상 값**이며, 확정되지 않은 제한·동기화 주기·AI 호출 주기를 의미하지 않는다.

### 상태값

- RECRUITING / READY / RUNNING / COMPLETED / CANCELLED (허용 전이 검토).

### 미정 사항

- [ ] 요청·응답의 세부 필드 타입, 허용 범위, nullable 규칙 및 실제 JSON 구조 검토
- [ ] HTTP 성공 코드 및 각 예외의 오류 코드 최종 확정
- [ ] 실시간 전달 채널, 선두 경로 기준 순위·동기화 처리 확정


## G05 그룹런 참가

`POST` `/api/v1/group-runs/{groupRunId}/join`

| 항목 | 값 |
|---|---|
| 단계 | 1차 MVP |
| 인증 | 회원 |
| 관련 요구사항 | GRP-001~004, GRP-006~008 / MAT-004 |
| 미정 사항 | 있음 |
| 비고 | API 요청/응답 필드와 값 제한은 검토용 제안 |

### 설명

정원 및 참가 여부 검사.

### 인증 및 권한

- 로그인 사용자 본인 또는 서비스 리소스 접근 권한 검사.
- 건강정보·실시간 위치·타인 기록 조회 시 동의 상태 및 공개 범위가 우선한다.

### Path Parameters

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `groupRunId` | string (UUID) | O | 그룹런 식별자 |

### Query Parameters

없음

### Request Body

없음


### Response

`200 OK (제안)`

```json
{}
```

응답 필드 정의(상세 객체는 미정 정책 확정 후 보완):

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `groupRunId` | string (UUID) | X | 그룹런 식별자 |
| `userId` | string (UUID) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `status` | string (제안) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `joinedAt` | string (ISO 8601) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |

### 오류 응답

- `409 FULL_OR_ALREADY_JOINED`
- `409 INVALID_GROUP_STATE`
- 공통 인증 오류 `401 UNAUTHORIZED`, 권한 오류 `403 FORBIDDEN`, 요청 형식 오류 `400 VALIDATION_ERROR` (해당 시).

### 처리 규칙

- 정원 및 참가 여부 검사.
- 사용자 소유권·그룹 참가 권한·상태 전이·재요청 여부를 검증한다(적용 범위는 API별로 결정).
- 예시는 **명세 구조를 보여주는 가상 값**이며, 확정되지 않은 제한·동기화 주기·AI 호출 주기를 의미하지 않는다.

### 상태값

- RECRUITING / READY / RUNNING / COMPLETED / CANCELLED (허용 전이 검토).

### 미정 사항

- [ ] 요청·응답의 세부 필드 타입, 허용 범위, nullable 규칙 및 실제 JSON 구조 검토
- [ ] HTTP 성공 코드 및 각 예외의 오류 코드 최종 확정
- [ ] 실시간 전달 채널, 선두 경로 기준 순위·동기화 처리 확정


## G06 그룹런 참가 취소

`DELETE` `/api/v1/group-runs/{groupRunId}/participants/me`

| 항목 | 값 |
|---|---|
| 단계 | 1차 MVP |
| 인증 | 회원 |
| 관련 요구사항 | GRP-001~004, GRP-006~008 / MAT-004 |
| 미정 사항 | 있음 |
| 비고 | API 요청/응답 필드와 값 제한은 검토용 제안 |

### 설명

시작 전 참가 취소. 러닝 중에는 개인 세션 종료 처리.

### 인증 및 권한

- 로그인 사용자 본인 또는 서비스 리소스 접근 권한 검사.
- 건강정보·실시간 위치·타인 기록 조회 시 동의 상태 및 공개 범위가 우선한다.

### Path Parameters

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `groupRunId` | string (UUID) | O | 그룹런 식별자 |

### Query Parameters

없음

### Request Body

없음


### Response

`200 OK (제안)`

```json
{}
```

응답 필드 정의(상세 객체는 미정 정책 확정 후 보완):

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `status` | string (제안) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `cancelledAt` | string (ISO 8601) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |

### 오류 응답

- `409 RUN_ALREADY_STARTED`
- 공통 인증 오류 `401 UNAUTHORIZED`, 권한 오류 `403 FORBIDDEN`, 요청 형식 오류 `400 VALIDATION_ERROR` (해당 시).

### 처리 규칙

- 시작 전 참가 취소. 러닝 중에는 개인 세션 종료 처리.
- 사용자 소유권·그룹 참가 권한·상태 전이·재요청 여부를 검증한다(적용 범위는 API별로 결정).
- 예시는 **명세 구조를 보여주는 가상 값**이며, 확정되지 않은 제한·동기화 주기·AI 호출 주기를 의미하지 않는다.

### 상태값

- RECRUITING / READY / RUNNING / COMPLETED / CANCELLED (허용 전이 검토).

### 미정 사항

- [ ] 요청·응답의 세부 필드 타입, 허용 범위, nullable 규칙 및 실제 JSON 구조 검토
- [ ] HTTP 성공 코드 및 각 예외의 오류 코드 최종 확정
- [ ] 실시간 전달 채널, 선두 경로 기준 순위·동기화 처리 확정


## G07 그룹런 참가자 조회

`GET` `/api/v1/group-runs/{groupRunId}/participants`

| 항목 | 값 |
|---|---|
| 단계 | 1차 MVP |
| 인증 | 회원 |
| 관련 요구사항 | GRP-001~004, GRP-006~008 / MAT-004 |
| 미정 사항 | 있음 |
| 비고 | API 요청/응답 필드와 값 제한은 검토용 제안 |

### 설명

참가자 역할·상태, 세션 연결. 위치는 별도 실시간 응답.

### 인증 및 권한

- 로그인 사용자 본인 또는 서비스 리소스 접근 권한 검사.
- 건강정보·실시간 위치·타인 기록 조회 시 동의 상태 및 공개 범위가 우선한다.

### Path Parameters

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `groupRunId` | string (UUID) | O | 그룹런 식별자 |

### Query Parameters

없음

### Request Body

없음


### Response

`200 OK (제안)`

```json
{}
```

응답 필드 정의(상세 객체는 미정 정책 확정 후 보완):

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `items` | array | X | 수집된 이벤트/측정 배치 목록. 상세 타입별 구성 미정 |

### 오류 응답

- `403 GROUP_FORBIDDEN`
- 공통 인증 오류 `401 UNAUTHORIZED`, 권한 오류 `403 FORBIDDEN`, 요청 형식 오류 `400 VALIDATION_ERROR` (해당 시).

### 처리 규칙

- 참가자 역할·상태, 세션 연결. 위치는 별도 실시간 응답.
- 사용자 소유권·그룹 참가 권한·상태 전이·재요청 여부를 검증한다(적용 범위는 API별로 결정).
- 예시는 **명세 구조를 보여주는 가상 값**이며, 확정되지 않은 제한·동기화 주기·AI 호출 주기를 의미하지 않는다.

### 상태값

- RECRUITING / READY / RUNNING / COMPLETED / CANCELLED (허용 전이 검토).

### 미정 사항

- [ ] 요청·응답의 세부 필드 타입, 허용 범위, nullable 규칙 및 실제 JSON 구조 검토
- [ ] HTTP 성공 코드 및 각 예외의 오류 코드 최종 확정
- [ ] 실시간 전달 채널, 선두 경로 기준 순위·동기화 처리 확정


## G08 그룹 초기 페이스 추천

`POST` `/api/v1/group-runs/{groupRunId}/pace-recommendations`

| 항목 | 값 |
|---|---|
| 단계 | 1차 MVP |
| 인증 | 회원 |
| 관련 요구사항 | GRP-001~004, GRP-006~008 / MAT-004 |
| 미정 사항 | 있음 |
| 비고 | API 요청/응답 필드와 값 제한은 검토용 제안 |

### 설명

시작 전 개인 상태와 그룹 목표로 공동 권장 페이스 제공.

### 인증 및 권한

- 로그인 사용자 본인 또는 서비스 리소스 접근 권한 검사.
- 건강정보·실시간 위치·타인 기록 조회 시 동의 상태 및 공개 범위가 우선한다.

### Path Parameters

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `groupRunId` | string (UUID) | O | 그룹런 식별자 |

### Query Parameters

없음

### Request Body

없음


### Response

`200 OK (제안)`

```json
{}
```

응답 필드 정의(상세 객체는 미정 정책 확정 후 보완):

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `revision` | number | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `targetPaceSecPerKm` | number | X | 목표 페이스, 초/km, 양수 |
| `createdAt` | string (ISO 8601) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `reasonCodes` | array | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `participantCount` | number | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |

### 오류 응답

- `409 GROUP_NOT_READY`
- `422 INSUFFICIENT_DATA`
- 공통 인증 오류 `401 UNAUTHORIZED`, 권한 오류 `403 FORBIDDEN`, 요청 형식 오류 `400 VALIDATION_ERROR` (해당 시).

### 처리 규칙

- 시작 전 개인 상태와 그룹 목표로 공동 권장 페이스 제공.
- 사용자 소유권·그룹 참가 권한·상태 전이·재요청 여부를 검증한다(적용 범위는 API별로 결정).
- 예시는 **명세 구조를 보여주는 가상 값**이며, 확정되지 않은 제한·동기화 주기·AI 호출 주기를 의미하지 않는다.

### 상태값

- RECRUITING / READY / RUNNING / COMPLETED / CANCELLED (허용 전이 검토).

### 미정 사항

- [ ] 요청·응답의 세부 필드 타입, 허용 범위, nullable 규칙 및 실제 JSON 구조 검토
- [ ] HTTP 성공 코드 및 각 예외의 오류 코드 최종 확정
- [ ] 실시간 전달 채널, 선두 경로 기준 순위·동기화 처리 확정


## G09 그룹런 시작

`POST` `/api/v1/group-runs/{groupRunId}/start`

| 항목 | 값 |
|---|---|
| 단계 | 1차 MVP |
| 인증 | 회원 |
| 관련 요구사항 | GRP-001~004, GRP-006~008 / MAT-004 |
| 미정 사항 | 있음 |
| 비고 | API 요청/응답 필드와 값 제한은 검토용 제안 |

### 설명

그룹 호스트가 시작. 개인 세션 생성·시작 연계 규칙 미정.

### 인증 및 권한

- 로그인 사용자 본인 또는 서비스 리소스 접근 권한 검사.
- 건강정보·실시간 위치·타인 기록 조회 시 동의 상태 및 공개 범위가 우선한다.

### Path Parameters

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `groupRunId` | string (UUID) | O | 그룹런 식별자 |

### Query Parameters

없음

### Request Body

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `commandId` | string (UUID) | X | 네트워크 재전송 중복 제거를 위한 명령 ID(제안) |

```json
{}
```

### Response

`200 OK (제안)`

```json
{}
```

응답 필드 정의(상세 객체는 미정 정책 확정 후 보완):

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `groupRunId` | string (UUID) | X | 그룹런 식별자 |
| `status` | string (제안) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `startedAt` | string (ISO 8601) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |

### 오류 응답

- `403 NOT_HOST`
- `409 INVALID_GROUP_STATE`
- 공통 인증 오류 `401 UNAUTHORIZED`, 권한 오류 `403 FORBIDDEN`, 요청 형식 오류 `400 VALIDATION_ERROR` (해당 시).

### 처리 규칙

- 그룹 호스트가 시작. 개인 세션 생성·시작 연계 규칙 미정.
- 사용자 소유권·그룹 참가 권한·상태 전이·재요청 여부를 검증한다(적용 범위는 API별로 결정).
- 예시는 **명세 구조를 보여주는 가상 값**이며, 확정되지 않은 제한·동기화 주기·AI 호출 주기를 의미하지 않는다.

### 상태값

- RECRUITING / READY / RUNNING / COMPLETED / CANCELLED (허용 전이 검토).

### 미정 사항

- [ ] 요청·응답의 세부 필드 타입, 허용 범위, nullable 규칙 및 실제 JSON 구조 검토
- [ ] HTTP 성공 코드 및 각 예외의 오류 코드 최종 확정
- [ ] 실시간 전달 채널, 선두 경로 기준 순위·동기화 처리 확정


## G10 그룹런 실시간 현황·순위

`GET` `/api/v1/group-runs/{groupRunId}/live`

| 항목 | 값 |
|---|---|
| 단계 | 1차 MVP |
| 인증 | 회원 |
| 관련 요구사항 | GRP-001~004, GRP-006~008 / MAT-004 |
| 미정 사항 | 있음 |
| 비고 | API 요청/응답 필드와 값 제한은 검토용 제안 |

### 설명

지정 코스는 코스상 진행률, 자유는 선두 실제 경로 기준으로 순위·앞뒤 거리 비교.

### 인증 및 권한

- 로그인 사용자 본인 또는 서비스 리소스 접근 권한 검사.
- 건강정보·실시간 위치·타인 기록 조회 시 동의 상태 및 공개 범위가 우선한다.

### Path Parameters

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `groupRunId` | string (UUID) | O | 그룹런 식별자 |

### Query Parameters

없음

### Request Body

없음


### Response

`200 OK (제안)`

```json
{
  "groupRunId": "00000000-0000-4000-8000-000000000001",
  "status": "RUNNING",
  "groupGuidePaceSecPerKm": 360,
  "participants": [
    {
      "userId": "00000000-0000-4000-8000-000000000001",
      "rank": 2,
      "aheadCount": 1,
      "behindCount": 2,
      "gapToAheadM": 35,
      "gapToBehindM": 20
    }
  ]
}
```

응답 필드 정의(상세 객체는 미정 정책 확정 후 보완):

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `groupRunId` | string (UUID) | X | 그룹런 식별자 |
| `status` | string (제안) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `courseId` | string (UUID) | X | 선택한 코스 식별자. 개인·그룹 자유러닝은 null/생략 가능 |
| `groupGuidePaceSecPerKm` | string / object (확인 필요) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `updatedAt` | string (ISO 8601) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `participants` | array | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |

### 오류 응답

- `403 NOT_PARTICIPANT`
- `404 GROUP_NOT_FOUND`
- 공통 인증 오류 `401 UNAUTHORIZED`, 권한 오류 `403 FORBIDDEN`, 요청 형식 오류 `400 VALIDATION_ERROR` (해당 시).

### 처리 규칙

- 지정 코스는 코스상 진행률, 자유는 선두 실제 경로 기준으로 순위·앞뒤 거리 비교.
- 사용자 소유권·그룹 참가 권한·상태 전이·재요청 여부를 검증한다(적용 범위는 API별로 결정).
- 예시는 **명세 구조를 보여주는 가상 값**이며, 확정되지 않은 제한·동기화 주기·AI 호출 주기를 의미하지 않는다.

### 상태값

- RECRUITING / READY / RUNNING / COMPLETED / CANCELLED (허용 전이 검토).

### 미정 사항

- [ ] 요청·응답의 세부 필드 타입, 허용 범위, nullable 규칙 및 실제 JSON 구조 검토
- [ ] HTTP 성공 코드 및 각 예외의 오류 코드 최종 확정
- [ ] 실시간 전달 채널, 선두 경로 기준 순위·동기화 처리 확정


## G11 그룹런 알림 조회

`GET` `/api/v1/group-runs/{groupRunId}/notifications`

| 항목 | 값 |
|---|---|
| 단계 | 1차 MVP |
| 인증 | 회원 |
| 관련 요구사항 | GRP-001~004, GRP-006~008 / MAT-004 |
| 미정 사항 | 있음 |
| 비고 | API 요청/응답 필드와 값 제한은 검토용 제안 |

### 설명

페이스 변경·격차·진행 알림 조회.

### 인증 및 권한

- 로그인 사용자 본인 또는 서비스 리소스 접근 권한 검사.
- 건강정보·실시간 위치·타인 기록 조회 시 동의 상태 및 공개 범위가 우선한다.

### Path Parameters

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `groupRunId` | string (UUID) | O | 그룹런 식별자 |

### Query Parameters

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `cursor` | string / object (확인 필요) | X | 서버 발급 불투명 페이지 커서 |
| `limit` | number | X | 조회 결과 최대 개수(최대값 미정) |

### Request Body

없음


### Response

`200 OK (제안)`

```json
{}
```

응답 필드 정의(상세 객체는 미정 정책 확정 후 보완):

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `items` | array | X | 수집된 이벤트/측정 배치 목록. 상세 타입별 구성 미정 |
| `page` | string / object (확인 필요) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |

### 오류 응답

- `403 NOT_PARTICIPANT`
- 공통 인증 오류 `401 UNAUTHORIZED`, 권한 오류 `403 FORBIDDEN`, 요청 형식 오류 `400 VALIDATION_ERROR` (해당 시).

### 처리 규칙

- 페이스 변경·격차·진행 알림 조회.
- 사용자 소유권·그룹 참가 권한·상태 전이·재요청 여부를 검증한다(적용 범위는 API별로 결정).
- 예시는 **명세 구조를 보여주는 가상 값**이며, 확정되지 않은 제한·동기화 주기·AI 호출 주기를 의미하지 않는다.

### 상태값

- RECRUITING / READY / RUNNING / COMPLETED / CANCELLED (허용 전이 검토).

### 미정 사항

- [ ] 요청·응답의 세부 필드 타입, 허용 범위, nullable 규칙 및 실제 JSON 구조 검토
- [ ] HTTP 성공 코드 및 각 예외의 오류 코드 최종 확정
- [ ] 실시간 전달 채널, 선두 경로 기준 순위·동기화 처리 확정


## G12 그룹런 전체 종료

`POST` `/api/v1/group-runs/{groupRunId}/finish`

| 항목 | 값 |
|---|---|
| 단계 | 1차 MVP |
| 인증 | 회원 |
| 관련 요구사항 | GRP-001~004, GRP-006~008 / MAT-004 |
| 미정 사항 | 있음 |
| 비고 | API 요청/응답 필드와 값 제한은 검토용 제안 |

### 설명

참가자별 러닝 종료 후 호스트가 그룹런 별도 종료. 미완료 참가자 예외 정책 미정.

### 인증 및 권한

- 로그인 사용자 본인 또는 서비스 리소스 접근 권한 검사.
- 건강정보·실시간 위치·타인 기록 조회 시 동의 상태 및 공개 범위가 우선한다.

### Path Parameters

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `groupRunId` | string (UUID) | O | 그룹런 식별자 |

### Query Parameters

없음

### Request Body

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `commandId` | string (UUID) | X | 네트워크 재전송 중복 제거를 위한 명령 ID(제안) |

```json
{}
```

### Response

`200 OK (제안)`

```json
{}
```

응답 필드 정의(상세 객체는 미정 정책 확정 후 보완):

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `groupRunId` | string (UUID) | X | 그룹런 식별자 |
| `status` | string (제안) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `endedAt` | string (ISO 8601) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `goalAchieved` | boolean | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |

### 오류 응답

- `403 NOT_HOST`
- `409 PARTICIPANTS_NOT_FINISHED`
- 공통 인증 오류 `401 UNAUTHORIZED`, 권한 오류 `403 FORBIDDEN`, 요청 형식 오류 `400 VALIDATION_ERROR` (해당 시).

### 처리 규칙

- 참가자별 러닝 종료 후 호스트가 그룹런 별도 종료. 미완료 참가자 예외 정책 미정.
- 사용자 소유권·그룹 참가 권한·상태 전이·재요청 여부를 검증한다(적용 범위는 API별로 결정).
- 예시는 **명세 구조를 보여주는 가상 값**이며, 확정되지 않은 제한·동기화 주기·AI 호출 주기를 의미하지 않는다.

### 상태값

- RECRUITING / READY / RUNNING / COMPLETED / CANCELLED (허용 전이 검토).

### 미정 사항

- [ ] 요청·응답의 세부 필드 타입, 허용 범위, nullable 규칙 및 실제 JSON 구조 검토
- [ ] HTTP 성공 코드 및 각 예외의 오류 코드 최종 확정
- [ ] 실시간 전달 채널, 선두 경로 기준 순위·동기화 처리 확정


## G13 그룹런 취소

`POST` `/api/v1/group-runs/{groupRunId}/cancel`

| 항목 | 값 |
|---|---|
| 단계 | 1차 MVP |
| 인증 | 회원 |
| 관련 요구사항 | GRP-001~004, GRP-006~008 / MAT-004 |
| 미정 사항 | 있음 |
| 비고 | API 요청/응답 필드와 값 제한은 검토용 제안 |

### 설명

그룹런 시작 전 호스트 취소.

### 인증 및 권한

- 로그인 사용자 본인 또는 서비스 리소스 접근 권한 검사.
- 건강정보·실시간 위치·타인 기록 조회 시 동의 상태 및 공개 범위가 우선한다.

### Path Parameters

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `groupRunId` | string (UUID) | O | 그룹런 식별자 |

### Query Parameters

없음

### Request Body

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `commandId` | string (UUID) | X | 네트워크 재전송 중복 제거를 위한 명령 ID(제안) |

```json
{}
```

### Response

`200 OK (제안)`

```json
{}
```

응답 필드 정의(상세 객체는 미정 정책 확정 후 보완):

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `groupRunId` | string (UUID) | X | 그룹런 식별자 |
| `status` | string (제안) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |

### 오류 응답

- `403 NOT_HOST`
- `409 INVALID_GROUP_STATE`
- 공통 인증 오류 `401 UNAUTHORIZED`, 권한 오류 `403 FORBIDDEN`, 요청 형식 오류 `400 VALIDATION_ERROR` (해당 시).

### 처리 규칙

- 그룹런 시작 전 호스트 취소.
- 사용자 소유권·그룹 참가 권한·상태 전이·재요청 여부를 검증한다(적용 범위는 API별로 결정).
- 예시는 **명세 구조를 보여주는 가상 값**이며, 확정되지 않은 제한·동기화 주기·AI 호출 주기를 의미하지 않는다.

### 상태값

- RECRUITING / READY / RUNNING / COMPLETED / CANCELLED (허용 전이 검토).

### 미정 사항

- [ ] 요청·응답의 세부 필드 타입, 허용 범위, nullable 규칙 및 실제 JSON 구조 검토
- [ ] HTTP 성공 코드 및 각 예외의 오류 코드 최종 확정
- [ ] 실시간 전달 채널, 선두 경로 기준 순위·동기화 처리 확정


## G14 그룹런 결과 조회

`GET` `/api/v1/group-runs/{groupRunId}/results`

| 항목 | 값 |
|---|---|
| 단계 | 1차 MVP |
| 인증 | 회원 |
| 관련 요구사항 | GRP-001~004, GRP-006~008 / MAT-004 |
| 미정 사항 | 있음 |
| 비고 | API 요청/응답 필드와 값 제한은 검토용 제안 |

### 설명

그룹 종료 후 참가자 개인 기록 및 공동 목표 달성 평가.

### 인증 및 권한

- 로그인 사용자 본인 또는 서비스 리소스 접근 권한 검사.
- 건강정보·실시간 위치·타인 기록 조회 시 동의 상태 및 공개 범위가 우선한다.

### Path Parameters

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `groupRunId` | string (UUID) | O | 그룹런 식별자 |

### Query Parameters

없음

### Request Body

없음


### Response

`200 OK (제안)`

```json
{}
```

응답 필드 정의(상세 객체는 미정 정책 확정 후 보완):

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `groupRunId` | string (UUID) | X | 그룹런 식별자 |
| `targetDistanceM` | number | X | 목표 거리, 미터, 양수 |
| `targetDurationSec` | number | X | 목표 완주 시간, 초, 양수 |
| `goalAchieved` | boolean | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `participants` | array | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |

### 오류 응답

- `409 RESULTS_NOT_READY`
- `403 NOT_PARTICIPANT`
- 공통 인증 오류 `401 UNAUTHORIZED`, 권한 오류 `403 FORBIDDEN`, 요청 형식 오류 `400 VALIDATION_ERROR` (해당 시).

### 처리 규칙

- 그룹 종료 후 참가자 개인 기록 및 공동 목표 달성 평가.
- 사용자 소유권·그룹 참가 권한·상태 전이·재요청 여부를 검증한다(적용 범위는 API별로 결정).
- 예시는 **명세 구조를 보여주는 가상 값**이며, 확정되지 않은 제한·동기화 주기·AI 호출 주기를 의미하지 않는다.

### 상태값

- RECRUITING / READY / RUNNING / COMPLETED / CANCELLED (허용 전이 검토).

### 미정 사항

- [ ] 요청·응답의 세부 필드 타입, 허용 범위, nullable 규칙 및 실제 JSON 구조 검토
- [ ] HTTP 성공 코드 및 각 예외의 오류 코드 최종 확정
- [ ] 실시간 전달 채널, 선두 경로 기준 순위·동기화 처리 확정
