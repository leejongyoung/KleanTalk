# Fork 운영 (leejongyoung/KleanTalk)

upstream(`showmeyourway-sketch/KleanTalk`)의 fork입니다. 분기점: v1.11 (`92bd138`).

## upstream과 다른 점

- **자동 업데이트 없음.** Sparkle 서명 키가 upstream에 있어 fork에서 피드(`SUFeedURL`)를 뺐습니다. 새 버전은 GitHub Releases에서 DMG를 받아 다시 설치하세요. fork용 EdDSA 키쌍을 만들면 되살립니다 (#1).
- **버그 신고·업데이트 확인이 이 fork를 가리킵니다.** (`Sources/KleanTalk.swift`의 `issueNewURL`, README 링크)
- **릴리스 스크립트는 fork 전용.** (`scripts/release.sh`의 `REPO=leejongyoung/KleanTalk`, origin 확인 포함)
- **식별자는 upstream과 공유 유지.** 번들 ID·LaunchDaemon 라벨·로그 서브시스템(`com.myungchul.kleantalk*`)·hosts 블록 표식은 바꾸지 않습니다. 설치된 기존 환경과 충돌하지 않게 하려는 의도입니다.
- **멀티유저 지원 (#11, upstream #1 대응).** 인증서 신뢰가 사용자 도메인이라 계정마다 한 번씩 신뢰 등록이 필요합니다. 설치 스크립트가 앱이 `/Applications`에 있을 때 시스템 로그인 에이전트(`/Library/LaunchAgents`)를 등록해, 모든 계정(향후 계정 포함)의 로그인 때 백그라운드 확인을 돕니다. 풀려 있으면 창을 띄워 안내하므로, 다른 계정에서는 첫 로그인 때 안내대로 **다시 설치**(신뢰 등록)를 한 번 하세요. `~/Applications` 설치에서는 설치한 계정에서만 돕니다.

## 브랜치 운용

- `main`: upstream 미러. 직접 커밋하지 않고 upstream 기본 브랜치와 fast-forward로만 맞춥니다 (`git fetch upstream` → `git merge --ff-only upstream/main`). 갈라지면 강제 동기화하지 않고 보고합니다.
- `work`: 기본 브랜치. fork 고유 변경은 여기서 개발·병합합니다.
- `upstream-submit`: upstream 제출용. upstream `main`에서 따서 제출할 변경만 담고, 제출이 끝나면 지웁니다.

## upstream 동기화

- upstream 릴리스를 주기적으로 확인하고, 보안·버그 수정은 선별해서 `work`에 가져옵니다.
- 미러(`main`)가 upstream보다 뒤처지면 위 fast-forward로 맞춥니다. 이 저장소는 `scripts/fork-sync.sh` 감시 대상 이름이 아니라 수동으로 합니다.

## 알려진 문제 (upstream 이슈 대응)

- upstream #1(다른 계정 광고 복귀) → fork #11로 가져와 시스템 로그인 에이전트로 해결.
- upstream #2(working인데 광고 복귀) → fork #12. `diagnose()`가 차단 3종 전체를 판정(`ok`·`blocked`·`NOT-REDIRECTED`·`UNBLOCKED`)하므로, 제보의 `hosts:` 한 줄이면 hosts 초기화와 신규 엔드포인트 우회를 가릴 수 있음.
- upstream #3(원격연결 불가) → 제보자 자가 해결 + 코드상 원격 서비스 접점 없음. 조치 불필요, README 문제 해결에 명시.

## 라벨 운용

- `security`: 신뢰 모델·권한·인증서·업데이트 서명 관련
- `supply-chain`: 릴리스·빌드·외부 의존성(Sparkle 등)
- `hardening`: 방어 심화 (원자 교체·검증 강화·마스킹)
- `privacy`: 진단 로그·수집 데이터
- 기본 라벨(`bug`·`documentation`·`enhancement` 등)은 GitHub 기본값 그대로 씁니다.

## 커밋 규칙

- 형식: `type: 한국어 요약 한 줄` (50자 내, 마침표 없음). 영어 말머리만 쓰고 나머지는 한국어.
- `feat` 기능추가 · `fix` 버그수정 · `docs` 문서 · `refactor` 리팩터 · `test` 시험 · `chore` 빌드·설정·잡일 · `release` 릴리스 커밋
- 본문: 배경 → 변경 → 검증 순서로 짧게. AI 작성자 표시(`Co-Authored-By` 등)는 넣지 않습니다.
- 예: `fix: 설치 시 검역 표시 제거`

## 릴리스 규칙

- 제목: `KleanTalk X.Y.Z`
- 본문: 한 줄 요약 → `### 고친 점` → `### 설치` → `### 알려진 문제` → 구분선 → 영어(같은 구조). 체크박스·이모지는 쓰지 않습니다.
- 에셋: `KleanTalk.dmg` + `KleanTalk-X.Y.Z.zip`. 자동 업데이트용 appcast는 fork 키가 생기기 전까지 올리지 않습니다.
