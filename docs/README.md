# RunWay 문서

현재 사용하는 문서만 두 영역으로 관리한다.

## 설계

- [1차 MVP 기능](design/mvp.md)
- [상세 요구사항](design/requirements.md)
- [데이터 모델 설명](design/erd.md) · [기준 스키마](design/schema.sql)
- [API 명세](design/api/README.md)
- [기술 결정 기록](design/adr.md)

설계 문서는 모두 `design/`에 둔다. 기능 구현 시 현재 Jira와 관련된 문서만 확인한다. 요구사항이 충돌하면 임의로 정하지 않고 제품 결정을 확인하며, 데이터 모델 내부가 충돌하면 `schema.sql`을 우선한다. API 문서는 문서에 표시된 상태를 확인한다.

## 개발 운영

- [Git 규칙](development/git-convention.md)
- [Jira 자동화](development/jira-automation.md)
- [GitLab 자동화](development/gitlab-automation.md)
- [개발용 AI 도구](development/ai-tooling.md)

AI Agent의 공통 보안·작업 규칙은 루트 [`AGENTS.md`](../AGENTS.md)를 따른다. 코드 실행·빌드 방법은 해당 코드 디렉터리의 `README.md`에서 관리한다. 아직 사용하지 않는 문서 분류나 빈 폴더는 미리 만들지 않는다.
