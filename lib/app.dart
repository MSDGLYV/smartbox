import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

part 'theme/app_colors.dart';
part 'utils/layout.dart';
part 'models/smart_box_scope.dart';
part 'models/smart_box_model.dart';
part 'screens/login_screen.dart';
part 'screens/register_screen.dart';
part 'screens/home_screen.dart';
part 'screens/lock_control_screen.dart';
part 'screens/security_alerts_screen.dart';
part 'screens/otp_screen.dart';
part 'screens/settings_screen.dart';
part 'widgets/drawer.dart';
part 'widgets/drawer_items.dart';
part 'widgets/headers.dart';
part 'widgets/controls.dart';
part 'widgets/smart_card.dart';
part 'widgets/home_widgets.dart';
part 'widgets/list_cards.dart';
part 'widgets/settings_toggle.dart';
part 'widgets/status_widgets.dart';
part 'widgets/lock_widgets.dart';
part 'widgets/detail_widgets.dart';
part 'widgets/app_logo_mark.dart';
part 'widgets/locker_illustrations.dart';
part 'widgets/package_widgets.dart';
part 'widgets/battery_widgets.dart';
part 'services/firebase_device_repository.dart';
part 'utils/navigation.dart';

typedef SignInHandler =
    FutureOr<String?> Function({
      required String email,
      required String password,
    });

typedef RegisterHandler =
    FutureOr<String?> Function({
      required String fullName,
      required String email,
      required String phone,
      required String password,
      required String confirmPassword,
    });

typedef LidCommandHandler = FutureOr<String?> Function({required bool open});
typedef DeviceRegistrationHandler =
    FutureOr<String?> Function({
      required String deviceId,
      required String alias,
    });
typedef SecurityModeHandler =
    FutureOr<String?> Function({required bool enabled});
typedef ImageRequestHandler = FutureOr<String?> Function();

class SmartDropOffApp extends StatefulWidget {
  const SmartDropOffApp({super.key});

  @override
  State<SmartDropOffApp> createState() => _SmartDropOffAppState();
}

class UserAccount {
  const UserAccount({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.password,
  });

  final String fullName;
  final String email;
  final String phone;
  final String password;
}

class _SmartDropOffAppState extends State<SmartDropOffApp> {
  final SmartBoxModel _model = SmartBoxModel();
  final Map<String, UserAccount> _accountsByEmail = {};
  late final bool _firebaseReady;
  FirebaseAuth? _auth;
  FirebaseDeviceRepository? _deviceRepository;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<List<RegisteredDevice>>? _registeredDevicesSubscription;
  StreamSubscription<SmartBoxDevice?>? _deviceSubscription;
  bool _signedIn = false;

  @override
  void initState() {
    super.initState();
    _firebaseReady = Firebase.apps.isNotEmpty;
    if (!_firebaseReady) {
      return;
    }

    _auth = FirebaseAuth.instance;
    _deviceRepository = FirebaseDeviceRepository();
    _signedIn = _auth!.currentUser != null;
    _handleFirebaseUser(_auth!.currentUser);
    _authSubscription = _auth!.authStateChanges().listen(_handleFirebaseUser);
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _registeredDevicesSubscription?.cancel();
    _deviceSubscription?.cancel();
    _model.dispose();
    super.dispose();
  }

