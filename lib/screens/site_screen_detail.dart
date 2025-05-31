import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:zanzibar_tourism/models/cultural_site.dart';

class SiteDetailScreen extends StatefulWidget {
  final CulturalSite site;
  const SiteDetailScreen({super.key, required this.site});

  @override
  State<SiteDetailScreen> createState() => _SiteDetailScreenState();
}

class _SiteDetailScreenState extends State<SiteDetailScreen> {
  final List<Widget> mediaWidgets = [];

  @override
  void initState() {
    super.initState();
    for (final url in [
      ...widget.site.images ?? [],
      ...widget.site.videos ?? [],
    ]) {
      if (url.endsWith('.mp4')) {
        final controller = VideoPlayerController.networkUrl(url);
        final chewieController = ChewieController(
          videoPlayerController: controller,
          autoPlay: false,
          looping: false,
        );
        mediaWidgets.add(Chewie(controller: chewieController));
      } else {
        mediaWidgets.add(
          CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            width: double.infinity,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    for (var widget in mediaWidgets) {
      if (widget is Chewie) {
        widget.controller.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.site.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CarouselSlider(
            items: mediaWidgets,
            options: CarouselOptions(
              viewportFraction: 1.0,
              height: 290,
              autoPlay: true,
            ),
          ),
          const SizedBox(height: 16),
          Text(widget.site.description),
          const SizedBox(height: 12),
          Text('Location: ${widget.site.location}'),
        ],
      ),
    );
  }
}
