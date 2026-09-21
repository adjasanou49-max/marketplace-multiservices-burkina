import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/repository_providers.dart';
import '../data/messaging_repository.dart';

final messagingRepositoryProvider=Provider<MessagingRepository?>((ref){
 final c=ref.watch(supabaseProvider); return c==null?null:MessagingRepository(c);
});
final conversationsProvider=FutureProvider((ref) async {
 final r=ref.watch(messagingRepositoryProvider); return r==null?const []:r.conversations();
});

class MessagesPage extends ConsumerWidget {
 const MessagesPage({super.key});
 @override Widget build(BuildContext context,WidgetRef ref){
  final state=ref.watch(conversationsProvider);
  return Scaffold(appBar:AppBar(title:const Text('Messages')),body:state.when(
   loading:()=>const Center(child:CircularProgressIndicator()),
   error:(e,_)=>Center(child:Text('Erreur : $e')),
   data:(items)=>items.isEmpty?const Center(child:Text('Aucune conversation')):ListView.builder(
    itemCount:items.length,itemBuilder:(_,i){
     final c=items[i]['conversations']; final m=c is Map?Map<String,dynamic>.from(c):<String,dynamic>{};
     return ListTile(leading:const Icon(Icons.chat_bubble_outline),title:Text(m['title'] as String? ?? 'Conversation'),subtitle:Text(m['created_at'] as String? ?? ''));
    }))
  );
 }
}