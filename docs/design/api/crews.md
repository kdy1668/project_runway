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

## ERD 응답 대응 기준

**응답 해석:** 각 Response의 JSON은 기존 동작과 기능상 필요한 출력을 설명하는 검토용 예시다. 저장·전송 정책이 미정인 보완 필드는 구현 완료 계약을 뜻하지 않는다. 확인 필요 필드의 생략은 기능 삭제나 최종 선택 필드 확정을 뜻하지 않는다. `O`는 해당 응답 객체가 존재할 때 키를 포함함을 뜻하며, 값의 NULL 허용은 타입의 ` / null`로 구분한다. 조회 결과 자체가 없는 경우와 복구 행동은 해당 오류 응답 절을 따른다.

crews와 crew_memberships를 구분한다. 크루 상태는 ACTIVE/INACTIVE, 가입 상태는 PENDING/APPROVED/REJECTED/LEFT다. myMembershipStatus는 본인의 가입 관계가 없으면 null이며 가입 상태와 크루 상태를 혼용하지 않는다.

자료형·NULL의 정본은 [schema.sql](../db/schema.sql), 표시·관계 설명은 [ERD](../db/erd.md)를 따른다. ERD 정합성 단계에서는 API 종류·개수·역할·오류 응답을 유지했다. 후속 오류 검토 내용은 각 오류 응답 절을 따른다.

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
{
  "items": [
    {
      "id": 101,
      "name": "러닝 크루",
      "description": null,
      "ownerId": 101,
      "capacity": 20,
      "status": "ACTIVE",
      "regionCode": null,
      "memberCount": 10,
      "myMembershipStatus": "PENDING"
    }
  ]
}
```

응답 필드 정의(저장 필드는 ERD ver.3에 대응, 파생·미정 값은 설명에 구분):

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `items` | array | X | 검색 조건에 맞는 크루 목록. 세부 객체 계약 미정 |
| `page` | string / object (확인 필요) | X | 페이지 메타데이터는 저장 엔티티가 아니다. cursor/limit 등 공통 페이지 형식 확정 필요. |

중첩 객체의 저장 필드 대응(추가 표시·집계 값은 기존 후보를 유지하며 별도 확인):

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `items[].id` | integer (int64) | O | `crews.id` (BIGINT). 저장 값은 NULL 불가. |
| `items[].name` | string | O | `crews.name` (VARCHAR(100)). 저장 값은 NULL 불가. |
| `items[].description` | string / null | O | `crews.description` (TEXT). NULL 허용; 미설정·미측정·미발생을 0/false/빈 문자열로 대체하지 않는다. |
| `items[].ownerId` | integer (int64) | O | `crews.owner_id` (BIGINT). 저장 값은 NULL 불가. |
| `items[].capacity` | integer | O | `crews.capacity` (INTEGER). 저장 값은 NULL 불가. |
| `items[].status` | string | O | `crews.status` (ENUM('ACTIVE', 'INACTIVE')). 저장 값은 NULL 불가. 허용값: ACTIVE, INACTIVE. |
| `items[].regionCode` | string / null | O | `crews.region_code` (VARCHAR(40)). NULL 허용; 미설정·미측정·미발생을 0/false/빈 문자열로 대체하지 않는다. |


**사용 흐름과 응답 판단**

목록 카드에는 이름·정원·현재 승인 인원·지역·본인 가입 상태가 필요하다. 타인 신청 내역을 공개하지 않는다.

표시·선택·후속 이동에 필요한 필드 보완안:

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `items[].memberCount` | integer | O | APPROVED 관계 수. |
| `items[].myMembershipStatus` | string / null | O | 본인 가입관계. 미가입 null, PENDING/APPROVED 등 ERD 상태. |

### 오류 응답

**상태: 오류 계약 초안.** 기존 오류 코드에 발생 조건을 보완했다. HTTP 상태·코드는 기존 제안을 유지하며, 추가 후보는 아래에 구분한다. 이 표만으로 미정 정책을 확정하지 않는다.

| HTTP·코드 | 오류 종류 | 발생 조건·주의사항 |
|---|---|---|
| `400 INVALID_FILTER` | 검색 조건 | 정렬·필터·페이지 조건이 명세의 허용값/형식에 맞지 않음 |
| `401 UNAUTHORIZED` | 인증 | 인증이 필요한 요청에 토큰이 없거나 만료·위변조되어 사용자를 확인할 수 없음 |
| `403 FORBIDDEN` | 권한 | 인증된 사용자가 해당 자원·작업에 필요한 권한을 갖지 않음 |
| `400 VALIDATION_ERROR` | 입력 형식 | JSON 구문·필수 필드·자료형·날짜 형식 또는 Path 식별자 형식이 맞지 않음. 서버 BIGINT 식별자의 소수·UUID·범위 초과 포함 |

- 공통 입력·서버 장애와 재시도 판단은 [오류 분류와 재시도 기준](README.md#오류-분류와-재시도-기준)을 함께 적용한다.
- 검색/조회 결과가 0건인 경우 자체는 오류가 아니다. 유효한 빈 목록과 잘못된 조회 조건을 구분한다.

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
| `crewId` | integer (int64) | O | ERD 및 화면 요구사항을 기준으로 확정 필요 |

### Query Parameters

없음

### Request Body

없음


### Response

`200 OK (제안)`

```json
{
  "id": 101,
  "name": "러닝 크루",
  "description": null,
  "ownerId": 101,
  "memberCount": 10,
  "capacity": 20,
  "regionCode": null,
  "myMembershipStatus": "PENDING"
}
```

응답 필드 정의(저장 필드는 ERD ver.3에 대응, 파생·미정 값은 설명에 구분):

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `id` | integer (int64) | O | `crews.id` (BIGINT). 저장 값은 NULL 불가. |
| `name` | string | O | `crews.name` (VARCHAR(100)). 저장 값은 NULL 불가. |
| `description` | string / null | O | crews.description. |
| `ownerId` | integer (int64) | O | `crews.owner_id` (BIGINT). 저장 값은 NULL 불가. |
| `memberCount` | integer | O | crew_memberships의 APPROVED 관계 수. 대기·거절·탈퇴 제외. |
| `myMembershipStatus` | string / null | O | 본인 crew_memberships.status. 관계 없으면 null. PENDING/APPROVED/REJECTED/LEFT. |


**사용 흐름과 응답 판단**

가입 버튼 판단에 myMembershipStatus와 정원·현재 인원이 필요하다. 관계 없음 null과 PENDING·APPROVED를 구분한다.

표시·선택·후속 이동에 필요한 필드 보완안:

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `capacity` | integer | O | crews.capacity. 크루 정원. |
| `regionCode` | string / null | O | crews.region_code. |

### 오류 응답

**상태: 오류 계약 초안.** 기존 오류 코드에 발생 조건을 보완했다. HTTP 상태·코드는 기존 제안을 유지하며, 추가 후보는 아래에 구분한다. 이 표만으로 미정 정책을 확정하지 않는다.

| HTTP·코드 | 오류 종류 | 발생 조건·주의사항 |
|---|---|---|
| `404 CREW_NOT_FOUND` | 대상 없음 | 대상 크루가 없음. INACTIVE 상태의 조회/조작 허용 범위는 별도 확인 |
| `401 UNAUTHORIZED` | 인증 | 인증이 필요한 요청에 토큰이 없거나 만료·위변조되어 사용자를 확인할 수 없음 |
| `403 FORBIDDEN` | 권한 | 인증된 사용자가 해당 자원·작업에 필요한 권한을 갖지 않음 |
| `400 VALIDATION_ERROR` | 입력 형식 | JSON 구문·필수 필드·자료형·날짜 형식 또는 Path 식별자 형식이 맞지 않음. 서버 BIGINT 식별자의 소수·UUID·범위 초과 포함 |

- **대상 없음·접근 차단 점검:** 경로 대상의 부재/삭제, 본인 소유·역할·참가 자격 불충족을 구분한다. 위 표에 없는 경우 `404` 자원 없음 또는 `403` 접근 거부의 추가 매핑을 확인한다. 존재 은닉을 위한 403/404 선택·검사 순서는 미정이며 새 코드로 단정하지 않는다.

- 공통 입력·서버 장애와 재시도 판단은 [오류 분류와 재시도 기준](README.md#오류-분류와-재시도-기준)을 함께 적용한다.

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
{
  "id": 101,
  "ownerId": 101,
  "name": "러닝 크루",
  "createdAt": "2026-10-24T09:00:00Z"
}
```

