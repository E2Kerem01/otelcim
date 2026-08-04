import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'profile_service.dart';

const _urgentRegionKey = 'urgent_listing_region';
const _urgentEnabledKey = 'urgent_listings_enabled';

String regionTopicName(String region) {
  final safeRegion = region.trim().toLowerCase().replaceAll(
    RegExp(r'[^a-z0-9-_.~%]'),
    '_',
  );
  return 'region_$safeRegion';
}

class NotificationService {
  NotificationService(this._profileService);

  final ProfileService _profileService;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;
  String? _currentUid;
  void Function(String conversationId)? _onOpenChat;

  Future<void> init({
    required void Function(String conversationId) onOpenChat,
  }) async {
    _onOpenChat = onOpenChat;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: (response) {
        final conversationId = response.payload;
        if (conversationId != null && conversationId.isNotEmpty) {
          _onOpenChat?.call(conversationId);
        }
      },
    );

    const messageChannel = AndroidNotificationChannel(
      'messages',
      'Yeni mesajlar',
      description: 'Sohbet mesajı bildirimleri',
      importance: Importance.high,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(messageChannel);
    const urgentChannel = AndroidNotificationChannel(
      'urgent_listings',
      'Acil ilanlar',
      description: 'Bölgenizdeki acil personel ilanları',
      importance: Importance.high,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(urgentChannel);

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    await _messaging.requestPermission(alert: true, badge: true, sound: true);
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: false,
      sound: false,
    );

    _tokenSubscription = _messaging.onTokenRefresh.listen(_saveToken);
    _foregroundSubscription = FirebaseMessaging.onMessage.listen(
      _showForegroundMessage,
    );
    _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      _handleOpenedMessage,
    );

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) _handleOpenedMessage(initialMessage);
  }

  Future<void> setCurrentUser(String? uid) async {
    final previousUid = _currentUid;
    if (previousUid != null && previousUid != uid) {
      try {
        await _profileService.clearFcmToken(previousUid);
      } catch (error) {
        debugPrint('Eski FCM token temizlenemedi: $error');
      }
    }
    _currentUid = uid;
    if (uid == null) {
      await _unsubscribeStoredRegion();
      return;
    }
    final token = await _messaging.getToken();
    if (token != null && token.isNotEmpty) await _saveToken(token);
    await _restoreUrgentTopicSubscription();
  }

  Future<void> selectRegion(String region) async {
    if (region.trim().isEmpty) return;
    final preferences = await SharedPreferences.getInstance();
    final previousRegion = preferences.getString(_urgentRegionKey);
    if (previousRegion != null && previousRegion != region) {
      await _messaging.unsubscribeFromTopic(regionTopicName(previousRegion));
    }
    await preferences.setString(_urgentRegionKey, region);
    if (_currentUid != null &&
        (preferences.getBool(_urgentEnabledKey) ?? true)) {
      await _messaging.subscribeToTopic(regionTopicName(region));
    }
  }

  Future<void> setUrgentListingsPreference(bool enabled) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_urgentEnabledKey, enabled);
    final region = preferences.getString(_urgentRegionKey);
    if (region == null) return;
    final topic = regionTopicName(region);
    if (enabled && _currentUid != null) {
      await _messaging.subscribeToTopic(topic);
    } else {
      await _messaging.unsubscribeFromTopic(topic);
    }
  }

  Future<void> _restoreUrgentTopicSubscription() async {
    final preferences = await SharedPreferences.getInstance();
    if (!(preferences.getBool(_urgentEnabledKey) ?? true)) return;
    final region = preferences.getString(_urgentRegionKey);
    if (region != null) {
      await _messaging.subscribeToTopic(regionTopicName(region));
    }
  }

  Future<void> _unsubscribeStoredRegion() async {
    final preferences = await SharedPreferences.getInstance();
    final region = preferences.getString(_urgentRegionKey);
    if (region != null) {
      await _messaging.unsubscribeFromTopic(regionTopicName(region));
    }
  }

  Future<void> _saveToken(String token) async {
    final uid = _currentUid;
    if (uid == null || token.isEmpty) return;
    try {
      await _profileService.updateFcmToken(uid, token);
    } catch (error) {
      debugPrint('FCM token kaydedilemedi: $error');
    }
  }

  Future<void> _showForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    final body = notification?.body ?? message.data['body'] as String?;
    if (body == null || body.isEmpty) return;
    await showMessageNotification(
      id:
          message.messageId?.hashCode ??
          DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: notification?.title ?? 'Yeni mesaj',
      body: body,
      conversationId: message.data['conversationId'] as String?,
    );
  }

  void _handleOpenedMessage(RemoteMessage message) {
    final conversationId = message.data['conversationId'] as String?;
    if (conversationId != null && conversationId.isNotEmpty) {
      _onOpenChat?.call(conversationId);
    }
  }

  Future<void> showMessageNotification({
    required int id,
    required String title,
    required String body,
    String? conversationId,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'messages',
        'Yeni mesajlar',
        channelDescription: 'Sohbet mesajı bildirimleri',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
      payload: conversationId,
    );
  }

  Future<void> dispose() async {
    await _tokenSubscription?.cancel();
    await _foregroundSubscription?.cancel();
    await _openedSubscription?.cancel();
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = NotificationService(ref.watch(profileServiceProvider));
  ref.onDispose(() => unawaited(service.dispose()));
  return service;
});
