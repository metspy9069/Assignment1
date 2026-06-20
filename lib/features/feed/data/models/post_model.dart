import 'package:equatable/equatable.dart';

class PostModel extends Equatable {
  final String id;
  final String mediaThumbUrl;
  final String mediaMobileUrl;
  final String mediaRawUrl;
  final int likeCount;
  final DateTime createdAt;
  final bool isLiked;

  const PostModel({
    required this.id,
    required this.mediaThumbUrl,
    required this.mediaMobileUrl,
    required this.mediaRawUrl,
    required this.likeCount,
    required this.createdAt,
    this.isLiked = false,
  });

  PostModel copyWith({
    String? id,
    String? mediaThumbUrl,
    String? mediaMobileUrl,
    String? mediaRawUrl,
    int? likeCount,
    DateTime? createdAt,
    bool? isLiked,
  }) {
    return PostModel(
      id: id ?? this.id,
      mediaThumbUrl: mediaThumbUrl ?? this.mediaThumbUrl,
      mediaMobileUrl: mediaMobileUrl ?? this.mediaMobileUrl,
      mediaRawUrl: mediaRawUrl ?? this.mediaRawUrl,
      likeCount: likeCount ?? this.likeCount,
      createdAt: createdAt ?? this.createdAt,
      isLiked: isLiked ?? this.isLiked,
    );
  }

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'] as String,
      mediaThumbUrl: json['media_thumb_url'] as String? ?? '',
      mediaMobileUrl: json['media_mobile_url'] as String? ?? '',
      mediaRawUrl: json['media_raw_url'] as String? ?? '',
      likeCount: json['like_count'] as int? ?? 0,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : DateTime.now(),
      isLiked: json['is_liked'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'media_thumb_url': mediaThumbUrl,
      'media_mobile_url': mediaMobileUrl,
      'media_raw_url': mediaRawUrl,
      'like_count': likeCount,
      'created_at': createdAt.toIso8601String(),
      'is_liked': isLiked,
    };
  }

  @override
  List<Object?> get props => [
        id,
        mediaThumbUrl,
        mediaMobileUrl,
        mediaRawUrl,
        likeCount,
        createdAt,
        isLiked,
      ];
}