응답 필드 정의(저장 필드는 ERD ver.3에 대응, 파생·미정 값은 설명에 구분):

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `id` | integer (int64) | O | `crews.id` (BIGINT). 저장 값은 NULL 불가. |
| `ownerId` | integer (int64) | O | `crews.owner_id` (BIGINT). 저장 값은 NULL 불가. |
| `name` | string | O | `crews.name` (VARCHAR(100)). 저장 값은 NULL 불가. |
| `createdAt` | string (ISO 8601 UTC) | O | `crews.created_at` (TIMESTAMPTZ). 저장 값은 NULL 불가. |


**사용 흐름과 응답 판단**

생성한 크루 ID로 상세 이동하고 본인이 크루장임을 확인한다. OWNER는 crews.owner_id에서 파생하며 membership enum이 아니다.

### 오류 응답

**상태: 오류 계약 초안.** 기존 오류 코드에 발생 조건을 보완했다. HTTP 상태·코드는 기존 제안을 유지하며, 추가 후보는 아래에 구분한다. 이 표만으로 미정 정책을 확정하지 않는다.

| HTTP·코드 | 오류 종류 | 발생 조건·주의사항 |
|---|---|---|
| `422 INVALID_CREW` | 입력 값 | 크루 이름·지역·정원 등 생성 값이 확정 규칙/ERD 형식과 맞지 않음. 최대 200명은 예정 정책 |
| `401 UNAUTHORIZED` | 인증 | 인증이 필요한 요청에 토큰이 없거나 만료·위변조되어 사용자를 확인할 수 없음 |
| `403 FORBIDDEN` | 권한 | 인증된 사용자가 해당 자원·작업에 필요한 권한을 갖지 않음 |
| `400 VALIDATION_ERROR` | 입력 형식 | JSON 구문·필수 필드·자료형·날짜 형식 또는 Path 식별자 형식이 맞지 않음. 서버 BIGINT 식별자의 소수·UUID·범위 초과 포함 |

