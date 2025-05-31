import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class FeaturedCarousel extends StatefulWidget {
  const FeaturedCarousel({super.key});

  @override
  State<FeaturedCarousel> createState() => _FeaturedCarouselState();
}

class _FeaturedCarouselState extends State<FeaturedCarousel> {
  Timer? timer;
  int _currentIndex = 0;
  final Duration _duration = const Duration(seconds: 5);
  final Duration _animationDuration = const Duration(milliseconds: 300);

  final PageController _pageController = PageController(viewportFraction: 0.85);
  final List<Map<String, String>> featuredItems = [
    {
      'title': 'Stone Town',
      'image':
          'https://dynamic-media-cdn.tripadvisor.com/media/photo-o/2f/a0/7d/01/caption.jpg?w=1400&h=-1&s=1',
    },
    {
      'title': 'Jozani Forest',
      'image':
          'https://www.zanzibar-tours.co.tz/wp-content/uploads/2024/12/Spice-Tour-Stone-Town-4-1-1-800x450.jpg',
    },
    {
      'title': 'Prison Island',
      'image':
          'https://dynamic-media-cdn.tripadvisor.com/media/photo-o/25/a5/14/7f/caption.jpg?w=1400&h=-1&s=1',
    },
  ];

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    timer = Timer.periodic(_duration, (Timer timer) {
      if (_currentIndex < featuredItems.length - 1) {
        _currentIndex++;
      } else {
        _currentIndex = 0;
      }
      _pageController.animateToPage(
        _currentIndex,
        duration: _animationDuration,
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    super.dispose();
    timer?.cancel();
    _pageController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: PageView.builder(
        controller: _pageController,
        itemCount: featuredItems.length,
        itemBuilder: (context, index) {
          final item = featuredItems[index];
          return _buildCard(item);
        },
      ),
    );
  }

  Widget _buildCard(Map<String, String> item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: item['image'] ?? '',
              fit: BoxFit.cover,
              placeholder:
                  (context, url) =>
                      const Center(child: CircularProgressIndicator()),
              errorWidget:
                  (context, url, error) =>
                      const Center(child: Icon(Icons.error)),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              child: Text(
                item['title'] ?? '',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black, blurRadius: 6)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
