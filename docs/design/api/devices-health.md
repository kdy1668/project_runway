# API 명세 — 워치·건강 데이터

[API 명세 색인](README.md)으로 돌아가기. 공통 규약은 [API 명세](README.md#공통-규약)를 따른다.

| ID | 이름 | Method | Endpoint | 단계 | 인증 |
|---|---|---|---|---|---|
| [W01](#w01-기기-등록) | 기기 등록 | POST | `/devices` | 1차 MVP | 회원 |
| [W02](#w02-등록-기기-조회) | 등록 기기 조회 | GET | `/devices` | 1차 MVP | 회원 |
| [W03](#w03-기기-연결-해제) | 기기 연결 해제 | DELETE | `/devices/{deviceId}` | 1차 MVP | 회원 |
| [W04](#w04-수집-동의-철회) | 수집 동의·철회 | POST | `/consents` | 1차 MVP | 회원 |
| [W05](#w05-동의-상태-조회) | 동의 상태 조회 | GET | `/consents` | 1차 MVP | 회원 |
| [W06](#w06-samsung-health-데이터-동기화) | Samsung Health 데이터 동기화 | POST | `/health-records/sync` | 1차 MVP | 회원 |
| [W07](#w07-워치-운동-배치-동기화) | 워치 운동 배치 동기화 | POST | `/sync/batches` | 1차 MVP | 회원 |
| [W08](#w08-동기화-진행-상태-조회) | 동기화 진행 상태 조회 | GET | `/devices/{deviceId}/sync/streams/{streamKey}/progress` | 1차 MVP | 회원 |

## W01 기기 등록

`POST` `/api/v1/devices`

| 항목 | 값 |
|---|---|
| 단계 | 1차 MVP |
| 인증 | 회원 |
| 관련 요구사항 | WAT-001~008 / SYS-001 / RDY-001 |
| 미정 사항 | 있음 |
| 비고 | API 요청/응답 필드와 값 제한은 검토용 제안 |

### 설명

실제 블루투스 연결은 기기 앱에서 제어. 동일 설치 중복 등록 방지.

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
| `installationId` | string (UUID) | O | 설치 인스턴스 식별자 |
| `deviceType` | string (제안) | O | WATCH/PHONE (제안) |
| `manufacturer` | string / object (확인 필요) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `model` | string / object (확인 필요) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `osVersion` | string / object (확인 필요) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `appVersion` | string / object (확인 필요) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `capabilities` | array | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |

```json
{
  "installationId": "watch-installation-01",
  "deviceType": "WATCH"
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
| `installationId` | string (UUID) | X | 설치 인스턴스 식별자 |
| `deviceType` | string (제안) | X | WATCH/PHONE (제안) |
| `lastSeenAt` | string (ISO 8601) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |

### 오류 응답

- `409 DEVICE_CONFLICT`
- 공통 인증 오류 `401 UNAUTHORIZED`, 권한 오류 `403 FORBIDDEN`, 요청 형식 오류 `400 VALIDATION_ERROR` (해당 시).

### 처리 규칙

- 실제 블루투스 연결은 기기 앱에서 제어. 동일 설치 중복 등록 방지.
- 사용자 소유권·그룹 참가 권한·상태 전이·재요청 여부를 검증한다(적용 범위는 API별로 결정).
- 예시는 **명세 구조를 보여주는 가상 값**이며, 확정되지 않은 제한·동기화 주기·AI 호출 주기를 의미하지 않는다.

### 상태값

- PUBLIC / PRIVATE 또는 기능별 ERD CHECK 값, 해당 없으면 별도 상태 없음.

### 미정 사항

- [ ] 요청·응답의 세부 필드 타입, 허용 범위, nullable 규칙 및 실제 JSON 구조 검토
- [ ] HTTP 성공 코드 및 각 예외의 오류 코드 최종 확정
- [ ] 실시간 전달 채널, 선두 경로 기준 순위·동기화 처리 확정

## W02 등록 기기 조회

`GET` `/api/v1/devices`

| 항목 | 값 |
|---|---|
| 단계 | 1차 MVP |
| 인증 | 회원 |
| 관련 요구사항 | WAT-001~008 / SYS-001 / RDY-001 |
| 미정 사항 | 있음 |
| 비고 | API 요청/응답 필드와 값 제한은 검토용 제안 |

### 설명

lastSeenAt은 서버 마지막 인지 시각이며 현재 연결 보장 아님.

### 인증 및 권한

- 로그인 사용자 본인 또는 서비스 리소스 접근 권한 검사.
- 건강정보·실시간 위치·타인 기록 조회 시 동의 상태 및 공개 범위가 우선한다.

### Path Parameters

없음

### Query Parameters

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `deviceType` | string (제안) | X | WATCH/PHONE (제안) |
| `includeUnlinked` | boolean | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |

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

- `401 UNAUTHORIZED`
- 공통 인증 오류 `401 UNAUTHORIZED`, 권한 오류 `403 FORBIDDEN`, 요청 형식 오류 `400 VALIDATION_ERROR` (해당 시).

### 처리 규칙

- lastSeenAt은 서버 마지막 인지 시각이며 현재 연결 보장 아님.
- 사용자 소유권·그룹 참가 권한·상태 전이·재요청 여부를 검증한다(적용 범위는 API별로 결정).
- 예시는 **명세 구조를 보여주는 가상 값**이며, 확정되지 않은 제한·동기화 주기·AI 호출 주기를 의미하지 않는다.

### 상태값

- PUBLIC / PRIVATE 또는 기능별 ERD CHECK 값, 해당 없으면 별도 상태 없음.

### 미정 사항

- [ ] 요청·응답의 세부 필드 타입, 허용 범위, nullable 규칙 및 실제 JSON 구조 검토
- [ ] HTTP 성공 코드 및 각 예외의 오류 코드 최종 확정
- [ ] 실시간 전달 채널, 선두 경로 기준 순위·동기화 처리 확정


## W03 기기 연결 해제

`DELETE` `/api/v1/devices/{deviceId}`

| 항목 | 값 |
|---|---|
| 단계 | 1차 MVP |
| 인증 | 회원 |
| 관련 요구사항 | WAT-001~008 / SYS-001 / RDY-001 |
| 미정 사항 | 있음 |
| 비고 | API 요청/응답 필드와 값 제한은 검토용 제안 |

### 설명

본인 소유 기기만 해제.

### 인증 및 권한

- 로그인 사용자 본인 또는 서비스 리소스 접근 권한 검사.
- 건강정보·실시간 위치·타인 기록 조회 시 동의 상태 및 공개 범위가 우선한다.

### Path Parameters

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `deviceId` | string (UUID) | O | ERD 및 화면 요구사항을 기준으로 확정 필요 |

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
| `success` | boolean | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |

### 오류 응답

- `404 DEVICE_NOT_FOUND`
- 공통 인증 오류 `401 UNAUTHORIZED`, 권한 오류 `403 FORBIDDEN`, 요청 형식 오류 `400 VALIDATION_ERROR` (해당 시).

### 처리 규칙

- 본인 소유 기기만 해제.
- 사용자 소유권·그룹 참가 권한·상태 전이·재요청 여부를 검증한다(적용 범위는 API별로 결정).
- 예시는 **명세 구조를 보여주는 가상 값**이며, 확정되지 않은 제한·동기화 주기·AI 호출 주기를 의미하지 않는다.

### 상태값

- PUBLIC / PRIVATE 또는 기능별 ERD CHECK 값, 해당 없으면 별도 상태 없음.

### 미정 사항

- [ ] 요청·응답의 세부 필드 타입, 허용 범위, nullable 규칙 및 실제 JSON 구조 검토
- [ ] HTTP 성공 코드 및 각 예외의 오류 코드 최종 확정
- [ ] 실시간 전달 채널, 선두 경로 기준 순위·동기화 처리 확정


## W04 수집 동의·철회

`POST` `/api/v1/consents`

| 항목 | 값 |
|---|---|
| 단계 | 1차 MVP |
| 인증 | 회원 |
| 관련 요구사항 | WAT-001~008 / SYS-001 / RDY-001 |
| 미정 사항 | 있음 |
| 비고 | API 요청/응답 필드와 값 제한은 검토용 제안 |

### 설명

동의와 철회 이력 보존. 최신 유효 이벤트로 상태 판단.

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
| `consentType` | string (제안) | O | HEALTH_DATA 또는 LOCATION_DATA |
| `policyVersion` | string (제안) | O | 동의 약관의 버전 |
| `action` | string (제안) | O | GRANT 또는 REVOKE |

```json
{
  "consentType": "HEALTH_DATA",
  "policyVersion": "v1",
  "action": "GRANT"
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
| `id` | string (UUID) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `consentType` | string (제안) | X | HEALTH_DATA 또는 LOCATION_DATA |
| `action` | string (제안) | X | GRANT 또는 REVOKE |
| `policyVersion` | string (제안) | X | 동의 약관의 버전 |
| `recordedAt` | string (ISO 8601) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |

### 오류 응답

- `422 INVALID_CONSENT`
- 공통 인증 오류 `401 UNAUTHORIZED`, 권한 오류 `403 FORBIDDEN`, 요청 형식 오류 `400 VALIDATION_ERROR` (해당 시).

### 처리 규칙

- 동의와 철회 이력 보존. 최신 유효 이벤트로 상태 판단.
- 사용자 소유권·그룹 참가 권한·상태 전이·재요청 여부를 검증한다(적용 범위는 API별로 결정).
- 예시는 **명세 구조를 보여주는 가상 값**이며, 확정되지 않은 제한·동기화 주기·AI 호출 주기를 의미하지 않는다.

### 상태값

- PUBLIC / PRIVATE 또는 기능별 ERD CHECK 값, 해당 없으면 별도 상태 없음.

### 미정 사항

- [ ] 요청·응답의 세부 필드 타입, 허용 범위, nullable 규칙 및 실제 JSON 구조 검토
- [ ] HTTP 성공 코드 및 각 예외의 오류 코드 최종 확정
- [ ] 실시간 전달 채널, 선두 경로 기준 순위·동기화 처리 확정


## W05 동의 상태 조회

`GET` `/api/v1/consents`

| 항목 | 값 |
|---|---|
| 단계 | 1차 MVP |
| 인증 | 회원 |
| 관련 요구사항 | WAT-001~008 / SYS-001 / RDY-001 |
| 미정 사항 | 있음 |
| 비고 | API 요청/응답 필드와 값 제한은 검토용 제안 |

### 설명

건강 데이터와 위치정보 수집 동의 상태 조회.

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
| `items` | array | X | 수집된 이벤트/측정 배치 목록. 상세 타입별 구성 미정 |

### 오류 응답

- `401 UNAUTHORIZED`
- 공통 인증 오류 `401 UNAUTHORIZED`, 권한 오류 `403 FORBIDDEN`, 요청 형식 오류 `400 VALIDATION_ERROR` (해당 시).

### 처리 규칙

- 건강 데이터와 위치정보 수집 동의 상태 조회.
- 사용자 소유권·그룹 참가 권한·상태 전이·재요청 여부를 검증한다(적용 범위는 API별로 결정).
- 예시는 **명세 구조를 보여주는 가상 값**이며, 확정되지 않은 제한·동기화 주기·AI 호출 주기를 의미하지 않는다.

### 상태값

- PUBLIC / PRIVATE 또는 기능별 ERD CHECK 값, 해당 없으면 별도 상태 없음.

### 미정 사항

- [ ] 요청·응답의 세부 필드 타입, 허용 범위, nullable 규칙 및 실제 JSON 구조 검토
- [ ] HTTP 성공 코드 및 각 예외의 오류 코드 최종 확정
- [ ] 실시간 전달 채널, 선두 경로 기준 순위·동기화 처리 확정


## W06 Samsung Health 데이터 동기화

`POST` `/api/v1/health-records/sync`

| 항목 | 값 |
|---|---|
| 단계 | 1차 MVP |
| 인증 | 회원 |
| 관련 요구사항 | WAT-001~008 / SYS-001 / RDY-001 |
| 미정 사항 | 있음 |
| 비고 | API 요청/응답 필드와 값 제한은 검토용 제안 |

### 설명

수면, 심박, 활동량과 이전 운동기록 수신. 상세 종류·매핑·동기화 시점 미정.

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
| `provider` | string (제안) | O | 외부 로그인 제공자(지원 목록 미정) |
| `records` | array | O | 수면·일일 활동·심박 등의 외부 레코드 배열(구조 미정) |
| `deviceId` | string (UUID) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |

```json
{
  "provider": "SAMSUNG",
  "records": []
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
| `duplicateCount` | number | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `rejectedCount` | number | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `errors` | array | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |

### 오류 응답

- `403 CONSENT_REQUIRED`
- `422 UNSUPPORTED_RECORD_TYPE`
- 공통 인증 오류 `401 UNAUTHORIZED`, 권한 오류 `403 FORBIDDEN`, 요청 형식 오류 `400 VALIDATION_ERROR` (해당 시).

### 처리 규칙

- 수면, 심박, 활동량과 이전 운동기록 수신. 상세 종류·매핑·동기화 시점 미정.
- 사용자 소유권·그룹 참가 권한·상태 전이·재요청 여부를 검증한다(적용 범위는 API별로 결정).
- 예시는 **명세 구조를 보여주는 가상 값**이며, 확정되지 않은 제한·동기화 주기·AI 호출 주기를 의미하지 않는다.

### 상태값

- PUBLIC / PRIVATE 또는 기능별 ERD CHECK 값, 해당 없으면 별도 상태 없음.

### 미정 사항

- [ ] 요청·응답의 세부 필드 타입, 허용 범위, nullable 규칙 및 실제 JSON 구조 검토
- [ ] HTTP 성공 코드 및 각 예외의 오류 코드 최종 확정
- [ ] 실시간 전달 채널, 선두 경로 기준 순위·동기화 처리 확정


## W07 워치 운동 배치 동기화

`POST` `/api/v1/sync/batches`

| 항목 | 값 |
|---|---|
| 단계 | 1차 MVP |
| 인증 | 회원 |
| 관련 요구사항 | WAT-001~008 / SYS-001 / RDY-001 |
| 미정 사항 | 있음 |
| 비고 | API 요청/응답 필드와 값 제한은 검토용 제안 |

### 설명

중복 배치는 멱등 처리. 실제 영속 저장 확인 후 ACK.

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
| `id` | string (UUID) | O | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `deviceId` | string (UUID) | O | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `sessionId` | string (UUID) | X | 러닝 세션 UUID |
| `schemaVersion` | string (제안) | O | 워치 배치 스키마 버전 |
| `payloadHash` | string / object (확인 필요) | O | 중복 배치 검증을 위한 페이로드 해시 |
| `streamKey` | string (제안) | O | 기기 내 데이터 스트림 구분 키 |
| `items` | array | O | 수집된 이벤트/측정 배치 목록. 상세 타입별 구성 미정 |

```json
{
  "id": "00000000-0000-4000-8000-000000000001",
  "deviceId": "00000000-0000-4000-8000-000000000001",
  "schemaVersion": "1",
  "payloadHash": "sha256-placeholder",
  "streamKey": "running-metrics",
  "items": [
    {
      "id": "00000000-0000-4000-8000-000000000001",
      "sequenceNo": 1,
      "measuredAt": "2026-10-20T01:00:00Z",
      "type": "HEART_RATE",
      "value": 142,
      "unit": "BPM"
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
| `batchId` | string (UUID) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `status` | string (제안) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `acceptedCount` | number | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `lastContiguousSequence` | string / object (확인 필요) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `missingSequences` | array | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |

### 오류 응답

- `403 DEVICE_FORBIDDEN`
- `409 BATCH_HASH_CONFLICT`
- `422 INVALID_BATCH`
- 공통 인증 오류 `401 UNAUTHORIZED`, 권한 오류 `403 FORBIDDEN`, 요청 형식 오류 `400 VALIDATION_ERROR` (해당 시).

### 처리 규칙

- 중복 배치는 멱등 처리. 실제 영속 저장 확인 후 ACK.
- 사용자 소유권·그룹 참가 권한·상태 전이·재요청 여부를 검증한다(적용 범위는 API별로 결정).
- 예시는 **명세 구조를 보여주는 가상 값**이며, 확정되지 않은 제한·동기화 주기·AI 호출 주기를 의미하지 않는다.

### 상태값

- PUBLIC / PRIVATE 또는 기능별 ERD CHECK 값, 해당 없으면 별도 상태 없음.

### 미정 사항

- [ ] 요청·응답의 세부 필드 타입, 허용 범위, nullable 규칙 및 실제 JSON 구조 검토
- [ ] HTTP 성공 코드 및 각 예외의 오류 코드 최종 확정
- [ ] 실시간 전달 채널, 선두 경로 기준 순위·동기화 처리 확정


## W08 동기화 진행 상태 조회

`GET` `/api/v1/devices/{deviceId}/sync/streams/{streamKey}/progress`

| 항목 | 값 |
|---|---|
| 단계 | 1차 MVP |
| 인증 | 회원 |
| 관련 요구사항 | WAT-001~008 / SYS-001 / RDY-001 |
| 미정 사항 | 있음 |
| 비고 | API 요청/응답 필드와 값 제한은 검토용 제안 |

### 설명

기기별 스트림의 마지막 연속 반영 위치 조회.

### 인증 및 권한

- 로그인 사용자 본인 또는 서비스 리소스 접근 권한 검사.
- 건강정보·실시간 위치·타인 기록 조회 시 동의 상태 및 공개 범위가 우선한다.

### Path Parameters

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `deviceId` | string (UUID) | O | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `streamKey` | string (제안) | O | 기기 내 데이터 스트림 구분 키 |

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
| `deviceId` | string (UUID) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `streamKey` | string (제안) | X | 기기 내 데이터 스트림 구분 키 |
| `lastContiguousSequence` | string / object (확인 필요) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `updatedAt` | string (ISO 8601) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `missingRanges` | array | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |

### 오류 응답

- `404 DEVICE_NOT_FOUND`
- 공통 인증 오류 `401 UNAUTHORIZED`, 권한 오류 `403 FORBIDDEN`, 요청 형식 오류 `400 VALIDATION_ERROR` (해당 시).

### 처리 규칙

- 기기별 스트림의 마지막 연속 반영 위치 조회.
- 사용자 소유권·그룹 참가 권한·상태 전이·재요청 여부를 검증한다(적용 범위는 API별로 결정).
- 예시는 **명세 구조를 보여주는 가상 값**이며, 확정되지 않은 제한·동기화 주기·AI 호출 주기를 의미하지 않는다.

### 상태값

- PUBLIC / PRIVATE 또는 기능별 ERD CHECK 값, 해당 없으면 별도 상태 없음.

### 미정 사항

- [ ] 요청·응답의 세부 필드 타입, 허용 범위, nullable 규칙 및 실제 JSON 구조 검토
- [ ] HTTP 성공 코드 및 각 예외의 오류 코드 최종 확정
- [ ] 실시간 전달 채널, 선두 경로 기준 순위·동기화 처리 확정
