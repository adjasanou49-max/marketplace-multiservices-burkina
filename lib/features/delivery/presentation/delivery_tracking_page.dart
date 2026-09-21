import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';

class DeliveryTrackingPage extends ConsumerWidget {
 const DeliveryTrackingPage({super.key,required this.courierId});
 final String courierId;
 @override Widget build(BuildContext context,WidgetRef ref){
  final service=ref.watch(realtimeServiceProvider);
  return Scaffold(appBar:AppBar(title:const Text('Suivi de livraison')),body:Column(
   children:[
    const Expanded(child:Center(child:Icon(Icons.map_outlined,size:96))),
    Padding(padding:const EdgeInsets.all(16),child:Text('Suivi en temps réel du livreur $courierId')),
    const SizedBox(height:16),
   ]));
 }
}