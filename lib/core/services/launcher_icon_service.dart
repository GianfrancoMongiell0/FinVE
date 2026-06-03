// Copyright (c) 2026 Gianfranco Mongiello. MIT License.
// https://github.com/GianfrancoMongiell0/FinVE

import 'package:flutter/services.dart';

class LauncherIconService {
  LauncherIconService._();
  static final instance = LauncherIconService._();

  static const _channel = MethodChannel('com.finve.app/launcher_icon');

  Future<bool> setIcon(String logoId) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'setIcon',
        {'logoId': logoId},
      );
      return result ?? false;
    } on PlatformException catch (e) {
      // Log but don't crash — some ROMs block this
      debugPrint('[LauncherIconService] setIcon failed: ${e.message}');
      return false;
    }
  }

  Future<String> getCurrentIcon() async {
    try {
      final result = await _channel.invokeMethod<String>('getIcon');
      return result ?? 'v4';
    } on PlatformException {
      return 'v4';
    }
  }
}

// ignore: avoid_print
void debugPrint(String msg) => print(msg);