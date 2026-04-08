import '../utils/secure_logger.dart';
import 'api_client.dart';

enum ProductCategory {
  aceite,
  filtro,
  frenos,
  neumaticos,
  bateria,
  aditivo,
  otro,
}

extension ProductCategoryExtension on ProductCategory {
  String get value {
    switch (this) {
      case ProductCategory.aceite:
        return 'aceite';
      case ProductCategory.filtro:
        return 'filtro';
      case ProductCategory.frenos:
        return 'frenos';
      case ProductCategory.neumaticos:
        return 'neumaticos';
      case ProductCategory.bateria:
        return 'bateria';
      case ProductCategory.aditivo:
        return 'aditivo';
      case ProductCategory.otro:
        return 'otro';
    }
  }

  String get displayName {
    switch (this) {
      case ProductCategory.aceite:
        return 'Aceite';
      case ProductCategory.filtro:
        return 'Filtro';
      case ProductCategory.frenos:
        return 'Frenos';
      case ProductCategory.neumaticos:
        return 'Neumáticos';
      case ProductCategory.bateria:
        return 'Batería';
      case ProductCategory.aditivo:
        return 'Aditivo';
      case ProductCategory.otro:
        return 'Otro';
    }
  }

  static ProductCategory fromString(String value) {
    switch (value) {
      case 'aceite':
        return ProductCategory.aceite;
      case 'filtro':
        return ProductCategory.filtro;
      case 'frenos':
        return ProductCategory.frenos;
      case 'neumaticos':
        return ProductCategory.neumaticos;
      case 'bateria':
        return ProductCategory.bateria;
      case 'aditivo':
        return ProductCategory.aditivo;
      default:
        return ProductCategory.otro;
    }
  }
}

class Product {
  final int id;
  final String name;
  final String? description;
  final double price;
  final ProductCategory category;
  final int stock;
  final String? brand;
  final String? sku;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.category,
    required this.stock,
    this.brand,
    this.sku,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final categoryValue =
        (json['category'] ?? json['categoria'] ?? 'otro') as String;
    final stockValue = json['stock'] ?? json['stock_actual'] ?? 0;
    final priceValue = json['price'] ?? json['precio'] ?? 0;

    return Product(
      id: json['id'] as int,
      name: (json['name'] ?? json['nombre']) as String,
      description: (json['description'] ?? json['descripcion']) as String?,
      price: (priceValue as num).toDouble(),
      category: ProductCategoryExtension.fromString(categoryValue),
      stock: stockValue is int ? stockValue : int.tryParse('$stockValue') ?? 0,
      brand: json['brand'] as String?,
      sku: json['sku'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (description != null) 'description': description,
      'price': price,
      'category': category.value,
      'stock': stock,
      if (brand != null) 'brand': brand,
      if (sku != null) 'sku': sku,
    };
  }

  bool get isLowStock => stock < 10;
}

class ProductService {
  final ApiClient _apiClient;
  static const bool useRealApi = bool.fromEnvironment(
    'USE_REAL_PRODUCT_API',
    defaultValue: true,
  );

  ProductService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Obtiene todos los productos
  Future<List<Product>> getProducts(
      {int offset = 0, int limit = 20, ProductCategory? category}) async {
    if (useRealApi) {
      try {
        final page = (offset ~/ limit) + 1;
        String endpoint = '/products?page=$page&limit=$limit';
        if (category != null) {
          endpoint += '&categoria=${category.value}';
        }
        final response = await _apiClient.get(endpoint);
        if (response.statusCode == 200) {
          final data = ApiClient.extractData(response);
          final productsList = (data is List)
              ? data
              : ((data is Map<String, dynamic> && data['products'] is List)
                  ? data['products'] as List
                  : <dynamic>[]);
          return productsList.map((p) => Product.fromJson(p)).toList();
        } else {
          SecureLogger.error('Failed to fetch products',
              data: {'status': response.statusCode});
          throw Exception(
            ApiClient.extractErrorMessage(
              response,
              fallback: 'Error al cargar productos',
            ),
          );
        }
      } catch (e) {
        SecureLogger.error('Error fetching products', error: e);
        rethrow;
      }
    } else {
      return _getMockProducts(category);
    }
  }

