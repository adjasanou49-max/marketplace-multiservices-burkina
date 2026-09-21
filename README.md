# Marketplace Multiservices Burkina

Application mobile Flutter pour marketplace locale et services associés au Burkina Faso.

## Stack

Flutter stable 3.47+, Dart 3.12+, Supabase, Riverpod, go_router et Geolocator.

## État fonctionnel — jalon 127

Le projet couvre maintenant le socle de navigation, authentification, catalogue paginé, catégories persistantes et circulaires, balayage vertical entre types de catégories, panier sécurisé, checkout avec recalcul serveur des frais, intentions de paiement, historique de commandes, suivi livraison avec position livreur, mécaniciens avec disponibilités et congés planifiés, transport avec réservation/ticket, restaurants, services, achats groupés, favoris/suivis, notifications Realtime + push FCM, messagerie support, administration, gestion des comptes et associés, ainsi qu’un espace vendeur pour boutique, produits/stock, commandes, coupons, promotions, clients, avis, statistiques, paramètres et finance. Les modules dynamiques incluent également trajets, location de véhicules, immobilier, hébergement, événements, emploi, professionnels, agriculture, fret, santé, beauté, services à domicile, numérique, formation, créatif et colis.

## Sécurité

Les opérations sensibles restent côté Supabase avec contrôles d’appartenance, RLS et RPC.

Ne jamais placer une clé service_role dans l’application mobile.

## Lancer localement

Générer les plateformes natives une première fois si les dossiers `android/` et `ios/` ne sont pas présents :

flutter create . --platforms=android,ios

Puis :

flutter pub get

flutter run --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY

## Validation

Le workflow GitHub Actions exécute flutter analyze et flutter test.

Le SDK Flutter n’étant pas installé dans l’environnement de cette session, ces commandes n’ont pas été exécutées localement ici.

## Base de données

Les changements récents sont désormais suivis dans `supabase/migrations/`. La base Supabase distante contient déjà l’historique des migrations appliquées jusqu’au jalon 127.
