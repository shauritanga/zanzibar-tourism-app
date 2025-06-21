import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zanzibar_tourism/providers/cultural_site_provider.dart';
import 'package:zanzibar_tourism/models/cultural_site.dart';

class FeaturedCarousel extends ConsumerStatefulWidget {
  const FeaturedCarousel({super.key});

  @override
  ConsumerState<FeaturedCarousel> createState() => _FeaturedCarouselState();
}

class _FeaturedCarouselState extends ConsumerState<FeaturedCarousel> {
  Timer? timer;
  int _currentIndex = 0;
  final Duration _duration = const Duration(seconds: 5);
  final Duration _animationDuration = const Duration(milliseconds: 300);

  final PageController _pageController = PageController(viewportFraction: 0.85);

  @override
  void initState() {
    super.initState();
  }

  void _startAutoScroll(int itemCount) {
    timer?.cancel();
    if (itemCount > 1) {
      timer = Timer.periodic(_duration, (Timer timer) {
        if (_currentIndex < itemCount - 1) {
          _currentIndex++;
        } else {
          _currentIndex = 0;
        }
        if (_pageController.hasClients) {
          _pageController.animateToPage(
            _currentIndex,
            duration: _animationDuration,
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    timer?.cancel();
    _pageController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sitesAsync = ref.watch(culturalSitesProvider);

    return sitesAsync.when(
      data: (sites) {
        if (sites.isEmpty) {
          return const SizedBox(
            height: 220,
            child: Center(child: Text('No featured sites available')),
          );
        }

        // Take top 3 sites for featured carousel
        final featuredSites = sites.take(3).toList();

        // Start auto-scroll when data is loaded
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _startAutoScroll(featuredSites.length);
        });

        return SizedBox(
          height: 220,
          child: PageView.builder(
            controller: _pageController,
            itemCount: featuredSites.length,
            itemBuilder: (context, index) {
              final site = featuredSites[index];
              return _buildCard(site);
            },
          ),
        );
      },
      loading:
          () => const SizedBox(
            height: 220,
            child: Center(child: CircularProgressIndicator()),
          ),
      error:
          (error, stack) => SizedBox(
            height: 220,
            child: Center(child: Text('Error: $error')),
          ),
    );
  }

  Widget _buildCard(CulturalSite site) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl:
                  (site.images?.isNotEmpty ?? false) ? site.images!.first : '',
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
                  colors: [
                    Colors.black.withValues(alpha: 0.6),
                    Colors.transparent,
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              child: Text(
                site.name,
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
