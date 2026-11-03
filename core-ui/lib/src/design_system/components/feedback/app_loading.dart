import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import '../../foundations/app_radius.dart';
import '../../foundations/app_spacing.dart';

/// Shared blocking loading overlay. No vendor types escape this bridge.
/// Mount [init] once in the application's MaterialApp.builder, then pair
/// [show] with [dismiss] in a try/finally around the operation.
abstract final class AppLoading {
  static TransitionBuilder init() => (context, child) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    EasyLoading.instance
      ..indicatorType = EasyLoadingIndicatorType.fadingCircle
      ..loadingStyle = EasyLoadingStyle.custom
      ..maskType = EasyLoadingMaskType.custom
      ..backgroundColor = colors.surfaceContainerLowest
      ..indicatorColor = colors.primary
      ..progressColor = colors.primary
      ..textColor = colors.onSurface
      ..textStyle = theme.textTheme.bodyMedium?.copyWith(
        color: colors.onSurface,
      )
      ..maskColor = colors.scrim.withValues(alpha: 0.5)
      ..radius = AppRadius.md
      ..contentPadding = const EdgeInsets.all(AppSpacing.lg)
      ..textPadding = const EdgeInsets.only(top: AppSpacing.sm)
      ..userInteractions = false
      ..dismissOnTap = false;
    return EasyLoading.init()(context, child ?? const SizedBox.shrink());
  };

  static bool get isVisible => EasyLoading.isShow;

  static Future<void> show({String? status}) =>
      EasyLoading.show(status: status);

  static Future<void> dismiss() => EasyLoading.dismiss();
}
