# Notifications push

## Architecture

- Firebase Cloud Messaging (FCM) gère les notifications Android/iOS.
- Le token FCM est enregistré dans notification_devices via register_notification_device.
- Le token est actualisé à chaque rotation FCM.
- Les préférences notification_preferences sont appliquées côté serveur avant l'envoi.
- Une notification insérée dans notifications déclenche automatiquement dispatch-push-notifications via pg_net.
- Supabase Cron relance les notifications non envoyées chaque minute.
- Quand l'application est ouverte, Flutter affiche aussi une notification locale.
- Quand l'application est en arrière-plan ou terminée, le payload FCM contient notification + data pour permettre l'affichage système et la navigation au clic.

## Dépendances

- firebase_core 4.15.0
- firebase_messaging 16.7.0
- flutter_local_notifications 22.3.1

Ces versions correspondent aux versions stables publiées actuellement sur pub.dev. FCM Flutter nécessite firebase_core et les plateformes natives doivent être configurées.

## Configuration Firebase

1. Créer un projet Firebase pour l'application.
2. Ajouter les applications Android et iOS au projet Firebase.
3. Exécuter flutterfire configure depuis la racine du projet pour générer la configuration Flutter officielle.
4. Pour iOS, activer Push Notifications et Remote notifications dans Xcode et téléverser la clé APNs dans Firebase.
5. Pour Android, inclure la configuration Firebase générée pour l'application.
6. Configurer Cloud Messaging API.
7. Créer un compte de service disposant de la permission cloudmessaging.messages.create.
8. Ajouter le JSON du compte de service comme secret Edge Function `FCM_SERVICE_ACCOUNT_JSON`.

## Secrets

Ne jamais committer le JSON du compte de service Firebase.

`FCM_SERVICE_ACCOUNT_JSON` doit rester dans les secrets Supabase Edge Functions.

Le secret interne `push_dispatch_secret` est déjà créé dans Supabase Vault pour les appels Postgres vers l'Edge Function.

## Fonctionnement

Quand une ligne est créée dans notifications :

notifications -> trigger SQL -> pg_net -> dispatch-push-notifications -> FCM -> téléphone.

Si l'envoi échoue, push_attempts et push_error sont conservés. Cron relance les notifications non envoyées jusqu'à 20 tentatives.

## Limitation actuelle

Le code serveur et Flutter sont prêts, mais l'activation réelle sur les téléphones dépend encore du projet Firebase, des fichiers de configuration Android/iOS et du compte de service Firebase. Ces éléments ne peuvent pas être inventés sans créer le projet Firebase réel.