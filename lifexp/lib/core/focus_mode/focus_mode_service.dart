import 'dart:convert';
import 'package:flutter/services.dart';

class FocusModeService {
  FocusModeService._();
  static final instance = FocusModeService._();

  static const MethodChannel _ch = MethodChannel('lifexp/sticky_service');

  Future<void> setFocusModeActive(bool active) async {
    await _ch.invokeMethod('setFocusModeActive', {'active': active});
  }

  Future<void> setBlockedPackages(List<String> packages) async {
    await _ch.invokeMethod('setBlockedPackages', {
      'json': jsonEncode(packages),
    });
  }
}

const List<String> kDefaultBlockedPackages = <String>[
  'com.instagram.android',
  'com.zhiliaoapp.musically',
  'com.google.android.youtube',
  'com.facebook.katana',
  'com.twitter.android',
];
