class Product {
  final String id;
  final String name;
  final double price;
  final double discount;
  final String description;
  final String category;
  final String? image;
  final String sellerId;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.discount,
    required this.description,
    required this.category,
    this.image,
    required this.sellerId,
  });

  factory Product.fromMap(Map<String, dynamic> data, String id) {
    return Product(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      discount: (data['discount'] ?? 0).toDouble(),
      price: (data['price'] ?? 0).toDouble(),
      image: data['image'],
      sellerId: data['seller_id'] ?? '',
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'description': description,
      'discount': discount,
      'category': category,
      'image': image,
      'seller_id': sellerId,
    };
  }
}

final List<Product> products = [
  Product(
    id: '1',
    name: 'Handcrafted Wooden Spoon',
    price: 10.99,
    discount: 0.0,
    description:
        'A beautifully handcrafted wooden spoon made from sustainable materials.',
    category: 'Handcrafts',
    image:
        'https://images.unsplash.com/photo-1536000800373-5b5e6020910a?w=900&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MTB8fFdvb2RlbiUyMFNwb29ufGVufDB8fDB8fHww',
    sellerId: '1',
  ),
  Product(
    id: '2',
    name: 'Zanzibar Spice Blend',
    price: 15.99,
    discount: 0.0,
    description:
        'A unique blend of spices from Zanzibar, perfect for seasoning your favorite dishes.',
    category: 'Spices',
    image:
        'https://images.unsplash.com/photo-1700227280140-ee5a75cc096b?w=900&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MTF8fFNwaWNlJTIwQmxlbmR8ZW58MHx8MHx8fDA%3D',
    sellerId: '2',
  ),
  Product(
    id: '3',
    name: 'Traditional Zanzibar Dates',
    price: 29.99,
    discount: 0.2,
    description:
        'A traditional dress made from locally sourced fabrics, perfect for cultural events.',
    category: 'Clothing',
    image:
        'https://images.unsplash.com/photo-1648288718348-4b6d53755716?w=900&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Nnx8RGF0ZXN8ZW58MHx8MHx8fDA%3D',
    sellerId: '3',
  ),
  Product(
    id: '4',
    name: 'Handcrafted Wooden Spoon',
    price: 10.99,
    discount: 0.03,
    description:
        'A beautifully handcrafted wooden spoon made from sustainable materials.',
    category: 'Handcrafts',
    image: 'https://images.unsplash.com/photo-1528735000313-039ec3a473b0',
    sellerId: '1',
  ),
  Product(
    id: '5',
    name: 'Zanzibar Spice Blend',
    price: 15.99,
    discount: 0.0,
    description:
        'A unique blend of spices from Zanzibar, perfect for seasoning your favorite dishes.',
    category: 'Spices',
    image: 'https://images.unsplash.com/photo-1528735000313-039ec3a473b0',
    sellerId: '2',
  ),
  Product(
    id: '6',
    name: 'Traditional Zanzibar Dress',
    price: 29.99,
    discount: 0.0,
    description:
        'A traditional dress made from locally sourced fabrics, perfect for cultural events.',
    category: 'Clothing',
    image: 'https://images.unsplash.com/photo-1528735000313-039ec3a473b0',
    sellerId: '3',
  ),
  Product(
    id: '7',
    name: 'Handcrafted Wooden Spoon',
    price: 10.99,
    discount: 0.0,
    description:
        'A beautifully handcrafted wooden spoon made from sustainable materials.',
    category: 'Handcrafts',
    image: 'https://images.unsplash.com/photo-1528735000313-039ec3a473b0',
    sellerId: '1',
  ),
  Product(
    id: '8',
    name: 'Zanzibar Dates',
    price: 15.99,
    discount: 0.0,
    description:
        'A unique blend of spices from Zanzibar, perfect for seasoning your favorite dishes.',
    category: 'Spices',
    image: 'https://images.unsplash.com/photo-1528735000313-039ec3a473b0',
    sellerId: '2',
  ),
  Product(
    id: '9',
    name: 'Traditional Zanzibar Dress',
    price: 29.99,
    discount: 0.0,
    description:
        'A traditional dress made from locally sourced fabrics, perfect for cultural events.',
    category: 'Clothing',
    image:
        'https://images.unsplash.com/photo-1585531708916-ef80350126d8?w=900&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8NzB8fFphbnppYmFyJTIwRHJlc3N8ZW58MHx8MHx8fDA%3D',
    sellerId: '3',
  ),
];
