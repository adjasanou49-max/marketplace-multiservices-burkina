# Phase 50 — Audit et fondation technique

## État constaté

Le backend Supabase de Marketplace Multiservices Burkina contient déjà les briques métier principales : utilisateurs et rôles, vendeurs et boutiques, catalogue, catégories, variantes, médias, inventaire, paniers, commandes, colis, livraison, géolocalisation, paiements, commissions, remboursements, litiges, messagerie, restaurants, transport, mécaniciens, services, achats groupés et modules dynamiques.

Le dépôt Flutter contenait initialement quelques écrans métier isolés. Plusieurs imports pointaient vers des fichiers inexistants et plusieurs routes utilisées par l’espace vendeur n’étaient pas déclarées.

## Corrections de cette phase

- socle Flutter : pubspec, analyse, main et application;
- configuration Supabase par dart-define sans secret serveur dans le client;
- navigation centrale;
- modules dynamiques activés depuis le backend;
- catalogue paginé;
- catégories persistantes pendant le défilement;
- authentification de base;
- panier client;
- RPC serveur sécurisé pour ajouter au panier et modifier une quantité;
- correction de la signature RPC create_service_request;
- routes vendeur présentes;
- CI GitHub avec analyse et tests.

## Décision logistique

Le calcul du tarif de livraison reste côté serveur. Le client ne doit jamais recalculer le montant final ni faire confiance à un montant libre envoyé par le téléphone.

Le schéma serveur dispose déjà de routes, arrêts, colis, affectations, événements et règles de tarification. Cette séparation permet de gérer une commande multi-boutiques avec un seul devis de livraison côté client, tout en conservant le suivi de chaque colis.

## Médias

Les buckets product-media et shop-media restent privés. Le client ne fabrique pas d'URL publiques à partir des chemins de stockage.

## Reste pour la prochaine phase

- checkout complet;
- affichage du devis de livraison avant paiement;
- suivi GPS temps réel;
- écrans opérationnels restaurants, transport, mécaniciens et expiration;
- administration complète;
- notifications push;
- messagerie temps réel;
- paiement opérateur entièrement branché;
- espace vendeur complet;
- signatures d'URL médias et optimisation des médias;
- revue sécurité/PostGIS finale.

## Risque restant

Supabase signale une alerte sur la table PostGIS spatial_ref_sys exposée dans le schéma public. Cette alerte doit être traitée séparément avec prudence pour éviter de casser les fonctions géospatiales utilisées par la livraison.
