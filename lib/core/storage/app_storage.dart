import 'package:supabase_flutter/supabase_flutter.dart';

class AppStorage {
  SupabaseStorageClient? get client {
    try {
      return Supabase.instance.client.storage;
    } catch (_) {
      return null;
    }
  }
}
