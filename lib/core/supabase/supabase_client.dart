import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/constants.dart';

class SupabaseConfig {
  /// Initializes the Supabase client.
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
    );
  }

  /// Singleton accessor for the Supabase client.
  static SupabaseClient get client => Supabase.instance.client;
}
