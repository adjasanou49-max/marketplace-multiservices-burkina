# Phase 50 — Audit et fondation technique

## État constaté

Le backend Supabase de Marketplace Multiservices Burkina contient déjà les briques métier principales : utilisateurs et rôles, vendeurs et boutiques, catalogue, catégories, variantes, médias, inventaire, paniers, commandes, colis, livraison, géolocalisation, paiements, commissions, remboursements, litiges, messagerie, restaurants, transport, mécaniciens, services, achats groupés et modules dynamiques.

Le dépôt Flutter contenait initialement quelques écrans métier isolés. Plusieurs imports pointaient vers des fichiers inexistants et plusieurs routes utilisées par l’espace vendeur n’étaient pas déclarées.

## Corrections de cette phase

- socle Flutter : pubspec, analyse, main et application;
- configuration Supabase par dart-define sans secret serveur dans le client;
- navigation centrale;
- routes de modules déclarées;
- modules dynamiques activés depuis le backend;
- catalogue paginé;
- catégories persistantes pendant le défilement;
- catégories affichées en pastilles rondes;
- authentification de base;
- panier client;
- ajout au panier contrôlé par RPC;
- modification de quantité contrôlée par RPC et stock;
- adresses de livraison propres au client;
- calcul du devis de livraison côté serveur;
- checkout avec idempotence;
- création d’intention de paiement Orange Money, Wave ou Moov Money;
- historique des commandes;
- correction de la signature RPC create_service_request;
- routes vendeur présentes;
- CI GitHub avec analyse et tests.

## Sécurité et intégrité métier

Le montant de livraison fourni par le téléphone n'est plus la source de vérité. Le checkout recalcule la livraison côté serveur à partir du panier et de l'adresse avant de déterminer le total de la commande.

Les fonctions add_to_cart et set_cart_item_quantity sont exécutables uniquement par authenticated. Elles vérifient le compte, le produit actif, l'expiration et le stock disponible.

Les buckets product-media et shop-media restent privés. Le client ne contourne pas cette protection en transformant un chemin Storage en URL publique.

Les fonctions sensibles de paiement, commande et administration restent côté Supabase.

## Logistique multi-boutiques

Le devis serveur tient compte de la distance et du nombre de boutiques distinctes présentes dans le panier. Une commande peut donc regrouper plusieurs fournisseurs sans créer un tarif de livraison calculé indépendamment par chaque boutique.

## Reste pour la prochaine phase

- sélection GPS réelle dans l'application et permissions de localisation;
- carte et suivi du livreur en temps réel;
- écran checkout avec détail complet des colis par boutique;
- confirmation réelle du paiement opérateur;
- écrans opérationnels restaurants, transport, mécaniciens et expiration;
- administration complète;
- notifications push;
- messagerie temps réel;
- espace vendeur complet;
- signatures d'URL médias et optimisation des médias;
- revue sécurité/PostGIS finale.

## Risque restant

Supabase signale une alerte sur la table PostGIS spatial_ref_sys exposée dans le schéma public ainsi que des extensions installées dans public. Je ne force pas leur déplacement pendant ce jalon : la géolocalisation de la livraison dépend de PostGIS et une modification aveugle pourrait casser les fonctions existantes.

Les fonctions PostGIS st_estimatedextent restent également signalées par le linter. Cette correction sera traitée avec une stratégie d'extension/schema séparée avant production.
