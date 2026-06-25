part of '../app.dart';

enum LidCommand { open, close }

class FirebaseDeviceRepository {
  FirebaseDeviceRepository({FirebaseDatabase? database})
    : _database = database ?? FirebaseDatabase.instance;

  final FirebaseDatabase _database;

  Future<void> createOrUpdateUserProfile({
    required String uid,
    required String email,
    required String name,
  }) {
    return _database.ref('users/$uid').update({
      'email': email,
      'name': name,
      'language': 'en',
      'theme': 'light',
    });
  }

  Stream<List<RegisteredDevice>> watchRegisteredDevices(String uid) {
    return _database.ref('users/$uid/devices').onValue.map((event) {
      if (!event.snapshot.exists || event.snapshot.value is! Map) {
        return const <RegisteredDevice>[];
      }

      final data = Map<Object?, Object?>.from(event.snapshot.value as Map);
      final devices =
          data.entries.where((entry) => entry.value is Map).map((entry) {
            final value = Map<Object?, Object?>.from(entry.value as Map);
            return RegisteredDevice.fromMap(
              id: entry.key.toString(),
              data: value,
            );
          }).toList()..sort(
            (a, b) => a.alias.toLowerCase().compareTo(b.alias.toLowerCase()),
          );
      return devices;
    });
  }

  Future<void> registerDevice({
    required String uid,
    required String deviceId,
    required String alias,
  }) async {
    final updates = <String, Object?>{
      'users/$uid/devices/$deviceId/alias': alias,
      'users/$uid/devices/$deviceId/addedAt': DateTime.now()
          .toUtc()
          .toIso8601String(),
      'devices/$deviceId/info/owner': uid,
    };
    await _database.ref().update(updates);
  }

  Stream<SmartBoxDevice?> watchDevice(String deviceId) {
    return _database.ref('devices/$deviceId').onValue.map((event) {
      if (!event.snapshot.exists) {
        return null;
      }

      final value = event.snapshot.value;
      if (value is! Map) {
        return null;
      }

      return SmartBoxDevice.fromMap(
        id: deviceId,
        data: Map<Object?, Object?>.from(value),
      );
    });
  }

  Future<void> sendLidCommand({
    required String deviceId,
    required LidCommand command,
  }) {
    return _database.ref('devices/$deviceId/lid').update({'change_lid': true});
  }

  Future<void> setSecurityMode({
    required String deviceId,
    required bool enabled,
  }) {
    return _database.ref('devices/$deviceId/security').update({
      'security_mode': enabled,
    });
  }

  Future<void> requestImageCapture({required String deviceId}) {
    return _database.ref('devices/$deviceId/info').update({
      'image_request': true,
      'image_status': 'requested',
    });
  }
}

class RegisteredDevice {
  const RegisteredDevice({
    required this.id,
    required this.alias,
    required this.addedAt,
  });

  factory RegisteredDevice.fromMap({
    required String id,
    required Map<Object?, Object?> data,
  }) {
    return RegisteredDevice(
      id: id,
      alias: SmartBoxDevice.stringValue(data['alias']).isEmpty
          ? id
          : SmartBoxDevice.stringValue(data['alias']),
      addedAt: SmartBoxDevice.stringValue(data['addedAt']),
    );
  }

  final String id;
  final String alias;
  final String addedAt;
}

class SmartBoxDevice {
  const SmartBoxDevice({
    required this.id,
    required this.isLocked,
    required this.lidState,
    required this.lidLocked,
    required this.lastSeen,
    required this.isOnline,
    required this.securityMode,
    required this.alarmTriggered,
    required this.imageStatus,
    required this.lastImageUrl,
    required this.lastImageTime,
    required this.events,
  });

