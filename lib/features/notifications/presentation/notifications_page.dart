import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/repository_providers.dart';
import '../data/notification_repository.dart';

final notificationRepositoryProvider=Provider<NotificationRepository?>((ref){
 final c=ref.watch(supabaseProvider); return c==null?null:NotificationRepository(c);
});
final notificationsProvider=FutureProvider((ref) async {
 final r=ref.watch(notificationRepositoryProvider); return r==null?const []:r.mine();
});

class NotificationsPage extends ConsumerWidget {
 const NotificationsPage({super.key});
 @override Widget build(BuildContext context,WidgetRef ref){
  final state=ref.watch(notificationsProvider);
  return Scaffold(appBar:AppBar(title:const Text('Notifications')),body:state.when(
   loading:()=>const Center(child:CircularProgressIndicator()),
   error:(e,_)=>Center(child:Text('Erreur : $e')),
   data:(items)=>items.isEmpty?const Center(child:Text('Aucune notification')):ListView.separated(
    padding:const EdgeInsets.all(12),itemCount:items.length,separatorBuilder:(_,__)=>const Divider(),
    itemBuilder:(_,i){final n=items[i];return ListTile(
      leading:const Icon(Icons.notifications_outlined),
      title:Text(n['title'] as String? ?? 'Notification'),
      subtitle:Text(n['body'] as String? ?? ''),
    );}))
  );
 }
}