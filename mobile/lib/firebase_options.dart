// PLACEHOLDER — este arquivo será SUBSTITUÍDO pelo comando:
//
//   dart pub global activate flutterfire_cli
//   flutterfire configure
//
// executado dentro da pasta mobile/ (ver docs/GUIA_FIREBASE.md).
// Enquanto os valores abaixo forem placeholders, o app abre uma tela
// avisando que o Firebase ainda não foi configurado.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'Este app foi configurado apenas para Android.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'SUBSTITUIR',
    appId: 'SUBSTITUIR',
    messagingSenderId: 'SUBSTITUIR',
    projectId: 'SUBSTITUIR',
    storageBucket: 'SUBSTITUIR',
  );
}
