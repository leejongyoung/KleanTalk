#!/bin/zsh
# 새 버전 배포: ./scripts/release.sh <버전> <릴리스 노트 파일>
#   예) ./scripts/release.sh 1.4 notes.md
# 하는 일 (fork, #1)
#  1. Info.plist 버전을 올린다 (빌드 번호는 1 증가)
#  2. DMG(처음 받는 사람용)와 zip(나중에 자동 업데이트를 살릴 때 쓸 것)을 만든다
#  3. fork용 Sparkle 키쌍이 생기기 전까지는 서명·appcast 생성을 건너뛴다 (아래 참고)
#  4. 커밋·태그·push 후 GitHub Release에 DMG를 올린다
# fork에는 업데이트 피드(SUFeedURL)가 없다. fork용 EdDSA 키쌍을 만들어 SUPublicEDKey와
# SUFeedURL을 되살리기 전까지 자동 업데이트는 동작하지 않으며, release.sh도 서명 단계를 건너뛴다.
set -euo pipefail
cd "${0:A:h}/.."

VERSION=${1:?버전을 적으세요 (예: 1.4)}
NOTES=${2:?릴리스 노트 파일을 적으세요}
[[ -f $NOTES ]] || { echo "릴리스 노트 파일이 없습니다: $NOTES"; exit 1; }
[[ -z $(git status --porcelain --untracked-files=no) ]] || { echo "커밋하지 않은 변경이 있습니다. 먼저 커밋하세요."; exit 1; }
REPO=leejongyoung/KleanTalk
# fork에서 upstream으로 실수 push하지 않도록 origin을 확인한다 (#1).
[[ $(git remote get-url origin) == *"$REPO"* ]] || { echo "origin이 $REPO가 아닙니다: $(git remote get-url origin)"; exit 1; }

BUILD=$(( $(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' Info.plist) + 1 ))
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" -c "Set :CFBundleVersion $BUILD" Info.plist

./scripts/make-dmg.sh
ZIP="build/KleanTalk-$VERSION.zip"
ditto -c -k --sequesterRsrc --keepParent build/KleanTalk.app "$ZIP"

# fork용 Sparkle 키쌍이 없으면 서명·appcast를 건너뛴다 (KLEANTALK_SPARKLE_KEY=1로 강제).
# 키쌍을 만들면 Info.plist에 SUFeedURL·SUPublicEDKey를 되살리고 이 분기를 지운다 (#1 후속).
APPCAST_ARGS=()
if [[ -n ${KLEANTALK_SPARKLE_KEY:-} ]]; then
  # 서명: sparkle:edSignature="..." length="..."
  SIGN_UPDATE=(vendor/Sparkle-*/bin/sign_update)
  SIG=$("${SIGN_UPDATE[1]}" --account kleantalk "$ZIP")

  # 릴리스 노트(빈 줄로 나눈 문단)를 업데이트 창에 보일 간단한 HTML로
  NOTES_HTML=$(/usr/bin/python3 -I -c '
import html, sys
paras = [p.strip() for p in open(sys.argv[1], encoding="utf-8").read().split("\n\n") if p.strip()]
print("".join("<p>" + html.escape(p).replace("\n", "<br>") + "</p>" for p in paras))' "$NOTES")

  cat > build/appcast.xml <<EOF
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <title>KleanTalk</title>
    <item>
      <title>KleanTalk $VERSION</title>
      <pubDate>$(LC_ALL=C date -u "+%a, %d %b %Y %H:%M:%S +0000")</pubDate>
      <sparkle:version>$BUILD</sparkle:version>
      <sparkle:shortVersionString>$VERSION</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>$(/usr/libexec/PlistBuddy -c 'Print :LSMinimumSystemVersion' Info.plist)</sparkle:minimumSystemVersion>
      <description><![CDATA[$NOTES_HTML]]></description>
      <enclosure url="https://github.com/$REPO/releases/download/v$VERSION/KleanTalk-$VERSION.zip" $SIG type="application/octet-stream"/>
    </item>
  </channel>
</rss>
EOF
  APPCAST_ARGS=(build/appcast.xml)
else
  echo "Sparkle 키 없음: appcast 없이 DMG+zip만 올립니다 (자동 업데이트 미동작, #1)."
fi

git commit -q -am "버전 $VERSION"
git tag "v$VERSION"
git push -q origin main "v$VERSION"
gh release create "v$VERSION" build/KleanTalk.dmg "$ZIP" ${APPCAST_ARGS[@]:-} \
  --repo "$REPO" --title "KleanTalk $VERSION" --notes-file "$NOTES" --latest
echo "배포했습니다: https://github.com/$REPO/releases/tag/v$VERSION"
