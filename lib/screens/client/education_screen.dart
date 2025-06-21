// File: lib/screens/education_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zanzibar_tourism/providers/education_provider.dart';

class EducationScreen extends ConsumerWidget {
  const EducationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentAsync = ref.watch(educationContentProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Zanzibar Knowledge Hub'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Search functionality
            },
          ),
        ],
      ),
      body: contentAsync.when(
        data:
            (contents) => CustomScrollView(
              slivers: [
                // Featured section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Discover Zanzibar',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Explore the rich history, culture, and natural wonders of Zanzibar',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        // Categories horizontal list
                        SizedBox(
                          height: 40,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              _buildCategoryChip('History', true),
                              _buildCategoryChip('Culture', false),
                              _buildCategoryChip('Nature', false),
                              _buildCategoryChip('Cuisine', false),
                              _buildCategoryChip('Language', false),
                              _buildCategoryChip('Traditions', false),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Content list
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final content = contents[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: ExpansionTile(
                        leading: _getCategoryIcon(content.category),
                        title: Text(
                          content.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(content.category),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  content.content,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      icon: const Icon(Icons.bookmark_outline),
                                      label: const Text('Save'),
                                      onPressed: () {
                                        // Save functionality
                                      },
                                    ),
                                    TextButton.icon(
                                      icon: const Icon(Icons.share),
                                      label: const Text('Share'),
                                      onPressed: () {
                                        // Share functionality
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }, childCount: contents.length),
                ),
              ],
            ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 60),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading content: $error',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.refresh(educationContentProvider),
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Show dialog with quick language phrases or travel tips
          _showQuickTipsDialog(context);
        },
        child: const Icon(Icons.lightbulb_outline),
      ),
    );
  }

  Widget _buildCategoryChip(String label, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Chip(
        label: Text(label),
        backgroundColor:
            isSelected ? Colors.teal.shade100 : Colors.grey.shade200,
        labelStyle: TextStyle(
          color: isSelected ? Colors.teal.shade700 : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Icon _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'history':
        return const Icon(Icons.history, color: Colors.brown);
      case 'culture':
        return const Icon(Icons.people, color: Colors.purple);
      case 'nature':
        return const Icon(Icons.nature, color: Colors.green);
      case 'cuisine':
        return const Icon(Icons.restaurant, color: Colors.orange);
      case 'language':
        return const Icon(Icons.translate, color: Colors.blue);
      case 'traditions':
        return const Icon(Icons.celebration, color: Colors.red);
      default:
        return const Icon(Icons.info, color: Colors.teal);
    }
  }

  void _showQuickTipsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Quick Travel Tips'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('• Jambo - Hello', style: TextStyle(fontSize: 16)),
                Text('• Asante - Thank you', style: TextStyle(fontSize: 16)),
                Text('• Tafadhali - Please', style: TextStyle(fontSize: 16)),
                Text('• Karibu - Welcome', style: TextStyle(fontSize: 16)),
                SizedBox(height: 16),
                Text(
                  '• Respect local customs and dress modestly',
                  style: TextStyle(fontSize: 16),
                ),
                Text('• Drink bottled water', style: TextStyle(fontSize: 16)),
                Text(
                  '• Negotiate prices at markets',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }
}
