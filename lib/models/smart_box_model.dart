part of '../app.dart';

class SmartBoxModel extends ChangeNotifier {
  String userName = 'Emir';
  bool isLocked = true;
  bool isOnline = true;
  bool lidLocked = true;
  bool securityMode = false;
  bool alarmTriggered = false;
  bool isDeviceLoading = false;
  bool isDeviceListLoading = false;
  bool hasDeviceNode = true;
  String? deviceError;
  String lidState = 'closed';
  String lastSeen = '';
  String deviceStatus = 'Online';
  String? activeDeviceId;
  String? selectedDeviceId;
  String imageStatus = 'idle';
  String lastImageUrl = '';
  String lastImageTime = '';
  List<RegisteredDevice> registeredDevices = const [];
  List<SecurityAlertItem> deviceEvents = const [];

  List<SecurityAlertItem> get alerts => deviceEvents;

  RegisteredDevice? get selectedDevice {
    final deviceId = selectedDeviceId;
    if (deviceId == null) {
      return null;
    }
    for (final device in registeredDevices) {
      if (device.id == deviceId) {
        return device;
      }
    }
    return null;
  }

  bool get hasRegisteredDevices => registeredDevices.isNotEmpty;

  void setUserName(String name) {
    final cleanName = name.trim();
    final firstName = cleanName.split(RegExp(r'\s+')).first;
    userName = firstName.isEmpty ? 'User' : firstName;
    notifyListeners();
  }

  void unlock() {
    isLocked = false;
    notifyListeners();
  }

  void lock() {
    isLocked = true;
    notifyListeners();
  }

  void setDeviceLoading() {
    isDeviceListLoading = true;
    isDeviceLoading = true;
    hasDeviceNode = true;
    deviceError = null;
    notifyListeners();
  }

  void setActiveDeviceLoading(String deviceId) {
    activeDeviceId = deviceId;
    isDeviceLoading = true;
    hasDeviceNode = true;
    deviceError = null;
    notifyListeners();
  }

  void setDeviceError(String message) {
    isDeviceListLoading = false;
    isDeviceLoading = false;
    deviceError = message;
    notifyListeners();
  }

  void applyRegisteredDevices(List<RegisteredDevice> devices) {
    isDeviceListLoading = false;
    registeredDevices = devices;
    if (devices.isEmpty) {
      selectedDeviceId = null;
      activeDeviceId = null;
      isDeviceLoading = false;
      hasDeviceNode = false;
      deviceError = null;
      deviceEvents = const [];
      imageStatus = 'idle';
      lastImageUrl = '';
      lastImageTime = '';
      lastSeen = '';
      deviceStatus = 'No devices';
      notifyListeners();
      return;
    }

    final currentSelected = selectedDeviceId;
    final selectedStillExists =
        currentSelected != null &&
        devices.any((device) => device.id == currentSelected);
    selectedDeviceId = selectedStillExists ? currentSelected : devices.first.id;
    hasDeviceNode = true;
    deviceError = null;
    notifyListeners();
  }

  void selectDevice(String deviceId) {
    if (selectedDeviceId == deviceId) {
      return;
    }

    selectedDeviceId = deviceId;
    isDeviceLoading = true;
    hasDeviceNode = true;
    deviceError = null;
    deviceEvents = const [];
    imageStatus = 'idle';
    lastImageUrl = '';
    lastImageTime = '';
    notifyListeners();
  }

  void applyDeviceSnapshot(SmartBoxDevice? device) {
    isDeviceLoading = false;
    if (device == null) {
      hasDeviceNode = false;
      deviceError = 'No device data found for the selected device.';
      notifyListeners();
      return;
    }

    activeDeviceId = device.id;
    hasDeviceNode = true;
    deviceError = null;
    isLocked = device.isLocked;
    lidLocked = device.lidLocked;
    lidState = device.lidState;
    lastSeen = device.lastSeen.isEmpty ? 'Unknown' : device.lastSeen;
    isOnline = device.isOnline;
    securityMode = device.securityMode;
    alarmTriggered = device.alarmTriggered;
    imageStatus = device.imageStatus.isEmpty ? 'idle' : device.imageStatus;
    lastImageUrl = device.lastImageUrl;
    lastImageTime = device.lastImageTime;
    deviceStatus = device.isOnline ? 'Online' : 'Offline';
    deviceEvents = device.events;
    notifyListeners();
  }

  void reset() {
    isLocked = true;
    isOnline = true;
    lidLocked = true;
    securityMode = false;
    alarmTriggered = false;
    isDeviceLoading = false;
    isDeviceListLoading = false;
    hasDeviceNode = true;
    deviceError = null;
    lidState = 'closed';
    lastSeen = '';
    deviceStatus = 'Online';
    activeDeviceId = null;
    selectedDeviceId = null;
    imageStatus = 'idle';
    lastImageUrl = '';
    lastImageTime = '';
    registeredDevices = const [];
    deviceEvents = const [];
    notifyListeners();
  }
}

enum PackageKind { cardboard, cardboardAlt, mailer }

class DeliveryItem {
  const DeliveryItem({
    required this.orderNumber,
    required this.status,
    required this.date,
    required this.time,
    required this.note,
    required this.packageKind,
    required this.otpUsed,
    required this.weight,
  });

  final int orderNumber;
  final String status;
  final String date;
  final String time;
  final String note;
  final PackageKind packageKind;
  final String otpUsed;
  final String weight;

  String get deliveredAtLabel => '$date - $time';
}

enum AlertSeverity { critical, warning, success, battery }

class SecurityAlertItem {
  const SecurityAlertItem({
    required this.title,
    required this.message,
    required this.time,
    required this.severity,
    this.attemptTimes = const [],
  });

  final String title;
  final String message;
  final String time;
  final AlertSeverity severity;
  final List<String> attemptTimes;
}