  factory SmartBoxDevice.fromMap({
    required String id,
    required Map<Object?, Object?> data,
  }) {
    final info = _mapValue(data['info']);
    final lid = _mapValue(data['lid']);
    final security = _mapValue(data['security']);
    final image = _mapValue(data['image']);
    final lidState = stringValue(lid['lid_state']);
    final lidLocked = _boolValue(lid['lid_locked']);
    return SmartBoxDevice(
      id: id,
      isLocked: lidLocked ?? _isLocked(lidState),
      lidState: lidState.isEmpty ? 'unknown' : lidState,
      lidLocked: lidLocked ?? _isLocked(lidState),
      lastSeen: stringValue(info['last_seen']),
      isOnline: _boolValue(info['online']) ?? false,
      securityMode: _boolValue(security['security_mode']) ?? false,
      alarmTriggered: _boolValue(security['alarm_triggered']) ?? false,
      imageStatus: _firstString([
        info['image_status'],
        image['image_status'],
        data['image_status'],
      ]),
      lastImageUrl: _firstString([
        info['last_image_url'],
        info['lastImageUrl'],
        image['last_image_url'],
        image['lastImageUrl'],
        data['last_image_url'],
        data['lastImageUrl'],
      ]),
      lastImageTime: _firstString([
        info['last_image_time'],
        info['lastImageTime'],
        image['last_image_time'],
        image['lastImageTime'],
        data['last_image_time'],
        data['lastImageTime'],
      ]),
      events: _eventsFromValue(data['events']),
    );
  }

  final String id;
  final bool isLocked;
  final String lidState;
  final bool lidLocked;
  final String lastSeen;
  final bool isOnline;
  final bool securityMode;
  final bool alarmTriggered;
  final String imageStatus;
  final String lastImageUrl;
  final String lastImageTime;
  final List<SecurityAlertItem> events;

  static bool _isLocked(String lidState) {
    final normalized = lidState.toLowerCase().trim();
    return normalized == 'closed' ||
        normalized == 'close' ||
        normalized == 'locked' ||
        normalized == 'lock';
  }

  static List<SecurityAlertItem> _eventsFromValue(Object? value) {
    if (value is! Map) {
      return const [];
    }

    final entries = value.entries.toList()
      ..sort((a, b) {
        final aMap = a.value is Map
            ? Map<Object?, Object?>.from(a.value as Map)
            : null;
        final bMap = b.value is Map
            ? Map<Object?, Object?>.from(b.value as Map)
            : null;
        return stringValue(
          bMap?['timestamp'],
        ).compareTo(stringValue(aMap?['timestamp']));
      });

    return entries
        .where((entry) => entry.value is Map)
        .map((entry) {
          final event = Map<Object?, Object?>.from(entry.value as Map);
          final description = stringValue(event['description']);
          final severityLabel = stringValue(event['severity']);
          final timestamp = stringValue(event['timestamp']);
          return SecurityAlertItem(
            title: description.isEmpty ? 'Device event' : description,
            message: severityLabel.isEmpty
                ? 'Event reported by device.'
                : 'Severity: $severityLabel',
            time: timestamp.isEmpty ? 'Unknown time' : timestamp,
            severity: _severityFromString(severityLabel),
          );
        })
        .toList(growable: false);
  }

  static AlertSeverity _severityFromString(String value) {
    switch (value.toLowerCase().trim()) {
      case 'critical':
      case 'danger':
      case 'high':
      case 'error':
        return AlertSeverity.critical;
      case 'warning':
      case 'warn':
      case 'medium':
        return AlertSeverity.warning;
      case 'success':
      case 'info':
      case 'low':
        return AlertSeverity.success;
      default:
        return AlertSeverity.warning;
    }
  }

  static Map<Object?, Object?> _mapValue(Object? value) {
    if (value is Map) {
      return Map<Object?, Object?>.from(value);
    }
    return const {};
  }

  static bool? _boolValue(Object? value) {
    if (value is bool) {
      return value;
    }
    final normalized = stringValue(value).toLowerCase();
    if (normalized == 'true' || normalized == '1' || normalized == 'on') {
      return true;
    }
    if (normalized == 'false' || normalized == '0' || normalized == 'off') {
      return false;
    }
    return null;
  }

  static String stringValue(Object? value) => value?.toString().trim() ?? '';

  static String _firstString(List<Object?> values) {
    for (final value in values) {
      final text = stringValue(value);
      if (text.isNotEmpty) {
        return text;
      }
    }
    return '';
  }
}
