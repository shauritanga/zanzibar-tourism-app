// File: lib/screens/marketplace_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zanzibar_tourism/models/product.dart';
import 'package:zanzibar_tourism/providers/marketplace_provider.dart';
import 'package:zanzibar_tourism/widgets/product_card.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MarketplaceScreen extends ConsumerStatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  ConsumerState<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends ConsumerState<MarketplaceScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  bool _isGridView = true;

  final List<String> _categories = [
    'All',
    'Handcrafts',
    'Spices',
    'Clothing',
    'Jewelry',
    'Art',
    'Food',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(marketplaceProvider);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 180.0,
              floating: false,
              pinned: true,
              backgroundColor: Colors.teal,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'Local Marketplace',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        blurRadius: 10.0,
                        color: Colors.black.withOpacity(0.5),
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl:
                          'https://images.unsplash.com/photo-1528735000313-039ec3a473b0',
                      fit: BoxFit.cover,
                      placeholder:
                          (context, url) => const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                      errorWidget:
                          (context, url, error) => const Icon(Icons.error),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.1),
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search local products...',
                      prefixIcon: const Icon(Icons.search, color: Colors.teal),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                    onChanged: (value) {
                      // Implement search functionality
                      setState(() {});
                    },
                  ),
                ),
              ),
            ),
          ];
        },
        body: Column(
          children: [
            // Category filter
            Container(
              height: 50,
              margin: const EdgeInsets.only(top: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = category == _selectedCategory;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.teal : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        category,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // View toggle and sort options
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Showing local products',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Row(
                    children: [
                      // Sort dropdown
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.sort, color: Colors.teal),
                        onSelected: (value) {
                          // Implement sorting
                        },
                        itemBuilder:
                            (context) => [
                              const PopupMenuItem(
                                value: 'price_asc',
                                child: Text('Price: Low to High'),
                              ),
                              const PopupMenuItem(
                                value: 'price_desc',
                                child: Text('Price: High to Low'),
                              ),
                              const PopupMenuItem(
                                value: 'rating',
                                child: Text('Top Rated'),
                              ),
                            ],
                      ),
                      // View toggle
                      IconButton(
                        icon: Icon(
                          _isGridView ? Icons.view_list : Icons.grid_view,
                          color: Colors.teal,
                        ),
                        onPressed: () {
                          setState(() {
                            _isGridView = !_isGridView;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Products list
            Expanded(
              child: Builder(
                builder: (context) {
                  final filteredProducts =
                      products.where((product) {
                        final matchesCategory =
                            _selectedCategory == 'All' ||
                            product.category == _selectedCategory;
                        final matchesSearch =
                            _searchController.text.isEmpty ||
                            product.name.toLowerCase().contains(
                              _searchController.text.toLowerCase(),
                            ) ||
                            product.description.toLowerCase().contains(
                              _searchController.text.toLowerCase(),
                            );
                        return matchesCategory && matchesSearch;
                      }).toList();

                  if (filteredProducts.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No products found',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return _isGridView
                      ? GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.63,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = filteredProducts[index];
                          return _EnhancedProductCard(product: product);
                        },
                      )
                      : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = filteredProducts[index];
                          return _ProductListItem(product: product);
                        },
                      );
                },
              ),

              //  productsAsync.when(
              //   data: (products) {
              //     // Filter products by category and search query
              //     final filteredProducts =
              //         products.where((product) {
              //           final matchesCategory =
              //               _selectedCategory == 'All' ||
              //               product.category == _selectedCategory;
              //           final matchesSearch =
              //               _searchController.text.isEmpty ||
              //               product.name.toLowerCase().contains(
              //                 _searchController.text.toLowerCase(),
              //               ) ||
              //               product.description.toLowerCase().contains(
              //                 _searchController.text.toLowerCase(),
              //               );
              //           return matchesCategory && matchesSearch;
              //         }).toList();

              // if (filteredProducts.isEmpty) {
              //   return Center(
              //     child: Column(
              //       mainAxisAlignment: MainAxisAlignment.center,
              //       children: [
              //         Icon(
              //           Icons.search_off,
              //           size: 64,
              //           color: Colors.grey.shade400,
              //         ),
              //         const SizedBox(height: 16),
              //         Text(
              //           'No products found',
              //           style: TextStyle(
              //             fontSize: 18,
              //             color: Colors.grey.shade600,
              //           ),
              //         ),
              //       ],
              //     ),
              //   );
              // }

              // return _isGridView
              //     ? GridView.builder(
              //       padding: const EdgeInsets.all(16),
              //       gridDelegate:
              //           const SliverGridDelegateWithFixedCrossAxisCount(
              //             crossAxisCount: 2,
              //             childAspectRatio: 0.75,
              //             crossAxisSpacing: 16,
              //             mainAxisSpacing: 16,
              //           ),
              //       itemCount: filteredProducts.length,
              //       itemBuilder: (context, index) {
              //         final product = filteredProducts[index];
              //         return _EnhancedProductCard(product: product);
              //       },
              //     )
              //     : ListView.builder(
              //       padding: const EdgeInsets.all(16),
              //       itemCount: filteredProducts.length,
              //       itemBuilder: (context, index) {
              //         final product = filteredProducts[index];
              //         return _ProductListItem(product: product);
              //       },
              //     );
              //   },
              //   loading: () => const Center(child: CircularProgressIndicator()),
              //   error:
              //       (error, stack) => Center(
              //         child: Column(
              //           mainAxisAlignment: MainAxisAlignment.center,
              //           children: [
              //             Icon(
              //               Icons.error_outline,
              //               size: 64,
              //               color: Colors.red.shade300,
              //             ),
              //             const SizedBox(height: 16),
              //             Text(
              //               'Error loading products',
              //               style: TextStyle(
              //                 fontSize: 18,
              //                 color: Colors.grey.shade600,
              //               ),
              //             ),
              //             const SizedBox(height: 8),
              //             ElevatedButton(
              //               onPressed: () => ref.refresh(marketplaceProvider),
              //               style: ElevatedButton.styleFrom(
              //                 backgroundColor: Colors.teal,
              //                 foregroundColor: Colors.white,
              //               ),
              //               child: const Text('Retry'),
              //             ),
              //           ],
              //         ),
              //       ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        child: const Icon(Icons.shopping_cart, color: Colors.white),
        onPressed: () {
          // Navigate to cart
        },
      ),
    );
  }
}

class _EnhancedProductCard extends StatelessWidget {
  final dynamic product;

  const _EnhancedProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // Navigate to product detail
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: CachedNetworkImage(
                    imageUrl: product.image ?? '',
                    fit: BoxFit.cover,
                    placeholder:
                        (context, url) => Container(
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                    errorWidget:
                        (context, url, error) => Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.error),
                        ),
                  ),
                ),
                // Seller badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.verified_user,
                          color: Colors.white,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Local Artisan',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Discount badge if applicable
                if (product.discount != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '-${product.discount}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            // Product info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.description,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${product.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.teal,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.teal,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.add_shopping_cart,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
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

class _ProductListItem extends StatelessWidget {
  final dynamic product;

  const _ProductListItem({required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // Navigate to product detail
        },
        child: Row(
          children: [
            // Product image
            SizedBox(
              width: 120,
              height: 120,
              child: CachedNetworkImage(
                imageUrl: product.image ?? '',
                fit: BoxFit.cover,
                placeholder:
                    (context, url) => Container(
                      color: Colors.grey.shade200,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                errorWidget:
                    (context, url, error) => Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.error),
                    ),
              ),
            ),
            // Product info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.description,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.store, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          product.sellerName,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '\$${product.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.teal,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            // Add to cart
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.shopping_cart, size: 16),
                          label: const Text('Add'),
                        ),
                      ],
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
