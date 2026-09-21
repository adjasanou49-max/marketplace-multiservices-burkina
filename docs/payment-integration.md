# Paiements réels

## Architecture

- Flutter ne contient aucune clé opérateur.
- Le checkout est créé côté Supabase Edge Functions avec un JWT utilisateur.
- Flutter ouvre le lien de paiement dans le navigateur externe.
- Wave utilise son Checkout API et un webhook signé HMAC.
- Orange Money et Moov Money au Burkina sont proposés via CinetPay Collect.
- CinetPay reçoit une notification x-www-form-urlencoded signée par x-token, puis le serveur vérifie toujours la transaction via l'API de vérification.
- Une notification WAITING_FOR_CUSTOMER reste en PROCESSING.
- Une tentative Wave checkout.session.payment_failed reste PROCESSING afin de permettre plusieurs tentatives sur la même session.
- Les événements de paiement sont traités par un RPC idempotent qui valide le montant et la devise avant de modifier la commande.

## Fonctions Edge actives

### Création

- create-wave-payment-session-v3
- create-cinetpay-payment-session-v3

Ces deux fonctions exigent un JWT valide.

### Webhooks

- wave-payment-webhook-v3
- cinetpay-webhook-v3

Ces deux fonctions sont publiques au niveau HTTP pour accepter les callbacks fournisseur et valident leur signature avant tout traitement.

### Autres

- payment-return
- execute-payment-refund

execute-payment-refund exige un JWT et vérifie l'autorisation administrateur avant toute exécution.

## Secrets

Les clés suivantes doivent être configurées dans les secrets des Edge Functions Supabase, jamais dans Flutter ni dans Git.

### Wave

- WAVE_API_KEY
- WAVE_WEBHOOK_SECRET
- WAVE_SIGNING_SECRET si la signature des requêtes sortantes est activée
- WAVE_SUCCESS_URL et WAVE_ERROR_URL sont optionnels

Webhook à enregistrer dans le compte marchand Wave :

https://dzhhsoikzxibmngjzcch.supabase.co/functions/v1/wave-payment-webhook-v3

Sans WAVE_SUCCESS_URL/WAVE_ERROR_URL, le code utilise automatiquement payment-return et ajoute la référence de commande.

### CinetPay

- CINETPAY_API_KEY
- CINETPAY_SITE_ID
- CINETPAY_SECRET_KEY
- CINETPAY_RETURN_URL est optionnel

Notification à enregistrer dans le compte marchand CinetPay :

https://dzhhsoikzxibmngjzcch.supabase.co/functions/v1/cinetpay-webhook-v3

Le code utilise MOBILE_MONEY comme univers de paiement afin de proposer les opérateurs mobile money disponibles sur le guichet.

## Montants

Tous les montants envoyés à CinetPay sont en XOF. Le montant est un entier positif et doit être un multiple de 5. Le code refuse le checkout si cette règle n'est pas respectée; il ne modifie jamais silencieusement le total de la commande.

## Remboursements

- Le client peut demander un remboursement partiel ou total depuis une commande livrée.
- Le cumul des demandes actives et terminées ne peut pas dépasser le montant réellement payé.
- Une demande passe par REQUESTED puis une validation admin.
- Pour Wave, execute-payment-refund appelle le endpoint officiel de remboursement de la session Checkout et ne marque le remboursement local comme terminé qu'après réponse fournisseur.
- Pour CinetPay, le checkout public actuel ne fournit pas un endpoint de remboursement direct documenté comparable à Wave. L'application conserve donc la demande dans le workflow admin et permet de confirmer manuellement le remboursement après exécution par le canal CinetPay prévu par le contrat.
- Un remboursement terminé met à jour le paiement en PARTIALLY_REFUNDED ou REFUNDED et répartit le débit du ledger vendeur entre les boutiques de la commande.

## Activation production

Le code d'intégration est en place, mais les comptes marchands/KYC, clés API, secrets de signature et URLs webhook doivent être fournis par les comptes fournisseur avant tout paiement réel.

Aucun secret réel ne doit être commit dans le dépôt.