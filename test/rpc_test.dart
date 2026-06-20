import 'package:flutter_test/flutter_test.dart';
import 'package:supabase/supabase.dart';
import 'package:flutter_high_performance_feed/core/constants/constants.dart';

void main() {
  test('rpc test', () async {
    final client = SupabaseClient(AppConstants.supabaseUrl, AppConstants.supabaseAnonKey);
    
    try {
      await client.rpc('toggle_like', params: {
        'p_post_id': '04e17e58-534b-4cac-946b-cfd57a967959', // Using the first post's ID from my previous fetch_test
        'p_user_id': 'user_123',
      });
      print('RPC Succeeded!');
    } catch (e) {
      print('RPC FAILED!');
      print('Exact Exception: $e');
      
      if (e is PostgrestException) {
        print('Postgrest Message: ${e.message}');
        print('Postgrest Code: ${e.code}');
        print('Postgrest Details: ${e.details}');
        print('Postgrest Hint: ${e.hint}');
      }
    }
  });
}
