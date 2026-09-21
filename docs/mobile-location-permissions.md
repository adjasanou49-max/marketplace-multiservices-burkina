# Localisation mobile

La couche Dart utilise geolocator 14.0.3 pour obtenir la position courante.

Avant une compilation Android/iOS, les plateformes natives doivent déclarer leurs permissions de localisation conformément à la documentation de Geolocator :

- Android : permission de localisation au runtime et déclaration dans le manifeste;
- iOS : description de l’usage de la localisation dans Info.plist;
- pour le suivi en arrière-plan, ajouter uniquement les permissions et modes réellement nécessaires à la version de l’application.

Le dépôt actuel était un squelette Flutter sans dossiers Android/iOS. Cette configuration native devra donc être appliquée lorsque les runners mobiles seront ajoutés.

Le client n’envoie une position à record_courier_location qu’après authentification et la base vérifie le rôle COURIER.
