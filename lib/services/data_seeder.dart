// File: lib/services/data_seeder.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class DataSeeder {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> seedSampleData() async {
    try {
      // Check if data already exists
      final productsSnapshot =
          await _firestore.collection('products').limit(1).get();
      if (productsSnapshot.docs.isNotEmpty) {
        print('Sample data already exists');
        return;
      }

      // Seed sample products
      await _seedProducts();

      // Seed sample cultural sites
      await _seedCulturalSites();

      // Seed sample educational content
      await _seedEducationalContent();

      // Seed sample tours
      await _seedTours();

      // Seed sample promotions
      await _seedPromotions();

      print('Sample data seeded successfully');
    } catch (e) {
      print('Error seeding data: $e');
    }
  }

  static Future<void> _seedProducts() async {
    final products = [
      {
        'name': 'Zanzibar Spice Mix',
        'description':
            'Authentic blend of local spices including cardamom, cinnamon, and cloves',
        'price': 15.99,
        'category': 'Spices',
        'image':
            'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?w=500',
        'sellerName': 'Spice Palace',
        'sellerId': 'seller1',
        'stock': 50,
        'rating': 4.8,
        'reviews': 23,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Handwoven Kikoy',
        'description': 'Traditional Swahili cotton wrap in vibrant colors',
        'price': 25.00,
        'category': 'Clothing',
        'image':
            'https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?w=500',
        'sellerName': 'Zanzibar Textiles',
        'sellerId': 'seller2',
        'stock': 30,
        'rating': 4.6,
        'reviews': 15,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Makonde Wood Carving',
        'description': 'Intricate traditional sculpture carved from ebony wood',
        'price': 75.00,
        'category': 'Art',
        'image':
            'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=500',
        'sellerName': 'Makonde Arts',
        'sellerId': 'seller3',
        'stock': 10,
        'rating': 4.9,
        'reviews': 8,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Coconut Oil Soap',
        'description': 'Natural handmade soap with coconut oil and local herbs',
        'price': 8.50,
        'category': 'Handcrafts',
        'image':
            'https://images.unsplash.com/photo-1556228720-195a672e8a03?w=500',
        'sellerName': 'Natural Zanzibar',
        'sellerId': 'seller4',
        'stock': 100,
        'rating': 4.7,
        'reviews': 42,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Silver Jewelry Set',
        'description':
            'Handcrafted silver necklace and earrings with traditional patterns',
        'price': 45.00,
        'category': 'Jewelry',
        'image':
            'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?w=500',
        'sellerName': 'Zanzibar Silver',
        'sellerId': 'seller5',
        'stock': 20,
        'rating': 4.8,
        'reviews': 12,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Baobab Fruit Powder',
        'description': 'Organic superfood powder from the iconic baobab tree',
        'price': 18.00,
        'category': 'Food',
        'image':
            'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=500',
        'sellerName': 'Baobab Organics',
        'sellerId': 'seller6',
        'stock': 75,
        'rating': 4.5,
        'reviews': 28,
        'createdAt': FieldValue.serverTimestamp(),
      },
    ];

    final batch = _firestore.batch();
    for (final product in products) {
      final docRef = _firestore.collection('products').doc();
      batch.set(docRef, product);
    }
    await batch.commit();
  }

  static Future<void> _seedCulturalSites() async {
    final sites = [
      {
        'name': 'Stone Town',
        'description':
            'Historic center of Zanzibar City, UNESCO World Heritage Site',
        'category': 'Historical',
        'location': const GeoPoint(-6.1659, 39.2026),
        'images': [
          'https://images.unsplash.com/photo-1589307357824-56dc9a5bf8a8?w=800',
          'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=800',
        ],
        'openingHours': '24/7',
        'entryFee': 0.0,
        'rating': 4.8,
        'reviews': 156,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Jozani Forest',
        'description':
            'Home to the endemic Red Colobus monkeys and diverse wildlife',
        'category': 'Nature',
        'location': const GeoPoint(-6.3000, 39.4000),
        'images': [
          'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=800',
        ],
        'openingHours': '7:30 AM - 5:00 PM',
        'entryFee': 10.0,
        'rating': 4.6,
        'reviews': 89,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Prison Island',
        'description': 'Former prison turned giant tortoise sanctuary',
        'category': 'Historical',
        'location': const GeoPoint(-6.1500, 39.1800),
        'images': [
          'https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?w=800',
        ],
        'openingHours': '9:00 AM - 4:00 PM',
        'entryFee': 15.0,
        'rating': 4.4,
        'reviews': 67,
        'createdAt': FieldValue.serverTimestamp(),
      },
    ];

    final batch = _firestore.batch();
    for (final site in sites) {
      final docRef = _firestore.collection('cultural_sites').doc();
      batch.set(docRef, site);
    }
    await batch.commit();
  }

  static Future<void> _seedEducationalContent() async {
    final content = [
      {
        'title': 'History of Zanzibar',
        'content':
            'Zanzibar has a rich history spanning over 1000 years, influenced by Arab, Persian, Indian, and European cultures. The islands were an important trading hub for spices, ivory, and slaves.',
        'category': 'History',
        'author': 'Dr. Amina Hassan',
        'readTime': 5,
        'tags': ['history', 'culture', 'trading'],
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'title': 'Swahili Culture and Language',
        'content':
            'Swahili culture is a unique blend of African, Arab, and Indian influences. The language serves as a lingua franca across East Africa and reflects this cultural diversity.',
        'category': 'Culture',
        'author': 'Prof. Said Khamis',
        'readTime': 7,
        'tags': ['language', 'culture', 'swahili'],
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'title': 'Zanzibar Spice Trade',
        'content':
            'Known as the "Spice Islands," Zanzibar was once the world\'s largest producer of cloves. Learn about the spice trade that shaped the islands\' economy and culture.',
        'category': 'History',
        'author': 'Dr. Fatma Ali',
        'readTime': 6,
        'tags': ['spices', 'trade', 'economy'],
        'createdAt': FieldValue.serverTimestamp(),
      },
    ];

    final batch = _firestore.batch();
    for (final item in content) {
      final docRef = _firestore.collection('educational_content').doc();
      batch.set(docRef, item);
    }
    await batch.commit();
  }

  static Future<void> _seedTours() async {
    final tours = [
      {
        'title': 'Spice Farm Tour',
        'description':
            'Discover the scents and flavors of Zanzibar\'s famous spices. Visit traditional spice farms and learn about cardamom, cinnamon, cloves, and more.',
        'duration': '4 hours',
        'price': 35.0,
        'maxParticipants': 15,
        'difficulty': 'Easy',
        'category': 'Cultural',
        'images': [
          'https://www.zanzibar-tours.co.tz/wp-content/uploads/2024/12/146-2.jpg',
          'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?w=800',
        ],
        'highlights': [
          'Visit traditional spice farms',
          'Learn about spice cultivation',
          'Taste fresh tropical fruits',
          'Traditional Swahili lunch included',
        ],
        'included': ['Transportation', 'Guide', 'Lunch', 'Spice tasting'],
        'meetingPoint': 'Stone Town Cultural Centre',
        'rating': 4.8,
        'reviews': 156,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'title': 'Prison Island Excursion',
        'description':
            'Visit the historical Changuu Island and meet the famous giant tortoises. Learn about the island\'s fascinating history as a former prison.',
        'duration': '3 hours',
        'price': 25.0,
        'maxParticipants': 20,
        'difficulty': 'Easy',
        'category': 'Historical',
        'images': [
          'https://www.zanzibar-tours.co.tz/wp-content/uploads/2024/11/tour_gallery_23-800x450.jpg',
          'https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?w=800',
        ],
        'highlights': [
          'Meet giant Aldabra tortoises',
          'Explore historical prison ruins',
          'Snorkeling opportunity',
          'Beautiful coral reef views',
        ],
        'included': ['Boat transfer', 'Guide', 'Snorkeling gear', 'Entry fees'],
        'meetingPoint': 'Stone Town Harbor',
        'rating': 4.6,
        'reviews': 89,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'title': 'Jozani Forest Adventure',
        'description':
            'Explore the lush Jozani Chwaka Bay National Park and spot the rare Red Colobus monkeys found only in Zanzibar.',
        'duration': '3.5 hours',
        'price': 30.0,
        'maxParticipants': 12,
        'difficulty': 'Moderate',
        'category': 'Nature',
        'images': [
          'https://www.zanzibar-tours.co.tz/wp-content/uploads/2024/12/P12-16-720x450.jpg',
          'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=800',
        ],
        'highlights': [
          'Spot Red Colobus monkeys',
          'Walk through mangrove boardwalk',
          'Learn about conservation efforts',
          'Diverse wildlife viewing',
        ],
        'included': ['Transportation', 'Guide', 'Park fees', 'Refreshments'],
        'meetingPoint': 'Jozani Forest Entrance',
        'rating': 4.7,
        'reviews': 134,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'title': 'Stone Town Walking Tour',
        'description':
            'Discover the rich history and culture of Stone Town, a UNESCO World Heritage Site, through its narrow streets and historic buildings.',
        'duration': '2.5 hours',
        'price': 20.0,
        'maxParticipants': 25,
        'difficulty': 'Easy',
        'category': 'Cultural',
        'images': [
          'https://images.unsplash.com/photo-1589307357824-56dc9a5bf8a8?w=800',
          'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=800',
        ],
        'highlights': [
          'Visit House of Wonders',
          'Explore Forodhani Gardens',
          'See Sultan\'s Palace',
          'Traditional architecture tour',
        ],
        'included': [
          'Professional guide',
          'Historical insights',
          'Photo opportunities',
        ],
        'meetingPoint': 'Forodhani Gardens',
        'rating': 4.5,
        'reviews': 203,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
    ];

    final batch = _firestore.batch();
    for (final tour in tours) {
      final docRef = _firestore.collection('tours').doc();
      batch.set(docRef, tour);
    }
    await batch.commit();
  }

  static Future<void> _seedPromotions() async {
    final promotions = [
      {
        'title': '10% Off Guided Tours!',
        'subtitle': 'Book your next adventure now and save big!',
        'description':
            'Get 10% discount on all guided tours when you book before the end of this month. Valid for all tour packages.',
        'discountPercentage': 10.0,
        'discountCode': 'TOUR10',
        'validFrom': DateTime.now(),
        'validUntil': DateTime.now().add(const Duration(days: 30)),
        'image':
            'https://dynamic-media-cdn.tripadvisor.com/media/photo-o/2f/53/df/3a/farma-koreni-a-kamenne.jpg?w=1100&h=-1&s=1',
        'category': 'Tours',
        'isActive': true,
        'maxUses': 100,
        'currentUses': 0,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'title': 'Free Spice Tasting!',
        'subtitle': 'Complimentary spice tasting with every spice farm tour',
        'description':
            'Experience the authentic flavors of Zanzibar with our complimentary spice tasting session included in every spice farm tour.',
        'discountPercentage': 0.0,
        'discountCode': 'SPICEFREE',
        'validFrom': DateTime.now(),
        'validUntil': DateTime.now().add(const Duration(days: 60)),
        'image':
            'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?w=800',
        'category': 'Tours',
        'isActive': true,
        'maxUses': 200,
        'currentUses': 0,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'title': 'Early Bird Special',
        'subtitle': '15% off for bookings made 7 days in advance',
        'description':
            'Plan ahead and save! Get 15% off any tour package when you book at least 7 days in advance.',
        'discountPercentage': 15.0,
        'discountCode': 'EARLY15',
        'validFrom': DateTime.now(),
        'validUntil': DateTime.now().add(const Duration(days: 90)),
        'image':
            'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=800',
        'category': 'Tours',
        'isActive': true,
        'maxUses': 50,
        'currentUses': 0,
        'createdAt': FieldValue.serverTimestamp(),
      },
    ];

    final batch = _firestore.batch();
    for (final promotion in promotions) {
      final docRef = _firestore.collection('promotions').doc();
      batch.set(docRef, promotion);
    }
    await batch.commit();
  }
}
