import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zanzibar_tourism/services/search_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  
  List<SearchResult> _searchResults = [];
  List<String> _popularSearches = [];
  List<SearchSuggestion> _suggestions = [];
  bool _isLoading = false;
  bool _showFilters = false;
  
  SearchType _selectedType = SearchType.all;
  SearchFilter _currentFilter = SearchFilter();

  @override
  void initState() {
    super.initState();
    _loadPopularSearches();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    if (query.length >= 2) {
      _loadSuggestions(query);
    } else {
      setState(() {
        _suggestions = [];
      });
    }
  }

  Future<void> _loadPopularSearches() async {
    try {
      final searches = await ref.read(searchServiceProvider).getPopularSearches();
      setState(() {
        _popularSearches = searches;
      });
    } catch (e) {
      print('Error loading popular searches: $e');
    }
  }

  Future<void> _loadSuggestions(String query) async {
    try {
      final suggestions = await ref.read(searchServiceProvider).getSearchSuggestions(query);
      setState(() {
        _suggestions = suggestions;
      });
    } catch (e) {
      print('Error loading suggestions: $e');
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _suggestions = [];
    });

    try {
      final results = await ref.read(searchServiceProvider).search(
        query: query,
        type: _selectedType,
        filter: _currentFilter,
      );

      setState(() {
        _searchResults = results;
        _isLoading = false;
      });

      _searchFocus.unfocus();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocus,
                    decoration: InputDecoration(
                      hintText: 'Search products, sites, tours...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchResults = [];
                                  _suggestions = [];
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: _performSearch,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    _showFilters ? Icons.filter_list : Icons.filter_list_outlined,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      _showFilters = !_showFilters;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Type Tabs
          Container(
            color: Colors.grey.shade100,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: SearchType.values.map((type) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(_getTypeLabel(type)),
                      selected: _selectedType == type,
                      onSelected: (selected) {
                        setState(() {
                          _selectedType = type;
                        });
                        if (_searchController.text.isNotEmpty) {
                          _performSearch(_searchController.text);
                        }
                      },
                      selectedColor: Colors.teal.withValues(alpha: 0.2),
                      checkmarkColor: Colors.teal,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Filters Panel
          if (_showFilters) _buildFiltersPanel(),

          // Content
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersPanel() {
    return Container(
      color: Colors.grey.shade50,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filters',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Price Range
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Min Price',
                    prefixText: '\$',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final price = double.tryParse(value);
                    _currentFilter = _currentFilter.copyWith(minPrice: price);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Max Price',
                    prefixText: '\$',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final price = double.tryParse(value);
                    _currentFilter = _currentFilter.copyWith(maxPrice: price);
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Sort Options
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Sort by',
              border: OutlineInputBorder(),
            ),
            value: _currentFilter.sortBy,
            items: const [
              DropdownMenuItem(value: null, child: Text('Relevance')),
              DropdownMenuItem(value: 'price_asc', child: Text('Price: Low to High')),
              DropdownMenuItem(value: 'price_desc', child: Text('Price: High to Low')),
              DropdownMenuItem(value: 'rating', child: Text('Highest Rated')),
              DropdownMenuItem(value: 'popular', child: Text('Most Popular')),
            ],
            onChanged: (value) {
              _currentFilter = _currentFilter.copyWith(sortBy: value);
            },
          ),
          
          const SizedBox(height: 16),
          
          // Apply Filters Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (_searchController.text.isNotEmpty) {
                  _performSearch(_searchController.text);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
              child: const Text('Apply Filters'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_suggestions.isNotEmpty) {
      return _buildSuggestions();
    }

    if (_searchResults.isNotEmpty) {
      return _buildSearchResults();
    }

    if (_searchController.text.isNotEmpty) {
      return _buildNoResults();
    }

    return _buildInitialState();
  }

  Widget _buildSuggestions() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _suggestions.length,
      itemBuilder: (context, index) {
        final suggestion = _suggestions[index];
        return ListTile(
          leading: const Icon(Icons.search, color: Colors.grey),
          title: Text(suggestion.text),
          subtitle: Text(_getTypeLabel(suggestion.type)),
          trailing: Text('${suggestion.frequency}'),
          onTap: () {
            _searchController.text = suggestion.text;
            _performSearch(suggestion.text);
          },
        );
      },
    );
  }

  Widget _buildSearchResults() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final result = _searchResults[index];
        return _buildResultCard(result);
      },
    );
  }

  Widget _buildResultCard(SearchResult result) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: result.imageUrl,
            width: 60,
            height: 60,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              width: 60,
              height: 60,
              color: Colors.grey.shade300,
              child: const Icon(Icons.image),
            ),
            errorWidget: (context, url, error) => Container(
              width: 60,
              height: 60,
              color: Colors.grey.shade300,
              child: const Icon(Icons.image_not_supported),
            ),
          ),
        ),
        title: Text(
          result.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getTypeColor(result.type),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _getTypeLabel(result.type),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (result.price != null)
                  Text(
                    '\$${result.price!.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                const Spacer(),
                Row(
                  children: [
                    const Icon(Icons.star, size: 16, color: Colors.amber),
                    Text(result.rating.toStringAsFixed(1)),
                  ],
                ),
              ],
            ),
          ],
        ),
        onTap: () {
          // Navigate to detail screen
          print('Navigate to ${result.type.name}: ${result.id}');
        },
      ),
    );
  }

  Widget _buildNoResults() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No results found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_popularSearches.isNotEmpty) ...[
            const Text(
              'Popular Searches',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _popularSearches.map((search) {
                return ActionChip(
                  label: Text(search),
                  onPressed: () {
                    _searchController.text = search;
                    _performSearch(search);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
          ],
          
          const Text(
            'Search Tips',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• Use specific keywords for better results',
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Try searching by category or location',
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Use filters to narrow down results',
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Search for "spices", "stone town", "tours"',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getTypeLabel(SearchType type) {
    switch (type) {
      case SearchType.all:
        return 'All';
      case SearchType.products:
        return 'Products';
      case SearchType.culturalSites:
        return 'Sites';
      case SearchType.tours:
        return 'Tours';
    }
  }

  Color _getTypeColor(SearchType type) {
    switch (type) {
      case SearchType.all:
        return Colors.grey;
      case SearchType.products:
        return Colors.blue;
      case SearchType.culturalSites:
        return Colors.green;
      case SearchType.tours:
        return Colors.orange;
    }
  }
}
