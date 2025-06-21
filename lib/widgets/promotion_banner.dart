import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zanzibar_tourism/providers/promotions_provider.dart';

class PromotionBanner extends ConsumerWidget {
  const PromotionBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final promotionAsync = ref.watch(featuredPromotionProvider);

    return promotionAsync.when(
      data: (promotion) {
        if (promotion == null) {
          return const SizedBox.shrink(); // Hide banner if no promotion
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // Background image
                CachedNetworkImage(
                  imageUrl: promotion.image,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder:
                      (context, url) =>
                          const Center(child: CircularProgressIndicator()),
                  errorWidget:
                      (context, url, error) =>
                          const Center(child: Icon(Icons.error)),
                ),

                // Gradient overlay
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.6),
                        Colors.black.withValues(alpha: 0.1),
                      ],
                      begin: Alignment.bottomLeft,
                      end: Alignment.topRight,
                    ),
                  ),
                ),

                // Promotion text
                Positioned(
                  left: 16,
                  bottom: 20,
                  right: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        promotion.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        promotion.subtitle,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          shadows: [
                            Shadow(color: Colors.black45, blurRadius: 3),
                          ],
                        ),
                      ),
                      if (promotion.discountPercentage > 0) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${promotion.discountPercentage.toInt()}% OFF',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading:
          () => const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SizedBox(
              height: 180,
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }
}
