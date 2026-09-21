# Android et iOS natifs

## Android

Le projet utilise le template Flutter 3.47.x et un identifiant d’application stable :

`com.marketplaceburkina.marketplace_multiservices_burkina`

Le niveau minimal Android est volontairement fixé à API 23 pour rester compatible avec les SDK Firebase actuels utilisés par l’application.

Permissions configurées :
- Internet
- localisation précise
- localisation approximative
- notifications Android 13+

Deep link configuré :
`marketplaceburkina://orders/<id>`
`marketplaceburkina://notifications`

### Signature

Le fichier `android/key.properties.example` sert de modèle. Le vrai `android/key.properties` et le keystore sont exclus de Git.
Pour la publication Play Store, créer une clé d’upload et conserver le keystore hors du dépôt. Flutter recommande de publier un App Bundle signé et de laisser Play App Signing gérer la clé d’application.

Commandes de production :
`flutter build appbundle`
`flutter build apk --release`

Référence officielle : https://docs.flutter.dev/deployment/android

## iOS

Le runner iOS est configuré en Swift avec Swift Package Manager.
Deployment Target : iOS 15.

Permissions configurées :
- localisation lorsque l’application est utilisée
- localisation toujours/activité de suivi
- mode background remote-notification
- mode background fetch

Deep link configuré :
`marketplaceburkina://orders/<id>`

Entitlements APNs :
`ios/Runner/Runner.entitlements` utilise `$(APS_ENVIRONMENT)` pour permettre Debug/Release.

### Push Apple

Pour recevoir FCM sur iPhone, il faut activer Push Notifications et Background Modes dans Xcode et fournir la clé APNs dans Firebase. Ces étapes exigent le véritable compte Apple Developer et le projet Firebase.

### Publication

`flutter build ipa` produit l’IPA destiné à TestFlight/App Store après configuration du compte Apple et de la signature.

Référence officielle : https://docs.flutter.dev/deployment/ios

## Firebase natif

Les fichiers `google-services.json` et `GoogleService-Info.plist` ne sont pas générés ici car ils dépendent d’un véritable projet Firebase. La procédure officielle est de créer/choisir le projet Firebase puis d’exécuter `flutterfire configure` afin de générer `firebase_options.dart` et d’enregistrer Android/iOS.

Référence officielle : https://firebase.google.com/docs/flutter/setup

## CI

`.github/workflows/native-build.yml` compile :
- Android en release APK
- iOS en release sans signature

Les signatures finales restent volontairement hors GitHub.