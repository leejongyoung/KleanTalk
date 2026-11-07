# Fork 운영 (leejongyoung/KleanTalk)

upstream(`showmeyourway-sketch/KleanTalk`)의 fork입니다. 분기점: v1.11 (`92bd138`).

## upstream과 다른 점

- **자동 업데이트 없음.** Sparkle 서명 키가 upstream에 있어 fork에서 피드(`SUFeedURL`)를 뺐습니다. 새 버전은 GitHub Releases에서 DMG를 받아 다시 설치하세요. fork용 EdDSA 키쌍을 만들면 되살립니다 (#1).
- **버그 신고·업데이트 확인이 이 fork를 가리킵니다.** (`Sources/KleanTalk.swift`의 `issueNewURL`, README 링크)
- **릴리스 스크립트는 fork 전용.** (`scripts/release.sh`의 `REPO=leejongyoung/KleanTalk`, origin 확인 포함)
- **식별자는 upstream과 공유 유지.** 번들 ID·LaunchDaemon 라벨·로그 서브시스템(`com.myungchul.kleantalk*`)·hosts 블록 표식은 바꾸지 않습니다. 설치된 기존 환경과 충돌하지 않게 하려는 의도입니다.
- **멀티유저 지원 (#11, upstream #1 대응).** 인증서 신뢰가 사용자 도메인이라 계정마다 한 번씩 신뢰 등록이 필요합니다. 설치 스크립트가 앱이 `/Applications`에 있을 때 시스템 로그인 에이전트(`/Library/LaunchAgents`)를 등록해, 모든 계정(향후 계정 포함)의 로그인 때 백그라운드 확인을 돕니다. 풀려 있으면 창을 띄워 안내하므로, 다른 계정에서는 첫 로그인 때 안내대로 **다시 설치**(신뢰 등록)를 한 번 하세요. `~/Applications` 설치에서는 설치한 계정에서만 돕니다.

## upstream 동기화

- upstream 릴리스를 주기적으로 확인하고, 보안·버그 수정은 선별해서 가져옵니다.
- 가져올 때는 upstream 기본 브랜치 대상이 아니라 fork `main`에 직접 머지하는 동기화 PR을 엽니다. fork 고유 변경(자동 업데이트 제거 등)과 충돌하면 fork 동작을 우선합니다.

## 라벨 운용

- `security`: 신뢰 모델·권한·인증서·업데이트 서명 관련
- `supply-chain`: 릴리스·빌드·외부 의존성(Sparkle 등)
- `hardening`: 방어 심화 (원자 교체·검증 강화·마스킹)
- `privacy`: 진단 로그·수집 데이터
- 기본 라벨(`bug`·`documentation`·`enhancement` 등)은 GitHub 기본값 그대로 씁니다.
