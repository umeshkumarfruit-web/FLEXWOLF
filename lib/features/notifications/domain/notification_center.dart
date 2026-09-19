import 'dart:convert';

import 'package:flexwolf/core/storage/local_storage.dart';
import 'package:flexwolf/features/notifications/domain/notification_models.dart';

const notificationCenterLimit = 50;

class NotificationCenterItem {
  const NotificationCenterItem({
    required this.id,
    required this.title,
    required this.receivedAt,
    this.body,
    this.deepLink,
    this.readAt,
  });

  final String id;
  final String title;
  final String? body;
  final String? deepLink;
  final DateTime receivedAt;
  final DateTime? readAt;

  bool get isRead => readAt != null;

  NotificationCenterItem markRead(DateTime readAt) => NotificationCenterItem(
    id: id,
    title: title,
    body: body,
    deepLink: deepLink,
    receivedAt: receivedAt,
    readAt: readAt,
  );

  NotificationPayload toPayload() =>
      NotificationPayload(id: id, title: title, body: body, deepLink: deepLink);
}

class NotificationCenterSnapshot {
  const NotificationCenterSnapshot({required this.items});

  final List<NotificationCenterItem> items;

  int get unreadCount => items.where((item) => !item.isRead).length;
}

abstract interface class NotificationCenterRepository {
  Future<NotificationCenterSnapshot> load({String? customerId});
  Future<NotificationCenterSnapshot> saveReceived(
    NotificationPayload payload, {
    String? customerId,
  });
  Future<NotificationCenterSnapshot> markRead(
    String notificationId, {
    String? customerId,
  });
  Future<NotificationCenterSnapshot> markAllRead({String? customerId});
  Future<void> clear({String? customerId});
}

class LocalNotificationCenterRepository
    implements NotificationCenterRepository {
  const LocalNotificationCenterRepository(this._storage);

  static const _guestKey = 'notifications.center.guest';

  final LocalStorage _storage;

  @override
  Future<NotificationCenterSnapshot> load({String? customerId}) async {
    final items = await _read(_key(customerId));
    return NotificationCenterSnapshot(items: items);
  }

  @override
  Future<NotificationCenterSnapshot> saveReceived(
    NotificationPayload payload, {
    String? customerId,
  }) async {
    final key = _key(customerId);
    final items = await _read(key);
    if (payload.id.trim().isEmpty || payload.title.trim().isEmpty) {
      return NotificationCenterSnapshot(items: items);
    }
    items.removeWhere((item) => item.id == payload.id);
    items.insert(
      0,
      NotificationCenterItem(
        id: payload.id,
        title: payload.title,
        body: payload.body,
        deepLink: payload.deepLink,
        receivedAt: DateTime.now().toUtc(),
      ),
    );
    final limited = items.take(notificationCenterLimit).toList(growable: true);
    await _write(key, limited);
    return NotificationCenterSnapshot(items: limited);
  }

  @override
  Future<NotificationCenterSnapshot> markRead(
    String notificationId, {
    String? customerId,
  }) async {
    final key = _key(customerId);
    final items = await _read(key);
    final now = DateTime.now().toUtc();
    final updated = [
      for (final item in items)
        if (item.id == notificationId) item.markRead(now) else item,
    ];
    await _write(key, updated);
    return NotificationCenterSnapshot(items: updated);
  }

  @override
  Future<NotificationCenterSnapshot> markAllRead({String? customerId}) async {
    final key = _key(customerId);
    final items = await _read(key);
    final now = DateTime.now().toUtc();
    final updated = [for (final item in items) item.markRead(now)];
    await _write(key, updated);
    return NotificationCenterSnapshot(items: updated);
  }

  @override
  Future<void> clear({String? customerId}) => _storage.remove(_key(customerId));

  Future<List<NotificationCenterItem>> _read(String key) async {
    final raw = await _storage.readString(key);
    if (raw == null) return <NotificationCenterItem>[];
    Object? parsed;
    try {
      parsed = jsonDecode(raw);
    } on FormatException {
      return <NotificationCenterItem>[];
    }
    if (parsed is! List) return <NotificationCenterItem>[];
    return parsed
        .whereType<Map<String, Object?>>()
        .map(_fromJson)
        .nonNulls
        .toList(growable: true);
  }

  Future<void> _write(String key, List<NotificationCenterItem> items) =>
      _storage.writeString(key, jsonEncode(items.map(_toJson).toList()));

  String _key(String? customerId) => customerId == null
      ? _guestKey
      : 'notifications.center.customer.$customerId';
}

NotificationCenterItem? _fromJson(Map<String, Object?> json) {
  final id = json['id'];
  final title = json['title'];
  final receivedAt = DateTime.tryParse(json['receivedAt'] as String? ?? '');
  if (id is! String ||
      id.trim().isEmpty ||
      title is! String ||
      title.trim().isEmpty ||
      receivedAt == null) {
    return null;
  }
  return NotificationCenterItem(
    id: id,
    title: title,
    body: json['body'] as String?,
    deepLink: json['deepLink'] as String?,
    receivedAt: receivedAt,
    readAt: DateTime.tryParse(json['readAt'] as String? ?? ''),
  );
}

Map<String, Object?> _toJson(NotificationCenterItem item) => {
  'id': item.id,
  'title': item.title,
  'receivedAt': item.receivedAt.toIso8601String(),
  if (item.body != null) 'body': item.body,
  if (item.deepLink != null) 'deepLink': item.deepLink,
  if (item.readAt != null) 'readAt': item.readAt!.toIso8601String(),
};
