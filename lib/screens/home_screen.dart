// File: lib/screens/cultural_showcase_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zanzibar_tourism/providers/cultural_site_provider.dart';
import 'package:zanzibar_tourism/widgets/featured_carousel.dart';
import 'package:zanzibar_tourism/widgets/promotion_banner.dart';
import 'package:zanzibar_tourism/widgets/suggested_tourlist.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sitesAsync = ref.watch(culturalSitesProvider);

    return Scaffold(
      body: sitesAsync.when(
        data:
            (sites) => Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 2. Featured Carousel
                    _SectionTitle(title: 'Featured Places'),
                    FeaturedCarousel(),
                    const SizedBox(height: 10),

                    // 3. Promotions
                    _SectionTitle(title: 'Promotions'),
                    PromotionBanner(),
                    const SizedBox(height: 10),

                    // 4. Suggested Tours
                    _SectionTitle(title: 'Suggested Tours'),
                    SuggestedTourList(),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: Colors.teal[700],
        ),
      ),
    );
  }
}
