import 'package:flutter_test/flutter_test.dart';
import 'package:supabase/supabase.dart';
import 'package:flutter_high_performance_feed/core/constants/constants.dart';
import 'package:flutter_high_performance_feed/features/feed/data/models/post_model.dart';

void main() {
  test('fetch posts', () async {
    final client = SupabaseClient(
      AppConstants.supabaseUrl, 
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFrcWVrd3Vwa2dod2R1eG95enZjIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4MTkzMDQ1MywiZXhwIjoyMDk3NTA2NDUzfQ.jA8J0L7O3E7rpA-HsvNlYKj9rfHlagC1ZLShl7NlvNY'
    );
    
    try {
      final response = await client.from('posts').select('*').count(CountOption.exact);
      print('Raw response: $response');
      
      final rows = await client.from('posts').select();
      print('Rows: ${rows.length}');
      if (rows.isNotEmpty) {
        print('First row: ${rows.first}');
        try {
          final post = PostModel.fromJson(rows.first);
          print('Successfully mapped first post: $post');
        } catch (e, stack) {
          print('MAPPING ERROR: $e');
          print(stack);
        }
      }
    } catch(e) {
      print('Error: $e');
    }
  });
}
