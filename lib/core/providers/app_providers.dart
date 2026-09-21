import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/supabase_client.dart';
import '../storage/app_storage.dart';
import '../services/realtime_service.dart';

final supabaseClientProvider = Provider<SupabaseClientProvider>(
  (ref) => SupabaseClientProvider(),
);

final appStorageProvider = Provider<AppStorage>((ref) => AppStorage());

final realtimeServiceProvider = Provider<RealtimeService>((ref) {
  final service = RealtimeService();
  ref.onDispose(service.dispose);
  return service;
});
