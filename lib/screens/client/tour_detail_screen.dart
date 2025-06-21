import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:zanzibar_tourism/models/tour.dart';
import 'package:zanzibar_tourism/providers/tours_provider.dart';

class TourDetailScreen extends ConsumerWidget {
  final String tourId;

  const TourDetailScreen({
    super.key,
    required this.tourId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tourAsync = ref.watch(tourByIdProvider(tourId));

    return Scaffold(
      body: tourAsync.when(
        data: (tour) {
          if (tour == null) {
            return const Center(child: Text('Tour not found'));
          }
          return _buildTourDetail(context, tour);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildTourDetail(BuildContext context, Tour tour) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              tour.title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(color: Colors.black, blurRadius: 4)],
              ),
            ),
            background: tour.images.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: tour.images.first,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        const Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) =>
                        const Center(child: Icon(Icons.error)),
                  )
                : Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.image, size: 100),
                  ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Price and rating row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '\$${tour.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          '${tour.rating} (${tour.reviews} reviews)',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Tour info chips
                Wrap(
                  spacing: 8,
                  children: [
                    Chip(
                      label: Text(tour.duration),
                      backgroundColor: Colors.blue[100],
                    ),
                    Chip(
                      label: Text(tour.difficulty),
                      backgroundColor: Colors.orange[100],
                    ),
                    Chip(
                      label: Text(tour.category),
                      backgroundColor: Colors.purple[100],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Description
                const Text(
                  'Description',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  tour.description,
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
                const SizedBox(height: 24),

                // Highlights
                if (tour.highlights.isNotEmpty) ...[
                  const Text(
                    'Highlights',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...tour.highlights.map((highlight) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check_circle,
                                color: Colors.green, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                highlight,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 24),
                ],

                // What's included
                if (tour.included.isNotEmpty) ...[
                  const Text(
                    'What\'s Included',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...tour.included.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check, color: Colors.blue, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 24),
                ],

                // Meeting point
                const Text(
                  'Meeting Point',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tour.meetingPoint,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Additional info
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Additional Information',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.group, size: 20),
                            const SizedBox(width: 8),
                            Text('Max ${tour.maxParticipants} participants'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.fitness_center, size: 20),
                            const SizedBox(width: 8),
                            Text('Difficulty: ${tour.difficulty}'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 100), // Space for floating button
              ],
            ),
          ),
        ),
      ],
    );
  }
}
