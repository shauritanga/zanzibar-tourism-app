import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zanzibar_tourism/providers/cultural_site_provider.dart';
import 'site_screen_detail.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CulturalShowcaseScreen extends ConsumerWidget {
  const CulturalShowcaseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sitesAsync = ref.watch(culturalSitesFutureProvider);

    return Scaffold(
      body: sitesAsync.when(
        data:
            (sites) => ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: sites.length,
              itemBuilder: (context, index) {
                final site = sites[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          fullscreenDialog: true,
                          builder: (_) => SiteDetailScreen(site: site),
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Hero image
                        Hero(
                          tag: site.id,
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                            child: CachedNetworkImage(
                              imageUrl:
                                  site.images?.isNotEmpty == true
                                      ? site.images!.first
                                      : 'https://via.placeholder.com/150',

                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              placeholder:
                                  (_, __) => const SizedBox(
                                    height: 180,
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                              errorWidget:
                                  (_, __, ___) => const Icon(Icons.error),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                site.name,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                site.description.length > 80
                                    ? '${site.description.substring(0, 80)}...'
                                    : site.description,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                site.location != null
                                    ? 'Lat: ${site.location!.latitude}, Lng: ${site.location!.longitude}'
                                    : 'Location not available',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading sites: $e')),
      ),
    );
  }
}
