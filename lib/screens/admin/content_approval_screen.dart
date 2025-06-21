import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zanzibar_tourism/services/content_editor_service.dart';
import 'package:zanzibar_tourism/services/auth_service.dart';
import 'package:intl/intl.dart';

class ContentApprovalScreen extends ConsumerStatefulWidget {
  const ContentApprovalScreen({super.key});

  @override
  ConsumerState<ContentApprovalScreen> createState() => _ContentApprovalScreenState();
}

class _ContentApprovalScreenState extends ConsumerState<ContentApprovalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Content Approval'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Pending', icon: Icon(Icons.pending)),
            Tab(text: 'Approved', icon: Icon(Icons.check_circle)),
            Tab(text: 'Rejected', icon: Icon(Icons.cancel)),
            Tab(text: 'Published', icon: Icon(Icons.public)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search content...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),

          // Content List
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildContentList(ContentStatus.pending),
                _buildContentList(ContentStatus.approved),
                _buildContentList(ContentStatus.rejected),
                _buildContentList(ContentStatus.published),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentList(ContentStatus status) {
    final contentEditorService = ref.read(contentEditorServiceProvider);

    return StreamBuilder<List<RichContent>>(
      stream: contentEditorService.getContentByStatus(status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final allContent = snapshot.data ?? [];
        final filteredContent = _searchQuery.isEmpty
            ? allContent
            : allContent.where((content) =>
                content.title.toLowerCase().contains(_searchQuery) ||
                content.plainText.toLowerCase().contains(_searchQuery) ||
                content.authorName.toLowerCase().contains(_searchQuery) ||
                content.tags.any((tag) => tag.toLowerCase().contains(_searchQuery))).toList();

        if (filteredContent.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getStatusIcon(status),
                  size: 80,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isEmpty
                      ? 'No ${status.name} content'
                      : 'No content found',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _searchQuery.isEmpty
                      ? 'Content will appear here when available'
                      : 'Try adjusting your search terms',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredContent.length,
            itemBuilder: (context, index) {
              final content = filteredContent[index];
              return _buildContentCard(content, status);
            },
          ),
        );
      },
    );
  }

  Widget _buildContentCard(RichContent content, ContentStatus status) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    content.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(content.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    content.status.name.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Content Type and Author
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getTypeColor(content.type),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    content.type.name.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'by ${content.authorName}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat('MMM dd, yyyy').format(content.updatedAt),
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Content Preview
            Text(
              content.plainText,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14),
            ),

            const SizedBox(height: 12),

            // Tags
            if (content.tags.isNotEmpty) ...[
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: content.tags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],

            // Reviewer Notes
            if (content.reviewerNotes != null && content.reviewerNotes!.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: content.status == ContentStatus.rejected
                      ? Colors.red.withValues(alpha: 0.1)
                      : Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reviewer Notes:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: content.status == ContentStatus.rejected
                            ? Colors.red.shade700
                            : Colors.green.shade700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      content.reviewerNotes!,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _showContentDetails(content),
                  child: const Text('View Details'),
                ),
                
                if (status == ContentStatus.pending) ...[
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => _showRejectDialog(content),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Reject'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _showApproveDialog(content),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Approve'),
                  ),
                ] else if (status == ContentStatus.approved) ...[
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _publishContent(content),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Publish'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showContentDetails(RichContent content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(content.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Type: ${content.type.name}'),
              Text('Author: ${content.authorName}'),
              Text('Created: ${DateFormat('MMM dd, yyyy HH:mm').format(content.createdAt)}'),
              Text('Updated: ${DateFormat('MMM dd, yyyy HH:mm').format(content.updatedAt)}'),
              const SizedBox(height: 16),
              const Text('Content:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(content.plainText),
            ],
          ),
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

  void _showApproveDialog(RichContent content) {
    final notesController = TextEditingController();
    bool publishImmediately = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Approve Content'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Reviewer Notes (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Publish immediately'),
                value: publishImmediately,
                onChanged: (value) {
                  setState(() {
                    publishImmediately = value ?? false;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => _approveContent(content, notesController.text, publishImmediately),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Approve'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRejectDialog(RichContent content) {
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Content'),
        content: TextField(
          controller: notesController,
          decoration: const InputDecoration(
            labelText: 'Reason for rejection *',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _rejectContent(content, notesController.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  Future<void> _approveContent(RichContent content, String notes, bool publish) async {
    try {
      final user = ref.read(authServiceProvider).currentUser;
      if (user == null) return;

      await ref.read(contentEditorServiceProvider).approveContent(
        contentId: content.id,
        reviewerId: user.uid,
        reviewerNotes: notes.isNotEmpty ? notes : null,
        publish: publish,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(publish ? 'Content approved and published!' : 'Content approved!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectContent(RichContent content, String notes) async {
    if (notes.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide a reason for rejection'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final user = ref.read(authServiceProvider).currentUser;
      if (user == null) return;

      await ref.read(contentEditorServiceProvider).rejectContent(
        contentId: content.id,
        reviewerId: user.uid,
        reviewerNotes: notes,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Content rejected'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _publishContent(RichContent content) async {
    try {
      await ref.read(contentEditorServiceProvider).publishContent(content.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Content published!'),
            backgroundColor: Colors.blue,
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
    }
  }

  IconData _getStatusIcon(ContentStatus status) {
    switch (status) {
      case ContentStatus.pending:
        return Icons.pending;
      case ContentStatus.approved:
        return Icons.check_circle;
      case ContentStatus.rejected:
        return Icons.cancel;
      case ContentStatus.published:
        return Icons.public;
      default:
        return Icons.article;
    }
  }

  Color _getStatusColor(ContentStatus status) {
    switch (status) {
      case ContentStatus.draft:
        return Colors.grey;
      case ContentStatus.pending:
        return Colors.orange;
      case ContentStatus.approved:
        return Colors.green;
      case ContentStatus.rejected:
        return Colors.red;
      case ContentStatus.published:
        return Colors.blue;
    }
  }

  Color _getTypeColor(ContentType type) {
    switch (type) {
      case ContentType.article:
        return Colors.blue;
      case ContentType.productDescription:
        return Colors.green;
      case ContentType.siteDescription:
        return Colors.purple;
      case ContentType.tourDescription:
        return Colors.orange;
      case ContentType.announcement:
        return Colors.red;
    }
  }
}
