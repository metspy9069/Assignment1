import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/supabase/supabase_client.dart';
import '../models/post_model.dart';

class FeedRepository {
  final SupabaseClient _supabaseClient;
  static const int _pageSize = 10;
  static const String _tableName = 'posts';

  FeedRepository({SupabaseClient? supabaseClient}) 
      : _supabaseClient = supabaseClient ?? SupabaseConfig.client;

  Future<List<PostModel>> fetchPosts({required int offset}) async {
    print('--- REPOSITORY: fetchPosts started with offset $offset ---');
    try {
      final response = await _supabaseClient
          .from(_tableName)
          .select()
          .order('created_at', ascending: false)
          .range(offset, offset + _pageSize - 1);

      print('--- REPOSITORY: Supabase query completed ---');
      
      final responseList = response as List<dynamic>;
      print('--- REPOSITORY: Received ${responseList.length} rows ---');

      final List<PostModel> mappedPosts = [];
      for (var i = 0; i < responseList.length; i++) {
        final data = responseList[i] as Map<String, dynamic>;
        print('--- REPOSITORY: Mapping row $i: $data ---');
        try {
          mappedPosts.add(PostModel.fromJson(data));
        } catch (e) {
          print('--- REPOSITORY ERROR: Failed to map row $i ---');
          print(e);
          rethrow; // Rethrow to fail the whole fetch, or handle individually
        }
      }

      print('--- REPOSITORY: Successfully mapped ${mappedPosts.length} posts ---');
      return mappedPosts;
    } catch (e, stackTrace) {
      // Re-throwing exception to be handled by the caller/provider
      print('--- REPOSITORY ERROR in fetchPosts ---');
      print(e);
      print(stackTrace);
      rethrow;
    }
  }

  Future<void> toggleLike(String postId, String userId) async {
    await _supabaseClient.rpc('toggle_like', params: {
      'p_post_id': postId,
      'p_user_id': userId,
    });
  }
}
