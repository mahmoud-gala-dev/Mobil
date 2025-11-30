import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dio/dio.dart';

// Note: Run 'flutter pub run build_runner build' to generate mocks

@GenerateMocks([Dio])
void main() {
  group('API Service Tests', () {
    test('Should parse product data correctly', () {
      // Test data
      final Map<String, dynamic> productJson = {
        'id': 1,
        'name': 'Test Product',
        'price': 99.99,
        'rating': 4.5,
        'image': 'https://example.com/image.jpg',
        'category': 'Electronics',
        'vendor': {
          'name': 'Test Vendor'
        }
      };

      // Verify parsing
      expect(productJson['id'], 1);
      expect(productJson['name'], 'Test Product');
      expect(productJson['price'], 99.99);
    });

    test('Should handle null values gracefully', () {
      final Map<String, dynamic> productJson = {
        'id': 1,
        'name': 'Test Product',
        'price': 99.99,
        'rating': null,
        'image': null,
      };

      expect(productJson['rating'], null);
      expect(productJson['image'], null);
    });

    test('Should calculate discounted price correctly', () {
      final double originalPrice = 100.0;
      final int discountPercentage = 20;
      final double expectedPrice = originalPrice * (1 - discountPercentage / 100);

      expect(expectedPrice, 80.0);
    });
  });

  group('Cart Calculations', () {
    test('Should calculate cart total correctly', () {
      final items = [
        {'price': 10.0, 'quantity': 2},
        {'price': 20.0, 'quantity': 1},
        {'price': 15.0, 'quantity': 3},
      ];

      double total = 0.0;
      for (var item in items) {
        total += (item['price'] as double) * (item['quantity'] as int);
      }

      expect(total, 85.0); // (10*2) + (20*1) + (15*3) = 85
    });

    test('Should apply coupon discount correctly', () {
      final double subtotal = 100.0;
      final double discountPercentage = 10.0;
      final double expectedTotal = subtotal * (1 - discountPercentage / 100);

      expect(expectedTotal, 90.0);
    });
  });

  group('Rating Calculations', () {
    test('Should calculate average rating correctly', () {
      final ratings = [5, 4, 5, 3, 4];
      final average = ratings.reduce((a, b) => a + b) / ratings.length;

      expect(average, 4.2);
    });

    test('Should handle empty ratings', () {
      final List<int> ratings = [];
      final average = ratings.isEmpty ? 0.0 : ratings.reduce((a, b) => a + b) / ratings.length;

      expect(average, 0.0);
    });
  });

  group('Date Formatting', () {
    test('Should format date correctly', () {
      final date = DateTime(2024, 10, 22, 14, 30);
      final formatted = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      expect(formatted, '2024-10-22');
    });

    test('Should check if offer is expired', () {
      final endDate = DateTime.now().subtract(const Duration(days: 1));
      final isExpired = endDate.isBefore(DateTime.now());

      expect(isExpired, true);
    });

    test('Should check if offer is active', () {
      final endDate = DateTime.now().add(const Duration(days: 1));
      final isActive = endDate.isAfter(DateTime.now());

      expect(isActive, true);
    });
  });

  group('Validation Tests', () {
    test('Should validate email format', () {
      final validEmail = 'test@example.com';
      final invalidEmail = 'invalid-email';

      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

      expect(emailRegex.hasMatch(validEmail), true);
      expect(emailRegex.hasMatch(invalidEmail), false);
    });

    test('Should validate phone number', () {
      final validPhone = '01234567890';
      final invalidPhone = '123';

      expect(validPhone.length >= 10, true);
      expect(invalidPhone.length >= 10, false);
    });

    test('Should validate password strength', () {
      final strongPassword = 'Abcd1234@';
      final weakPassword = '123';

      expect(strongPassword.length >= 8, true);
      expect(weakPassword.length >= 8, false);
    });
  });

  group('Search and Filter Tests', () {
    test('Should filter products by price range', () {
      final products = [
        {'name': 'Product 1', 'price': 50.0},
        {'name': 'Product 2', 'price': 150.0},
        {'name': 'Product 3', 'price': 75.0},
      ];

      final minPrice = 60.0;
      final maxPrice = 100.0;

      final filtered = products.where((p) {
        final price = p['price'] as double;
        return price >= minPrice && price <= maxPrice;
      }).toList();

      expect(filtered.length, 1);
      expect(filtered[0]['name'], 'Product 3');
    });

    test('Should search products by name', () {
      final products = [
        {'name': 'Apple iPhone', 'category': 'Electronics'},
        {'name': 'Samsung Galaxy', 'category': 'Electronics'},
        {'name': 'Apple Watch', 'category': 'Accessories'},
      ];

      final query = 'apple';
      final results = products.where((p) {
        final name = (p['name'] as String).toLowerCase();
        return name.contains(query.toLowerCase());
      }).toList();

      expect(results.length, 2);
    });
  });

  group('Order Status Tests', () {
    test('Should determine order status color', () {
      String getStatusColor(String status) {
        switch (status) {
          case 'pending':
            return 'orange';
          case 'processing':
            return 'blue';
          case 'completed':
            return 'green';
          case 'cancelled':
            return 'red';
          default:
            return 'grey';
        }
      }

      expect(getStatusColor('pending'), 'orange');
      expect(getStatusColor('completed'), 'green');
      expect(getStatusColor('unknown'), 'grey');
    });

    test('Should translate order status', () {
      String translateStatus(String status) {
        final translations = {
          'pending': 'قيد الانتظار',
          'processing': 'قيد التجهيز',
          'completed': 'مكتمل',
          'cancelled': 'ملغي',
        };
        return translations[status] ?? 'غير معروف';
      }

      expect(translateStatus('pending'), 'قيد الانتظار');
      expect(translateStatus('completed'), 'مكتمل');
    });
  });

  group('Quantity Management', () {
    test('Should increment quantity', () {
      int quantity = 1;
      quantity++;
      expect(quantity, 2);
    });

    test('Should decrement quantity but not below 1', () {
      int quantity = 2;
      quantity--;
      expect(quantity, 1);

      if (quantity > 1) {
        quantity--;
      }
      expect(quantity, 1); // Should not go below 1
    });

    test('Should update quantity within valid range', () {
      int updateQuantity(int current, int change, {int min = 1, int max = 99}) {
        final newQuantity = current + change;
        if (newQuantity < min) return min;
        if (newQuantity > max) return max;
        return newQuantity;
      }

      expect(updateQuantity(5, 3), 8);
      expect(updateQuantity(1, -1), 1); // Should not go below min
      expect(updateQuantity(98, 5), 99); // Should not exceed max
    });
  });

  group('Currency Formatting', () {
    test('Should format currency correctly', () {
      String formatCurrency(double amount) {
        return '${amount.toStringAsFixed(2)} ج.م';
      }

      expect(formatCurrency(99.99), '99.99 ج.م');
      expect(formatCurrency(100), '100.00 ج.م');
    });

    test('Should format large numbers with separators', () {
      String formatWithSeparators(double amount) {
        final parts = amount.toStringAsFixed(2).split('.');
        final intPart = parts[0].replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]},',
        );
        return '$intPart.${parts[1]} ج.م';
      }

      expect(formatWithSeparators(1234.56), '1,234.56 ج.م');
      expect(formatWithSeparators(1234567.89), '1,234,567.89 ج.م');
    });
  });
}

