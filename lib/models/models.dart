import '../config/api_config.dart';

// ============ SLIDER MODEL ============
class SliderModel {
  final int id;
  final String? title;
  final String? subtitle;
  final String? description;
  final String? buttonText;
  final String? buttonUrl;
  final String? image;
  final String? backgroundImage;
  final String? badge;
  final String? gradientColor;
  final int sortOrder;
  final bool isActive;

  const SliderModel({
    required this.id,
    this.title,
    this.subtitle,
    this.description,
    this.buttonText,
    this.buttonUrl,
    this.image,
    this.backgroundImage,
    this.badge,
    this.gradientColor,
    required this.sortOrder,
    required this.isActive,
  });

  factory SliderModel.fromApi(Map<String, dynamic> json) {
    // معالجة مسارات الصور
    String? getImageUrl(String? path) {
      if (path == null || path.isEmpty) return null;
      if (path.startsWith('http')) return path;
      return '${ApiConfig.storageUrl}/$path';
    }

    return SliderModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title'] as String?,
      subtitle: json['subtitle'] as String?,
      description: json['description'] as String?,
      buttonText: json['button_text'] as String?,
      buttonUrl: json['button_url'] as String?,
      image: getImageUrl(json['image_url'] as String?) ?? getImageUrl(json['image'] as String?),
      backgroundImage: getImageUrl(json['background_image_url'] as String?) ?? getImageUrl(json['background_image'] as String?),
      badge: json['badge'] as String?,
      gradientColor: json['gradient_color'] as String?,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      isActive: json['is_active'] == true || json['is_active'] == 1,
    );
  }
}

// ============ CATEGORY MODEL ============
class CategoryModel {
  final String id; // slug
  final int dbId; // id من قاعدة البيانات
  final String name;
  final String image;
  final int productsCount;
  
  const CategoryModel({
    required this.id, 
    required this.dbId,
    required this.name, 
    required this.image,
    this.productsCount = 0,
  });

  factory CategoryModel.fromApi(Map<String, dynamic> json) {
    // قراءة البيانات من API بشكل صحيح
    final slug = (json['slug'] as String?) ?? '';
    final dbId = (json['id'] as num?)?.toInt() ?? 0;
    final name = (json['name_ar'] as String?) ?? (json['name'] as String?) ?? 'غير معروف';
    
    // قراءة عدد المنتجات من API
    final productsCount = (json['products_count'] as num?)?.toInt() ?? 0;
    
    String image = '';
    
    // أولوية 1: image_url (المسار الكامل من الباك إند)
    if (json['image_url'] != null && (json['image_url'] as String).isNotEmpty) {
      image = json['image_url'] as String;
    }
    // أولوية 2: إذا لم يكن موجوداً، استخدم image
    else if (json['image'] != null && (json['image'] as String).isNotEmpty) {
      final imagePath = json['image'] as String;
      
      // إذا كانت الصورة تحتوي على رابط كامل (يبدأ بـ http)، استخدمها مباشرة
      if (imagePath.startsWith('http')) {
        image = imagePath;
      }
      // إذا كانت الصورة نسبية (لا تبدأ بـ http)، أضف المسار الكامل
      else {
        // استخدم المسار الأساسي من الإعدادات
        final baseUrl = ApiConfig.storageUrl;
        // إضافة / في البداية إذا لم تكن موجودة
        final cleanPath = imagePath.startsWith('/') ? imagePath : '/$imagePath';
        image = '$baseUrl$cleanPath';
      }
    }
    // أولوية 3: استخدم صورة افتراضية من assets أو placeholder آمن
    else {
      image = _categoryImage(slug);
    }
    
    return CategoryModel(
      id: slug,
      dbId: dbId,
      name: name,
      image: image,
      productsCount: productsCount,
    );
  }
}

String _categoryImage(String slug) {
  // استخدام صور من Pexels بدلاً من via.placeholder.com
  switch (slug) {
    case 'fruits-vegetables':
      return 'https://images.pexels.com/photos/8805175/pexels-photo-8805175.jpeg';
    case 'dairy':
      return 'https://images.pexels.com/photos/8064204/pexels-photo-8064204.jpeg';
    case 'meat-poultry':
      return 'https://images.pexels.com/photos/19352815/pexels-photo-19352815.jpeg';
    case 'bakery':
      return 'https://images.pexels.com/photos/2680601/pexels-photo-2680601.jpeg';
    case 'frozen':
      return 'https://images.pexels.com/photos/4846308/pexels-photo-4846308.jpeg';
    default:
      // استخدام صورة من Pexels بدلاً من via.placeholder.com
      return 'https://images.pexels.com/photos/264636/pexels-photo-264636.jpeg';
  }
}

