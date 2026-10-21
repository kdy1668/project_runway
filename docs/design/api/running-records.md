# API 명세 — 러닝 기록·분석

[API 명세 색인](README.md)으로 돌아가기. 공통 규약은 [API 명세](README.md#공통-규약)를 따른다.

| ID | 이름 | Method | Endpoint | 단계 | 인증 |
|---|---|---|---|---|---|
| [H01](#h01-러닝-기록-목록) | 러닝 기록 목록 | GET | `/running-records` | 1차 MVP | 회원 |
| [H02](#h02-러닝-기록-상세) | 러닝 기록 상세 | GET | `/running-records/{sessionId}` | 1차 MVP | 회원 |
| [H03](#h03-구간별-러닝-분석) | 구간별 러닝 분석 | GET | `/running-records/{sessionId}/splits` | 1차 MVP | 회원 |
| [H04](#h04-러닝-gps-경로) | 러닝 GPS 경로 | GET | `/running-records/{sessionId}/route` | 1차 MVP | 회원 |
| [H05](#h05-러닝-기록-공개-설정) | 러닝 기록 공개 설정 | PATCH | `/running-records/{sessionId}/visibility` | 1차 MVP | 회원 |

## H01 러닝 기록 목록

`GET` `/api/v1/running-records`

| 항목 | 값 |
|---|---|
| 단계 | 1차 MVP |
| 인증 | 회원 |
| 관련 요구사항 | REC-001~005 / SYS-002 |
| 미정 사항 | 있음 |
| 비고 | API 요청/응답 필드와 값 제한은 검토용 제안 |

### 설명

완료된 본인 러닝 기록 목록만 조회.

### 인증 및 권한

- 로그인 사용자 본인 또는 서비스 리소스 접근 권한 검사.
- 건강정보·실시간 위치·타인 기록 조회 시 동의 상태 및 공개 범위가 우선한다.

### Path Parameters

없음

### Query Parameters

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `cursor` | string / object (확인 필요) | X | 서버 발급 불투명 페이지 커서 |
| `limit` | number | X | 조회 결과 최대 개수(최대값 미정) |
| `from` | string / object (확인 필요) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `to` | string / object (확인 필요) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `courseId` | string (UUID) | X | 선택한 코스 식별자. 개인·그룹 자유러닝은 null/생략 가능 |

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

- 완료된 본인 러닝 기록 목록만 조회.
- 사용자 소유권·그룹 참가 권한·상태 전이·재요청 여부를 검증한다(적용 범위는 API별로 결정).
- 예시는 **명세 구조를 보여주는 가상 값**이며, 확정되지 않은 제한·동기화 주기·AI 호출 주기를 의미하지 않는다.

### 상태값

- PUBLIC / PRIVATE 또는 기능별 ERD CHECK 값, 해당 없으면 별도 상태 없음.

### 미정 사항

- [ ] 요청·응답의 세부 필드 타입, 허용 범위, nullable 규칙 및 실제 JSON 구조 검토
- [ ] HTTP 성공 코드 및 각 예외의 오류 코드 최종 확정
- [ ] 접근 권한과 데이터 정합성의 구체적인 처리 조건 확정

## H02 러닝 기록 상세

`GET` `/api/v1/running-records/{sessionId}`

| 항목 | 값 |
|---|---|
| 단계 | 1차 MVP |
| 인증 | 회원 |
| 관련 요구사항 | REC-001~005 / SYS-002 |
| 미정 사항 | 있음 |
| 비고 | API 요청/응답 필드와 값 제한은 검토용 제안 |

### 설명

초기 목표와 실제 결과를 함께 제공. 공개 범위 검사.

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
| `sessionId` | string (UUID) | X | 러닝 세션 UUID |
| `targetDistanceM` | number | X | 목표 거리, 미터, 양수 |
| `targetDurationSec` | number | X | 목표 완주 시간, 초, 양수 |
| `actualDistanceM` | number | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `movingDurationSec` | number | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `elapsedDurationSec` | number | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `averagePaceSecPerKm` | number | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `averageHeartRate` | string / object (확인 필요) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `averageCadence` | string / object (확인 필요) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `goalAchieved` | boolean | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `visibility` | string (제안) | X | PUBLIC / PRIVATE (DB 제한 기준) |
| `courseId` | string (UUID) | X | 선택한 코스 식별자. 개인·그룹 자유러닝은 null/생략 가능 |

### 오류 응답

- `403 RECORD_PRIVATE`
- `404 RECORD_NOT_FOUND`
- 공통 인증 오류 `401 UNAUTHORIZED`, 권한 오류 `403 FORBIDDEN`, 요청 형식 오류 `400 VALIDATION_ERROR` (해당 시).

### 처리 규칙

- 초기 목표와 실제 결과를 함께 제공. 공개 범위 검사.
- 사용자 소유권·그룹 참가 권한·상태 전이·재요청 여부를 검증한다(적용 범위는 API별로 결정).
- 예시는 **명세 구조를 보여주는 가상 값**이며, 확정되지 않은 제한·동기화 주기·AI 호출 주기를 의미하지 않는다.

### 상태값

- PUBLIC / PRIVATE 또는 기능별 ERD CHECK 값, 해당 없으면 별도 상태 없음.

### 미정 사항

- [ ] 요청·응답의 세부 필드 타입, 허용 범위, nullable 규칙 및 실제 JSON 구조 검토
- [ ] HTTP 성공 코드 및 각 예외의 오류 코드 최종 확정
- [ ] 접근 권한과 데이터 정합성의 구체적인 처리 조건 확정


## H03 구간별 러닝 분석

`GET` `/api/v1/running-records/{sessionId}/splits`

| 항목 | 값 |
|---|---|
| 단계 | 1차 MVP |
| 인증 | 회원 |
| 관련 요구사항 | REC-001~005 / SYS-002 |
| 미정 사항 | 있음 |
| 비고 | API 요청/응답 필드와 값 제한은 검토용 제안 |

### 설명

구간별 페이스·심박·케이던스 분석.

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
| `splits` | array | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |

### 오류 응답

- `404 RECORD_NOT_FOUND`
- 공통 인증 오류 `401 UNAUTHORIZED`, 권한 오류 `403 FORBIDDEN`, 요청 형식 오류 `400 VALIDATION_ERROR` (해당 시).

### 처리 규칙

- 구간별 페이스·심박·케이던스 분석.
- 사용자 소유권·그룹 참가 권한·상태 전이·재요청 여부를 검증한다(적용 범위는 API별로 결정).
- 예시는 **명세 구조를 보여주는 가상 값**이며, 확정되지 않은 제한·동기화 주기·AI 호출 주기를 의미하지 않는다.

### 상태값

- PUBLIC / PRIVATE 또는 기능별 ERD CHECK 값, 해당 없으면 별도 상태 없음.

### 미정 사항

- [ ] 요청·응답의 세부 필드 타입, 허용 범위, nullable 규칙 및 실제 JSON 구조 검토
- [ ] HTTP 성공 코드 및 각 예외의 오류 코드 최종 확정
- [ ] 접근 권한과 데이터 정합성의 구체적인 처리 조건 확정


## H04 러닝 GPS 경로

`GET` `/api/v1/running-records/{sessionId}/route`

| 항목 | 값 |
|---|---|
| 단계 | 1차 MVP |
| 인증 | 회원 |
| 관련 요구사항 | REC-001~005 / SYS-002 |
| 미정 사항 | 있음 |
| 비고 | API 요청/응답 필드와 값 제한은 검토용 제안 |

### 설명

좌표 공개 범위 적용. 위치 비공개일 때 경로 미노출.

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
| `route` | GeoJSON | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `pointCount` | number | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `locationVisibility` | string / object (확인 필요) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |

### 오류 응답

- `403 LOCATION_PRIVATE`
- `404 RECORD_NOT_FOUND`
- 공통 인증 오류 `401 UNAUTHORIZED`, 권한 오류 `403 FORBIDDEN`, 요청 형식 오류 `400 VALIDATION_ERROR` (해당 시).

### 처리 규칙

- 좌표 공개 범위 적용. 위치 비공개일 때 경로 미노출.
- 사용자 소유권·그룹 참가 권한·상태 전이·재요청 여부를 검증한다(적용 범위는 API별로 결정).
- 예시는 **명세 구조를 보여주는 가상 값**이며, 확정되지 않은 제한·동기화 주기·AI 호출 주기를 의미하지 않는다.

### 상태값

- PUBLIC / PRIVATE 또는 기능별 ERD CHECK 값, 해당 없으면 별도 상태 없음.

### 미정 사항

- [ ] 요청·응답의 세부 필드 타입, 허용 범위, nullable 규칙 및 실제 JSON 구조 검토
- [ ] HTTP 성공 코드 및 각 예외의 오류 코드 최종 확정
- [ ] 접근 권한과 데이터 정합성의 구체적인 처리 조건 확정


## H05 러닝 기록 공개 설정

`PATCH` `/api/v1/running-records/{sessionId}/visibility`

| 항목 | 값 |
|---|---|
| 단계 | 1차 MVP |
| 인증 | 회원 |
| 관련 요구사항 | REC-001~005 / SYS-002 |
| 미정 사항 | 있음 |
| 비고 | API 요청/응답 필드와 값 제한은 검토용 제안 |

### 설명

본인 완료 기록만 공개 범위 수정.

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
| `visibility` | string (제안) | O | PUBLIC / PRIVATE (DB 제한 기준) |

```json
{
  "visibility": "PRIVATE"
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
| `sessionId` | string (UUID) | X | 러닝 세션 UUID |
| `visibility` | string (제안) | X | PUBLIC / PRIVATE (DB 제한 기준) |

### 오류 응답

- `403 NOT_OWNER`
- `404 RECORD_NOT_FOUND`
- 공통 인증 오류 `401 UNAUTHORIZED`, 권한 오류 `403 FORBIDDEN`, 요청 형식 오류 `400 VALIDATION_ERROR` (해당 시).

### 처리 규칙

- 본인 완료 기록만 공개 범위 수정.
- 사용자 소유권·그룹 참가 권한·상태 전이·재요청 여부를 검증한다(적용 범위는 API별로 결정).
- 예시는 **명세 구조를 보여주는 가상 값**이며, 확정되지 않은 제한·동기화 주기·AI 호출 주기를 의미하지 않는다.

### 상태값

- PUBLIC / PRIVATE 또는 기능별 ERD CHECK 값, 해당 없으면 별도 상태 없음.

### 미정 사항

- [ ] 요청·응답의 세부 필드 타입, 허용 범위, nullable 규칙 및 실제 JSON 구조 검토
- [ ] HTTP 성공 코드 및 각 예외의 오류 코드 최종 확정
- [ ] 접근 권한과 데이터 정합성의 구체적인 처리 조건 확정
