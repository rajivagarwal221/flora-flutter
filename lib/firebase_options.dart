import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Public Firebase app identifiers. Access is enforced by Authentication and
/// Firestore rules, not by these values.
class FloraFirebaseOptions {
  static FirebaseOptions get current {
    if (kIsWeb) {
      return const FirebaseOptions(
        apiKey: 'AIzaSyC3sFPgI-N8Uqieo23An-KwqKmavfYTSEk',
        appId: '1:686143109566:web:fb63e8d62a87614c60a1ef',
        messagingSenderId: '686143109566',
        projectId: 'flora-411ad',
        authDomain: 'flora-411ad.firebaseapp.com',
        storageBucket: 'flora-411ad.firebasestorage.app',
        measurementId: 'G-JLSFJWNZQJ',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return const FirebaseOptions(
          apiKey: 'AIzaSyBPV-Jkci3Fb8ZRlsXkVQ-ttCJZMFPZOaM',
          appId: '1:686143109566:android:ef23758b0b17216060a1ef',
          messagingSenderId: '686143109566',
          projectId: 'flora-411ad',
          storageBucket: 'flora-411ad.firebasestorage.app',
        );
      default:
        throw UnsupportedError(
            'Flora Firebase is configured for Android and web.');
    }
  }
}
