import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/providers/repository_providers.dart';
import '../data/messaging_repository.dart';
import '../data/message_sender_repository.dart';

class ConversationPage extends ConsumerStatefulWidget {
 const ConversationPage({super.key,required this.conversationId}); final String conversationId;
 @override ConsumerState<ConversationPage> createState()=>_ConversationPageState();
}
class _ConversationPageState extends ConsumerState<ConversationPage>{
 final controller=TextEditingController(); StreamSubscription? sub; List<Map<String,dynamic>> messages=[];
 @override void initState(){super.initState();_load();_subscribe();}
 Future<void> _load() async {final c=ref.read(supabaseProvider);if(c==null)return;final rows=await MessagingRepository(c).messages(widget.conversationId);if(mounted)setState(()=>messages=rows);}
 void _subscribe(){final c=ref.read(supabaseProvider);if(c==null)return;final channel=c.channel('conversation:${widget.conversationId}');channel.onPostgresChanges(event:PostgresChangeEvent.insert,schema:'public',table:'messages',filter:PostgresChangeFilter(type:PostgresChangeFilterType.eq,column:'conversation_id',value:widget.conversationId),callback:(p){if(mounted)setState(()=>messages.add(Map<String,dynamic>.from(p.newRecord)));}).subscribe();}
 @override void dispose(){controller.dispose();super.dispose();}
 @override Widget build(BuildContext context){return Scaffold(appBar:AppBar(title:const Text('Conversation')),body:Column(children:[Expanded(child:ListView.builder(reverse:false,itemCount:messages.length,itemBuilder:(_,i)=>ListTile(title:Text(messages[i]['body'] as String? ?? ''),subtitle:Text(messages[i]['created_at'].toString())))),SafeArea(child:Row(children:[Expanded(child:TextField(controller:controller,decoration:const InputDecoration(hintText:'Écrire un message'))),IconButton(icon:const Icon(Icons.send),onPressed:()async{final c=ref.read(supabaseProvider);if(c==null)return;await MessageSenderRepository(c).send(conversationId:widget.conversationId,body:controller.text);controller.clear();})]))]));}
}