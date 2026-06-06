// File generated from android/app/google-services.json for this Firebase app.
// Re-run `flutterfire configure` if you add iOS, web, macOS, or Windows apps.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'Firebase options are not configured for web. Run flutterfire configure '
        'after adding a web app to the Firebase project.',
      );
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        throw UnsupportedError(
          'Firebase options are only configured for Android. Run flutterfire '
          'configure after adding this platform to the Firebase project.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAAPkkHxoGA2zn2A-JV89O0hgsev5HHL74',
    appId: '1:1095281113336:android:604b7075e098e06ae6e30d',
    messagingSenderId: '1095281113336',
    projectId: 'smart-drop-off-box',
    databaseURL:
        'https://smart-drop-off-box-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'smart-drop-off-box.firebasestorage.app',
  );
}
