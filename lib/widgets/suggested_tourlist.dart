import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class SuggestedTourList extends StatelessWidget {
  const SuggestedTourList({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample data — replace with Firestore data
    final tours = [
      {
        'title': 'Spice Farm Tour',
        'description': 'Discover the scents of Zanzibar’s famous spices.',
        'image':
            'https://www.zanzibar-tours.co.tz/wp-content/uploads/2024/12/146-2.jpg',
      },
      {
        'title': 'Prison Island Excursion',
        'description':
            'Visit the historical island and meet the giant tortoises.',
        'image':
            'https://www.zanzibar-tours.co.tz/wp-content/uploads/2024/11/tour_gallery_23-800x450.jpg',
      },
      {
        'title': 'Jozani Forest Adventure',
        'description':
            'Explore the lush forest and spot rare Red Colobus monkeys.',
        'image':
            'https://www.zanzibar-tours.co.tz/wp-content/uploads/2024/12/P12-16-720x450.jpg',
      },
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tours.length,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemBuilder: (context, index) {
        final tour = tours[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            onTap: () {
              // Navigate to detail or booking page
              // Navigator.push(context, MaterialPageRoute(...));
            },
            child: Row(
              children: [
                // Tour image
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: tour['image']!,
                    width: 120,
                    height: 100,
                    fit: BoxFit.cover,
                    placeholder:
                        (context, url) =>
                            const Center(child: CircularProgressIndicator()),
                    errorWidget:
                        (context, url, error) => const Icon(Icons.error),
                  ),
                ),
                // Text content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tour['title']!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          tour['description']!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: TextButton(
                            onPressed: () {
                              // Navigate to booking
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.teal,
                            ),
                            child: const Text('Book Now'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
