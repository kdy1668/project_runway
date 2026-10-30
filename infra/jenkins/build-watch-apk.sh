#!/bin/sh
set -eu

# MR·master에서 같은 제품 앱 검사와 APK 빌드를 수행한다. 실험용 :demo는 제외한다.
cd wear
started=$(date +%s)
if sh ./gradlew --no-daemon --max-workers=1 --build-cache --profile \
    :app:testDebugUnitTest :app:lintDebug :app:assembleDebug "$@"; then
    result=0
else
    result=$?
fi
elapsed=$(( $(date +%s) - started ))
mkdir -p build/reports/profile
printf 'duration_seconds=%s\nexit_code=%s\n' "$elapsed" "$result" > build/reports/profile/build-time.txt
printf '워치 검사·APK 빌드 소요 시간: %s초 (종료 코드: %s)\n' "$elapsed" "$result"
if [ "$result" -ne 0 ]; then exit "$result"; fi
test -s app/build/outputs/apk/debug/app-debug.apk
