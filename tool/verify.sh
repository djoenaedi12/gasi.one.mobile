#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
flutter pub get --offline
packages=(core-api core-starter core-ui platform-app)
for package in plugins/*; do
  if [[ "$package" != plugins/legacy_epc && -f "$package/pubspec.yaml" ]]; then packages+=("$package"); fi
done
format_paths=(tool plugins/legacy_epc/lib/src plugins/legacy_epc/lib/legacy_epc.dart)
legacy_analysis_paths=(plugins/legacy_epc/lib/src)
# Keep the retained splash checked until its removal during the CR cutover.
if [[ -f plugins/legacy_epc/lib/view/splash_screen_page.dart ]]; then
  format_paths+=(plugins/legacy_epc/lib/view/splash_screen_page.dart)
  legacy_analysis_paths+=(plugins/legacy_epc/lib/view/splash_screen_page.dart)
fi
for package in "${packages[@]}"; do
  format_paths+=("$package/lib")
  if [[ -d "$package/test" ]]; then format_paths+=("$package/test"); fi
done
if [[ "${1:-}" == "--format" ]]; then dart format "${format_paths[@]}"; fi
dart format --output=none --set-exit-if-changed "${format_paths[@]}"
dart run tool/check_architecture.dart
# Imported EPC code has a separate baseline of existing lints. New modular code
# must pass strict analysis; do not suppress legacy diagnostics globally.
flutter analyze --no-pub "${packages[@]}" "${legacy_analysis_paths[@]}"
for package in "${packages[@]}"; do
  if [[ -d "$package/test" ]] && [[ -n "$(find "$package/test" -type f -name '*_test.dart' -print -quit)" ]]; then
    (cd "$package" && flutter test --no-pub --reporter expanded)
  fi
done

if [[ " $* " == *" --apk "* ]]; then
  (cd platform-app && flutter build apk --debug --no-pub)
fi