  Future<String?> _signIn({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = _normalizeEmail(email);
    final cleanPassword = password.trim();

    if (normalizedEmail.isEmpty || cleanPassword.isEmpty) {
      return 'Enter your email and password.';
    }

    if (_firebaseReady) {
      try {
        await _auth!.signInWithEmailAndPassword(
          email: normalizedEmail,
          password: cleanPassword,
        );
        final user = _auth!.currentUser;
        if (user != null) {
          await _deviceRepository!.createOrUpdateUserProfile(
            uid: user.uid,
            email: normalizedEmail,
            name: user.displayName ?? normalizedEmail,
          );
        }
        return null;
      } on FirebaseAuthException catch (error) {
        return _authErrorMessage(error);
      } catch (_) {
        return 'Could not connect to Firebase. Try again.';
      }
    }

    final account = _accountsByEmail[normalizedEmail];
    if (account == null || account.password != cleanPassword) {
      return 'No account matches those credentials.';
    }

    _model.setUserName(account.fullName);
    setState(() => _signedIn = true);
    return null;
  }

  Future<String?> _register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
  }) async {
    final cleanName = fullName.trim();
    final normalizedEmail = _normalizeEmail(email);
    final cleanPhone = phone.trim();
    final cleanPassword = password.trim();
    final cleanConfirmPassword = confirmPassword.trim();

    if (cleanName.isEmpty ||
        normalizedEmail.isEmpty ||
        cleanPhone.isEmpty ||
        cleanPassword.isEmpty ||
        cleanConfirmPassword.isEmpty) {
      return 'Fill in every field to create your account.';
    }

    if (!_isValidEmail(normalizedEmail)) {
      return 'Enter a valid email address.';
    }

    if (!_isValidPhone(cleanPhone)) {
      return 'Phone number must start with 0 and be 11 digits.';
    }

    if (cleanPassword.length < 6) {
      return 'Password must be at least 6 characters.';
    }

    if (cleanPassword != cleanConfirmPassword) {
      return 'Passwords do not match.';
    }

    if (_accountsByEmail.containsKey(normalizedEmail)) {
      return 'An account with this email already exists.';
    }

    if (_firebaseReady) {
      try {
        debugPrint('Creating Firebase user...');
        final credential = await _auth!.createUserWithEmailAndPassword(
          email: normalizedEmail,
          password: cleanPassword,
        );
        debugPrint('Firebase user created: ${credential.user?.uid ?? ''}');
        await credential.user?.updateDisplayName(cleanName);
        if (credential.user != null) {
          await _deviceRepository!.createOrUpdateUserProfile(
            uid: credential.user!.uid,
            email: normalizedEmail,
            name: cleanName,
          );
        }
        _model.setUserName(cleanName);
        if (mounted) {
          setState(() => _signedIn = true);
        }
        return null;
      } on FirebaseAuthException catch (error) {
        final message = _firebaseAuthExceptionMessage(error);
        debugPrint('Firebase register failed: $message');
        return message;
      } catch (error) {
        debugPrint('Firebase register failed: $error');
        return 'Firebase register failed: $error';
      }
    }

    final account = UserAccount(
      fullName: cleanName,
      email: normalizedEmail,
      phone: cleanPhone,
      password: cleanPassword,
    );
    _accountsByEmail[normalizedEmail] = account;
    _model.setUserName(account.fullName);
    setState(() => _signedIn = true);
    return null;
  }

  String _normalizeEmail(String email) => email.trim().toLowerCase();

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }

  bool _isValidPhone(String phone) {
    return RegExp(r'^0\d{10}$').hasMatch(phone);
  }

  Future<void> _signOut() async {
    _deviceSubscription?.cancel();
    _deviceSubscription = null;
    _registeredDevicesSubscription?.cancel();
    _registeredDevicesSubscription = null;
    _model.reset();

    if (_firebaseReady) {
      await _auth?.signOut();
    }

    if (mounted) {
      setState(() => _signedIn = false);
    }
  }

  void _handleFirebaseUser(User? user) {
    if (user == null) {
      _deviceSubscription?.cancel();
      _deviceSubscription = null;
      _registeredDevicesSubscription?.cancel();
      _registeredDevicesSubscription = null;
      _model.reset();
      if (mounted) {
        setState(() => _signedIn = false);
      }
      return;
    }

    _model.setUserName(user.displayName ?? user.email ?? 'User');
    _deviceRepository
        ?.createOrUpdateUserProfile(
          uid: user.uid,
          email: user.email ?? '',
          name: user.displayName ?? user.email ?? 'User',
        )
        .catchError((_) {});
    _listenToRegisteredDevices(user.uid);
    if (mounted) {
      setState(() => _signedIn = true);
    }
  }

  void _listenToRegisteredDevices(String uid) {
    _registeredDevicesSubscription?.cancel();
    _deviceSubscription?.cancel();
    _deviceSubscription = null;
    _model.setDeviceLoading();
    _registeredDevicesSubscription = _deviceRepository!
        .watchRegisteredDevices(uid)
        .listen(
          (devices) {
            _model.applyRegisteredDevices(devices);
            final selectedDeviceId = _model.selectedDeviceId;
            if (selectedDeviceId == null) {
              _deviceSubscription?.cancel();
              _deviceSubscription = null;
              return;
            }
            _listenToDevice(selectedDeviceId);
          },
          onError: (_) => _model.setDeviceError(
            'Could not load registered devices from Firebase.',
          ),
        );
  }

  void _listenToDevice(String deviceId) {
    if (_model.activeDeviceId == deviceId && _deviceSubscription != null) {
      return;
    }

    _deviceSubscription?.cancel();
    _model.setActiveDeviceLoading(deviceId);
    _deviceSubscription = _deviceRepository!
        .watchDevice(deviceId)
        .listen(
          _model.applyDeviceSnapshot,
          onError: (_) => _model.setDeviceError(
            'Could not load device data from Firebase.',
          ),
        );
  }

  void _selectDevice(String deviceId) {
    _model.selectDevice(deviceId);
    _listenToDevice(deviceId);
  }

  Future<String?> _registerDevice({
    required String deviceId,
    required String alias,
  }) async {
    final user = _auth?.currentUser;
    if (!_firebaseReady || user == null) {
      return 'You need to sign in before registering a device.';
    }

    final cleanDeviceId = deviceId.trim();
    final cleanAlias = alias.trim();
    if (cleanDeviceId.isEmpty || cleanAlias.isEmpty) {
      return 'Enter a device ID and alias.';
    }

    try {
      await _deviceRepository!.registerDevice(
        uid: user.uid,
        deviceId: cleanDeviceId,
        alias: cleanAlias,
      );
      _selectDevice(cleanDeviceId);
      return null;
    } catch (_) {
      return 'Could not register this device in Firebase.';
    }
  }

  Future<String?> _sendLidCommand({required bool open}) async {
    final user = _auth?.currentUser;
    if (!_firebaseReady || user == null) {
      if (!_firebaseReady) {
        open ? _model.unlock() : _model.lock();
        return null;
      }
      return 'You need to sign in before sending device commands.';
    }

    final deviceId = _model.selectedDeviceId;
    if (deviceId == null) {
      return 'Register a device before sending commands.';
    }

    try {
      await _deviceRepository!.sendLidCommand(
        deviceId: deviceId,
        command: open ? LidCommand.open : LidCommand.close,
      );
      return null;
    } catch (_) {
      return 'Could not send command to Firebase.';
    }
  }

  Future<String?> _setSecurityMode({required bool enabled}) async {
    final user = _auth?.currentUser;
    if (!_firebaseReady || user == null) {
      return 'You need to sign in before changing security mode.';
    }

    final deviceId = _model.selectedDeviceId;
    if (deviceId == null) {
      return 'Register a device before changing security mode.';
    }

    try {
      await _deviceRepository!.setSecurityMode(
        deviceId: deviceId,
        enabled: enabled,
      );
      return null;
    } catch (_) {
      return 'Could not update security mode in Firebase.';
    }
  }

  Future<String?> _requestImageCapture() async {
    final user = _auth?.currentUser;
    if (!_firebaseReady || user == null) {
      return 'You need to sign in before requesting an image.';
    }

    final deviceId = _model.selectedDeviceId;
    if (deviceId == null) {
      return 'Register a device before requesting an image.';
    }

    try {
      await _deviceRepository!.requestImageCapture(deviceId: deviceId);
      return null;
    } catch (_) {
      return 'Could not request an image from Firebase.';
    }
  }

  String _authErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'invalid-credential':
      case 'user-not-found':
      case 'wrong-password':
        return 'No account matches those credentials.';
      case 'network-request-failed':
        return 'Could not connect to Firebase. Try again.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      default:
        return error.message ?? 'Firebase authentication failed.';
    }
  }

  String _firebaseAuthExceptionMessage(FirebaseAuthException error) {
    final message = error.message;
    if (message == null || message.isEmpty) {
      return 'FirebaseAuthException(${error.code})';
    }

    return 'FirebaseAuthException(${error.code}): $message';
  }

  @override
  Widget build(BuildContext context) {
    return SmartBoxScope(
      model: _model,
      onSendLidCommand: _sendLidCommand,
      onRegisterDevice: _registerDevice,
      onSelectDevice: _selectDevice,
      onSetSecurityMode: _setSecurityMode,
      onRequestImageCapture: _requestImageCapture,
      child: MaterialApp(
        key: ValueKey(_signedIn),
        title: 'Smart Drop-Off Box',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: AppColors.background,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.navy,
            brightness: Brightness.light,
          ),
          textTheme: const TextTheme(
            headlineLarge: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
              height: 1.05,
            ),
            headlineMedium: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
            titleLarge: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
            titleMedium: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
            bodyLarge: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.muted,
              height: 1.35,
            ),
            bodyMedium: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.muted,
              height: 1.35,
            ),
          ),
        ),
        home: _signedIn
            ? HomeScreen(onSignOut: _signOut, onSendLidCommand: _sendLidCommand)
            : LoginScreen(onSignIn: _signIn, onRegister: _register),
      ),
    );
  }
}
