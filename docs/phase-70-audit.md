# Phase 70 — intégration opérationnelle et durcissement

## Fonctionnalités ajoutées

- localisation appareil pour les demandes mécanicien;
- partage de position du livreur par intervalle;
- lecture de la dernière position du livreur;
- rafraîchissement et événements temps réel pour livraison;
- réservations transport sécurisées;
- séparation réservation / émission du billet;
- affichage des restaurants, menus et plats;
- messagerie utilisateur avec conversation support administration;
- lecture temps réel des messages;
- notifications temps réel;
- suivi temps réel des paiements;
- favoris produits et boutiques suivies;
- tableau de bord administration et activation des modules;
- tableau de bord vendeur;
- produits vendeur et stock initial;
- commandes vendeur;
- finance vendeur, ledger, commissions et retraits;
- filtre serveur des produits arrivant à expiration entre 5 et 30 jours;
- balayage vertical pour changer de type de catégories;
- affichage des médias produits privés via URL Storage signée.

## Corrections d’intégrité métier

Le checkout recalcule le tarif de livraison côté serveur au lieu de faire confiance au montant fourni par le téléphone.

Les demandes client de mécanicien, service et transport sont en lecture seule côté client ; les changements d’état sensibles passent par des RPC.

La création d’un produit vendeur et son inventaire initial sont effectués par une RPC propriétaire.

Le retrait vendeur vérifie l’appartenance du vendeur au compte connecté.

L’administration possède maintenant une politique de lecture séparée lui permettant de voir aussi les modules désactivés afin de pouvoir les réactiver.

La messagerie support ne permet plus à un utilisateur de s’ajouter arbitrairement à une conversation.

Les fonctions de localisation livreur contrôlent le rôle COURIER, l’utilisateur appelant et les coordonnées.

## Vérifications effectuées

- présence de la branche main;
- présence des routes critiques dans le routeur;
- contrôle des permissions des RPC utilisées par le front;
- contrôle RLS des surfaces transport, restaurants, panier, commandes, paiements, favoris et vendeur;
- revue Supabase Security Advisor.

## Limites restant à traiter avant production

Le dépôt ne contient toujours pas les runners natifs Android/iOS du projet initial. Les permissions natives de géolocalisation doivent donc être ajoutées lors de la génération des plateformes.

Les clés des fournisseurs de paiement et les webhooks de confirmation n’ont pas été inventés. Le front suit le statut de paiement déjà enregistré en base ; l’intégration fournisseur réelle reste à configurer avec les comptes marchands.

Supabase signale toujours l’alerte PostGIS spatial_ref_sys et les fonctions st_estimatedextent exposées par l’extension. Une modification aveugle de l’extension serait risquée pour la géolocalisation et n’a pas été effectuée.

L’analyse locale complète avec Flutter n’a pas pu être exécutée dans cette session car le SDK Flutter n’est pas installé dans l’environnement d’exécution. La CI GitHub est présente pour faire cette validation sur le runner.
