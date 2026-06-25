part of '../app.dart';

class SmartBoxScope extends InheritedNotifier<SmartBoxModel> {
  const SmartBoxScope({
    super.key,
    required SmartBoxModel model,
    this.onSendLidCommand,
    this.onRegisterDevice,
    this.onSelectDevice,
    this.onSetSecurityMode,
    this.onRequestImageCapture,
    required super.child,
  }) : super(notifier: model);

  final LidCommandHandler? onSendLidCommand;
  final DeviceRegistrationHandler? onRegisterDevice;
  final ValueChanged<String>? onSelectDevice;
  final SecurityModeHandler? onSetSecurityMode;
  final ImageRequestHandler? onRequestImageCapture;

  static SmartBoxModel of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SmartBoxScope>();
    assert(scope != null, 'SmartBoxScope was not found in the widget tree.');
    return scope!.notifier!;
  }

  static LidCommandHandler? lidCommandHandlerOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<SmartBoxScope>()
        ?.onSendLidCommand;
  }

  static DeviceRegistrationHandler? deviceRegistrationHandlerOf(
    BuildContext context,
  ) {
    return context
        .dependOnInheritedWidgetOfExactType<SmartBoxScope>()
        ?.onRegisterDevice;
  }

  static ValueChanged<String>? deviceSelectionHandlerOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<SmartBoxScope>()
        ?.onSelectDevice;
  }

  static SecurityModeHandler? securityModeHandlerOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<SmartBoxScope>()
        ?.onSetSecurityMode;
  }

  static ImageRequestHandler? imageRequestHandlerOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<SmartBoxScope>()
        ?.onRequestImageCapture;
  }
}
