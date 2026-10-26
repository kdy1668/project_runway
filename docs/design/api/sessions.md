# API 명세 — 러닝 세션

[API 명세 색인](README.md)으로 돌아가기. 공통 규약은 [API 명세](README.md#공통-규약)를 따른다.

| ID | 이름 | Method | Endpoint | 단계 | 인증 |
|---|---|---|---|---|---|
| [S01](#s01-러닝-세션-생성) | 러닝 세션 생성 | POST | `/running-sessions` | 1차 MVP | 회원 |
| [S02](#s02-러닝-세션-조회) | 러닝 세션 조회 | GET | `/running-sessions/{sessionId}` | 1차 MVP | 회원 |
| [S03](#s03-러닝-시작) | 러닝 시작 | POST | `/running-sessions/{sessionId}/start` | 1차 MVP | 회원 |
| [S04](#s04-러닝-일시정지) | 러닝 일시정지 | POST | `/running-sessions/{sessionId}/pause` | 1차 MVP | 회원 |
| [S05](#s05-러닝-재개) | 러닝 재개 | POST | `/running-sessions/{sessionId}/resume` | 1차 MVP | 회원 |
| [S06](#s06-개인-러닝-종료) | 개인 러닝 종료 | POST | `/running-sessions/{sessionId}/finish` | 1차 MVP | 회원 |
| [S07](#s07-러닝-취소) | 러닝 취소 | POST | `/running-sessions/{sessionId}/cancel` | 1차 MVP | 회원 |
| [S08](#s08-출발-전-러닝-설정-수정) | 출발 전 러닝 설정 수정 | PATCH | `/running-sessions/{sessionId}` | 1차 MVP | 회원 |
| [S09](#s09-러닝-세션-삭제) | 러닝 세션 삭제 | DELETE | `/running-sessions/{sessionId}` | 1차 MVP | 회원 |

## S01 러닝 세션 생성

`POST` `/api/v1/running-sessions`

| 항목 | 값 |
|---|---|
| 단계 | 1차 MVP |
| 인증 | 회원 |
| 관련 요구사항 | STA-001~005 / REC-001 |
| 관련 화면 | 2.0 코스 러닝, 2.0F 자유 러닝, 3.2 코스 상세 '경쟁 모드' (화면 설계 v10) |
| 미정 사항 | 있음 |
| 비고 | API 요청/응답 필드와 값 제한은 검토용 제안 |

### 설명

개인런·그룹런 공통. courseId null이면 자유러닝. groupRunId는 참가자 테이블로 연결.

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
| `courseId` | string (UUID) | X | 선택한 코스 식별자. 개인·그룹 자유러닝은 null/생략 가능 |
| `groupRunId` | string (UUID) | X | 그룹런 식별자 |
| `targetDistanceM` | number | 조건부 | 목표 거리, 미터, 양수. 목표를 끈 자유 러닝은 생략 |
| `targetDurationSec` | number | 조건부 | 목표 완주 시간, 초, 양수. 자유러닝은 선택 입력·단독 입력 가능 |
| `targetPaceSecPerKm` | number | X | 목표 페이스, 초/km, 양수. 자유러닝은 선택 입력·단독 입력 가능 |
| `comparisonSessionId` | string (UUID) | X | 경쟁 모드에서 겨룰 같은 코스의 내 과거 기록 ID(3.2) |

```json
{
  "targetDistanceM": 5000,
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
| `initialGuidance` | object / null (제안) | X | 모드에 따른 초기 안내. 무목표 자유러닝은 사전 Pace Plan 없음. 준비 중인 계획은 후속 전달 |
| `guidanceStatus` | string (제안) | X | 전략 준비 상태. 무목표의 계획 비대상을 준비 중·실패와 구분. 구체 상태값은 미정 |
| `id` | string (UUID) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `status` | string (제안) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `courseId` | string (UUID) | X | 선택한 코스 식별자. 개인·그룹 자유러닝은 null/생략 가능 |
| `targetDistanceM` | number | X | 목표 거리, 미터, 양수 |
| `targetDurationSec` | number | X | 목표 완주 시간, 초, 양수 |
| `groupRunId` | string (UUID) | X | 그룹런 식별자 |

### 오류 응답

- `403 COURSE_INACCESSIBLE`
- `409 ACTIVE_SESSION_EXISTS`
- 공통 인증 오류 `401 UNAUTHORIZED`, 권한 오류 `403 FORBIDDEN`, 요청 형식 오류 `400 VALIDATION_ERROR` (해당 시).

### 처리 규칙

- 세션 준비 시점에는 목표가 수정 가능하다. S08로 출발 전 변경을 반영하고 전략을 다시 생성한다. 실제 운동 시작이 확정되면 그때의 목표를 고정한다.
- groupRunId를 받으면 본인이 해당 그룹런 참가자인지와 준비 가능한 그룹 상태인지 검사한다. 개인 세션 생성으로 그룹장 시작 권한을 우회할 수 없다.
- 코스·목표·비교 기록으로 세션을 준비하면 모드에 맞는 초기 안내를 내부에서 자동 생성한다. 무목표 자유러닝에는 사전 Pace Plan을 생성하지 않는다. 클라이언트는 별도 전략 생성 요청을 하지 않는다.
- 준비 결과는 세션 생성 응답과 후속 갱신으로 제공한다. 전략 산출 대기·실패 시 시작 허용 정책은 미정이다.
- 코스 러닝은 목표가 필수다. 자유러닝은 거리·시간·페이스 중 원하는 목표만 입력하거나 모두 생략할 수 있다. 목표가 있으면 Future Grade 0%의 평지 기준 계획을 생성하고, 목표가 없으면 사전 계획 없이 실시간 HR 예측·MPC 코칭을 제공한다.
- 자유러닝은 목표 2개 입력을 강제하지 않는다. [모드별 AI 동작](../requirements.md#러닝-모드별-ai-동작)을 따른다. 일부 목표의 환산·상충 입력 검증과 응답 구조는 세부 계약에서 정의한다.
- 개인런·그룹런 공통. courseId null이면 자유러닝. groupRunId는 참가자 테이블로 연결.
- 사용자 소유권·그룹 참가 권한·상태 전이·재요청 여부를 검증한다(적용 범위는 API별로 결정).
- 예시는 **명세 구조를 보여주는 가상 값**이며, 확정되지 않은 제한·동기화 주기·AI 호출 주기를 의미하지 않는다.

### 상태값

- READY → RUNNING ↔ PAUSED → COMPLETED, 시작 전 CANCELLED 가능.

### 미정 사항

- [ ] 선택 목표의 환산·상충 입력 검증, 목표별 결과 표시와 무목표 계획 비대상 응답 표현
- [ ] 요청·응답의 세부 필드 타입, 허용 범위, nullable 규칙 및 실제 JSON 구조 검토
- [ ] HTTP 성공 코드 및 각 예외의 오류 코드 최종 확정
- [ ] 접근 권한과 데이터 정합성의 구체적인 처리 조건 확정

## S02 러닝 세션 조회

`GET` `/api/v1/running-sessions/{sessionId}`

| 항목 | 값 |
|---|---|
| 단계 | 1차 MVP |
| 인증 | 회원 |
| 관련 요구사항 | STA-001~005 / REC-001 |
| 미정 사항 | 있음 |
| 비고 | API 요청/응답 필드와 값 제한은 검토용 제안 |

### 설명

본인 세션 상태 조회.

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
| `guidance` | object / null (제안) | X | 최신 전략 버전·구간 페이스·코칭·BPM·기록 비교와 적용 시각. 구조 미정 |
| `id` | string (UUID) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `status` | string (제안) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `courseId` | string (UUID) | X | 선택한 코스 식별자. 개인·그룹 자유러닝은 null/생략 가능 |
| `targetDistanceM` | number | X | 목표 거리, 미터, 양수 |
| `targetDurationSec` | number | X | 목표 완주 시간, 초, 양수 |
| `startedAt` | string (ISO 8601) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `endedAt` | string (ISO 8601) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `movingDurationSec` | number | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `elapsedDurationSec` | number | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `totalDistanceM` | number | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |

### 오류 응답

- `403 NOT_OWNER`
- `404 SESSION_NOT_FOUND`
- 공통 인증 오류 `401 UNAUTHORIZED`, 권한 오류 `403 FORBIDDEN`, 요청 형식 오류 `400 VALIDATION_ERROR` (해당 시).

### 처리 규칙

- 세션 재진입·재연결 복구 시 최신 준비 전략·코칭·BPM·과거 기록 비교 상태를 함께 반환한다. 조회로 분석을 실행하지 않는다.
- 정상 운동 중 갱신은 지속 전달한다. 사용자에게 새로고침이나 반복 요청을 요구하지 않는다.
- 본인 세션 상태 조회.
- 사용자 소유권·그룹 참가 권한·상태 전이·재요청 여부를 검증한다(적용 범위는 API별로 결정).
- 예시는 **명세 구조를 보여주는 가상 값**이며, 확정되지 않은 제한·동기화 주기·AI 호출 주기를 의미하지 않는다.

### 상태값

- READY → RUNNING ↔ PAUSED → COMPLETED, 시작 전 CANCELLED 가능.

### 미정 사항

- [ ] 요청·응답의 세부 필드 타입, 허용 범위, nullable 규칙 및 실제 JSON 구조 검토
- [ ] HTTP 성공 코드 및 각 예외의 오류 코드 최종 확정
- [ ] 접근 권한과 데이터 정합성의 구체적인 처리 조건 확정

## S03 러닝 시작

`POST` `/api/v1/running-sessions/{sessionId}/start`

| 항목 | 값 |
|---|---|
| 단계 | 1차 MVP |
| 인증 | 회원 |
| 관련 요구사항 | STA-001~005 / REC-001 |
| 미정 사항 | 있음 |
| 비고 | API 요청/응답 필드와 값 제한은 검토용 제안 |

### 설명

READY에서 RUNNING 전이. 초기 페이스 계획은 시작 이전 생성.

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
| `id` | string (UUID) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `status` | string (제안) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `startedAt` | string (ISO 8601) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |

### 오류 응답

- `409 INVALID_STATE`
- `403 CONSENT_REQUIRED`
- 공통 인증 오류 `401 UNAUTHORIZED`, 권한 오류 `403 FORBIDDEN`, 요청 형식 오류 `400 VALIDATION_ERROR` (해당 시).

### 처리 규칙

- 시작 상태를 반영하는 시점의 목표를 최초 목표로 고정한다. 출발 후에는 일시정지 중이어도 S08로 목표를 바꿀 수 없다. S08 변경과 시작이 경합하면 시작 여부를 일관되게 검사한다.
- 그룹런 참가 세션의 시작은 G09의 그룹장 시작 흐름과 연계한다. 일반 참가자가 S03을 직접 호출해 그룹 시작 전 자기 세션만 임의 시작하지 않도록 그룹 상태·참가 관계를 검사한다.
- 계획 대상 모드의 초기 전략 생성은 내부 준비 과정에서 수행한다. 생성 대기·실패의 구분과 시작 전제 조건은 계약 확정 시 정의한다. 무목표 자유러닝은 사전 계획 생성이 시작 조건이 아니다.
- 휴대폰·워치의 시작 요청은 같은 세션에 반영하고 중복 시작을 방지한다.
- READY에서 RUNNING 전이. 초기 페이스 계획은 시작 이전 생성.
- 사용자 소유권·그룹 참가 권한·상태 전이·재요청 여부를 검증한다(적용 범위는 API별로 결정).
- 예시는 **명세 구조를 보여주는 가상 값**이며, 확정되지 않은 제한·동기화 주기·AI 호출 주기를 의미하지 않는다.

### 상태값

- READY → RUNNING ↔ PAUSED → COMPLETED, 시작 전 CANCELLED 가능.

### 미정 사항

- [ ] 요청·응답의 세부 필드 타입, 허용 범위, nullable 규칙 및 실제 JSON 구조 검토
- [ ] HTTP 성공 코드 및 각 예외의 오류 코드 최종 확정
- [ ] 접근 권한과 데이터 정합성의 구체적인 처리 조건 확정

## S04 러닝 일시정지

`POST` `/api/v1/running-sessions/{sessionId}/pause`

| 항목 | 값 |
|---|---|
| 단계 | 1차 MVP |
| 인증 | 회원 |
| 관련 요구사항 | STA-001~005 / REC-001 |
| 미정 사항 | 있음 |
| 비고 | API 요청/응답 필드와 값 제한은 검토용 제안 |

### 설명

RUNNING에서 PAUSED 전이. 정지 기간은 페이스 저하 판단에서 제외.

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
| `id` | string (UUID) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `status` | string (제안) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `pausedAt` | string (ISO 8601) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |

### 오류 응답

- `409 INVALID_STATE`
- 공통 인증 오류 `401 UNAUTHORIZED`, 권한 오류 `403 FORBIDDEN`, 요청 형식 오류 `400 VALIDATION_ERROR` (해당 시).

### 처리 규칙

- RUNNING에서 PAUSED 전이. 정지 기간은 페이스 저하 판단에서 제외.
- 사용자 소유권·그룹 참가 권한·상태 전이·재요청 여부를 검증한다(적용 범위는 API별로 결정).
- 예시는 **명세 구조를 보여주는 가상 값**이며, 확정되지 않은 제한·동기화 주기·AI 호출 주기를 의미하지 않는다.

### 상태값

- READY → RUNNING ↔ PAUSED → COMPLETED, 시작 전 CANCELLED 가능.

### 미정 사항

- [ ] 요청·응답의 세부 필드 타입, 허용 범위, nullable 규칙 및 실제 JSON 구조 검토
- [ ] HTTP 성공 코드 및 각 예외의 오류 코드 최종 확정
- [ ] 접근 권한과 데이터 정합성의 구체적인 처리 조건 확정

## S05 러닝 재개

`POST` `/api/v1/running-sessions/{sessionId}/resume`

| 항목 | 값 |
|---|---|
| 단계 | 1차 MVP |
| 인증 | 회원 |
| 관련 요구사항 | STA-001~005 / REC-001 |
| 미정 사항 | 있음 |
| 비고 | API 요청/응답 필드와 값 제한은 검토용 제안 |

### 설명

PAUSED에서 RUNNING 전이.

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
| `id` | string (UUID) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `status` | string (제안) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `resumedAt` | string (ISO 8601) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |

### 오류 응답

- `409 INVALID_STATE`
- 공통 인증 오류 `401 UNAUTHORIZED`, 권한 오류 `403 FORBIDDEN`, 요청 형식 오류 `400 VALIDATION_ERROR` (해당 시).

### 처리 규칙

- PAUSED에서 RUNNING 전이.
- 사용자 소유권·그룹 참가 권한·상태 전이·재요청 여부를 검증한다(적용 범위는 API별로 결정).
- 예시는 **명세 구조를 보여주는 가상 값**이며, 확정되지 않은 제한·동기화 주기·AI 호출 주기를 의미하지 않는다.

### 상태값

- READY → RUNNING ↔ PAUSED → COMPLETED, 시작 전 CANCELLED 가능.

### 미정 사항

- [ ] 요청·응답의 세부 필드 타입, 허용 범위, nullable 규칙 및 실제 JSON 구조 검토
- [ ] HTTP 성공 코드 및 각 예외의 오류 코드 최종 확정
- [ ] 접근 권한과 데이터 정합성의 구체적인 처리 조건 확정

## S06 개인 러닝 종료

`POST` `/api/v1/running-sessions/{sessionId}/finish`

| 항목 | 값 |
|---|---|
| 단계 | 1차 MVP |
| 인증 | 회원 |
| 관련 요구사항 | STA-001~005 / REC-001 |
| 미정 사항 | 있음 |
| 비고 | API 요청/응답 필드와 값 제한은 검토용 제안 |

### 설명

본인 개인 운동을 종료한다. 그룹런에서도 본인만 종료하며, 실제로 운동을 시작한 참가자 전원의 개인 종료가 확인되면 서버가 그룹을 자동 종료한다.

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
| `id` | string (UUID) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `status` | string (제안) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `endedAt` | string (ISO 8601) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `totalDistanceM` | number | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `movingDurationSec` | number | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `elapsedDurationSec` | number | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `goalAchieved` | boolean | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |

### 오류 응답

- `409 INVALID_STATE`
- 공통 인증 오류 `401 UNAUTHORIZED`, 권한 오류 `403 FORBIDDEN`, 요청 형식 오류 `400 VALIDATION_ERROR` (해당 시).

### 처리 규칙

- 기록 경로를 반영한 뒤 공용 코스 자동 등록·중복 정리를 연계한다. 별도 사용자 코스 등록 요청은 요구하지 않는다.
- 그룹 강제 종료 시 종료 기준 시각까지의 측정 기록을 반영한다. 기준 시각 이전 데이터는 늦게 도착해도 복구·재집계하고 이후 데이터는 해당 그룹런 기록에 합산하지 않는다.
- 종료 후 기록 요약·구간 분석·목표 달성 평가·통계 갱신을 자동 실행한다. 별도 분석·통계 생성 요청을 요구하지 않는다.
- 운동 종료와 마지막 기록 동기화·분석 완료는 구분한다. 늦게 도착한 측정값 반영 후 결과 갱신과 중복 집계 방지 규칙을 정의한다.
- 종료 응답이 모든 분석의 완료를 보장하지 않는다. 결과 준비 상태·잠정값 표현은 응답 계약과 ERD 확정 시 보완한다.
- 연결 끊김 동안 기기가 저장한 종료 상태·기록은 재연결 시 복구한다.
- 본인 개인 운동을 종료한다. 그룹런에서도 본인만 종료하며, 실제로 운동을 시작한 참가자 전원의 개인 종료가 확인되면 서버가 그룹을 자동 종료한다.
- 사용자 소유권·그룹 참가 권한·상태 전이·재요청 여부를 검증한다(적용 범위는 API별로 결정).
- 예시는 **명세 구조를 보여주는 가상 값**이며, 확정되지 않은 제한·동기화 주기·AI 호출 주기를 의미하지 않는다.

### 상태값

- READY → RUNNING ↔ PAUSED → COMPLETED, 시작 전 CANCELLED 가능.

### 미정 사항

- [ ] 요청·응답의 세부 필드 타입, 허용 범위, nullable 규칙 및 실제 JSON 구조 검토
- [ ] HTTP 성공 코드 및 각 예외의 오류 코드 최종 확정
- [ ] 접근 권한과 데이터 정합성의 구체적인 처리 조건 확정

## S07 러닝 취소

`POST` `/api/v1/running-sessions/{sessionId}/cancel`

| 항목 | 값 |
|---|---|
| 단계 | 1차 MVP |
| 인증 | 회원 |
| 관련 요구사항 | STA-001~005 / REC-001 |
| 미정 사항 | 있음 |
| 비고 | API 요청/응답 필드와 값 제한은 검토용 제안 |

### 설명

READY에서 CANCELLED. 달리기 시작 후 취소와 구분.

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
| `id` | string (UUID) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `status` | string (제안) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |

### 오류 응답

- `409 INVALID_STATE`
- 공통 인증 오류 `401 UNAUTHORIZED`, 권한 오류 `403 FORBIDDEN`, 요청 형식 오류 `400 VALIDATION_ERROR` (해당 시).

### 처리 규칙

- READY에서 CANCELLED. 달리기 시작 후 취소와 구분.
- 사용자 소유권·그룹 참가 권한·상태 전이·재요청 여부를 검증한다(적용 범위는 API별로 결정).
- 예시는 **명세 구조를 보여주는 가상 값**이며, 확정되지 않은 제한·동기화 주기·AI 호출 주기를 의미하지 않는다.

### 상태값

- READY → RUNNING ↔ PAUSED → COMPLETED, 시작 전 CANCELLED 가능.

### 미정 사항

- [ ] 요청·응답의 세부 필드 타입, 허용 범위, nullable 규칙 및 실제 JSON 구조 검토
- [ ] HTTP 성공 코드 및 각 예외의 오류 코드 최종 확정
- [ ] 접근 권한과 데이터 정합성의 구체적인 처리 조건 확정

## S08 출발 전 러닝 설정 수정

`PATCH` `/api/v1/running-sessions/{sessionId}`

| 항목 | 값 |
|---|---|
| 단계 | 1차 MVP |
| 인증 | 본인 |
| 관련 요구사항 | USR-004 / PAC-001 |
| 비고 | 사용자 결정 반영. 필드·경로·오류 코드는 구현 전 검토할 제안 |

### 설명

러닝 시작 전 준비 중인 세션의 코스·목표·비교 기록을 수정한다. 시작 후에는 최초 목표를 변경할 수 없다.

### 인증 및 권한

- 본인 소유의 아직 출발하지 않은 READY 세션만 수정한다. 그룹 공동 코스·목표는 그룹장 G04로 변경하며 S08로 개인이 덮어쓰지 않는다.

### Path Parameters

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `sessionId` | string (UUID) | O | 준비 중인 본인 세션 |

### Query Parameters

없음

### Request Body

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `courseId` | string (UUID) / null | X | 코스 변경. null은 자유러닝 선택 |
| `targetDistanceM` | number / null | X | 목표 거리. 자유러닝은 선택 입력. 기존 목표 제거의 null 처리 계약은 별도 확정 |
| `targetDurationSec` | number / null | X | 목표 시간. 입력 조합은 S01과 동일 |
| `targetPaceSecPerKm` | number / null | X | 목표 페이스. 자유러닝은 단독 입력 가능. 환산·상충 검증 계약은 별도 확정 |
| `comparisonSessionId` | string (UUID) / null | X | 비교 기록. null은 비교 해제 |

```json
{"targetDistanceM": 5000, "targetDurationSec": 1800}
```

### Response

`200 OK (제안)`

```json
{}
```

- 세션 ID·변경된 설정·모드에 따른 계획 제공 여부와 준비 상태를 제공한다. 계획 대상 모드는 준비 완료 시 전략·BPM을 제공하고 무목표 자유러닝은 사전 계획 비대상으로 표시한다. 상세 구조는 S01/S02 계약 확정 시 통일한다.

### 오류 응답

- `403 NOT_OWNER`
- `409 SESSION_ALREADY_STARTED`
- `409 INVALID_STATE`
- `422 INVALID_GOAL`

### 처리 규칙

- 생략한 필드는 유지하고 변경 후 전체 설정을 검증한다. 코스·비교 기록 일치와 목표 유효성을 함께 검사한다.
- 저장 후 바뀐 입력과 모드에 따라 초기 안내를 갱신해 앱·워치에 전달한다. 자유러닝의 목표를 모두 제거하면 기존 사전 계획을 해제하고 계획 비대상으로 전환한다. 이전 입력의 늦은 분석 결과는 폐기한다.
- 이미 RUNNING·PAUSED·종료 상태이거나 실제 시작 이력이 있으면 거부한다. 그룹장 G04로도 출발 후 공동 목표를 변경하지 않는다.

### 상태값

READY에서만 허용한다.

### 미정 사항

- [ ] 기존 목표 제거의 null 처리와 선택 목표 환산·상충 검증 계약
- [ ] 변경·시작 경합, 전략 버전·준비 상태·실패 표시 계약

## S09 러닝 세션 삭제

`DELETE` `/api/v1/running-sessions/{sessionId}`

| 항목 | 값 |
|---|---|
| 단계 | 1차 MVP |
| 인증 | 본인 |
| 관련 요구사항 | STA-004 / REC-001~002 |
| 미정 사항 | 있음 |
| 비고 | API 요청/응답 필드와 값 제한은 검토용 제안. S07 취소와 별도 |

### 설명

본인 러닝 세션을 삭제 표시(기존방식)한다. S07은 세션을 `CANCELLED`로 남기고, 이 API는 이후 조회 대상에서 제거한다.

### 인증 및 권한

- 본인 소유의 세션만 삭제한다.
- 그룹 공동 진행 상태와 다른 참가자 세션은 이 API로 지우지 않는다.

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
  "id": "018f5c2a-7b3d-7c2a-8f1e-6a0b9c8d7e6f",
  "deletedAt": "2026-10-26T10:54:00+09:00"
}
```

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `id` | string (UUID) | O | 삭제한 세션 ID |
| `deletedAt` | string (ISO 8601) | O | 삭제 표시 시각 |

### 오류 응답

- `403 NOT_OWNER`
- `404 SESSION_NOT_FOUND`
- `409 INVALID_STATE`
- 공통 인증 오류 `401 UNAUTHORIZED`, 권한 오류 `403 FORBIDDEN`, 요청 형식 오류 `400 VALIDATION_ERROR` (해당 시).

### 처리 규칙

- 본인 세션인지 확인한 뒤 삭제 표시(기존방식)한다. 행을 물리 삭제하지 않는다.
- 이미 삭제 표시된 세션의 재요청은 `404 SESSION_NOT_FOUND`로 응답한다.
- `RUNNING`, `PAUSED`는 삭제하지 않고 `409 INVALID_STATE`로 거부한다.
- 그룹런에 연결된 세션은 다른 참가자 진행과 그룹 결과에 영향을 주면 거부한다. 허용 상태는 미정이다.
- 사용자 소유권·그룹 참가 권한·상태 전이·재요청 여부를 검증한다(적용 범위는 API별로 결정).

### 상태값

- `READY`, `CANCELLED`, `COMPLETED` 삭제 허용은 제안이다. `RUNNING`, `PAUSED`는 거부한다.

### 미정 사항

- [ ] `READY`, `CANCELLED`, `COMPLETED` 중 실제로 지울 수 있는 상태
- [ ] 삭제 시 구간 기록, 비교 대상, 커뮤니티에 공유된 기록의 처리
