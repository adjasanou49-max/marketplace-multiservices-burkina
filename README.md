# Marketplace Multiservices Burkina

Application mobile Flutter pour marketplace locale et services associés au Burkina Faso.

## Stack

Flutter stable 3.47+, Dart 3.12+, Supabase, Riverpod, go_router et Geolocator.

## Fonctionnel jusqu’au jalon 70

Le projet possède maintenant le socle de navigation, authentification, catalogue paginé, catégories persistantes et circulaires, balayage vertical entre types de catégories, panier sécurisé, checkout avec recalcul serveur de livraison, intentions de paiement, suivi de paiement, historique de commandes, suivi livraison, localisation livreur, mécaniciens, transport, restaurants, services, achats groupés, favoris/suivis, notifications, messagerie support, administration et espace vendeur produits/stock/commandes/finance.

## Sécurité

Les opérations sensibles restent côté Supabase avec contrôles d’appartenance, RLS et RPC.

Ne jamais placer une clé service_role dans l’application mobile.

## Lancer localement

flutter pub get

flutter run --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY

## Validation

Le workflow GitHub Actions exécute flutter analyze et flutter test.

Le SDK Flutter n’étant pas installé dans l’environnement de cette session, ces commandes n’ont pas été exécutées localement ici.
