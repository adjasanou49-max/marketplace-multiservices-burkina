# Phase 80 — expansion métier, sécurité et validation

## Ajouts

- 16 verticales métier maintenant exposées par des routes réelles : mobilité, location de véhicules, immobilier, hébergement, événements, emplois, professionnels, agriculture, fret, santé, beauté, services à domicile, numérique, formations, créatifs et colis.
- création sécurisée des demandes de trajet, fret et colis;
- réservations sécurisées pour événements, véhicules et hébergements;
- candidatures emploi et inscriptions formation;
- commandes de services numériques;
- rendez-vous beauté et demandes à domicile;
- suivi colis par code de tracking avec historique limité aux données logistiques nécessaires;
- affichage de la position du livreur sur carte avec attribution OpenStreetMap;
- gestion vendeur : boutique, profil, coupons, promotions, clients, avis, statistiques, finance;
- gestion administrateur : comptes, blocage/réactivation et activation d’associés après paiement vérifié;
- détail de commande avec retours, litiges, avis et accès au suivi livraison;
- tests de cohérence de configuration des verticales.

## Durcissement Supabase

Les mutations sensibles de commandes, avis, retours, litiges, coupons, promotions, boutique, profil vendeur, fret, colis et modules passent par des RPC qui vérifient le propriétaire ou le rôle.

Les données des acheteurs ne sont pas exposées au tableau de bord vendeur. Le suivi d’un colis ne renvoie pas les coordonnées personnelles du destinataire.

Les politiques SELECT dupliquées sur les surfaces concernées ont été regroupées afin de réduire les évaluations RLS inutiles.

## Vérification

La CI GitHub est utilisée pour flutter analyze et flutter test. Plusieurs anciens runs ont échoué sur des erreurs intermédiaires qui ont ensuite été corrigées. Le run associé au dernier commit doit être considéré comme la référence finale lorsqu’il est terminé.

Le SDK Flutter n’est pas installé dans l’environnement de travail courant, donc aucune analyse locale n’est déclarée comme réussie.

## Points production encore distincts

Les plateformes natives Android/iOS doivent être générées/configurées pour les permissions de localisation.

Les intégrations Orange Money, Wave et Moov Money nécessitent les comptes marchands, secrets et webhooks réels. L’application ne simule pas ces accès.

PostGIS reste dans le schéma public car l’extension est non-relocatable. L’avertissement spatial_ref_sys et l’exposition des fonctions st_estimatedextent restent à traiter avec une migration d’extension contrôlée, sans casser la géolocalisation.
