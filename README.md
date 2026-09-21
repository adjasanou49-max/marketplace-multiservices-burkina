# Marketplace Multiservices Burkina

Application mobile Flutter pour marketplace locale et services associés au Burkina Faso.

## Stack

Flutter stable 3.47+, Dart 3.12+, Supabase, Riverpod et go_router.

## Lancer localement

flutter pub get

flutter run --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY

Ne jamais placer une clé service_role dans l’application mobile.

## Première phase intégrée

Le client Flutter possède maintenant un socle de navigation, authentification, catalogue paginé, catégories persistantes, panier, achats groupés, services et modules dynamiques.

Les fonctions sensibles comme le calcul de livraison, le checkout, les changements d'état de commande, les paiements, les commissions et l'administration restent côté Supabase.
