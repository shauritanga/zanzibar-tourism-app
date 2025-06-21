import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zanzibar_tourism/models/cultural_site.dart';
import 'package:zanzibar_tourism/routing/routes.dart';
import 'package:zanzibar_tourism/screens/client/site_screen_detail.dart';

class SiteCard extends StatelessWidget {
  final CulturalSite site;

  const SiteCard({super.key, required this.site});

  @override
  Widget build(BuildContext context) {
    final imageUrl =
        site.images?.isNotEmpty == true ? site.images!.first : null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
         context.goNamed(AppRoute.clientSites.name);
        },
        child: Row(
          children: [
            Hero(
              tag: site.name,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
                child:
                    imageUrl != null
                        ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          placeholder:
                              (context, url) => const SizedBox(
                                width: 100,
                                height: 100,
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                          errorWidget:
                              (context, url, error) => const SizedBox(
                                width: 100,
                                height: 100,
                                child: Icon(Icons.image_not_supported),
                              ),
                        )
                        : const SizedBox(
                          width: 100,
                          height: 100,
                          child: Icon(Icons.image_not_supported),
                        ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      site.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      site.description.length > 80
                          ? '${site.description.substring(0, 80)}...'
                          : site.description,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