  /// Obtiene un producto por ID
  Future<Product?> getProductById(int id) async {
    if (useRealApi) {
      try {
        final response = await _apiClient.get('/products/$id');
        if (response.statusCode == 200) {
          final data = ApiClient.extractData(response) as Map<String, dynamic>;
          return Product.fromJson(data);
        }
        return null;
      } catch (e) {
        SecureLogger.error('Error fetching product', error: e);
        return null;
      }
    } else {
      final products = _getMockProducts(null);
      return products.where((p) => p.id == id).firstOrNull;
    }
  }

  /// Obtiene productos con bajo stock
  Future<List<Product>> getLowStockProducts() async {
    if (useRealApi) {
      try {
        final response = await _apiClient.get('/admin/products/low-stock');
        if (response.statusCode == 200) {
          final data = ApiClient.extractData(response);
          final productsList = (data is List)
              ? data
              : ((data is Map<String, dynamic> && data['products'] is List)
                  ? data['products'] as List
                  : <dynamic>[]);
          return productsList.map((p) => Product.fromJson(p)).toList();
        }
        return [];
      } catch (e) {
        SecureLogger.error('Error fetching low stock products', error: e);
        return [];
      }
    } else {
      return _getMockProducts(null).where((p) => p.isLowStock).toList();
    }
  }

  /// Actualiza el stock de un producto
  Future<bool> updateStock(int productId, int newStock) async {
    if (useRealApi) {
      try {
        final response = await _apiClient.patch(
          '/products/$productId/stock',
          {'cantidad': newStock},
          requiresAuth: true,
        );
        return response.statusCode == 200;
      } catch (e) {
        SecureLogger.error('Error updating stock', error: e);
        return false;
      }
    } else {
      return true;
    }
  }

  // Mock data
  List<Product> _getMockProducts(ProductCategory? category) {
    final now = DateTime.now();
    final products = [
      Product(
        id: 1,
        name: 'Aceite Sintético 5W-30',
        description: 'Aceite sintético de alta performance',
        price: 2500.00,
        category: ProductCategory.aceite,
        stock: 45,
        brand: 'Mobil',
        sku: 'MOB-5W30',
        createdAt: now,
        updatedAt: now,
      ),
      Product(
        id: 2,
        name: 'Filtro de Aceite Universal',
        description: 'Filtro de aceite compatible con mayoría de vehículos',
        price: 850.00,
        category: ProductCategory.filtro,
        stock: 8, // Low stock
        brand: 'Fram',
        sku: 'FRM-OIL',
        createdAt: now,
        updatedAt: now,
      ),
      Product(
        id: 3,
        name: 'Pastillas de Freno Delanteras',
        description: 'Juego de pastillas de freno delanteras',
        price: 4200.00,
        category: ProductCategory.frenos,
        stock: 12,
        brand: 'Bendix',
        sku: 'BEN-FR-DEL',
        createdAt: now,
        updatedAt: now,
      ),
      Product(
        id: 4,
        name: 'Neumático 185/65 R15',
        description: 'Neumático para sedan compacto',
        price: 18500.00,
        category: ProductCategory.neumaticos,
        stock: 4, // Low stock
        brand: 'Pirelli',
        sku: 'PIR-185-65-15',
        createdAt: now,
        updatedAt: now,
      ),
      Product(
        id: 5,
        name: 'Batería 12V 60Ah',
        description: 'Batería de arranque para automóviles',
        price: 12500.00,
        category: ProductCategory.bateria,
        stock: 6, // Low stock
        brand: 'Epsilon',
        sku: 'EPS-12V60',
        createdAt: now,
        updatedAt: now,
      ),
      Product(
        id: 6,
        name: 'Aditivo Limpiainyectores',
        description: 'Aditivo para limpieza de inyectores',
        price: 1200.00,
        category: ProductCategory.aditivo,
        stock: 30,
        brand: 'Liqui Moly',
        sku: 'LIQ-INY',
        createdAt: now,
        updatedAt: now,
      ),
    ];

    if (category != null) {
      return products.where((p) => p.category == category).toList();
    }
    return products;
  }
}
