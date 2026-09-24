String userFacingError(Object? error) {
  final message = error?.toString().toLowerCase() ?? '';
  if (message.contains('not_authenticated') ||
      (message.contains('auth') && message.contains('session'))) {
    return 'Votre session a expiré. Veuillez vous reconnecter.';
  }
  if (message.contains('not_authorized') ||
      message.contains('unauthorized') ||
      message.contains('forbidden') ||
      message.contains('admin_required') ||
      message.contains('permission')) {
    return 'Action non autorisée.';
  }
  if (message.contains('not_owned') ||
      message.contains('payment_not_owned') ||
      message.contains('seller_not_owned')) {
    return 'Cette ressource ne vous appartient pas.';
  }
  if (message.contains('insufficient') ||
      message.contains('out_of_stock') ||
      message.contains('stock')) {
    return 'Stock ou solde insuffisant.';
  }
  if (message.contains('payment') ||
      message.contains('cinetpay') ||
      message.contains('wave')) {
    return 'Le paiement n’a pas pu être traité. Veuillez réessayer.';
  }
  if (message.contains('network') ||
      message.contains('timeout') ||
      message.contains('socket')) {
    return 'Connexion impossible. Vérifiez votre réseau et réessayez.';
  }
  return 'Une erreur est survenue. Veuillez réessayer.';
}
