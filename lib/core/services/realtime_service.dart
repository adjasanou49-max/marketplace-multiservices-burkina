import 'package:supabase_flutter/supabase_flutter.dart';
class RealtimeService {
 final Map<String,RealtimeChannel> _channels={};
 RealtimeChannel? subscribeTable({required String key,required String table,required void Function(Map<String,dynamic>) onChange,String? column,String? value}){
  try{
   final client=Supabase.instance.client;final channel=client.channel(key);
   final callback=(PostgresChangePayload p)=>onChange(Map<String,dynamic>.from(p.newRecord.isNotEmpty?p.newRecord:p.oldRecord));
   final configured=column!=null&&value!=null
    ?channel.onPostgresChanges(event:PostgresChangeEvent.all,schema:'public',table:table,filter:PostgresChangeFilter(type:PostgresChangeFilterType.eq,column:column,value:value),callback:callback)
    :channel.onPostgresChanges(event:PostgresChangeEvent.all,schema:'public',table:table,callback:callback);
   configured.subscribe();_channels[key]=configured;return configured;
  }catch(_){return null;}
 }
 Future<void> dispose() async {if(_channels.isEmpty)return;final client=Supabase.instance.client;for(final c in _channels.values){await client.removeChannel(c);}_channels.clear();}
}