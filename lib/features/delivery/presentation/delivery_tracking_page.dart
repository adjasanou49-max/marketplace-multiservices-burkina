import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/delivery_tracking_repository.dart';

class DeliveryTrackingPage extends StatefulWidget {
  const DeliveryTrackingPage({super.key,required this.orderId,required this.courierId});
  final String orderId;
  final String courierId;
  @override State<DeliveryTrackingPage> createState()=>_DeliveryTrackingPageState();
}
class _DeliveryTrackingPageState extends State<DeliveryTrackingPage>{
  List<Map<String,dynamic>> locations=[];
  RealtimeChannel? channel;
  bool loading=true;
  @override void initState(){super.initState();_init();}
  Future<void> _init() async {
    final repo=DeliveryTrackingRepository(Supabase.instance.client);
    try{
      locations = await repo.recentLocations(
        orderId: widget.orderId,
        courierId: widget.courierId,
      );
      channel = await repo.subscribe(
        orderId: widget.orderId,
        courierId: widget.courierId,
        onLocation: (value) {
          if (mounted) {
            setState(() {
              locations = [value, ...locations];
              if (locations.length > 50) locations.removeLast();
            });
          }
        },
      );
    }catch(_){
      if(mounted)setState(()=>locations=[]);
    }finally{
      if(mounted)setState(()=>loading=false);
    }
  }
  @override void dispose(){final current=channel;if(current!=null)Supabase.instance.client.removeChannel(current);super.dispose();}
  @override Widget build(BuildContext context){
    final latest=locations.isEmpty?null:locations.first;
    final shortOrder=widget.orderId.length>8?widget.orderId.substring(0,8):widget.orderId;
    return Scaffold(appBar:AppBar(title:const Text('Suivi de livraison')),body:Column(children:[
      Expanded(child:Container(color:Theme.of(context).colorScheme.surfaceContainerHighest,child:Center(child:Column(mainAxisSize:MainAxisSize.min,children:[
        const Icon(Icons.location_on,size:72),
        Text(latest==null?'Position en attente':'Livreur en déplacement'),
        if(latest!=null)Text('Dernière mise à jour: ${latest['recorded_at']}'),
      ])))),
      Card(child:ListTile(leading:const Icon(Icons.local_shipping_outlined),title:Text('Commande #$shortOrder'),subtitle:Text(loading?'Connexion au suivi GPS…':locations.isEmpty?'Position indisponible':'GPS actif'))),
      Padding(padding:const EdgeInsets.all(16),child:LinearProgressIndicator(value:locations.isEmpty?null:.75)),
    ]));
  }
}
