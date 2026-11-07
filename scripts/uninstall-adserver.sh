#!/bin/zsh
# KleanTalk 제거: 빈 광고 서버·인증서 신뢰·키·전용 주소를 지우고, /etc/hosts의 광고 차단 블록을 뺀다.
# 실행: KleanTalk 앱의 '제거' 버튼, 또는  sudo ./scripts/uninstall-adserver.sh
set -euo pipefail

[[ $EUID -eq 0 ]] || { echo "sudo로 실행하세요: sudo $0"; exit 1; }

LABEL=com.myungchul.kleantalk.adserver
DIR="/Library/Application Support/KleanTalk/AdServer"
ADDR=127.84.11.1

launchctl bootout system/$LABEL 2>/dev/null || true
rm -f /Library/LaunchDaemons/$LABEL.plist
if [[ -f $DIR/cert.pem ]]; then
  FP=$(/usr/bin/openssl x509 -in "$DIR/cert.pem" -noout -fingerprint -sha1 | cut -d= -f2 | tr -d :)
  security delete-certificate -Z "$FP" /Library/Keychains/System.keychain 2>/dev/null || true
  # 터미널 설치 안내대로 로그인 키체인에 신뢰가 들어갔을 수 있다 (#3). 사용자마다 best-effort로 지운다.
  # 앱 설치 경로의 사용자 신뢰는 앱이 먼저 지운다 (KleanTalk.untrustCertificate).
  for home in /Users/*; do
    [[ -d $home ]] || continue
    user=${home#/Users/}
    [[ $user == Shared || $user == "*"* ]] && continue
    keychain="$home/Library/Keychains/login.keychain-db"
    [[ -f $keychain ]] || continue
    sudo -u "$user" security delete-certificate -Z "$FP" "$keychain" 2>/dev/null || true
  done
fi
rm -rf "${DIR:?}"
rmdir "/Library/Application Support/KleanTalk" 2>/dev/null || true
/sbin/ifconfig lo0 -alias $ADDR 2>/dev/null || true

# hosts에서 관리 대상 행만 지운다. 블록 안에 사용자가 넣은 행이 있으면 표식을 남기고 보존한다 (#4).
# 제거 전 타임스탬프 백업을 남긴다 (최대 5개).
TS=$(date +%Y%m%d-%H%M%S)
cp -p /etc/hosts "/etc/hosts.kleantalk.$TS.bak"
ls -t /etc/hosts.kleantalk.*.bak 2>/dev/null | tail -n +6 | xargs rm -f --
TMP_HOSTS=$(mktemp /etc/hosts.kleantalk.XXXXXX)
trap 'rm -f "$TMP_HOSTS"' EXIT
awk -v host="serv.ds.kakao.com" '
  /^# >>> KakaoAdBlock/ { inside = 1; buf = ""; kept = 0; next }
  inside && /^# <<< KakaoAdBlock/ {
    inside = 0
    if (kept) { print "# >>> KakaoAdBlock (custom lines kept)"; printf "%s", buf; print "# <<< KakaoAdBlock" }
    next
  }
  !inside { print; next }
  NF >= 2 && ($2 == host || $2 == "display.ad.daum.net" || $2 == "analytics.ad.daum.net") { next }
  { buf = buf $0 "\n"; kept = 1; next }
' /etc/hosts > "$TMP_HOSTS"
chmod 644 "$TMP_HOSTS"; chown root:wheel "$TMP_HOSTS"
mv -f "$TMP_HOSTS" /etc/hosts
trap - EXIT
dscacheutil -flushcache; killall mDNSResponder 2>/dev/null || true

echo "KleanTalk의 광고 차단과 빈 광고 서버를 모두 지웠습니다."
