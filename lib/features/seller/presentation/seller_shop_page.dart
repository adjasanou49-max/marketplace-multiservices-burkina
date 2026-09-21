import 'package:flutter/material.dart';

class SellerShopPage extends StatelessWidget {
  const SellerShopPage({super.key,required this.shop});
  final Map<String,dynamic> shop;
  @override Widget build(BuildContext context){
    return Scaffold(appBar:AppBar(title:Text(shop['name'] as String? ?? 'Ma boutique')),body:ListView(
      padding:const EdgeInsets.all(16),children:[
        CircleAvatar(radius:44,child:Text((shop['name'] as String? ?? 'B').substring(0,1).toUpperCase())),
        const SizedBox(height:16),
        Text(shop['name'] as String? ?? 'Ma boutique',style:Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height:8),
        Text(shop['description'] as String? ?? 'Aucune description'),
        const SizedBox(height:20),
        ListTile(leading:const Icon(Icons.location_on_outlined),title:Text(shop['address'] as String? ?? 'Adresse non renseignée')),
        ListTile(leading:const Icon(Icons.phone_outlined),title:Text(shop['phone'] as String? ?? 'Téléphone non renseigné')),
      ]));
  }
}