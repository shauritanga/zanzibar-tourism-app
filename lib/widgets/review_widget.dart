import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zanzibar_tourism/services/review_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

class ReviewWidget extends ConsumerWidget {
  final String itemId;
  final ReviewType type;
  final String itemName;

  const ReviewWidget({
    super.key,
    required this.itemId,
    required this.type,
    required this.itemName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewService = ref.read(reviewServiceProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Reviews Header with Stats
        FutureBuilder<ReviewStats>(
          future: reviewService.getReviewStats(itemId, type),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return _buildReviewHeader(context, snapshot.data!);
            }
            return const SizedBox.shrink();
          },
        ),
        
        const SizedBox(height: 16),
        
        // Add Review Button
        ElevatedButton.icon(
          onPressed: () => _showAddReviewDialog(context, ref),
          icon: const Icon(Icons.rate_review),
          label: const Text('Write a Review'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Reviews List
        StreamBuilder<List<Review>>(
          stream: reviewService.getItemReviews(itemId, type),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            
            final reviews = snapshot.data ?? [];
            
            if (reviews.isEmpty) {
              return const Center(
                child: Column(
                  children: [
                    Icon(Icons.rate_review_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No reviews yet',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    Text(
                      'Be the first to write a review!',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              );
            }
            
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: reviews.length,
              itemBuilder: (context, index) {
                return _buildReviewCard(context, reviews[index], ref);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildReviewHeader(BuildContext context, ReviewStats stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  stats.averageRating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStarRating(stats.averageRating),
                    Text(
                      '${stats.totalReviews} reviews',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Rating Distribution
            ...List.generate(5, (index) {
              final rating = 5 - index;
              final count = stats.ratingDistribution[rating] ?? 0;
              final percentage = stats.totalReviews > 0 
                  ? (count / stats.totalReviews) 
                  : 0.0;
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Text('$rating'),
                    const SizedBox(width: 8),
                    const Icon(Icons.star, size: 16, color: Colors.amber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: percentage,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('$count'),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildStarRating(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating.floor()
              ? Icons.star
              : index < rating
                  ? Icons.star_half
                  : Icons.star_border,
          color: Colors.amber,
          size: 20,
        );
      }),
    );
  }

  Widget _buildReviewCard(BuildContext context, Review review, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info and Rating
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: review.userAvatar.isNotEmpty
                      ? CachedNetworkImageProvider(review.userAvatar)
                      : null,
                  child: review.userAvatar.isEmpty
                      ? Text(review.userName.isNotEmpty ? review.userName[0].toUpperCase() : 'U')
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            review.userName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (review.isVerifiedPurchase) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'Verified',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Row(
                        children: [
                          _buildStarRating(review.rating),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('MMM dd, yyyy').format(review.createdAt),
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Review Comment
            if (review.comment.isNotEmpty)
              Text(
                review.comment,
                style: const TextStyle(fontSize: 14),
              ),
            
            // Review Images
            if (review.images.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: review.images.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: review.images[index],
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey.shade300,
                            child: const Icon(Icons.image),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey.shade300,
                            child: const Icon(Icons.image_not_supported),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            
            const SizedBox(height: 12),
            
            // Helpful Button
            Row(
              children: [
                TextButton.icon(
                  onPressed: () {
                    ref.read(reviewServiceProvider).markReviewHelpful(review.id);
                  },
                  icon: const Icon(Icons.thumb_up_outlined, size: 16),
                  label: Text('Helpful (${review.helpfulCount})'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddReviewDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AddReviewDialog(
        itemId: itemId,
        type: type,
        itemName: itemName,
      ),
    );
  }
}

class AddReviewDialog extends ConsumerStatefulWidget {
  final String itemId;
  final ReviewType type;
  final String itemName;

  const AddReviewDialog({
    super.key,
    required this.itemId,
    required this.type,
    required this.itemName,
  });

  @override
  ConsumerState<AddReviewDialog> createState() => _AddReviewDialogState();
}

class _AddReviewDialogState extends ConsumerState<AddReviewDialog> {
  double _rating = 5.0;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Review ${widget.itemName}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Rating'),
            const SizedBox(height: 8),
            Row(
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () => setState(() => _rating = index + 1.0),
                  child: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 32,
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            const Text('Comment'),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                hintText: 'Share your experience...',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitReview,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Submit'),
        ),
      ],
    );
  }

  Future<void> _submitReview() async {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a comment')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // TODO: Get current user info
      await ref.read(reviewServiceProvider).addReview(
        itemId: widget.itemId,
        userId: 'current_user_id', // TODO: Get from auth
        userName: 'Current User', // TODO: Get from auth
        userAvatar: '', // TODO: Get from auth
        type: widget.type,
        rating: _rating,
        comment: _commentController.text.trim(),
        isVerifiedPurchase: true, // TODO: Check actual purchase status
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
