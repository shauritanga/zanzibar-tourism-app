import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class PromotionBanner extends StatelessWidget {
  const PromotionBanner({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample promotional data (you can fetch from Firestore later)
    final promotion = {
      'title': '10% Off Guided Tours!',
      'subtitle': 'Book your next adventure now and save big!',
      'image':
          'https://dynamic-media-cdn.tripadvisor.com/media/photo-o/2f/53/df/3a/farma-koreni-a-kamenne.jpg?w=1100&h=-1&s=1',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Background image
            CachedNetworkImage(
              imageUrl: promotion['image']!,
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
              height: 160,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.black.withOpacity(0.1),
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
                    promotion['title']!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    promotion['subtitle']!,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      shadows: [Shadow(color: Colors.black45, blurRadius: 3)],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
