import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/models/post_model.dart';
import '../../../detail/presentation/detail_screen.dart';

class PostCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback? onLikePressed;

  const PostCard({
    super.key,
    required this.post,
    this.onLikePressed,
  });

  @override
  Widget build(BuildContext context) {
    // memCacheWidth is calculated dynamically based on the screen width and pixel ratio.
    // This strictly prevents the app from loading full resolution images into memory,
    // decoding only what is needed for the container size.
    final screenWidth = MediaQuery.sizeOf(context).width;
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    // Assuming 32px total horizontal margin
    final cacheWidth = ((screenWidth - 32) * devicePixelRatio).toInt();

    return RepaintBoundary(
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => DetailScreen(post: post),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          height: 450, // Fixed aspect ratio for premium look
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(32.0), // Large border radius
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2), // Heavy BoxShadow
                blurRadius: 30.0,
                offset: const Offset(0, 15),
                spreadRadius: 2.0,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32.0),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Media Thumbnail using CachedNetworkImage wrapped in Hero
                Hero(
                  tag: post.id,
                  child: CachedNetworkImage(
                    imageUrl: post.mediaThumbUrl,
                    fit: BoxFit.cover,
                    memCacheWidth: cacheWidth,
                    placeholder: (context, url) => Container(
                      color: Colors.grey.shade900, // Sleek dark placeholder
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white54,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey.shade900,
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image, color: Colors.white54, size: 48),
                          SizedBox(height: 8),
                          Text('Image not available', style: TextStyle(color: Colors.white54)),
                        ],
                      ),
                    ),
                  ),
                ),

                // Gradient Overlay for text/button visibility
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 140,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.85),
                        ],
                      ),
                    ),
                  ),
                ),

                // Social Actions Overlay
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '${post.likeCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 1),
                              blurRadius: 4.0,
                              color: Colors.black54,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: onLikePressed,
                        child: Container(
                          padding: const EdgeInsets.all(10.0),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.15), // Frosted glass effect
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            post.isLiked ? Icons.favorite : Icons.favorite_border,
                            color: post.isLiked ? Colors.redAccent : Colors.white,
                            size: 26,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
