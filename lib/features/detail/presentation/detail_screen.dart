import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import '../../feed/data/models/post_model.dart';

class DetailScreen extends StatefulWidget {
  final PostModel post;

  const DetailScreen({super.key, required this.post});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  bool _isDownloadingRaw = false;

  Future<void> _downloadRawImage() async {
    setState(() {
      _isDownloadingRaw = true;
    });

    try {
      final dio = Dio();
      final tempDir = await getTemporaryDirectory();
      // Save locally using the post id
      final savePath = '${tempDir.path}/${widget.post.id}_raw.jpg';
      
      // We only touch the mediaRawUrl here, upon explicit user request
      await dio.download(widget.post.mediaRawUrl, savePath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('High-Res image downloaded successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to download High-Res image.'),
            backgroundColor: Colors.redAccent,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloadingRaw = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      body: Center(
        child: Hero(
          tag: widget.post.id,
          child: CachedNetworkImage(
            imageUrl: widget.post.mediaMobileUrl,
            fit: BoxFit.contain,
            fadeInDuration: const Duration(milliseconds: 500),
            placeholder: (context, url) => CachedNetworkImage(
              imageUrl: widget.post.mediaThumbUrl,
              fit: BoxFit.contain,
            ),
            errorWidget: (context, url, error) => const Center(
              child: Icon(Icons.error, color: Colors.white, size: 48),
            ),
          ),
        ),
      ),
      // 3. Optional raw download
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isDownloadingRaw ? null : _downloadRawImage,
        icon: _isDownloadingRaw 
            ? const SizedBox(
                width: 20, 
                height: 20, 
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.high_quality),
        label: Text(_isDownloadingRaw ? 'Downloading...' : 'Download High-Res'),
      ),
    );
  }
}
