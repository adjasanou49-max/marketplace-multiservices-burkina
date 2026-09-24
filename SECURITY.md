# Security policy

## Principes

Les secrets d’infrastructure, clés de paiement et clés Supabase privées doivent rester dans les variables/secrets du fournisseur d’exécution. Aucune clé `service_role`, clé de paiement, keystore ou certificat privé ne doit être embarqué dans l’application mobile ni commité dans Git.

Les opérations financières, administratives, de livraison, de géolocalisation et de gestion des comptes doivent être autorisées côté serveur. Une validation faite uniquement dans Flutter n’est pas considérée comme une protection.

## Déploiement

Les builds Android de production doivent utiliser un keystore de signature fourni par la CI et ne doivent jamais utiliser une clé de debug.

Les migrations Supabase doivent rester synchronisées entre Git et la base distante. Une modification directe de production doit ensuite être enregistrée dans Git avec le numéro de migration réellement appliqué.

## Incidents

En cas de soupçon de compromission d’un secret, le secret doit être révoqué/rotaté immédiatement, les sessions concernées invalidées et les journaux de sécurité examinés. Ne jamais publier un secret dans une issue, un commit ou un message de debug.

## Modèle de menace

L’application considère comme hostiles : un client modifié, un compte compromis, un appelant REST/RPC direct, un webhook forgé, un appareil rooté/jailbreaké, un développeur disposant d’un accès non approuvé au dépôt et un agent automatisé malveillant.