- 공통 입력·서버 장애와 재시도 판단은 [오류 분류와 재시도 기준](README.md#오류-분류와-재시도-기준)을 함께 적용한다.
- **중복·경합 점검:** 통신 시간초과는 저장 실패를 뜻하지 않는다. 동일 요청 재전송·다른 요청과의 충돌을 구분한다. 기존 멱등 처리 기준이 없는 경우 성공 재응답/409/재조회 선택은 확인 필요다.

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
| `crewId` | integer (int64) | O | ERD 및 화면 요구사항을 기준으로 확정 필요 |

### Query Parameters

없음

### Request Body

없음


### Response

`200 OK (제안)`

```json
{
  "crewId": 101,
  "userId": 101,
  "status": "PENDING",
  "requestedAt": "2026-10-24T09:00:00Z"
}
```

응답 필드 정의(저장 필드는 ERD ver.3에 대응, 파생·미정 값은 설명에 구분):

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `crewId` | integer (int64) | O | `crew_memberships.crew_id` (BIGINT). 저장 값은 NULL 불가. |
| `userId` | integer (int64) | O | `crew_memberships.user_id` (BIGINT). 저장 값은 NULL 불가. |
| `status` | string | O | `crew_memberships.status` (ENUM('PENDING', 'APPROVED', 'REJECTED', 'LEFT')). 저장 값은 NULL 불가. 허용값: PENDING, APPROVED, REJECTED, LEFT. |
| `requestedAt` | string (ISO 8601 UTC) | O | `crew_memberships.requested_at` (TIMESTAMPTZ). 저장 값은 NULL 불가. |


**사용 흐름과 응답 판단**

신청 성공은 PENDING이며 가입 완료가 아니다. 중복 신청은 기존 멱등/409 선택을 확정해야 한다.

### 오류 응답

**상태: 오류 계약 초안.** 기존 오류 코드에 발생 조건을 보완했다. HTTP 상태·코드는 기존 제안을 유지하며, 추가 후보는 아래에 구분한다. 이 표만으로 미정 정책을 확정하지 않는다.

| HTTP·코드 | 오류 종류 | 발생 조건·주의사항 |
|---|---|---|
| `409 ALREADY_MEMBER_OR_PENDING` | 중복 관계 | 이미 APPROVED 또는 PENDING 관계가 있는데 가입 신청을 다시 보냄. 같은 요청의 성공 재응답 정책은 확인 필요 |
| `401 UNAUTHORIZED` | 인증 | 인증이 필요한 요청에 토큰이 없거나 만료·위변조되어 사용자를 확인할 수 없음 |
| `403 FORBIDDEN` | 권한 | 인증된 사용자가 해당 자원·작업에 필요한 권한을 갖지 않음 |
| `400 VALIDATION_ERROR` | 입력 형식 | JSON 구문·필수 필드·자료형·날짜 형식 또는 Path 식별자 형식이 맞지 않음. 서버 BIGINT 식별자의 소수·UUID·범위 초과 포함 |

- **대상 없음·접근 차단 점검:** 경로 대상의 부재/삭제, 본인 소유·역할·참가 자격 불충족을 구분한다. 위 표에 없는 경우 `404` 자원 없음 또는 `403` 접근 거부의 추가 매핑을 확인한다. 존재 은닉을 위한 403/404 선택·검사 순서는 미정이며 새 코드로 단정하지 않는다.

- 공통 입력·서버 장애와 재시도 판단은 [오류 분류와 재시도 기준](README.md#오류-분류와-재시도-기준)을 함께 적용한다.
- **중복·경합 점검:** 통신 시간초과는 저장 실패를 뜻하지 않는다. 동일 요청 재전송·다른 요청과의 충돌을 구분한다. 기존 멱등 처리 기준이 없는 경우 성공 재응답/409/재조회 선택은 확인 필요다.

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
| `crewId` | integer (int64) | O | ERD 및 화면 요구사항을 기준으로 확정 필요 |

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
{
  "items": [
    {
      "userId": 101,
      "status": "PENDING",
      "requestedAt": "2026-10-24T09:00:00Z",
      "joinedAt": null,
      "nickname": "러너"
    }
  ]
}
```

응답 필드 정의(저장 필드는 ERD ver.3에 대응, 파생·미정 값은 설명에 구분):

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `items` | array | X | 해당 크루 가입 신청 목록. 세부 객체 계약 미정 |
| `page` | string / object (확인 필요) | X | 페이지 메타데이터는 저장 엔티티가 아니다. cursor/limit 등 공통 페이지 형식 확정 필요. |

중첩 객체의 저장 필드 대응(추가 표시·집계 값은 기존 후보를 유지하며 별도 확인):

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `items[].userId` | integer (int64) | O | `crew_memberships.user_id` (BIGINT). 저장 값은 NULL 불가. |
| `items[].status` | string | O | `crew_memberships.status` (ENUM('PENDING', 'APPROVED', 'REJECTED', 'LEFT')). 저장 값은 NULL 불가. 허용값: PENDING, APPROVED, REJECTED, LEFT. |
| `items[].requestedAt` | string (ISO 8601 UTC) | O | `crew_memberships.requested_at` (TIMESTAMPTZ). 저장 값은 NULL 불가. |
| `items[].joinedAt` | string (ISO 8601 UTC) / null | O | `crew_memberships.joined_at` (TIMESTAMPTZ). NULL 허용; 미설정·미측정·미발생을 0/false/빈 문자열로 대체하지 않는다. |


**사용 흐름과 응답 판단**

승인 대기자 목록은 PENDING 대상과 회원 식별·닉네임이 필요하다. 승인 버튼을 행의 userId에 연결한다.

표시·선택·후속 이동에 필요한 필드 보완안:

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `items[].nickname` | string | O | 신청 회원의 표시명. |

### 오류 응답

**상태: 오류 계약 초안.** 기존 오류 코드에 발생 조건을 보완했다. HTTP 상태·코드는 기존 제안을 유지하며, 추가 후보는 아래에 구분한다. 이 표만으로 미정 정책을 확정하지 않는다.

| HTTP·코드 | 오류 종류 | 발생 조건·주의사항 |
|---|---|---|
| `403 NOT_ADMIN` | 역할 권한 | 가입 처리·내보내기에 필요한 크루 관리 권한이 없음. 관리자 범위는 기존 크루장 정책 확인 |
| `401 UNAUTHORIZED` | 인증 | 인증이 필요한 요청에 토큰이 없거나 만료·위변조되어 사용자를 확인할 수 없음 |
| `403 FORBIDDEN` | 권한 | 인증된 사용자가 해당 자원·작업에 필요한 권한을 갖지 않음 |
| `400 VALIDATION_ERROR` | 입력 형식 | JSON 구문·필수 필드·자료형·날짜 형식 또는 Path 식별자 형식이 맞지 않음. 서버 BIGINT 식별자의 소수·UUID·범위 초과 포함 |

- **대상 없음·접근 차단 점검:** 경로 대상의 부재/삭제, 본인 소유·역할·참가 자격 불충족을 구분한다. 위 표에 없는 경우 `404` 자원 없음 또는 `403` 접근 거부의 추가 매핑을 확인한다. 존재 은닉을 위한 403/404 선택·검사 순서는 미정이며 새 코드로 단정하지 않는다.

- 공통 입력·서버 장애와 재시도 판단은 [오류 분류와 재시도 기준](README.md#오류-분류와-재시도-기준)을 함께 적용한다.

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
| `crewId` | integer (int64) | O | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `userId` | integer (int64) | O | ERD 및 화면 요구사항을 기준으로 확정 필요 |

### Query Parameters

없음

### Request Body

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `status` | string (제안) | O | 승인 APPROVED 또는 거절 REJECTED만 허용. |

```json
{
  "status": "APPROVED"
}
```

### Response

`200 OK (제안)`

```json
{
  "crewId": 101,
  "userId": 101,
  "status": "APPROVED"
}
```

응답 필드 정의(저장 필드는 ERD ver.3에 대응, 파생·미정 값은 설명에 구분):

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `crewId` | integer (int64) | O | `crew_memberships.crew_id` (BIGINT). 저장 값은 NULL 불가. |
| `userId` | integer (int64) | O | `crew_memberships.user_id` (BIGINT). 저장 값은 NULL 불가. |
| `status` | string | O | `crew_memberships.status` (ENUM('PENDING', 'APPROVED', 'REJECTED', 'LEFT')). 승인 성공은 APPROVED, 거절 성공은 REJECTED. PENDING/LEFT는 이 작업의 성공 결과가 아니다. |
| `resolvedAt` | string (ISO 8601) | X | crew_memberships에 처리 완료 시각 컬럼 없음. joined_at은 가입 시각이며 거절 시각과 구분한다. |


**사용 흐름과 응답 판단**

요청 결정은 APPROVED/REJECTED만 허용하고 응답은 처리된 상태를 반환한다. 정원 검증은 승인에만 해당한다.

### 오류 응답

**상태: 오류 계약 초안.** 기존 오류 코드에 발생 조건을 보완했다. HTTP 상태·코드는 기존 제안을 유지하며, 추가 후보는 아래에 구분한다. 이 표만으로 미정 정책을 확정하지 않는다.

| HTTP·코드 | 오류 종류 | 발생 조건·주의사항 |
|---|---|---|
| `403 NOT_ADMIN` | 역할 권한 | 가입 처리·내보내기에 필요한 크루 관리 권한이 없음. 관리자 범위는 기존 크루장 정책 확인 |
| `409 NOT_PENDING` | 상태 충돌 | 신청 상태가 더 이상 PENDING이 아니거나 신청 관계가 없음. 동시 승인·거절·취소 포함 |
| `401 UNAUTHORIZED` | 인증 | 인증이 필요한 요청에 토큰이 없거나 만료·위변조되어 사용자를 확인할 수 없음 |
| `403 FORBIDDEN` | 권한 | 인증된 사용자가 해당 자원·작업에 필요한 권한을 갖지 않음 |
| `400 VALIDATION_ERROR` | 입력 형식 | JSON 구문·필수 필드·자료형·날짜 형식 또는 Path 식별자 형식이 맞지 않음. 서버 BIGINT 식별자의 소수·UUID·범위 초과 포함 |

**추가 오류 후보 — HTTP·코드·판정 정책 확인 필요**

| 후보 | 발생 가능 상황 |
|---|---|
| `409 CREW_CAPACITY_EXCEEDED` | 승인 직전 정원 확인. 동시 승인에서도 정원 초과 방지. 정원 상한 정책은 미정 |

- **대상 없음·접근 차단 점검:** 경로 대상의 부재/삭제, 본인 소유·역할·참가 자격 불충족을 구분한다. 위 표에 없는 경우 `404` 자원 없음 또는 `403` 접근 거부의 추가 매핑을 확인한다. 존재 은닉을 위한 403/404 선택·검사 순서는 미정이며 새 코드로 단정하지 않는다.

- 공통 입력·서버 장애와 재시도 판단은 [오류 분류와 재시도 기준](README.md#오류-분류와-재시도-기준)을 함께 적용한다.
- **중복·경합 점검:** 통신 시간초과는 저장 실패를 뜻하지 않는다. 동일 요청 재전송·다른 요청과의 충돌을 구분한다. 기존 멱등 처리 기준이 없는 경우 성공 재응답/409/재조회 선택은 확인 필요다.

**응답·복구 행동과의 연결:** APPROVED/REJECTED 외 결정은 422 INVALID_DECISION 후보다. 현재 PENDING 관계가 아닌 경우는 NOT_PENDING, 동시 승인 정원 충돌은 승인 분기에만 적용한다.

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
| `crewId` | integer (int64) | O | ERD 및 화면 요구사항을 기준으로 확정 필요 |

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
{
  "items": [
    {
      "userId": 101,
      "status": "APPROVED",
      "joinedAt": "2026-10-24T09:00:00Z",
      "nickname": "러너",
      "isOwner": false
    }
  ]
}
```

응답 필드 정의(저장 필드는 ERD ver.3에 대응, 파생·미정 값은 설명에 구분):

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `items` | array | X | 해당 크루 멤버 목록. 세부 객체 계약 미정 |
| `page` | string / object (확인 필요) | X | 페이지 메타데이터는 저장 엔티티가 아니다. cursor/limit 등 공통 페이지 형식 확정 필요. |

중첩 객체의 저장 필드 대응(추가 표시·집계 값은 기존 후보를 유지하며 별도 확인):

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `items[].userId` | integer (int64) | O | `crew_memberships.user_id` (BIGINT). 저장 값은 NULL 불가. |
| `items[].status` | string | O | `crew_memberships.status` (ENUM('PENDING', 'APPROVED', 'REJECTED', 'LEFT')). 현재 승인된 멤버만 조회하므로 APPROVED. |
| `items[].joinedAt` | string (ISO 8601 UTC) / null | O | `crew_memberships.joined_at` (TIMESTAMPTZ). NULL 허용; 미설정·미측정·미발생을 0/false/빈 문자열로 대체하지 않는다. |


**사용 흐름과 응답 판단**

현재 멤버 목록은 APPROVED만 반환한다. 크루장 역할은 owner_id 비교로 파생하고 가입 요청은 포함하지 않는다.

표시·선택·후속 이동에 필요한 필드 보완안:

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `items[].nickname` | string | O | 멤버의 표시명. |
| `items[].isOwner` | boolean | O | crews.owner_id와 해당 userId의 비교. |

### 오류 응답

**상태: 오류 계약 초안.** 기존 오류 코드에 발생 조건을 보완했다. HTTP 상태·코드는 기존 제안을 유지하며, 추가 후보는 아래에 구분한다. 이 표만으로 미정 정책을 확정하지 않는다.

| HTTP·코드 | 오류 종류 | 발생 조건·주의사항 |
|---|---|---|
| `404 CREW_NOT_FOUND` | 대상 없음 | 대상 크루가 없음. INACTIVE 상태의 조회/조작 허용 범위는 별도 확인 |
| `401 UNAUTHORIZED` | 인증 | 인증이 필요한 요청에 토큰이 없거나 만료·위변조되어 사용자를 확인할 수 없음 |
| `403 FORBIDDEN` | 권한 | 인증된 사용자가 해당 자원·작업에 필요한 권한을 갖지 않음 |
| `400 VALIDATION_ERROR` | 입력 형식 | JSON 구문·필수 필드·자료형·날짜 형식 또는 Path 식별자 형식이 맞지 않음. 서버 BIGINT 식별자의 소수·UUID·범위 초과 포함 |

- **대상 없음·접근 차단 점검:** 경로 대상의 부재/삭제, 본인 소유·역할·참가 자격 불충족을 구분한다. 위 표에 없는 경우 `404` 자원 없음 또는 `403` 접근 거부의 추가 매핑을 확인한다. 존재 은닉을 위한 403/404 선택·검사 순서는 미정이며 새 코드로 단정하지 않는다.

- 공통 입력·서버 장애와 재시도 판단은 [오류 분류와 재시도 기준](README.md#오류-분류와-재시도-기준)을 함께 적용한다.

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
| `crewId` | integer (int64) | O | ERD 및 화면 요구사항을 기준으로 확정 필요 |

### Query Parameters

없음

### Request Body

없음


### Response

`200 OK (제안)`

```json
{
  "status": "LEFT",
  "leftAt": "2026-10-24T09:00:00Z"
}
```

응답 필드 정의(저장 필드는 ERD ver.3에 대응, 파생·미정 값은 설명에 구분):

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `status` | string | O | `crew_memberships.status` (ENUM('PENDING', 'APPROVED', 'REJECTED', 'LEFT')). 저장 값은 NULL 불가. 허용값: PENDING, APPROVED, REJECTED, LEFT. |
| `leftAt` | string (ISO 8601 UTC) / null | O | `crew_memberships.left_at` (TIMESTAMPTZ). NULL 허용; 미설정·미측정·미발생을 0/false/빈 문자열로 대체하지 않는다. |


**사용 흐름과 응답 판단**

탈퇴 완료 상태 LEFT와 실제 leftAt을 반환한다. 크루장 위임 정책이 결정되지 않으면 일반 탈퇴로 우회하지 않는다.

### 오류 응답

**상태: 오류 계약 초안.** 기존 오류 코드에 발생 조건을 보완했다. HTTP 상태·코드는 기존 제안을 유지하며, 추가 후보는 아래에 구분한다. 이 표만으로 미정 정책을 확정하지 않는다.

| HTTP·코드 | 오류 종류 | 발생 조건·주의사항 |
|---|---|---|
| `409 OWNER_CANNOT_LEAVE` | 역할 제약 | 크루장 위임 처리 없이 일반 탈퇴를 요청함 |
| `401 UNAUTHORIZED` | 인증 | 인증이 필요한 요청에 토큰이 없거나 만료·위변조되어 사용자를 확인할 수 없음 |
| `403 FORBIDDEN` | 권한 | 인증된 사용자가 해당 자원·작업에 필요한 권한을 갖지 않음 |
| `400 VALIDATION_ERROR` | 입력 형식 | JSON 구문·필수 필드·자료형·날짜 형식 또는 Path 식별자 형식이 맞지 않음. 서버 BIGINT 식별자의 소수·UUID·범위 초과 포함 |

- **대상 없음·접근 차단 점검:** 경로 대상의 부재/삭제, 본인 소유·역할·참가 자격 불충족을 구분한다. 위 표에 없는 경우 `404` 자원 없음 또는 `403` 접근 거부의 추가 매핑을 확인한다. 존재 은닉을 위한 403/404 선택·검사 순서는 미정이며 새 코드로 단정하지 않는다.

- 공통 입력·서버 장애와 재시도 판단은 [오류 분류와 재시도 기준](README.md#오류-분류와-재시도-기준)을 함께 적용한다.
- **중복·경합 점검:** 통신 시간초과는 저장 실패를 뜻하지 않는다. 동일 요청 재전송·다른 요청과의 충돌을 구분한다. 기존 멱등 처리 기준이 없는 경우 성공 재응답/409/재조회 선택은 확인 필요다.

### 처리 규칙

- OWNER의 탈퇴 시 권한 이양 정책 미정.
- 사용자 소유권·그룹 참가 권한·상태 전이·재요청 여부를 검증한다(적용 범위는 API별로 결정).
- 예시는 **명세 구조를 보여주는 가상 값**이며, 확정되지 않은 제한·동기화 주기·AI 호출 주기를 의미하지 않는다.

### 상태값

- PENDING / APPROVED / REJECTED / LEFT.

### 미정 사항

- 사용자 확인 방향: 다른 승인 멤버가 있는 OWNER는 직접 지정한 크루 내 승인 멤버에게 권한을 이양한 뒤 탈퇴한다. OWNER 혼자 남은 경우에는 본인이 탈퇴를 요청할 때 해산을 안내하고 확인 후 크루 해산과 탈퇴를 처리한다. 혼자 남았다는 이유로 자동 해산하지 않으며, 최초 생성 직후의 1인 크루도 유지한다.
- [ ] 위 방향을 반영한 후임 지정·해산 확인의 API 계약, 권한 이양과 탈퇴의 일괄 처리 및 실패·동시 요청 처리 규칙 확정
- [ ] 크루 해산 시 가입 대기 요청·그룹런·연결 데이터의 처리와 보존 정책 확정
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
| `crewId` | integer (int64) | O | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `userId` | integer (int64) | O | ERD 및 화면 요구사항을 기준으로 확정 필요 |

### Query Parameters

없음

### Request Body

없음


### Response

`200 OK (제안)`

```json
{
  "status": "LEFT",
  "leftAt": "2026-10-24T09:00:00Z"
}
```

응답 필드 정의(저장 필드는 ERD ver.3에 대응, 파생·미정 값은 설명에 구분):

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `status` | string | O | `crew_memberships.status` (ENUM('PENDING', 'APPROVED', 'REJECTED', 'LEFT')). 저장 값은 NULL 불가. 허용값: PENDING, APPROVED, REJECTED, LEFT. |
| `leftAt` | string (ISO 8601 UTC) / null | O | `crew_memberships.left_at` (TIMESTAMPTZ). NULL 허용; 미설정·미측정·미발생을 0/false/빈 문자열로 대체하지 않는다. |


**사용 흐름과 응답 판단**

내보내기 대상의 LEFT와 leftAt을 반환한다. 요청자·대상·크루장 역할을 각각 검사한다.

### 오류 응답

**상태: 오류 계약 초안.** 기존 오류 코드에 발생 조건을 보완했다. HTTP 상태·코드는 기존 제안을 유지하며, 추가 후보는 아래에 구분한다. 이 표만으로 미정 정책을 확정하지 않는다.

| HTTP·코드 | 오류 종류 | 발생 조건·주의사항 |
|---|---|---|
| `403 NOT_ADMIN` | 역할 권한 | 가입 처리·내보내기에 필요한 크루 관리 권한이 없음. 관리자 범위는 기존 크루장 정책 확인 |
| `409 CANNOT_REMOVE_OWNER` | 역할 제약 | 크루장을 일반 멤버 내보내기로 제거하려 함 |
| `401 UNAUTHORIZED` | 인증 | 인증이 필요한 요청에 토큰이 없거나 만료·위변조되어 사용자를 확인할 수 없음 |
| `403 FORBIDDEN` | 권한 | 인증된 사용자가 해당 자원·작업에 필요한 권한을 갖지 않음 |
| `400 VALIDATION_ERROR` | 입력 형식 | JSON 구문·필수 필드·자료형·날짜 형식 또는 Path 식별자 형식이 맞지 않음. 서버 BIGINT 식별자의 소수·UUID·범위 초과 포함 |

- **대상 없음·접근 차단 점검:** 경로 대상의 부재/삭제, 본인 소유·역할·참가 자격 불충족을 구분한다. 위 표에 없는 경우 `404` 자원 없음 또는 `403` 접근 거부의 추가 매핑을 확인한다. 존재 은닉을 위한 403/404 선택·검사 순서는 미정이며 새 코드로 단정하지 않는다.

- 공통 입력·서버 장애와 재시도 판단은 [오류 분류와 재시도 기준](README.md#오류-분류와-재시도-기준)을 함께 적용한다.
- **중복·경합 점검:** 통신 시간초과는 저장 실패를 뜻하지 않는다. 동일 요청 재전송·다른 요청과의 충돌을 구분한다. 기존 멱등 처리 기준이 없는 경우 성공 재응답/409/재조회 선택은 확인 필요다.

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
{
  "items": [
    {
      "id": 101,
      "name": "러닝 크루",
      "regionCode": null,
      "myMembershipStatus": "PENDING",
      "memberCount": 10,
      "isOwner": false
    }
  ]
}
```

응답 필드 정의(ERD ver.3 대조):

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `items` | array | X | 크루 id·이름·레벨·지역·멤버 수·내 역할·가입 상태(승인 대기 표시) |

중첩 객체의 저장 필드 대응(추가 표시·집계 값은 기존 후보를 유지하며 별도 확인):

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `items[].id` | integer (int64) | O | `crews.id` (BIGINT). 저장 값은 NULL 불가. |
| `items[].name` | string | O | `crews.name` (VARCHAR(100)). 저장 값은 NULL 불가. |
| `items[].regionCode` | string / null | O | `crews.region_code` (VARCHAR(40)). NULL 허용; 미설정·미측정·미발생을 0/false/빈 문자열로 대체하지 않는다. |


**사용 흐름과 응답 판단**

승인 대기 표시와 크루 진입 가능 여부를 구분한다. 크루 상태와 본인 가입 상태는 다른 값이다.

기존 목록/결과의 기능상 필요한 하위 필드 보완안:

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `items[].myMembershipStatus` | string | O | PENDING/APPROVED 중 본인 목록 포함 조건에 맞는 가입상태. 크루장 포함 규칙 확인 필요. |
| `items[].memberCount` | integer | O | APPROVED 관계 수. |
| `items[].isOwner` | boolean | O | crews.owner_id=본인 비교 결과. |

### 오류 응답

**상태: 오류 계약 초안.** 기존 오류 코드에 발생 조건을 보완했다. HTTP 상태·코드는 기존 제안을 유지하며, 추가 후보는 아래에 구분한다. 이 표만으로 미정 정책을 확정하지 않는다.

| HTTP·코드 | 오류 종류 | 발생 조건·주의사항 |
|---|---|---|
| `401 UNAUTHORIZED` | 인증 | 인증이 필요한 요청에 토큰이 없거나 만료·위변조되어 사용자를 확인할 수 없음 |
| `403 FORBIDDEN` | 권한 | 인증된 사용자가 해당 자원·작업에 필요한 권한을 갖지 않음 |
| `400 VALIDATION_ERROR` | 입력 형식 | JSON 구문·필수 필드·자료형·날짜 형식 또는 Path 식별자 형식이 맞지 않음. 서버 BIGINT 식별자의 소수·UUID·범위 초과 포함 |

- 공통 입력·서버 장애와 재시도 판단은 [오류 분류와 재시도 기준](README.md#오류-분류와-재시도-기준)을 함께 적용한다.

### 처리 규칙

- 가입한 크루가 없으면 빈 배열을 반환하고 화면은 6.0b 안내를 보여 준다.
- 사용자 소유권·그룹 참가 권한·상태 전이·재요청 여부를 검증한다(적용 범위는 API별로 결정).
- 예시는 **명세 구조를 보여주는 가상 값**이며, 확정되지 않은 제한·동기화 주기·AI 호출 주기를 의미하지 않는다.

### 상태값

- 해당 없음.

### 미정 사항

- [ ] 응답 필드는 ERD 확정 후 갱신
- [ ] HTTP 성공 코드 및 각 예외의 오류 코드 최종 확정
