import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static const MethodChannel _stickyChannel = MethodChannel(
    'lifexp/sticky_service',
  );

  // Bump channel ID when behavior/importance is changed. Android channels are sticky.
  static const _channelId = 'lifexp_daily_v2';
  static const _channelName = 'LifeXP Daily';
  static const _channelDesc = 'Daily reminder to complete missions or focus';

  static const int dailyScheduleNotifId = 1001;
  static const int stickyNotifId = 2001;
  static const int _appCooldownMs = 2 * 60 * 1000;

  Future<void> init() async {
    tzdata.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(initSettings);

    final permissionGranted = await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    _log('notification permission granted=$permissionGranted');

    // Create channel explicitly to avoid relying on implicit plugin behavior.
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDesc,
            importance: Importance.max,
          ),
        );

    _log('init completed channel=$_channelId');
  }

  Future<void> scheduleDailyInWindow() async {
    final now = tz.TZDateTime.now(tz.local);

    final hour = 13 + Random().nextInt(10); // 13..22
    final minute = Random().nextInt(60);

    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.max,
      priority: Priority.high,
      ongoing: false,
      autoCancel: true,
      onlyAlertOnce: true,
      category: AndroidNotificationCategory.reminder,
    );

    const details = NotificationDetails(android: androidDetails);

    try {
      await _plugin.zonedSchedule(
        dailyScheduleNotifId,
        'LifeXP',
        'Completa 1 misión o haz Focus 30 💪',
        scheduled,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'daily',
      );
      _log('daily scheduled id=$dailyScheduleNotifId at=$scheduled exact=true');
    } on PlatformException catch (e) {
      if (e.code != 'exact_alarms_not_permitted') rethrow;
      await _plugin.zonedSchedule(
        dailyScheduleNotifId,
        'LifeXP',
        'Completa 1 misión o haz Focus 30 💪',
        scheduled,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'daily',
      );
      _log(
        'daily scheduled id=$dailyScheduleNotifId at=$scheduled exact=false',
      );
    }

    final pending = await _plugin.pendingNotificationRequests();
    _log('pending notifications=${pending.map((p) => p.id).toList()}');
  }

  Future<void> showOngoingNow() async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.max,
      priority: Priority.high,
      ongoing: true,
      autoCancel: false,
      onlyAlertOnce: true,
      category: AndroidNotificationCategory.service,
    );

    const details = NotificationDetails(android: androidDetails);

    await _plugin.show(
      stickyNotifId,
      'LifeXP',
      'Completa 1 misión o haz Focus 30 💪',
      details,
      payload: 'sticky',
    );
    _log('fallback sticky shown id=$stickyNotifId');
  }

  Future<void> cancelDaily() async {
    await _plugin.cancel(stickyNotifId);
    _log('fallback sticky canceled id=$stickyNotifId');
  }

  /// ✅ Sticky real:
  /// - Si ya completaste hoy => cancela
  /// - Si NO => muestra ongoing
  Future<void> syncStickyDaily({
    required bool completedToday,
    required String todayLocalIso,
  }) async {
    _log(
      'syncStickyDaily completedToday=$completedToday todayLocalIso=$todayLocalIso',
    );
    await setStickyEnabled(true);

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final lastSyncAt = await getStickyLastSyncAt();
    final lastDecision = await getStickyLastDecision();
    final lastDate = await getStickyLastDate();
    final inCooldown = (nowMs - lastSyncAt) < _appCooldownMs;

    if (inCooldown && lastDate == todayLocalIso) {
      _log('sync skipped by cooldown');
      return;
    }

    final decision = completedToday ? 'stop' : 'start';
    if (lastDate == todayLocalIso && lastDecision == decision) {
      await setStickyLastSyncAt(nowMs);
      _log('sync noop same decision=$decision');
      return;
    }

    await setStickyLastDate(todayLocalIso);
    await setStickyLastDecision(decision);
    await setStickyLastSyncAt(nowMs);

    if (decision == 'stop') {
      await stopSticky();
      return;
    }
    await startSticky();
  }

  Future<void> startSticky() async {
    if (_isAndroid) {
      // NOTE: On some OEM ROMs, regular "ongoing" notifications can still be swiped.
      // Foreground Service is the most reliable Android-native option for true persistence.
      await _stickyChannel.invokeMethod<void>('startSticky');
      _log('foreground sticky start requested');
      return;
    }
    await showOngoingNow();
  }

  Future<void> stopSticky() async {
    if (_isAndroid) {
      await _stickyChannel.invokeMethod<void>('stopSticky');
      _log('foreground sticky stop requested');
      return;
    }
    await cancelDaily();
  }

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> setStickyEnabled(bool enabled) async {
    if (!_isAndroid) return;
    await _stickyChannel.invokeMethod<void>('setStickyEnabled', {
      'enabled': enabled,
    });
    _log('setStickyEnabled=$enabled');
  }

  Future<bool> getStickyEnabled() async {
    if (!_isAndroid) return false;
    final res = await _stickyChannel.invokeMethod<dynamic>('getStickyEnabled');
    return (res as bool?) ?? false;
  }

  Future<void> setStickyLastDate(String yyyyMmDd) async {
    if (!_isAndroid) return;
    await _stickyChannel.invokeMethod<void>('setStickyLastDate', {
      'date': yyyyMmDd,
    });
    _log('setStickyLastDate=$yyyyMmDd');
  }

  Future<void> setStickyLastSyncAt(int ms) async {
    if (!_isAndroid) return;
    await _stickyChannel.invokeMethod<void>('setStickyLastSyncAt', {'ms': ms});
    _log('setStickyLastSyncAt=$ms');
  }

  Future<void> setStickyLastDecision(String decision) async {
    if (!_isAndroid) return;
    await _stickyChannel.invokeMethod<void>('setStickyLastDecision', {
      'decision': decision,
    });
    _log('setStickyLastDecision=$decision');
  }

  Future<int> getStickyLastSyncAt() async {
    if (!_isAndroid) return 0;
    final res = await _stickyChannel.invokeMethod<dynamic>(
      'getStickyLastSyncAt',
    );
    return (res as num?)?.toInt() ?? 0;
  }

  Future<String> getStickyLastDecision() async {
    if (!_isAndroid) return '';
    final res = await _stickyChannel.invokeMethod<dynamic>(
      'getStickyLastDecision',
    );
    return (res as String?) ?? '';
  }

  Future<String> getStickyLastDate() async {
    if (!_isAndroid) return '';
    final res = await _stickyChannel.invokeMethod<dynamic>('getStickyLastDate');
    return (res as String?) ?? '';
  }

  Future<String> getPendingAction() async {
    if (!_isAndroid) return '';
    final res = await _stickyChannel.invokeMethod<dynamic>('getPendingAction');
    return (res as String?) ?? '';
  }

  Future<void> clearPendingAction() async {
    if (!_isAndroid) return;
    await _stickyChannel.invokeMethod<void>('clearPendingAction');
  }

  void _log(String message) {
    debugPrint('[NotificationService] $message');
  }
}
