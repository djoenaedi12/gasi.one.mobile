#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
dart format --output=none --set-exit-if-changed \
  core-api/lib core-api/test core-starter/lib core-starter/test \
  core-ui/lib core-ui/test platform-app/lib tool
dart run tool/check_architecture.dart
flutter analyze --no-pub
for package in core-api core-starter core-ui platform-app; do
  if [[ -n "$(find "$package/test" -type f -name '*_test.dart' -print -quit 2>/dev/null)" ]]; then
    (cd "$package" && flutter test --no-pub)
  fi
done
