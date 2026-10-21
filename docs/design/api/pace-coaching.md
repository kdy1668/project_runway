# API 명세 — AI 페이스·실시간 분석·BPM

[API 명세 색인](README.md)으로 돌아가기. 공통 규약은 [API 명세](README.md#공통-규약)를 따른다.

| ID | 이름 | Method | Endpoint | 단계 | 인증 |
|---|---|---|---|---|---|
| [P01](#p01-초기-페이스-계획-생성) | 초기 페이스 계획 생성 | POST | `/running-sessions/{sessionId}/pace-plans` | 1차 MVP | 회원 |
| [P02](#p02-현재-페이스-계획-조회) | 현재 페이스 계획 조회 | GET | `/running-sessions/{sessionId}/pace-plans/current` | 1차 MVP | 회원 |
| [P03](#p03-러닝-측정값-수신) | 러닝 측정값 수신 | POST | `/running-sessions/{sessionId}/metrics` | 1차 MVP | 회원 |
| [P04](#p04-실시간-운동-코칭-상태) | 실시간 운동·코칭 상태 | GET | `/running-sessions/{sessionId}/live` | 1차 MVP | 회원 |
| [P05](#p05-과거-동일-코스-기록-비교) | 과거 동일 코스 기록 비교 | GET | `/running-sessions/{sessionId}/past-record-comparison` | 1차 MVP | 회원 |
| [P06](#p06-bpm-프로필-조회) | BPM 프로필 조회 | GET | `/users/me/bpm-profile` | 1차 MVP | 회원 |
| [P07](#p07-bpm-초기값-설정) | BPM 초기값 설정 | PUT | `/users/me/bpm-profile` | 1차 MVP | 회원 |

## P01 초기 페이스 계획 생성

`POST` `/api/v1/running-sessions/{sessionId}/pace-plans`

| 항목 | 값 |
|---|---|
| 단계 | 1차 MVP |
| 인증 | 회원 |
| 관련 요구사항 | PAC-001~007 / BPM-001~003 / REC-005 |
| 미정 사항 | 있음 |
| 비고 | API 요청/응답 필드와 값 제한은 검토용 제안 |

### 설명

READY 상태에서 최초 페이스 전략 생성. AI 조정은 러닝 중 안내 페이스에만 적용.

### 인증 및 권한

- 로그인 사용자 본인 또는 서비스 리소스 접근 권한 검사.
- 건강정보·실시간 위치·타인 기록 조회 시 동의 상태 및 공개 범위가 우선한다.

### Path Parameters

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `sessionId` | string (UUID) | O | 러닝 세션 UUID |

### Query Parameters

없음

### Request Body

없음


### Response

`201 Created (제안)`

```json
{}
```

응답 필드 정의(상세 객체는 미정 정책 확정 후 보완):

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `planId` | string (UUID) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `revision` | number | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `planKind` | string (제안) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `initialPaceSecPerKm` | number | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `estimatedDurationSec` | number | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `segments` | array | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |

### 오류 응답

- `409 INVALID_STATE`
- `422 INSUFFICIENT_PROFILE`
- 공통 인증 오류 `401 UNAUTHORIZED`, 권한 오류 `403 FORBIDDEN`, 요청 형식 오류 `400 VALIDATION_ERROR` (해당 시).

### 처리 규칙

- READY 상태에서 최초 페이스 전략 생성. AI 조정은 러닝 중 안내 페이스에만 적용.
- 사용자 소유권·그룹 참가 권한·상태 전이·재요청 여부를 검증한다(적용 범위는 API별로 결정).
- 예시는 **명세 구조를 보여주는 가상 값**이며, 확정되지 않은 제한·동기화 주기·AI 호출 주기를 의미하지 않는다.

### 상태값

- PUBLIC / PRIVATE 또는 기능별 ERD CHECK 값, 해당 없으면 별도 상태 없음.

### 미정 사항

- [ ] 요청·응답의 세부 필드 타입, 허용 범위, nullable 규칙 및 실제 JSON 구조 검토
- [ ] HTTP 성공 코드 및 각 예외의 오류 코드 최종 확정
- [ ] 실시간 전달 채널, 선두 경로 기준 순위·동기화 처리 확정

## P02 현재 페이스 계획 조회

`GET` `/api/v1/running-sessions/{sessionId}/pace-plans/current`

| 항목 | 값 |
|---|---|
| 단계 | 1차 MVP |
| 인증 | 회원 |
| 관련 요구사항 | PAC-001~007 / BPM-001~003 / REC-005 |
| 미정 사항 | 있음 |
| 비고 | API 요청/응답 필드와 값 제한은 검토용 제안 |

### 설명

최신 유효한 계획 버전과 구간별 권장 페이스.

### 인증 및 권한

- 로그인 사용자 본인 또는 서비스 리소스 접근 권한 검사.
- 건강정보·실시간 위치·타인 기록 조회 시 동의 상태 및 공개 범위가 우선한다.

### Path Parameters

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `sessionId` | string (UUID) | O | 러닝 세션 UUID |

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
| `planId` | string (UUID) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `revision` | number | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `planKind` | string (제안) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `effectiveAt` | string (ISO 8601) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `initialPaceSecPerKm` | number | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `segments` | array | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |

### 오류 응답

- `404 PLAN_NOT_FOUND`
- 공통 인증 오류 `401 UNAUTHORIZED`, 권한 오류 `403 FORBIDDEN`, 요청 형식 오류 `400 VALIDATION_ERROR` (해당 시).

### 처리 규칙

- 최신 유효한 계획 버전과 구간별 권장 페이스.
- 사용자 소유권·그룹 참가 권한·상태 전이·재요청 여부를 검증한다(적용 범위는 API별로 결정).
- 예시는 **명세 구조를 보여주는 가상 값**이며, 확정되지 않은 제한·동기화 주기·AI 호출 주기를 의미하지 않는다.

### 상태값

- PUBLIC / PRIVATE 또는 기능별 ERD CHECK 값, 해당 없으면 별도 상태 없음.

### 미정 사항

- [ ] 요청·응답의 세부 필드 타입, 허용 범위, nullable 규칙 및 실제 JSON 구조 검토
- [ ] HTTP 성공 코드 및 각 예외의 오류 코드 최종 확정
- [ ] 실시간 전달 채널, 선두 경로 기준 순위·동기화 처리 확정


## P03 러닝 측정값 수신

`POST` `/api/v1/running-sessions/{sessionId}/metrics`

| 항목 | 값 |
|---|---|
| 단계 | 1차 MVP |
| 인증 | 회원 |
| 관련 요구사항 | PAC-001~007 / BPM-001~003 / REC-005 |
| 미정 사항 | 있음 |
| 비고 | API 요청/응답 필드와 값 제한은 검토용 제안 |

### 설명

GPS·심박·페이스·케이던스 측정 시각과 품질 포함. 전송 방식 미정.

### 인증 및 권한

- 로그인 사용자 본인 또는 서비스 리소스 접근 권한 검사.
- 건강정보·실시간 위치·타인 기록 조회 시 동의 상태 및 공개 범위가 우선한다.

### Path Parameters

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `sessionId` | string (UUID) | O | 러닝 세션 UUID |

### Query Parameters

없음

### Request Body

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `deviceId` | string (UUID) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `samples` | array | O | 심박수·페이스·케이던스 등 측정 데이터 배열 |
| `routePoints` | array | X | 시각과 GPS 좌표를 포함한 경로 포인트 배열, 상세 아이템 필드 검토 |

```json
{
  "samples": [
    {
      "id": "00000000-0000-4000-8000-000000000001",
      "metricType": "HEART_RATE",
      "measuredAt": "2026-10-20T01:00:00Z",
      "value": 142,
      "unit": "BPM",
      "qualityStatus": "VALID"
    }
  ]
}
```

### Response

`200 OK (제안)`

```json
{}
```

응답 필드 정의(상세 객체는 미정 정책 확정 후 보완):

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `acceptedCount` | number | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `rejectedCount` | number | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `receivedAt` | string (ISO 8601) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |

### 오류 응답

- `403 SESSION_FORBIDDEN`
- `409 SESSION_NOT_RUNNING`
- `422 BAD_MEASUREMENT`
- 공통 인증 오류 `401 UNAUTHORIZED`, 권한 오류 `403 FORBIDDEN`, 요청 형식 오류 `400 VALIDATION_ERROR` (해당 시).

### 처리 규칙

- GPS·심박·페이스·케이던스 측정 시각과 품질 포함. 전송 방식 미정.
- 사용자 소유권·그룹 참가 권한·상태 전이·재요청 여부를 검증한다(적용 범위는 API별로 결정).
- 예시는 **명세 구조를 보여주는 가상 값**이며, 확정되지 않은 제한·동기화 주기·AI 호출 주기를 의미하지 않는다.

### 상태값

- PUBLIC / PRIVATE 또는 기능별 ERD CHECK 값, 해당 없으면 별도 상태 없음.

### 미정 사항

- [ ] 요청·응답의 세부 필드 타입, 허용 범위, nullable 규칙 및 실제 JSON 구조 검토
- [ ] HTTP 성공 코드 및 각 예외의 오류 코드 최종 확정
- [ ] 실시간 전달 채널, 선두 경로 기준 순위·동기화 처리 확정


## P04 실시간 운동·코칭 상태

`GET` `/api/v1/running-sessions/{sessionId}/live`

| 항목 | 값 |
|---|---|
| 단계 | 1차 MVP |
| 인증 | 회원 |
| 관련 요구사항 | PAC-001~007 / BPM-001~003 / REC-005 |
| 미정 사항 | 있음 |
| 비고 | API 요청/응답 필드와 값 제한은 검토용 제안 |

### 설명

러닝 중 현재 센서 상태, AI 페이스 조정과 BPM 통합 조회.

### 인증 및 권한

- 로그인 사용자 본인 또는 서비스 리소스 접근 권한 검사.
- 건강정보·실시간 위치·타인 기록 조회 시 동의 상태 및 공개 범위가 우선한다.

### Path Parameters

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `sessionId` | string (UUID) | O | 러닝 세션 UUID |

### Query Parameters

없음

### Request Body

없음


### Response

`200 OK (제안)`

```json
{
  "sessionId": "00000000-0000-4000-8000-000000000001",
  "status": "RUNNING",
  "distanceM": 2300,
  "elapsedDurationSec": 820,
  "paceSecPerKm": 365,
  "heartRateBpm": 142,
  "cadenceSpm": 164,
  "currentGuidePaceSecPerKm": 360,
  "targetBpm": 165,
  "coachingEvent": null
}
```

응답 필드 정의(상세 객체는 미정 정책 확정 후 보완):

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `sessionId` | string (UUID) | X | 러닝 세션 UUID |
| `status` | string (제안) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `measuredAt` | string (ISO 8601) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `dataQuality` | string / object (확인 필요) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `distanceM` | number | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `elapsedDurationSec` | number | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `paceSecPerKm` | number | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `heartRateBpm` | number | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `cadenceSpm` | number | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `currentGuidePaceSecPerKm` | number | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `targetTimeGapSec` | number | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `predictedFinishDurationSec` | number | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `loadLevel` | string / object (확인 필요) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `overpaceDetected` | boolean | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `paceDropDetected` | boolean | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `targetBpm` | number | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `coachingEvent` | string / object (확인 필요) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |

### 오류 응답

- `403 SESSION_FORBIDDEN`
- `404 SESSION_NOT_FOUND`
- 공통 인증 오류 `401 UNAUTHORIZED`, 권한 오류 `403 FORBIDDEN`, 요청 형식 오류 `400 VALIDATION_ERROR` (해당 시).

### 처리 규칙

- 러닝 중 현재 센서 상태, AI 페이스 조정과 BPM 통합 조회.
- 사용자 소유권·그룹 참가 권한·상태 전이·재요청 여부를 검증한다(적용 범위는 API별로 결정).
- 예시는 **명세 구조를 보여주는 가상 값**이며, 확정되지 않은 제한·동기화 주기·AI 호출 주기를 의미하지 않는다.

### 상태값

- PUBLIC / PRIVATE 또는 기능별 ERD CHECK 값, 해당 없으면 별도 상태 없음.

### 미정 사항

- [ ] 요청·응답의 세부 필드 타입, 허용 범위, nullable 규칙 및 실제 JSON 구조 검토
- [ ] HTTP 성공 코드 및 각 예외의 오류 코드 최종 확정
- [ ] 실시간 전달 채널, 선두 경로 기준 순위·동기화 처리 확정


## P05 과거 동일 코스 기록 비교

`GET` `/api/v1/running-sessions/{sessionId}/past-record-comparison`

| 항목 | 값 |
|---|---|
| 단계 | 1차 MVP |
| 인증 | 회원 |
| 관련 요구사항 | PAC-001~007 / BPM-001~003 / REC-005 |
| 미정 사항 | 있음 |
| 비고 | API 요청/응답 필드와 값 제한은 검토용 제안 |

### 설명

같은 코스를 과거에 달린 기록과 현재 거리 도달시간 비교. 복수 과거 기록 기본 선택 규칙 미정.

### 인증 및 권한

- 로그인 사용자 본인 또는 서비스 리소스 접근 권한 검사.
- 건강정보·실시간 위치·타인 기록 조회 시 동의 상태 및 공개 범위가 우선한다.

### Path Parameters

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `sessionId` | string (UUID) | O | 러닝 세션 UUID |

### Query Parameters

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `referenceSessionId` | string (UUID) | X | 같은 코스를 과거에 완주한 비교 기준 세션 UUID |

### Request Body

없음


### Response

`200 OK (제안)`

```json
{
  "comparisonStatus": "AVAILABLE",
  "referenceSessionId": "00000000-0000-4000-8000-000000000001",
  "currentDistanceM": 2300,
  "currentElapsedDurationSec": 820,
  "referenceElapsedAtDistanceSec": 835,
  "deltaSec": -15
}
```

응답 필드 정의(상세 객체는 미정 정책 확정 후 보완):

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `referenceSessionId` | string (UUID) | X | 같은 코스를 과거에 완주한 비교 기준 세션 UUID |
| `courseId` | string (UUID) | X | 선택한 코스 식별자. 개인·그룹 자유러닝은 null/생략 가능 |
| `currentDistanceM` | number | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `currentElapsedDurationSec` | number | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `referenceElapsedAtDistanceSec` | number | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `deltaSec` | number | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `comparisonStatus` | string (제안) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |

### 오류 응답

- `404 SESSION_NOT_FOUND`
- `422 DIFFERENT_COURSE`
- 공통 인증 오류 `401 UNAUTHORIZED`, 권한 오류 `403 FORBIDDEN`, 요청 형식 오류 `400 VALIDATION_ERROR` (해당 시).

### 처리 규칙

- 같은 코스를 과거에 달린 기록과 현재 거리 도달시간 비교. 복수 과거 기록 기본 선택 규칙 미정.
- 사용자 소유권·그룹 참가 권한·상태 전이·재요청 여부를 검증한다(적용 범위는 API별로 결정).
- 예시는 **명세 구조를 보여주는 가상 값**이며, 확정되지 않은 제한·동기화 주기·AI 호출 주기를 의미하지 않는다.

### 상태값

- PUBLIC / PRIVATE 또는 기능별 ERD CHECK 값, 해당 없으면 별도 상태 없음.

### 미정 사항

- [ ] 요청·응답의 세부 필드 타입, 허용 범위, nullable 규칙 및 실제 JSON 구조 검토
- [ ] HTTP 성공 코드 및 각 예외의 오류 코드 최종 확정
- [ ] 실시간 전달 채널, 선두 경로 기준 순위·동기화 처리 확정


## P06 BPM 프로필 조회

`GET` `/api/v1/users/me/bpm-profile`

| 항목 | 값 |
|---|---|
| 단계 | 1차 MVP |
| 인증 | 회원 |
| 관련 요구사항 | PAC-001~007 / BPM-001~003 / REC-005 |
| 미정 사항 | 있음 |
| 비고 | API 요청/응답 필드와 값 제한은 검토용 제안 |

### 설명

개인 특성 및 보정 상태 조회.

### 인증 및 권한

- 로그인 사용자 본인 또는 서비스 리소스 접근 권한 검사.
- 건강정보·실시간 위치·타인 기록 조회 시 동의 상태 및 공개 범위가 우선한다.

### Path Parameters

없음

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
| `initialBpm` | number | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `stepLengthM` | number | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `preferredCadenceSpm` | number | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `calibrationState` | string (제안) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `confidence` | string / object (확인 필요) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `calibratedAt` | string (ISO 8601) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |

### 오류 응답

- `404 BPM_PROFILE_NOT_FOUND`
- 공통 인증 오류 `401 UNAUTHORIZED`, 권한 오류 `403 FORBIDDEN`, 요청 형식 오류 `400 VALIDATION_ERROR` (해당 시).

### 처리 규칙

- 개인 특성 및 보정 상태 조회.
- 사용자 소유권·그룹 참가 권한·상태 전이·재요청 여부를 검증한다(적용 범위는 API별로 결정).
- 예시는 **명세 구조를 보여주는 가상 값**이며, 확정되지 않은 제한·동기화 주기·AI 호출 주기를 의미하지 않는다.

### 상태값

- PUBLIC / PRIVATE 또는 기능별 ERD CHECK 값, 해당 없으면 별도 상태 없음.

### 미정 사항

- [ ] 요청·응답의 세부 필드 타입, 허용 범위, nullable 규칙 및 실제 JSON 구조 검토
- [ ] HTTP 성공 코드 및 각 예외의 오류 코드 최종 확정
- [ ] 실시간 전달 채널, 선두 경로 기준 순위·동기화 처리 확정


## P07 BPM 초기값 설정

`PUT` `/api/v1/users/me/bpm-profile`

| 항목 | 값 |
|---|---|
| 단계 | 1차 MVP |
| 인증 | 회원 |
| 관련 요구사항 | PAC-001~007 / BPM-001~003 / REC-005 |
| 미정 사항 | 있음 |
| 비고 | API 요청/응답 필드와 값 제한은 검토용 제안 |

### 설명

사용자 입력 초기 BPM 설정. 자동 특성 보정은 시스템 담당.

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
| `initialBpm` | number | O | ERD 및 화면 요구사항을 기준으로 확정 필요 |

```json
{
  "initialBpm": 165
}
```

### Response

`200 OK (제안)`

```json
{}
```

응답 필드 정의(상세 객체는 미정 정책 확정 후 보완):

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `initialBpm` | number | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `calibrationState` | string (제안) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `updatedAt` | string (ISO 8601) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |

### 오류 응답

- `422 INVALID_BPM`
- 공통 인증 오류 `401 UNAUTHORIZED`, 권한 오류 `403 FORBIDDEN`, 요청 형식 오류 `400 VALIDATION_ERROR` (해당 시).

### 처리 규칙

- 사용자 입력 초기 BPM 설정. 자동 특성 보정은 시스템 담당.
- 사용자 소유권·그룹 참가 권한·상태 전이·재요청 여부를 검증한다(적용 범위는 API별로 결정).
- 예시는 **명세 구조를 보여주는 가상 값**이며, 확정되지 않은 제한·동기화 주기·AI 호출 주기를 의미하지 않는다.

### 상태값

- PUBLIC / PRIVATE 또는 기능별 ERD CHECK 값, 해당 없으면 별도 상태 없음.

### 미정 사항

- [ ] 요청·응답의 세부 필드 타입, 허용 범위, nullable 규칙 및 실제 JSON 구조 검토
- [ ] HTTP 성공 코드 및 각 예외의 오류 코드 최종 확정
- [ ] 실시간 전달 채널, 선두 경로 기준 순위·동기화 처리 확정
