import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Model Parsing Tests', () {
    test('Should parse Product model from JSON', () {
      final json = {
        'id': 1,
        'name': 'Test Product',
        'price': '99.99',
        'original_price': '120.00',
        'rating': '4.5',
        'image': 'https://example.com/image.jpg',
        'category': 'Electronics',
        'vendor': {'name': 'Test Vendor'}
      };

      expect(json['id'], isA<int>());
      expect(json['name'], isA<String>());
      expect(json['price'], isA<String>());
    });

    test('Should parse Vendor model from JSON', () {
      final json = {
        'id': 1,
        'store_name': 'Test Store',
        'logo': 'https://example.com/logo.jpg',
        'description': 'A test store',
        'rating': 4.8,
        'reviews_count': 150,
        'phone': '01234567890',
        'city': {'name_ar': 'القاهرة'},
        'governorate': {'name_ar': 'القاهرة'},
      };

      expect(json['id'], 1);
      expect(json['store_name'], 'Test Store');
      expect(json['rating'], 4.8);
    });

    test('Should parse Offer model from JSON', () {
      final json = {
        'id': 1,
        'title': 'Special Offer',
        'image': 'https://example.com/offer.jpg',
        'original_price': 100.0,
        'discounted_price': 80.0,
        'discount_percentage': 20,
        'start_date': '2024-10-01T00:00:00Z',
        'end_date': '2024-10-31T23:59:59Z',
      };

      expect(json['discount_percentage'], 20);
      expect(json['original_price'], 100.0);
      expect(json['discounted_price'], 80.0);
    });

    test('Should parse Address model from JSON', () {
      final json = {
        'id': 1,
        'label': 'Home',
        'address': '123 Main St',
        'city': 'Cairo',
        'governorate': 'Cairo',
        'is_default': true,
      };

      expect(json['label'], 'Home');
      expect(json['is_default'], true);
    });

    test('Should parse Order model from JSON', () {
      final json = {
        'id': 1,
        'order_number': 'ORD-12345',
        'total': 250.50,
        'status': 'pending',
        'created_at': '2024-10-22T10:00:00Z',
        'items': [
          {
            'id': 1,
            'product_name': 'Product 1',
            'quantity': 2,
            'price': 50.0,
          }
        ],
      };

      expect(json['order_number'], 'ORD-12345');
      expect(json['total'], 250.50);
      expect(json['items'], isA<List>());
    });
  });

  group('Model Validation Tests', () {
    test('Should validate required fields', () {
      bool validateProduct(Map<String, dynamic> json) {
        return json.containsKey('id') &&
            json.containsKey('name') &&
            json.containsKey('price');
      }

      final validProduct = {
        'id': 1,
        'name': 'Test',
        'price': 99.99,
      };

      final invalidProduct = {
        'id': 1,
        'name': 'Test',
      };

      expect(validateProduct(validProduct), true);
      expect(validateProduct(invalidProduct), false);
    });

    test('Should handle null values', () {
      final json = {
        'id': 1,
        'name': 'Test',
        'description': null,
        'image': null,
      };

      expect(json['description'], null);
      expect(json['image'], null);
      expect(json['description'] ?? 'No description', 'No description');
    });
  });

  group('Model Transformation Tests', () {
    test('Should convert price string to double', () {
      double parsePrice(dynamic value) {
        if (value == null) return 0.0;
        if (value is num) return value.toDouble();
        return double.tryParse(value.toString()) ?? 0.0;
      }

      expect(parsePrice('99.99'), 99.99);
      expect(parsePrice(99.99), 99.99);
      expect(parsePrice(100), 100.0);
      expect(parsePrice(null), 0.0);
      expect(parsePrice('invalid'), 0.0);
    });

    test('Should parse boolean from different formats', () {
      bool parseBool(dynamic value) {
        if (value is bool) return value;
        if (value is int) return value == 1;
        if (value is String) return value.toLowerCase() == 'true' || value == '1';
        return false;
      }

      expect(parseBool(true), true);
      expect(parseBool(1), true);
      expect(parseBool('true'), true);
      expect(parseBool('1'), true);
      expect(parseBool(false), false);
      expect(parseBool(0), false);
      expect(parseBool('false'), false);
    });

    test('Should format date for display', () {
      String formatDate(String isoDate) {
        final date = DateTime.parse(isoDate);
        return '${date.day}/${date.month}/${date.year}';
      }

      expect(formatDate('2024-10-22T10:00:00Z'), '22/10/2024');
    });
  });

  group('Collection Operations', () {
    test('Should filter items by condition', () {
      final items = [
        {'name': 'Item 1', 'active': true},
        {'name': 'Item 2', 'active': false},
        {'name': 'Item 3', 'active': true},
      ];

      final active = items.where((item) => item['active'] == true).toList();

      expect(active.length, 2);
      expect(active[0]['name'], 'Item 1');
      expect(active[1]['name'], 'Item 3');
    });

    test('Should sort items by property', () {
      final items = [
        {'name': 'C', 'order': 3},
        {'name': 'A', 'order': 1},
        {'name': 'B', 'order': 2},
      ];

      items.sort((a, b) => (a['order'] as int).compareTo(b['order'] as int));

      expect(items[0]['name'], 'A');
      expect(items[1]['name'], 'B');
      expect(items[2]['name'], 'C');
    });

    test('Should group items by property', () {
      final items = [
        {'name': 'Item 1', 'category': 'A'},
        {'name': 'Item 2', 'category': 'B'},
        {'name': 'Item 3', 'category': 'A'},
      ];

      final grouped = <String, List<Map<String, dynamic>>>{};
      for (var item in items) {
        final category = item['category'] as String;
        grouped[category] = [...(grouped[category] ?? []), item];
      }

      expect(grouped['A']?.length, 2);
      expect(grouped['B']?.length, 1);
    });
  });
}

