import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/feed_repository.dart';
import 'feed_state.dart';
import '../data/models/post_model.dart';

// Provider for the repository
final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  return FeedRepository();
});

// Notifier Provider for the feed
final feedNotifierProvider = NotifierProvider<FeedNotifier, FeedState>(() {
  return FeedNotifier();
});

class FeedNotifier extends Notifier<FeedState> {
  static const int _pageSize = 10;
  
  late final FeedRepository _repository;
  
  // Maps to track debounce timers and original states per post
  final Map<String, Timer> _likeTimers = {};
  final Map<String, bool> _originalLikeStates = {};
  final Map<String, int> _originalLikeCounts = {};

  @override
  FeedState build() {
    _repository = ref.watch(feedRepositoryProvider);
    
    // Cleanup timers if the provider is disposed
    ref.onDispose(() {
      for (final timer in _likeTimers.values) {
        timer.cancel();
      }
    });
    
    return const FeedState();
  }

  /// Loads the initial set of posts.
  Future<void> loadInitialPosts() async {
    print('--- PROVIDER: loadInitialPosts started ---');
    if (state.isLoading || state.posts.isNotEmpty) {
      print('--- PROVIDER: loadInitialPosts skipped (isLoading: ${state.isLoading}, hasPosts: ${state.posts.isNotEmpty}) ---');
      return;
    }

    state = state.copyWith(isLoading: true);
    print('--- PROVIDER: State updated to isLoading: true ---');

    try {
      final posts = await _repository.fetchPosts(offset: 0);
      print('--- PROVIDER: Fetched ${posts.length} posts ---');
      
      state = state.copyWith(
        posts: posts,
        isLoading: false,
        hasMore: posts.length == _pageSize,
      );
      print('--- PROVIDER: State updated with posts ---');
    } catch (e, stackTrace) {
      print('--- PROVIDER ERROR in loadInitialPosts ---');
      print(e);
      print(stackTrace);
      state = state.copyWith(isLoading: false);
    }
  }

  /// Loads the next page of posts.
  Future<void> loadMorePosts() async {
    print('--- PROVIDER: loadMorePosts started ---');
    if (state.isLoading || !state.hasMore) {
      print('--- PROVIDER: loadMorePosts skipped (isLoading: ${state.isLoading}, hasMore: ${state.hasMore}) ---');
      return;
    }

    state = state.copyWith(isLoading: true);
    print('--- PROVIDER: State updated to isLoading: true ---');

    try {
      final currentOffset = state.posts.length;
      final pageX = (currentOffset ~/ _pageSize) + 1;
      print('Loading page $pageX');
      final newPosts = await _repository.fetchPosts(offset: currentOffset);
      print('--- PROVIDER: Fetched ${newPosts.length} more posts ---');

      state = state.copyWith(
        posts: [...state.posts, ...newPosts],
        isLoading: false,
        hasMore: newPosts.length == _pageSize,
      );
      print('--- PROVIDER: State updated with more posts ---');
    } catch (e, stackTrace) {
      print('--- PROVIDER ERROR in loadMorePosts ---');
      print(e);
      print(stackTrace);
      state = state.copyWith(isLoading: false);
    }
  }

  /// Refreshes the feed entirely.
  Future<void> refreshFeed() async {
    print('--- PROVIDER: refreshFeed started ---');
    if (state.isLoading) {
      print('--- PROVIDER: refreshFeed skipped (isLoading: true) ---');
      return;
    }

    // Reset to loading state, keep existing posts until new ones arrive
    state = state.copyWith(isLoading: true, hasMore: true);
    print('--- PROVIDER: State updated to isLoading: true ---');

    try {
      final posts = await _repository.fetchPosts(offset: 0);
      print('--- PROVIDER: Fetched ${posts.length} posts on refresh ---');

      state = state.copyWith(
        posts: posts,
        isLoading: false,
        hasMore: posts.length == _pageSize,
      );
      print('--- PROVIDER: State updated with refreshed posts ---');
    } catch (e, stackTrace) {
      print('--- PROVIDER ERROR in refreshFeed ---');
      print(e);
      print(stackTrace);
      state = state.copyWith(isLoading: false);
    }
  }

  /// Optimistically toggles a like on a post with debounce protection.
  void toggleLike(String postId, {required void Function(String) onError}) {
    final index = state.posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    final currentPost = state.posts[index];
    final wasLiked = currentPost.isLiked;
    final newLikeCount = wasLiked ? currentPost.likeCount - 1 : currentPost.likeCount + 1;
    
    // 1. Record original state if this is the start of a debounce session
    if (!_originalLikeStates.containsKey(postId)) {
      _originalLikeStates[postId] = wasLiked;
      _originalLikeCounts[postId] = currentPost.likeCount;
    }

    // 2. Optimistic Update (Immediate UI response)
    final updatedPost = currentPost.copyWith(
      isLiked: !wasLiked,
      likeCount: newLikeCount,
    );
    
    final newPosts = List<PostModel>.from(state.posts);
    newPosts[index] = updatedPost;
    state = state.copyWith(posts: newPosts);
    
    // 3. Debounce the server call
    _likeTimers[postId]?.cancel();
    
    _likeTimers[postId] = Timer(const Duration(milliseconds: 500), () async {
      final originalLiked = _originalLikeStates[postId];
      final originalCount = _originalLikeCounts[postId];
      
      // Clean up maps immediately so next taps start a new session
      _originalLikeStates.remove(postId);
      _originalLikeCounts.remove(postId);
      _likeTimers.remove(postId);

      // Get the latest post state after debounce
      final postAfterDebounceIdx = state.posts.indexWhere((p) => p.id == postId);
      if (postAfterDebounceIdx == -1) return;
      
      final postAfterDebounce = state.posts[postAfterDebounceIdx];

      // Only sync if the final state differs from the original state
      if (postAfterDebounce.isLiked != originalLiked) {
        try {
          await _repository.toggleLike(postId, 'user_123');
        } catch (e) {
          // 4. Revert on failure
          final revertIndex = state.posts.indexWhere((p) => p.id == postId);
          if (revertIndex != -1 && originalLiked != null && originalCount != null) {
            final revertedPosts = List<PostModel>.from(state.posts);
            revertedPosts[revertIndex] = revertedPosts[revertIndex].copyWith(
              isLiked: originalLiked,
              likeCount: originalCount,
            );
            state = state.copyWith(posts: revertedPosts);
          }
          onError('Failed to update like. Please check your connection.');
        }
      }
    });
  }
}
