#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
dart format --output=none --set-exit-if-changed \
  core-api/lib core-api/test core-starter/lib core-starter/test \
  core-ui/lib core-ui/test plugins platform-app/lib platform-app/test tool
dart run tool/check_architecture.dart
flutter analyze --no-pub
for package in core-api core-starter core-ui plugins/auth plugins/catalog platform-app; do
  (cd "$package" && flutter test --no-pub)
done
