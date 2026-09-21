# Paiements réels

## Architecture

- Flutter ne contient aucune clé opérateur.
- La création de session passe par des Supabase Edge Functions authentifiées.
- Wave utilise son Checkout API et un webhook signé HMAC.
- Orange Money et Moov Money au Burkina passent par CinetPay Collect, qui documente actuellement ces deux opérateurs au Burkina.
- Les webhooks vérifient la signature, puis interrogent le fournisseur avant de modifier le paiement local.
- `payments` reste la source d’état interne et une commande n’est marquée `PAID` qu’après confirmation serveur.

## Secrets Supabase Edge Functions

### Wave

`WAVE_API_KEY`
`WAVE_SIGNING_SECRET` (si la clé Wave est configurée pour signer les requêtes)
`WAVE_WEBHOOK_SECRET`

Les URLs de succès/erreur peuvent utiliser la fonction `payment-return`.

Webhook Wave :
`https://dzhhsoikzxibmngjzcch.supabase.co/functions/v1/wave-payment-webhook`

### CinetPay

`CINETPAY_API_KEY`
`CINETPAY_SITE_ID`
`CINETPAY_SECRET_KEY`

URL de retour :
`https://dzhhsoikzxibmngjzcch.supabase.co/functions/v1/payment-return?status=success`

URL de notification :
`https://dzhhsoikzxibmngjzcch.supabase.co/functions/v1/cinetpay-webhook`

CinetPay exige la vérification serveur de la transaction après notification. Les montants XOF doivent être des multiples de 5.

## Sécurité

Aucune clé fournisseur ne doit être placée dans Flutter ou commitée dans Git. Les secrets doivent rester dans les secrets Supabase Edge Functions.

## Production

L’activation réelle dépend de l’ouverture et de la validation des comptes marchands chez les fournisseurs.