// ============ PRODUCT MODEL ============
class ProductModel {
  final int id;
  final String name;
  final String image;
  final double price;
  final double? originalPrice;
  final double rating;
  final String category;
  final String supplier;
  const ProductModel({
    required this.id,
    required this.name,
    required this.image,
    required this.price,
    this.originalPrice,
    required this.rating,
    required this.category,
    required this.supplier,
  });

  factory ProductModel.fromApi(Map<String, dynamic> json) {
    double parseNum(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    String img = '';
    
    // أولوية 1: image_url (المسار الكامل من الباك إند)
    if (json['image_url'] != null && (json['image_url'] as String).isNotEmpty) {
      img = json['image_url'] as String;
    }
    // أولوية 2: استخدم image
    else if (json['image'] != null && (json['image'] as String).isNotEmpty) {
      final imagePath = json['image'] as String;
      
      // إذا كانت الصورة تحتوي على رابط كامل، استخدمها مباشرة
      if (imagePath.startsWith('http')) {
        img = imagePath;
      }
      // إذا كانت الصورة نسبية (لا تبدأ بـ http)، أضف المسار الكامل
      else {
        final baseUrl = ApiConfig.storageUrl;
        final cleanPath = imagePath.startsWith('/') ? imagePath : '/$imagePath';
        img = '$baseUrl$cleanPath';
      }
    }
    // أولوية 3: استخدم images_urls
    else if (json['images_urls'] != null && (json['images_urls'] as List).isNotEmpty) {
      final imagesUrls = json['images_urls'] as List;
      img = imagesUrls.first as String;
    }
    // أولوية 4: استخدم images
    else if (json['images'] != null && (json['images'] as List).isNotEmpty) {
      final images = json['images'] as List;
      final imagePath = images.first as String;
      
      // إذا كانت الصورة تحتوي على رابط كامل، استخدمها مباشرة
      if (imagePath.startsWith('http')) {
        img = imagePath;
      }
      // إذا كانت الصورة نسبية (لا تبدأ بـ http)، أضف المسار الكامل
      else {
        final baseUrl = ApiConfig.storageUrl;
        final cleanPath = imagePath.startsWith('/') ? imagePath : '/$imagePath';
        img = '$baseUrl$cleanPath';
      }
    }
    // استخدم placeholder آمن من Pexels إذا لم يكن هناك صورة
    else {
      img = 'https://images.pexels.com/photos/1656663/pexels-photo-1656663.jpeg';
    }

    // معالجة آمنة لـ category (قد يكون String أو Map)
    String categoryName = '';
    if (json['category'] is String) {
      categoryName = json['category'] as String;
    } else if (json['category'] is Map) {
      final catMap = json['category'] as Map<String, dynamic>;
      categoryName = (catMap['name_ar'] as String?) ?? 
                     (catMap['name'] as String?) ?? 
                     (catMap['name_en'] as String?) ?? '';
    }
    
    // معالجة آمنة لـ vendor/supplier
    String supplierName = '';
    if (json['vendor'] is String) {
      supplierName = json['vendor'] as String;
    } else if (json['vendor'] is Map) {
      final vendorMap = json['vendor'] as Map<String, dynamic>;
      supplierName = (vendorMap['name_ar'] as String?) ?? 
                     (vendorMap['name'] as String?) ?? 
                     (vendorMap['store_name'] as String?) ?? '';
    }

    return ProductModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String?) ?? 'منتج غير معروف',
      image: img,
      price: parseNum(json['price']),
      originalPrice: json['original_price'] != null ? parseNum(json['original_price']) : null,
      rating: parseNum(json['rating']),
      category: categoryName,
      supplier: supplierName,
    );
  }
}

// ============ VENDOR MODEL ============
class VendorModel {
  final int id;
  final String storeName;
  final String? logo;
  final String? description;
  final double rating;
  final int reviewsCount;
  final String? phone;
  final String? city;
  final String? governorate;

  const VendorModel({
    required this.id,
    required this.storeName,
    this.logo,
    this.description,
    required this.rating,
    required this.reviewsCount,
    this.phone,
    this.city,
    this.governorate,
  });

  factory VendorModel.fromApi(Map<String, dynamic> json) {
    return VendorModel(
      id: (json['id'] as num).toInt(),
      storeName: json['store_name'] as String? ?? '',
      logo: json['logo'] as String?,
      description: json['description'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewsCount: (json['reviews_count'] as num?)?.toInt() ?? 0,
      phone: json['phone'] as String?,
      city: json['city']?['name_ar'] as String?,
      governorate: json['governorate']?['name_ar'] as String?,
    );
  }
}

// ============ OFFER MODEL ============
class OfferModel {
  final int id;
  final String title;
  final String? image;
  final double originalPrice;
  final double discountedPrice;
  final int discountPercentage;
  final DateTime? startDate;
  final DateTime? endDate;

