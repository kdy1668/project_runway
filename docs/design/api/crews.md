# API 명세 — 크루

[API 명세 색인](README.md)으로 돌아가기. 공통 규약은 [API 명세](README.md#공통-규약)를 따른다.

| ID | 이름 | Method | Endpoint | 단계 | 인증 |
|---|---|---|---|---|---|
| [M01](#m01-크루-검색) | 크루 검색 | GET | `/crews` | 1차 MVP | 회원 |
| [M02](#m02-크루-상세) | 크루 상세 | GET | `/crews/{crewId}` | 1차 MVP | 회원 |
| [M03](#m03-크루-생성) | 크루 생성 | POST | `/crews` | 1차 MVP | 회원 |
| [M04](#m04-크루-가입-신청) | 크루 가입 신청 | POST | `/crews/{crewId}/join-requests` | 1차 MVP | 회원 |
| [M05](#m05-크루-가입-신청-목록) | 크루 가입 신청 목록 | GET | `/crews/{crewId}/join-requests` | 1차 MVP | 회원 |
| [M06](#m06-크루-가입-승인거절) | 크루 가입 승인·거절 | PATCH | `/crews/{crewId}/join-requests/{userId}` | 1차 MVP | 회원 |
| [M07](#m07-크루-멤버-목록) | 크루 멤버 목록 | GET | `/crews/{crewId}/members` | 1차 MVP | 회원 |
| [M08](#m08-크루-탈퇴) | 크루 탈퇴 | DELETE | `/crews/{crewId}/members/me` | 1차 MVP | 회원 |
| [M09](#m09-크루-멤버-내보내기) | 크루 멤버 내보내기 | DELETE | `/crews/{crewId}/members/{userId}` | 선택 기능 | 회원 |
| [M10](#m10-내-크루-목록) | 내 크루 목록 | GET | `/users/me/crews` | 1차 MVP | 회원 |

## M01 크루 검색

`GET` `/api/v1/crews`

| 항목 | 값 |
|---|---|
| 단계 | 1차 MVP |
| 인증 | 회원 |
| 관련 요구사항 | MAT-003~004 |
| 관련 화면 | 6.0b 가입한 크루 없음, 6.1 크루 모집 (화면 설계 v10) |
| 미정 사항 | 있음 |
| 비고 | API 요청/응답 필드와 값 제한은 검토용 제안 |

### 설명

크루 공개 검색 범위 정책 미정.

### 인증 및 권한

- 로그인 사용자 본인 또는 서비스 리소스 접근 권한 검사.
- 건강정보·실시간 위치·타인 기록 조회 시 동의 상태 및 공개 범위가 우선한다.

### Path Parameters

없음

### Query Parameters

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `q` | string | X | 크루 이름 또는 지역(예: 광안리, 민락) 검색어 |
| `latitude` | number | X | '내 근처' 기준 위도 |
| `longitude` | number | X | '내 근처' 기준 경도 |
| `radiusM` | number | X | 검색 반경(화면 기본 3km) |
| `level` | string | X | BEGINNER/INTERMEDIATE/ADVANCED. 생략 시 모든 레벨 |
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
| `items` | array | X | 검색 조건에 맞는 크루 목록. 세부 객체 계약 미정 |
| `page` | string / object (확인 필요) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |

### 오류 응답

- `400 INVALID_FILTER`
- 공통 인증 오류 `401 UNAUTHORIZED`, 권한 오류 `403 FORBIDDEN`, 요청 형식 오류 `400 VALIDATION_ERROR` (해당 시).

### 처리 규칙

- 정원이 찬 크루는 '마감'으로 함께 내려 주되 모집 중 크루를 먼저 정렬한다.
- 크루 공개 검색 범위 정책 미정.
- 사용자 소유권·그룹 참가 권한·상태 전이·재요청 여부를 검증한다(적용 범위는 API별로 결정).
- 예시는 **명세 구조를 보여주는 가상 값**이며, 확정되지 않은 제한·동기화 주기·AI 호출 주기를 의미하지 않는다.

### 상태값

- PENDING / APPROVED / REJECTED / LEFT.

### 미정 사항

- [ ] 요청·응답의 세부 필드 타입, 허용 범위, nullable 규칙 및 실제 JSON 구조 검토
- [ ] HTTP 성공 코드 및 각 예외의 오류 코드 최종 확정
- [ ] 접근 권한과 데이터 정합성의 구체적인 처리 조건 확정

## M02 크루 상세

`GET` `/api/v1/crews/{crewId}`

| 항목 | 값 |
|---|---|
| 단계 | 1차 MVP |
| 인증 | 회원 |
| 관련 요구사항 | MAT-003~004 |
| 관련 화면 | 6.2 크루 상세, 6.2b 가입 신청 완료 (화면 설계 v10) |
| 미정 사항 | 있음 |
| 비고 | API 요청/응답 필드와 값 제한은 검토용 제안 |

### 설명

가입 상태는 본인에게만 노출.

### 인증 및 권한

- 로그인 사용자 본인 또는 서비스 리소스 접근 권한 검사.
- 건강정보·실시간 위치·타인 기록 조회 시 동의 상태 및 공개 범위가 우선한다.

### Path Parameters

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `crewId` | string (UUID) | O | ERD 및 화면 요구사항을 기준으로 확정 필요 |

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
| `name` | string / object (확인 필요) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `description` | string / object (확인 필요) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `ownerId` | string (UUID) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `memberCount` | number | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `myMembershipStatus` | string / object (확인 필요) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |

### 오류 응답

- `404 CREW_NOT_FOUND`
- 공통 인증 오류 `401 UNAUTHORIZED`, 권한 오류 `403 FORBIDDEN`, 요청 형식 오류 `400 VALIDATION_ERROR` (해당 시).

### 처리 규칙

- 응답에 지역·레벨·정원·대표 사진과 모집 상태를 포함한다. 구성원 미리보기(크루장 표시, 평균 페이스)는 M07로 조회한다.
- 가입 상태는 본인에게만 노출.
- 사용자 소유권·그룹 참가 권한·상태 전이·재요청 여부를 검증한다(적용 범위는 API별로 결정).
- 예시는 **명세 구조를 보여주는 가상 값**이며, 확정되지 않은 제한·동기화 주기·AI 호출 주기를 의미하지 않는다.

### 상태값

- PENDING / APPROVED / REJECTED / LEFT.

### 미정 사항

- [ ] 요청·응답의 세부 필드 타입, 허용 범위, nullable 규칙 및 실제 JSON 구조 검토
- [ ] HTTP 성공 코드 및 각 예외의 오류 코드 최종 확정
- [ ] 접근 권한과 데이터 정합성의 구체적인 처리 조건 확정


## M03 크루 생성

`POST` `/api/v1/crews`

| 항목 | 값 |
|---|---|
| 단계 | 1차 MVP |
| 인증 | 회원 |
| 관련 요구사항 | MAT-003~004 |
| 관련 화면 | 6.3 크루 만들기 (화면 설계 v10) |
| 미정 사항 | 있음 |
| 비고 | API 요청/응답 필드와 값 제한은 검토용 제안 |

### 설명

생성자는 OWNER 구성원으로 등록. 가입 방식은 크루장 승인으로 고정이므로 `joinPolicy`를 받지 않는다.

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
| `name` | string / object (확인 필요) | O | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `description` | string | X | 소개(최대 200자) |
| `imageId` | string (UUID) | X | 대표 사진([F01](files.md#f01-이미지-업로드)) |
| `regionName` | string | O | 활동 지역 이름(검색해서 선택) |
| `regionPosition` | GeoJSON | O | 활동 지역 좌표. '내 근처' 검색에 사용 |
| `level` | string | O | BEGINNER/INTERMEDIATE/ADVANCED |
| `capacity` | number | O | 모집 인원 |

```json
{
  "name": "하천 러닝 코스",
  "regionName": "지역 예시",
  "regionPosition": {
    "type": "Point",
    "coordinates": [
      129.118,
      35.153
    ]
  },
  "level": "BEGINNER",
  "capacity": 10
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
| `ownerId` | string (UUID) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `name` | string / object (확인 필요) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `createdAt` | string (ISO 8601) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |

### 오류 응답

- `422 INVALID_CREW`
- 공통 인증 오류 `401 UNAUTHORIZED`, 권한 오류 `403 FORBIDDEN`, 요청 형식 오류 `400 VALIDATION_ERROR` (해당 시).

### 처리 규칙

- 생성자는 OWNER 구성원으로 등록. 가입 방식은 크루장 승인으로 고정이므로 `joinPolicy`를 받지 않는다.
- 사용자 소유권·그룹 참가 권한·상태 전이·재요청 여부를 검증한다(적용 범위는 API별로 결정).
- 예시는 **명세 구조를 보여주는 가상 값**이며, 확정되지 않은 제한·동기화 주기·AI 호출 주기를 의미하지 않는다.

### 상태값

- PENDING / APPROVED / REJECTED / LEFT.

### 미정 사항

- [ ] 지역 검색을 지도 SDK(클라이언트)로 처리할지
- [ ] 요청·응답의 세부 필드 타입, 허용 범위, nullable 규칙 및 실제 JSON 구조 검토
- [ ] HTTP 성공 코드 및 각 예외의 오류 코드 최종 확정
- [ ] 접근 권한과 데이터 정합성의 구체적인 처리 조건 확정


## M04 크루 가입 신청

`POST` `/api/v1/crews/{crewId}/join-requests`

| 항목 | 값 |
|---|---|
| 단계 | 1차 MVP |
| 인증 | 회원 |
| 관련 요구사항 | MAT-003~004 |
| 미정 사항 | 있음 |
| 비고 | API 요청/응답 필드와 값 제한은 검토용 제안 |

### 설명

모든 가입 신청은 PENDING으로 등록하고 크루장 승인(M06) 후 멤버가 된다. 승인 전에는 내 크루에 '승인 대기'로 보인다(6.0, 6.2b).

### 인증 및 권한

- 로그인 사용자 본인 또는 서비스 리소스 접근 권한 검사.
- 건강정보·실시간 위치·타인 기록 조회 시 동의 상태 및 공개 범위가 우선한다.

### Path Parameters

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `crewId` | string (UUID) | O | ERD 및 화면 요구사항을 기준으로 확정 필요 |

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
| `crewId` | string (UUID) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `userId` | string (UUID) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `status` | string (제안) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `requestedAt` | string (ISO 8601) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |

### 오류 응답

- `409 ALREADY_MEMBER_OR_PENDING`
- 공통 인증 오류 `401 UNAUTHORIZED`, 권한 오류 `403 FORBIDDEN`, 요청 형식 오류 `400 VALIDATION_ERROR` (해당 시).

### 처리 규칙

- 모든 가입 신청은 PENDING으로 등록하고 크루장 승인(M06) 후 멤버가 된다. 승인 전에는 내 크루에 '승인 대기'로 보인다(6.0, 6.2b).
- 사용자 소유권·그룹 참가 권한·상태 전이·재요청 여부를 검증한다(적용 범위는 API별로 결정).
- 예시는 **명세 구조를 보여주는 가상 값**이며, 확정되지 않은 제한·동기화 주기·AI 호출 주기를 의미하지 않는다.

### 상태값

- PENDING / APPROVED / REJECTED / LEFT.

### 미정 사항

- [ ] 요청·응답의 세부 필드 타입, 허용 범위, nullable 규칙 및 실제 JSON 구조 검토
- [ ] HTTP 성공 코드 및 각 예외의 오류 코드 최종 확정
- [ ] 접근 권한과 데이터 정합성의 구체적인 처리 조건 확정


## M05 크루 가입 신청 목록

`GET` `/api/v1/crews/{crewId}/join-requests`

| 항목 | 값 |
|---|---|
| 단계 | 1차 MVP |
| 인증 | 회원 |
| 관련 요구사항 | MAT-003~004 |
| 미정 사항 | 있음 |
| 비고 | API 요청/응답 필드와 값 제한은 검토용 제안 |

### 설명

OWNER/ADMIN만 조회.

### 인증 및 권한

- 로그인 사용자 본인 또는 서비스 리소스 접근 권한 검사.
- 건강정보·실시간 위치·타인 기록 조회 시 동의 상태 및 공개 범위가 우선한다.

### Path Parameters

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `crewId` | string (UUID) | O | ERD 및 화면 요구사항을 기준으로 확정 필요 |

### Query Parameters

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `status` | string (제안) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
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
| `items` | array | X | 해당 크루 가입 신청 목록. 세부 객체 계약 미정 |
| `page` | string / object (확인 필요) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |

### 오류 응답

- `403 NOT_ADMIN`
- 공통 인증 오류 `401 UNAUTHORIZED`, 권한 오류 `403 FORBIDDEN`, 요청 형식 오류 `400 VALIDATION_ERROR` (해당 시).

### 처리 규칙

- OWNER/ADMIN만 조회.
- 사용자 소유권·그룹 참가 권한·상태 전이·재요청 여부를 검증한다(적용 범위는 API별로 결정).
- 예시는 **명세 구조를 보여주는 가상 값**이며, 확정되지 않은 제한·동기화 주기·AI 호출 주기를 의미하지 않는다.

### 상태값

- PENDING / APPROVED / REJECTED / LEFT.

### 미정 사항

- [ ] 요청·응답의 세부 필드 타입, 허용 범위, nullable 규칙 및 실제 JSON 구조 검토
- [ ] HTTP 성공 코드 및 각 예외의 오류 코드 최종 확정
- [ ] 접근 권한과 데이터 정합성의 구체적인 처리 조건 확정


## M06 크루 가입 승인·거절

`PATCH` `/api/v1/crews/{crewId}/join-requests/{userId}`

| 항목 | 값 |
|---|---|
| 단계 | 1차 MVP |
| 인증 | 회원 |
| 관련 요구사항 | MAT-003~004 |
| 미정 사항 | 있음 |
| 비고 | API 요청/응답 필드와 값 제한은 검토용 제안 |

### 설명

PENDING 신청에 대해 APPROVED 또는 REJECTED 처리.

### 인증 및 권한

- 로그인 사용자 본인 또는 서비스 리소스 접근 권한 검사.
- 건강정보·실시간 위치·타인 기록 조회 시 동의 상태 및 공개 범위가 우선한다.

### Path Parameters

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `crewId` | string (UUID) | O | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `userId` | string (UUID) | O | ERD 및 화면 요구사항을 기준으로 확정 필요 |

### Query Parameters

없음

### Request Body

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `status` | string (제안) | O | ERD 및 화면 요구사항을 기준으로 확정 필요 |

```json
{
  "status": "READY"
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
| `crewId` | string (UUID) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `userId` | string (UUID) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `status` | string (제안) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `resolvedAt` | string (ISO 8601) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |

### 오류 응답

- `403 NOT_ADMIN`
- `409 NOT_PENDING`
- 공통 인증 오류 `401 UNAUTHORIZED`, 권한 오류 `403 FORBIDDEN`, 요청 형식 오류 `400 VALIDATION_ERROR` (해당 시).

### 처리 규칙

- 승인·거절 상태 저장이 확정되면 신청자에게 해당 결과 알림을 자동 연계한다. 같은 결정 재전송으로 알림·멤버·인원 수를 중복 반영하지 않는다. 상세 전달 정책은 [알림 정책](../requirements.md#알림-정책)를 따른다.

- PENDING 신청에 대해 APPROVED 또는 REJECTED 처리.
- 사용자 소유권·그룹 참가 권한·상태 전이·재요청 여부를 검증한다(적용 범위는 API별로 결정).
- 예시는 **명세 구조를 보여주는 가상 값**이며, 확정되지 않은 제한·동기화 주기·AI 호출 주기를 의미하지 않는다.

### 상태값

- PENDING / APPROVED / REJECTED / LEFT.

### 미정 사항

- [ ] 요청·응답의 세부 필드 타입, 허용 범위, nullable 규칙 및 실제 JSON 구조 검토
- [ ] HTTP 성공 코드 및 각 예외의 오류 코드 최종 확정
- [ ] 접근 권한과 데이터 정합성의 구체적인 처리 조건 확정


## M07 크루 멤버 목록

`GET` `/api/v1/crews/{crewId}/members`

| 항목 | 값 |
|---|---|
| 단계 | 1차 MVP |
| 인증 | 회원 |
| 관련 요구사항 | MAT-003~004 |
| 관련 화면 | 6.2 크루 상세 구성원 (화면 설계 v10) |
| 미정 사항 | 있음 |
| 비고 | API 요청/응답 필드와 값 제한은 검토용 제안 |

### 설명

승인된 현재 구성원 목록.

### 인증 및 권한

- 로그인 사용자 본인 또는 서비스 리소스 접근 권한 검사.
- 건강정보·실시간 위치·타인 기록 조회 시 동의 상태 및 공개 범위가 우선한다.

### Path Parameters

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `crewId` | string (UUID) | O | ERD 및 화면 요구사항을 기준으로 확정 필요 |

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
| `items` | array | X | 해당 크루 멤버 목록. 세부 객체 계약 미정 |
| `page` | string / object (확인 필요) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |

### 오류 응답

- `404 CREW_NOT_FOUND`
- 공통 인증 오류 `401 UNAUTHORIZED`, 권한 오류 `403 FORBIDDEN`, 요청 형식 오류 `400 VALIDATION_ERROR` (해당 시).

### 처리 규칙

- 구성원 항목에 역할(크루장)과 최근 평균 페이스를 포함한다(6.2).
- 승인된 현재 구성원 목록.
- 사용자 소유권·그룹 참가 권한·상태 전이·재요청 여부를 검증한다(적용 범위는 API별로 결정).
- 예시는 **명세 구조를 보여주는 가상 값**이며, 확정되지 않은 제한·동기화 주기·AI 호출 주기를 의미하지 않는다.

### 상태값

- PENDING / APPROVED / REJECTED / LEFT.

### 미정 사항

- [ ] 요청·응답의 세부 필드 타입, 허용 범위, nullable 규칙 및 실제 JSON 구조 검토
- [ ] HTTP 성공 코드 및 각 예외의 오류 코드 최종 확정
- [ ] 접근 권한과 데이터 정합성의 구체적인 처리 조건 확정


## M08 크루 탈퇴

`DELETE` `/api/v1/crews/{crewId}/members/me`

| 항목 | 값 |
|---|---|
| 단계 | 1차 MVP |
| 인증 | 회원 |
| 관련 요구사항 | MAT-003~004 |
| 미정 사항 | 있음 |
| 비고 | API 요청/응답 필드와 값 제한은 검토용 제안 |

### 설명

OWNER의 탈퇴 시 권한 이양 정책 미정.

### 인증 및 권한

- 로그인 사용자 본인 또는 서비스 리소스 접근 권한 검사.
- 건강정보·실시간 위치·타인 기록 조회 시 동의 상태 및 공개 범위가 우선한다.

### Path Parameters

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `crewId` | string (UUID) | O | ERD 및 화면 요구사항을 기준으로 확정 필요 |

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
| `leftAt` | string (ISO 8601) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |

### 오류 응답

- `409 OWNER_CANNOT_LEAVE`
- 공통 인증 오류 `401 UNAUTHORIZED`, 권한 오류 `403 FORBIDDEN`, 요청 형식 오류 `400 VALIDATION_ERROR` (해당 시).

### 처리 규칙

- OWNER의 탈퇴 시 권한 이양 정책 미정.
- 사용자 소유권·그룹 참가 권한·상태 전이·재요청 여부를 검증한다(적용 범위는 API별로 결정).
- 예시는 **명세 구조를 보여주는 가상 값**이며, 확정되지 않은 제한·동기화 주기·AI 호출 주기를 의미하지 않는다.

### 상태값

- PENDING / APPROVED / REJECTED / LEFT.

### 미정 사항

- [ ] 요청·응답의 세부 필드 타입, 허용 범위, nullable 규칙 및 실제 JSON 구조 검토
- [ ] HTTP 성공 코드 및 각 예외의 오류 코드 최종 확정
- [ ] 접근 권한과 데이터 정합성의 구체적인 처리 조건 확정


## M09 크루 멤버 내보내기

`DELETE` `/api/v1/crews/{crewId}/members/{userId}`

| 항목 | 값 |
|---|---|
| 단계 | 선택 기능 |
| 인증 | 회원 |
| 관련 요구사항 | MAT-003~004 |
| 미정 사항 | 있음 |
| 비고 | API 요청/응답 필드와 값 제한은 검토용 제안 |

### 설명

선택 기능. OWNER/ADMIN만 가능하고 OWNER는 내보낼 수 없음.

### 인증 및 권한

- 로그인 사용자 본인 또는 서비스 리소스 접근 권한 검사.
- 건강정보·실시간 위치·타인 기록 조회 시 동의 상태 및 공개 범위가 우선한다.

### Path Parameters

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `crewId` | string (UUID) | O | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `userId` | string (UUID) | O | ERD 및 화면 요구사항을 기준으로 확정 필요 |

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
| `leftAt` | string (ISO 8601) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |

### 오류 응답

- `403 NOT_ADMIN`
- `409 CANNOT_REMOVE_OWNER`
- 공통 인증 오류 `401 UNAUTHORIZED`, 권한 오류 `403 FORBIDDEN`, 요청 형식 오류 `400 VALIDATION_ERROR` (해당 시).

### 처리 규칙

- 선택 기능. OWNER/ADMIN만 가능하고 OWNER는 내보낼 수 없음.
- 사용자 소유권·그룹 참가 권한·상태 전이·재요청 여부를 검증한다(적용 범위는 API별로 결정).
- 예시는 **명세 구조를 보여주는 가상 값**이며, 확정되지 않은 제한·동기화 주기·AI 호출 주기를 의미하지 않는다.

### 상태값

- PENDING / APPROVED / REJECTED / LEFT.

### 미정 사항

- [ ] 요청·응답의 세부 필드 타입, 허용 범위, nullable 규칙 및 실제 JSON 구조 검토
- [ ] HTTP 성공 코드 및 각 예외의 오류 코드 최종 확정
- [ ] 접근 권한과 데이터 정합성의 구체적인 처리 조건 확정


## M10 내 크루 목록

`GET` `/api/v1/users/me/crews`

| 항목 | 값 |
|---|---|
| 단계 | 1차 MVP |
| 인증 | 회원 |
| 관련 요구사항 | MAT-003 |
| 관련 화면 | 6.0 그룹 — 내 크루, 6.0b 가입한 크루 없음, 2.P 그룹 탭 (화면 설계 v10) |
| 미정 사항 | 있음 |
| 비고 | 화면 설계 v10 대조로 추가. 응답 형식은 ERD 확정 후 갱신 |

### 설명

가입한 크루와 승인 대기 중인 크루를 조회한다. 크루별 그룹런은 G02(`crewId`)로 조회한다.

### 인증 및 권한

- 로그인 사용자 본인 또는 서비스 리소스 접근 권한 검사.

### Path Parameters

없음

### Query Parameters

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `membershipStatus` | string | X | APPROVED/PENDING. 생략 시 둘 다 |

### Request Body

없음

### Response

`200 OK (제안)`

```json
{}
```

응답 필드 후보(화면 표시 항목 기준, **ERD 확정 후 갱신**):

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `items` | array | X | 크루 id·이름·레벨·지역·멤버 수·내 역할·가입 상태(승인 대기 표시) |

### 오류 응답

- 공통 인증 오류 `401 UNAUTHORIZED`, 권한 오류 `403 FORBIDDEN`, 요청 형식 오류 `400 VALIDATION_ERROR` (해당 시).

### 처리 규칙

- 가입한 크루가 없으면 빈 배열을 반환하고 화면은 6.0b 안내를 보여 준다.
- 사용자 소유권·그룹 참가 권한·상태 전이·재요청 여부를 검증한다(적용 범위는 API별로 결정).
- 예시는 **명세 구조를 보여주는 가상 값**이며, 확정되지 않은 제한·동기화 주기·AI 호출 주기를 의미하지 않는다.

### 상태값

- 해당 없음.

### 미정 사항

- [ ] 응답 필드는 ERD 확정 후 갱신
- [ ] HTTP 성공 코드 및 각 예외의 오류 코드 최종 확정
