# RunWay 문서 안내

RunWay의 제품 범위, 기술 결정, 인터페이스 계약, 실험 결과와 개발 운영 문서를 목적별로 관리한다. 새 문서를 추가하거나 기존 문서를 이동할 때는 이 문서의 분류와 링크를 함께 갱신한다.

## 먼저 읽을 문서

1. [1차 MVP 요구사항](requirements/mvp.md)에서 구현 범위와 제외 범위를 확인한다.
2. [상세 요구사항 참고본](requirements/detailed-requirements.md)에서 요구사항 ID와 세부 조건을 확인한다.
3. [기술 결정 기록](adr/README.md)에서 현재 채택되거나 제안된 기술 결정을 확인한다.
4. [서비스 API 검토안](api/service-api.md)과 [데이터 모델 안내](architecture/data-model/README.md)에서 구현 계약의 현재 상태를 확인한다.
5. 작업 방식은 [개발 운영 문서](development/README.md), AI 작업 범위는 [AI 개발 문서](ai/README.md)를 따른다.

상세 요구사항이 1차 MVP 요구사항과 충돌하면 `requirements/mvp.md`를 우선한다. API 검토안과 아직 등록되지 않은 ERD는 확정된 계약으로 간주하지 않는다.

## 문서 구조

| 위치 | 역할 | 현재 기준 상태 |
| --- | --- | --- |
| [`requirements/`](requirements/) | MVP 범위와 상세 요구사항 | `mvp.md`가 제품 범위의 기준 문서 |
| [`architecture/`](architecture/) | 시스템 개요와 데이터 모델 | 확정 자료가 추가될 때 갱신 |
| [`api/`](api/) | 서비스 및 실험용 인터페이스 계약 | 문서별 상태를 확인 |
| [`adr/`](adr/) | 기술 선택의 배경·대안·결과 | ADR 상태와 대체 관계가 기준 |
| [`experiments/`](experiments/) | PoC 실행 방법과 검증 범위 | 제품 계약이 아닌 실험 기록 |
| [`development/`](development/) | Git·Jira·GitLab 운영 방법 | 팀 개발 절차의 기준 문서 |
| [`ai/`](ai/) | 개발용 AI 도구 조사와 검증 기록 | 서비스 내부 AI 설계와 분리 |

## 상태와 관리 원칙

- 각 문서 상단에 상태, 기준일 또는 관련 Jira를 기록한다.
- 같은 내용을 여러 문서에 복사하지 않고 기준 문서를 링크한다.
- 아키텍처와 핵심 기술 선택은 [ADR 운영 규칙](adr/README.md)에 따라 기록한다.
- 실험 결과는 실제로 확인한 범위와 미검증 범위를 구분한다.
- 파일을 이동하거나 이름을 바꾸면 저장소 내부 링크와 자동화 스크립트의 안내 경로도 함께 수정한다.
- 인증정보가 포함된 `.env`와 `.env.*`는 문서, 로그, 예시에 포함하지 않는다.
