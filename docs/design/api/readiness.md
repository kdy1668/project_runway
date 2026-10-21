# API 명세 — 운동 준비도

[API 명세 색인](README.md)으로 돌아가기. 공통 규약은 [API 명세](README.md#공통-규약)를 따른다.

| ID | 이름 | Method | Endpoint | 단계 | 인증 |
|---|---|---|---|---|---|
| [R01](#r01-운동-준비도-평가) | 운동 준비도 평가 | POST | `/readiness-assessments` | 1차 MVP | 회원 |
| [R02](#r02-최신-준비도-조회) | 최신 준비도 조회 | GET | `/readiness-assessments/latest` | 1차 MVP | 회원 |

## R01 운동 준비도 평가

`POST` `/api/v1/readiness-assessments`

| 항목 | 값 |
|---|---|
| 단계 | 1차 MVP |
| 인증 | 회원 |
| 관련 요구사항 | RDY-001~003 |
| 미정 사항 | 있음 |
| 비고 | API 요청/응답 필드와 값 제한은 검토용 제안 |

### 설명

주관적 컨디션, 건강·활동 데이터 기반 평가. 자료 부족 시 결과 표기 정책 미정.

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
| `subjectiveCondition` | string (제안) | O | 운동 전 사용자 자가 컨디션(선택지 미정) |
| `sessionId` | string (UUID) | X | 러닝 세션 UUID |

```json
{
  "subjectiveCondition": "NORMAL"
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
| `readinessScore` | number | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `readinessLevel` | string (제안) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `reasonDetails` | string / object (확인 필요) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `assessedAt` | string (ISO 8601) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `dataAvailability` | object | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |

### 오류 응답

- `403 CONSENT_REQUIRED`
- `422 INSUFFICIENT_DATA`
- 공통 인증 오류 `401 UNAUTHORIZED`, 권한 오류 `403 FORBIDDEN`, 요청 형식 오류 `400 VALIDATION_ERROR` (해당 시).

### 처리 규칙

- 주관적 컨디션, 건강·활동 데이터 기반 평가. 자료 부족 시 결과 표기 정책 미정.
- 사용자 소유권·그룹 참가 권한·상태 전이·재요청 여부를 검증한다(적용 범위는 API별로 결정).
- 예시는 **명세 구조를 보여주는 가상 값**이며, 확정되지 않은 제한·동기화 주기·AI 호출 주기를 의미하지 않는다.

### 상태값

- PUBLIC / PRIVATE 또는 기능별 ERD CHECK 값, 해당 없으면 별도 상태 없음.

### 미정 사항

- [ ] 요청·응답의 세부 필드 타입, 허용 범위, nullable 규칙 및 실제 JSON 구조 검토
- [ ] HTTP 성공 코드 및 각 예외의 오류 코드 최종 확정
- [ ] 접근 권한과 데이터 정합성의 구체적인 처리 조건 확정

## R02 최신 준비도 조회

`GET` `/api/v1/readiness-assessments/latest`

| 항목 | 값 |
|---|---|
| 단계 | 1차 MVP |
| 인증 | 회원 |
| 관련 요구사항 | RDY-001~003 |
| 미정 사항 | 있음 |
| 비고 | API 요청/응답 필드와 값 제한은 검토용 제안 |

### 설명

본인 최신 준비도 평가 반환.

### 인증 및 권한

- 로그인 사용자 본인 또는 서비스 리소스 접근 권한 검사.
- 건강정보·실시간 위치·타인 기록 조회 시 동의 상태 및 공개 범위가 우선한다.

### Path Parameters

없음

### Query Parameters

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `sessionId` | string (UUID) | X | 러닝 세션 UUID |

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
| `subjectiveCondition` | string (제안) | X | 운동 전 사용자 자가 컨디션(선택지 미정) |
| `readinessScore` | number | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `readinessLevel` | string (제안) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `reasonDetails` | string / object (확인 필요) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `assessedAt` | string (ISO 8601) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |

### 오류 응답

- `404 ASSESSMENT_NOT_FOUND`
- 공통 인증 오류 `401 UNAUTHORIZED`, 권한 오류 `403 FORBIDDEN`, 요청 형식 오류 `400 VALIDATION_ERROR` (해당 시).

### 처리 규칙

- 본인 최신 준비도 평가 반환.
- 사용자 소유권·그룹 참가 권한·상태 전이·재요청 여부를 검증한다(적용 범위는 API별로 결정).
- 예시는 **명세 구조를 보여주는 가상 값**이며, 확정되지 않은 제한·동기화 주기·AI 호출 주기를 의미하지 않는다.

### 상태값

- PUBLIC / PRIVATE 또는 기능별 ERD CHECK 값, 해당 없으면 별도 상태 없음.

### 미정 사항

- [ ] 요청·응답의 세부 필드 타입, 허용 범위, nullable 규칙 및 실제 JSON 구조 검토
- [ ] HTTP 성공 코드 및 각 예외의 오류 코드 최종 확정
- [ ] 접근 권한과 데이터 정합성의 구체적인 처리 조건 확정
