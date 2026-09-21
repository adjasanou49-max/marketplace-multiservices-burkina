# Marketplace Multiservices Burkina

Application mobile Flutter pour marketplace locale et services associés au Burkina Faso.

## Stack

Flutter stable 3.47+, Dart 3.12+, Supabase, Riverpod et go_router.

## Lancer localement

flutter pub get

flutter run --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY

Ne jamais placer une clé service_role dans l’application mobile.

## Fonctionnel dans le jalon actuel

Navigation centrale, authentification, catalogue paginé, catégories persistantes et rondes, modules dynamiques, panier, adresses de livraison, devis de livraison serveur, checkout idempotent, création d'intention de paiement et historique des commandes.

Les fonctions sensibles comme le calcul de livraison, le checkout, les changements d'état de commande, les paiements, les commissions et l'administration restent côté Supabase.
