import 'package:equatable/equatable.dart';
import '../data/models/post_model.dart';

class FeedState extends Equatable {
  final List<PostModel> posts;
  final bool isLoading;
  final bool hasMore;

  const FeedState({
    this.posts = const [],
    this.isLoading = false,
    this.hasMore = true,
  });

  FeedState copyWith({
    List<PostModel>? posts,
    bool? isLoading,
    bool? hasMore,
  }) {
    return FeedState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
    );
  }

  @override
  List<Object> get props => [posts, isLoading, hasMore];
}
