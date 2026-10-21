# API 명세 — 러닝 코스

[API 명세 색인](README.md)으로 돌아가기. 공통 규약은 [API 명세](README.md#공통-규약)를 따른다.

| ID | 이름 | Method | Endpoint | 단계 | 인증 |
|---|---|---|---|---|---|
| [C01](#c01-ai-코스-추천) | AI 코스 추천 | POST | `/courses/recommendations` | 1차 MVP | 회원 |
| [C02](#c02-공용-코스-검색) | 공용 코스 검색 | GET | `/courses` | 1차 MVP | 회원 |
| [C03](#c03-코스-상세-조회) | 코스 상세 조회 | GET | `/courses/{courseId}` | 1차 MVP | 회원 |
| [C04](#c04-완료-경로-코스-등록) | 완료 경로 코스 등록 | POST | `/courses` | 1차 MVP | 회원 |
| [C07](#c07-코스-저장) | 코스 저장 | PUT | `/courses/{courseId}/bookmark` | 1차 MVP | 회원 |
| [C08](#c08-코스-저장-해제) | 코스 저장 해제 | DELETE | `/courses/{courseId}/bookmark` | 1차 MVP | 회원 |
| [C09](#c09-저장-코스-목록) | 저장 코스 목록 | GET | `/users/me/bookmarked-courses` | 1차 MVP | 회원 |

## C01 AI 코스 추천

`POST` `/api/v1/courses/recommendations`

| 항목 | 값 |
|---|---|
| 단계 | 1차 MVP |
| 인증 | 회원 |
| 관련 요구사항 | CRS-001, CRS-003, CRS-005, CRS-007~008 / COM-002 / SYS-002 |
| 미정 사항 | 있음 |
| 비고 | API 요청/응답 필드와 값 제한은 검토용 제안 |

### 설명

1차 MVP는 `ACTIVE` 상태의 기존 서비스 공용 코스만 추천하며 새 코스를 생성하지 않는다. 결과가 없으면 빈 배열을 반환한다.

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
| `latitude` | number | O | 시작 위도(WGS84, -90~90) |
| `longitude` | number | O | 시작 경도(WGS84, -180~180) |
| `targetDistanceM` | number | O | 목표 거리, 미터, 양수 |
| `goalInputType` | string (제안) | O | TIME/PACE 중 하나 |
| `targetDurationSec` | number | 조건부 | TIME 선택 시 필수인 목표 완주 시간, 초, 양수 |
| `targetPaceSecPerKm` | number | 조건부 | PACE 선택 시 필수인 목표 페이스, 초/km, 양수 |
| `runningLevel` | string (제안) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `environmentIds` | string[] (UUID) | X | 선호 환경 유형 UUID 배열 |
| `limit` | number | X | 조회 결과 최대 개수(최대값 미정) |

```json
{
  "latitude": 35.1796,
  "longitude": 129.0756,
  "targetDistanceM": 5000,
  "goalInputType": "TIME",
  "targetDurationSec": 1800
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
| `courses` | array | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `emptyReason` | string / object (확인 필요) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |

### 오류 응답

- `403 LOCATION_CONSENT_REQUIRED`
- `422 INVALID_SEARCH`
- 공통 인증 오류 `401 UNAUTHORIZED`, 권한 오류 `403 FORBIDDEN`, 요청 형식 오류 `400 VALIDATION_ERROR` (해당 시).

### 처리 규칙

- 1차 MVP는 `ACTIVE` 상태의 기존 서비스 공용 코스만 추천하며 새 코스를 생성하지 않는다. `MERGED`, `BLOCKED` 코스는 추천에서 제외하고 결과가 없으면 빈 배열을 반환한다.
- 사용자 소유권·그룹 참가 권한·상태 전이·재요청 여부를 검증한다(적용 범위는 API별로 결정).
- 예시는 **명세 구조를 보여주는 가상 값**이며, 확정되지 않은 제한·동기화 주기·AI 호출 주기를 의미하지 않는다.

### 상태값

- `ACTIVE` 코스만 추천 대상이다.

### 미정 사항

- [ ] 요청·응답의 세부 필드 타입, 허용 범위, nullable 규칙 및 실제 JSON 구조 검토
- [ ] HTTP 성공 코드 및 각 예외의 오류 코드 최종 확정
- [ ] 접근 권한과 데이터 정합성의 구체적인 처리 조건 확정

## C02 공용 코스 검색

`GET` `/api/v1/courses`

| 항목 | 값 |
|---|---|
| 단계 | 1차 MVP |
| 인증 | 회원 |
| 관련 요구사항 | CRS-001, CRS-003, CRS-005, CRS-007~008 / COM-002 / SYS-002 |
| 미정 사항 | 있음 |
| 비고 | API 요청/응답 필드와 값 제한은 검토용 제안 |

### 설명

`ACTIVE` 상태의 서비스 공용 코스를 조회하고 필터를 조합한다.

### 인증 및 권한

- 로그인 사용자 본인 또는 서비스 리소스 접근 권한 검사.
- 건강정보·실시간 위치·타인 기록 조회 시 동의 상태 및 공개 범위가 우선한다.

### Path Parameters

없음

### Query Parameters

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `latitude` | number | X | 시작 위도(WGS84, -90~90) |
| `longitude` | number | X | 시작 경도(WGS84, -180~180) |
| `radiusM` | number | X | 검색 반경, 미터 |
| `targetDistanceM` | number | X | 목표 거리, 미터, 양수 |
| `goalInputType` | string (제안) | X | TIME/PACE 중 하나 |
| `targetDurationSec` | number | 조건부 | TIME 선택 시 필요한 목표 완주 시간, 초, 양수 |
| `targetPaceSecPerKm` | number | 조건부 | PACE 선택 시 필요한 목표 페이스, 초/km, 양수 |
| `environmentId` | string (UUID) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
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
| `items` | array | X | 조건에 맞는 `ACTIVE` 상태 공용 코스 목록 |
| `page` | string / object (확인 필요) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |

### 오류 응답

- `400 INVALID_FILTER`
- 공통 인증 오류 `401 UNAUTHORIZED`, 권한 오류 `403 FORBIDDEN`, 요청 형식 오류 `400 VALIDATION_ERROR` (해당 시).

### 처리 규칙

- `ACTIVE` 상태의 서비스 공용 코스만 일반 검색 결과에 포함한다.
- 사용자 소유권·그룹 참가 권한·상태 전이·재요청 여부를 검증한다(적용 범위는 API별로 결정).
- 예시는 **명세 구조를 보여주는 가상 값**이며, 확정되지 않은 제한·동기화 주기·AI 호출 주기를 의미하지 않는다.

### 상태값

- `ACTIVE` 코스만 일반 검색 대상이다.

### 미정 사항

- [ ] 요청·응답의 세부 필드 타입, 허용 범위, nullable 규칙 및 실제 JSON 구조 검토
- [ ] HTTP 성공 코드 및 각 예외의 오류 코드 최종 확정
- [ ] 접근 권한과 데이터 정합성의 구체적인 처리 조건 확정


## C03 코스 상세 조회

`GET` `/api/v1/courses/{courseId}`

| 항목 | 값 |
|---|---|
| 단계 | 1차 MVP |
| 인증 | 회원 |
| 관련 요구사항 | CRS-001, CRS-003, CRS-005, CRS-007~008 / COM-002 / SYS-002 |
| 미정 사항 | 있음 |
| 비고 | API 요청/응답 필드와 값 제한은 검토용 제안 |

### 설명

요청 사용자 페이스 기준 예상 소요 시간, 경로는 GeoJSON.

### 인증 및 권한

- 로그인 사용자 본인 또는 서비스 리소스 접근 권한 검사.
- 건강정보·실시간 위치·타인 기록 조회 시 동의 상태 및 공개 범위가 우선한다.

### Path Parameters

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `courseId` | string (UUID) | O | 선택한 코스 식별자. 개인·그룹 자유러닝은 null/생략 가능 |

### Query Parameters

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `targetPaceSecPerKm` | number | X | 목표 페이스, 초/km, 양수 |

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
| `name` | string / object (확인 필요) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `description` | string / object (확인 필요) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `route` | GeoJSON | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `startPosition` | GeoJSON | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `distanceM` | number | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `elevationGainM` | number | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `elevationProfile` | string / object (확인 필요) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `environmentTags` | array | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `estimatedDurationSec` | number | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `status` | string | X | `ACTIVE` / `MERGED` / `BLOCKED` |
| `mergedIntoCourseId` | string (UUID) | X | `MERGED`일 때 안내할 대표 코스 식별자 |

### 오류 응답

- `404 COURSE_NOT_FOUND`
- 공통 인증 오류 `401 UNAUTHORIZED`, 권한 오류 `403 FORBIDDEN`, 요청 형식 오류 `400 VALIDATION_ERROR` (해당 시).

### 처리 규칙

- 요청 사용자 페이스 기준 예상 소요 시간, 경로는 GeoJSON.
- 사용자 소유권·그룹 참가 권한·상태 전이·재요청 여부를 검증한다(적용 범위는 API별로 결정).
- 예시는 **명세 구조를 보여주는 가상 값**이며, 확정되지 않은 제한·동기화 주기·AI 호출 주기를 의미하지 않는다.

### 상태값

- `ACTIVE` / `MERGED` / `BLOCKED`. 저장한 코스가 `MERGED` 또는 `BLOCKED`이면 상태를 안내하고, `MERGED`이면 대표 코스를 함께 안내한다.

### 미정 사항

- [ ] 요청·응답의 세부 필드 타입, 허용 범위, nullable 규칙 및 실제 JSON 구조 검토
- [ ] HTTP 성공 코드 및 각 예외의 오류 코드 최종 확정
- [ ] 접근 권한과 데이터 정합성의 구체적인 처리 조건 확정


## C04 완료 경로 코스 등록

`POST` `/api/v1/courses`

| 항목 | 값 |
|---|---|
| 단계 | 1차 MVP |
| 인증 | 회원 |
| 관련 요구사항 | CRS-001, CRS-003, CRS-005, CRS-007~008 / COM-002 / SYS-002 |
| 미정 사항 | 있음 |
| 비고 | API 요청/응답 필드와 값 제한은 검토용 제안 |

### 설명

완료된 본인 세션의 GPS 경로 사용.

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
| `sourceSessionId` | string (UUID) | O | 코스의 원천이 되는 완료된 러닝 세션 UUID |
| `name` | string / object (확인 필요) | O | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `description` | string / object (확인 필요) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `environmentIds` | string[] (UUID) | X | 선호 환경 유형 UUID 배열 |

```json
{
  "sourceSessionId": "00000000-0000-4000-8000-000000000001",
  "name": "하천 러닝 코스"
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
| `name` | string / object (확인 필요) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `sourceSessionId` | string (UUID) | X | 코스의 원천이 되는 완료된 러닝 세션 UUID |
| `route` | GeoJSON | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `distanceM` | number | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `environmentTags` | array | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `status` | string | X | 등록 시 `ACTIVE` |

### 오류 응답

- `403 SESSION_NOT_OWNED`
- `409 SESSION_NOT_COMPLETED`
- 공통 인증 오류 `401 UNAUTHORIZED`, 권한 오류 `403 FORBIDDEN`, 요청 형식 오류 `400 VALIDATION_ERROR` (해당 시).

### 처리 규칙

- 완료된 본인 세션의 GPS 경로 사용.
- 사용자 소유권·그룹 참가 권한·상태 전이·재요청 여부를 검증한다(적용 범위는 API별로 결정).
- 예시는 **명세 구조를 보여주는 가상 값**이며, 확정되지 않은 제한·동기화 주기·AI 호출 주기를 의미하지 않는다.

### 상태값

- 등록된 코스는 서비스 공용 코스이며 초기 상태는 `ACTIVE`이다. 등록자도 코스 원본을 임의로 비공개 전환하거나 삭제할 수 없다.

### 미정 사항

- [ ] 요청·응답의 세부 필드 타입, 허용 범위, nullable 규칙 및 실제 JSON 구조 검토
- [ ] HTTP 성공 코드 및 각 예외의 오류 코드 최종 확정
- [ ] 접근 권한과 데이터 정합성의 구체적인 처리 조건 확정


## C07 코스 저장

`PUT` `/api/v1/courses/{courseId}/bookmark`

| 항목 | 값 |
|---|---|
| 단계 | 1차 MVP |
| 인증 | 회원 |
| 관련 요구사항 | CRS-001, CRS-003, CRS-005, CRS-007~008 / COM-002 / SYS-002 |
| 미정 사항 | 있음 |
| 비고 | API 요청/응답 필드와 값 제한은 검토용 제안 |

### 설명

반복 저장은 멱등.

### 인증 및 권한

- 로그인 사용자 본인 또는 서비스 리소스 접근 권한 검사.
- 건강정보·실시간 위치·타인 기록 조회 시 동의 상태 및 공개 범위가 우선한다.

### Path Parameters

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `courseId` | string (UUID) | O | 선택한 코스 식별자. 개인·그룹 자유러닝은 null/생략 가능 |

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
| `bookmarked` | boolean | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `createdAt` | string (ISO 8601) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |

### 오류 응답

- `403 COURSE_INACCESSIBLE`
- `404 COURSE_NOT_FOUND`
- 공통 인증 오류 `401 UNAUTHORIZED`, 권한 오류 `403 FORBIDDEN`, 요청 형식 오류 `400 VALIDATION_ERROR` (해당 시).

### 처리 규칙

- 반복 저장은 멱등.
- 사용자 소유권·그룹 참가 권한·상태 전이·재요청 여부를 검증한다(적용 범위는 API별로 결정).
- 예시는 **명세 구조를 보여주는 가상 값**이며, 확정되지 않은 제한·동기화 주기·AI 호출 주기를 의미하지 않는다.

### 상태값

- `ACTIVE`, `MERGED`, `BLOCKED` 코스를 저장할 수 있으나 추천에는 `ACTIVE`만 사용한다.

### 미정 사항

- [ ] 요청·응답의 세부 필드 타입, 허용 범위, nullable 규칙 및 실제 JSON 구조 검토
- [ ] HTTP 성공 코드 및 각 예외의 오류 코드 최종 확정
- [ ] 접근 권한과 데이터 정합성의 구체적인 처리 조건 확정


## C08 코스 저장 해제

`DELETE` `/api/v1/courses/{courseId}/bookmark`

| 항목 | 값 |
|---|---|
| 단계 | 1차 MVP |
| 인증 | 회원 |
| 관련 요구사항 | CRS-001, CRS-003, CRS-005, CRS-007~008 / COM-002 / SYS-002 |
| 미정 사항 | 있음 |
| 비고 | API 요청/응답 필드와 값 제한은 검토용 제안 |

### 설명

사용자의 저장 코스 목록에서만 코스를 제거한다. 서비스 공용 코스 원본은 변경하거나 삭제하지 않으며, 이미 저장 해제된 경우에도 성공 가능한 멱등 규칙을 적용한다.

### 인증 및 권한

- 로그인 사용자 본인 또는 서비스 리소스 접근 권한 검사.
- 건강정보·실시간 위치·타인 기록 조회 시 동의 상태 및 공개 범위가 우선한다.

### Path Parameters

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `courseId` | string (UUID) | O | 선택한 코스 식별자. 개인·그룹 자유러닝은 null/생략 가능 |

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
| `bookmarked` | boolean | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |

### 오류 응답

- `404 COURSE_NOT_FOUND`
- 공통 인증 오류 `401 UNAUTHORIZED`, 권한 오류 `403 FORBIDDEN`, 요청 형식 오류 `400 VALIDATION_ERROR` (해당 시).

### 처리 규칙

- 사용자의 북마크 관계만 삭제한다. 코스 등록자 여부와 관계없이 서비스 공용 코스 원본은 변경하거나 삭제하지 않는다.
- 사용자 소유권·그룹 참가 권한·상태 전이·재요청 여부를 검증한다(적용 범위는 API별로 결정).
- 예시는 **명세 구조를 보여주는 가상 값**이며, 확정되지 않은 제한·동기화 주기·AI 호출 주기를 의미하지 않는다.

### 상태값

- 코스 상태는 변경하지 않는다.

### 미정 사항

- [ ] 요청·응답의 세부 필드 타입, 허용 범위, nullable 규칙 및 실제 JSON 구조 검토
- [ ] HTTP 성공 코드 및 각 예외의 오류 코드 최종 확정
- [ ] 접근 권한과 데이터 정합성의 구체적인 처리 조건 확정


## C09 저장 코스 목록

`GET` `/api/v1/users/me/bookmarked-courses`

| 항목 | 값 |
|---|---|
| 단계 | 1차 MVP |
| 인증 | 회원 |
| 관련 요구사항 | CRS-001, CRS-003, CRS-005, CRS-007~008 / COM-002 / SYS-002 |
| 미정 사항 | 있음 |
| 비고 | API 요청/응답 필드와 값 제한은 검토용 제안 |

### 설명

저장한 코스의 현재 상태를 구분한다. `MERGED` 코스는 대표 코스를 함께 안내하고 `BLOCKED` 코스는 추천 대상이 아님을 안내한다.

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
| `items` | array | X | 사용자가 저장한 코스와 각 코스의 현재 상태 목록 |
| `page` | string / object (확인 필요) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |

### 오류 응답

- `401 UNAUTHORIZED`
- 공통 인증 오류 `401 UNAUTHORIZED`, 권한 오류 `403 FORBIDDEN`, 요청 형식 오류 `400 VALIDATION_ERROR` (해당 시).

### 처리 규칙

- `ACTIVE`, `MERGED`, `BLOCKED` 상태를 구분하고, `MERGED`이면 `mergedIntoCourseId`를 함께 반환한다.
- 사용자 소유권·그룹 참가 권한·상태 전이·재요청 여부를 검증한다(적용 범위는 API별로 결정).
- 예시는 **명세 구조를 보여주는 가상 값**이며, 확정되지 않은 제한·동기화 주기·AI 호출 주기를 의미하지 않는다.

### 상태값

- `ACTIVE` / `MERGED` / `BLOCKED`.

### 미정 사항

- [ ] 요청·응답의 세부 필드 타입, 허용 범위, nullable 규칙 및 실제 JSON 구조 검토
- [ ] HTTP 성공 코드 및 각 예외의 오류 코드 최종 확정
- [ ] 접근 권한과 데이터 정합성의 구체적인 처리 조건 확정