  const OfferModel({
    required this.id,
    required this.title,
    this.image,
    required this.originalPrice,
    required this.discountedPrice,
    required this.discountPercentage,
    this.startDate,
    this.endDate,
  });

  factory OfferModel.fromApi(Map<String, dynamic> json) {
    return OfferModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      image: json['image'] as String?,
      originalPrice: (json['original_price'] as num?)?.toDouble() ?? 0.0,
      discountedPrice: (json['discounted_price'] as num?)?.toDouble() ?? 0.0,
      discountPercentage: (json['discount_percentage'] as num?)?.toInt() ?? 0,
      startDate: json['start_date'] != null ? DateTime.tryParse(json['start_date']) : null,
      endDate: json['end_date'] != null ? DateTime.tryParse(json['end_date']) : null,
    );
  }
}

// ============ REVIEW MODEL ============
class ReviewModel {
  final int id;
  final int rating;
  final String? comment;
  final String userName;
  final DateTime createdAt;
  final List<String> images;
  final int helpfulCount;
  final int notHelpfulCount;

  const ReviewModel({
    required this.id,
    required this.rating,
    this.comment,
    required this.userName,
    required this.createdAt,
    required this.images,
    required this.helpfulCount,
    required this.notHelpfulCount,
  });

  factory ReviewModel.fromApi(Map<String, dynamic> json) {
    return ReviewModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      comment: json['comment'] as String?,
      userName: json['user']?['name'] as String? ?? 'مستخدم',
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
      images: (json['images'] as List?)?.cast<String>() ?? [],
      helpfulCount: (json['helpful_count'] as num?)?.toInt() ?? 0,
      notHelpfulCount: (json['not_helpful_count'] as num?)?.toInt() ?? 0,
    );
  }
}

// ============ ADDRESS MODEL ============
class AddressModel {
  final int id;
  final String label;
  final String address;
  final String? city;
  final String? governorate;
  final String? phone;
  final bool isDefault;

  const AddressModel({
    required this.id,
    required this.label,
    required this.address,
    this.city,
    this.governorate,
    this.phone,
    required this.isDefault,
  });

  factory AddressModel.fromApi(Map<String, dynamic> json) {
    String? city = json['city'] as String?;
    if (city == 'Voluptate velit exer.') {
      city = null;
    }

    return AddressModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      label: (json['label'] as String?) ?? (json['title'] as String?) ?? '',
      address: json['address'] as String? ?? '',
      city: city,
      governorate: json['governorate'] as String?,
      phone: json['phone'] as String?,
      isDefault: json['is_default'] == true || json['is_default'] == 1,
    );
  }
}

// ============ ORDER MODEL ============
class OrderModel {
  final int id;
  final String orderNumber;
  final double total;
  final String status;
  final DateTime createdAt;
  final List<OrderItemModel> items;

  const OrderModel({
    required this.id,
    required this.orderNumber,
    required this.total,
    required this.status,
    required this.createdAt,
    required this.items,
  });

  factory OrderModel.fromApi(Map<String, dynamic> json) {
    return OrderModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      orderNumber: json['order_number'] as String? ?? '',
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'pending',
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
      items: (json['items'] as List?)
              ?.map((item) => OrderItemModel.fromApi(item))
              .toList() ??
          [],
    );
  }
}

// ============ ORDER ITEM MODEL ============
class OrderItemModel {
  final int id;
  final String productName;
  final int quantity;
  final double price;
  final String? image;

  const OrderItemModel({
    required this.id,
    required this.productName,
    required this.quantity,
    required this.price,
    this.image,
  });

  factory OrderItemModel.fromApi(Map<String, dynamic> json) {
    return OrderItemModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      productName: json['product_name'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      image: json['product']?['image'] as String?,
    );
  }
}

// ============ USER MODEL ============
class UserModel {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? avatar;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatar,
  });

  factory UserModel.fromApi(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      avatar: json['avatar'] as String?,
    );
  }
}

// ============ CART ITEM MODEL ============
class CartItemModel {
  final int productId;
  final String productName;
  final double price;
  final int quantity;
  final String? image;
  final double subtotal;

  const CartItemModel({
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    this.image,
    required this.subtotal,
  });

  factory CartItemModel.fromApi(Map<String, dynamic> json) {
    return CartItemModel(
      productId: (json['product_id'] as num?)?.toInt() ?? 0,
      productName: json['product_name'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      image: json['product']?['image'] as String?,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

