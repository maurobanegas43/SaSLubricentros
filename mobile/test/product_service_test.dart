import 'package:flutter_test/flutter_test.dart';
import 'package:lubricentros_app/services/product_service.dart';

void main() {
  group('ProductService Tests', () {
    late ProductService productService;

    setUp(() {
      productService = ProductService();
    });

    test('getProducts returns mock products in dev mode', () async {
      final products = await productService.getProducts();

      expect(products, isNotEmpty);
      expect(products.length, 6);
    });

    test('getProducts filters by category', () async {
      final aceiteProducts =
          await productService.getProducts(category: ProductCategory.aceite);

      expect(aceiteProducts, isNotEmpty);
      expect(aceiteProducts.every((p) => p.category == ProductCategory.aceite),
          true);
    });

    test('getProductById returns correct product', () async {
      final product = await productService.getProductById(1);

      expect(product, isNotNull);
      expect(product?.name, 'Aceite Sintético 5W-30');
    });

    test('getLowStockProducts returns products with stock < 10', () async {
      final lowStockProducts = await productService.getLowStockProducts();

      expect(lowStockProducts, isNotEmpty);
      expect(lowStockProducts.every((p) => p.stock < 10), true);
    });

    test('updateStock returns true in dev mode', () async {
      final result = await productService.updateStock(1, 100);

      expect(result, true);
    });
  });

  group('Product Model Tests', () {
    test('Product fromJson parses correctly', () {
      final json = {
        'id': 1,
        'name': 'Test Product',
        'description': 'Test description',
        'price': 100.50,
        'category': 'aceite',
        'stock': 10,
        'brand': 'TestBrand',
        'sku': 'TEST-001',
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-01T00:00:00Z',
      };

      final product = Product.fromJson(json);

      expect(product.id, 1);
      expect(product.name, 'Test Product');
      expect(product.price, 100.50);
      expect(product.category, ProductCategory.aceite);
      expect(product.stock, 10);
      expect(product.brand, 'TestBrand');
      expect(product.sku, 'TEST-001');
    });

    test('Product toJson generates correct map', () {
      final product = Product(
        id: 1,
        name: 'Test Product',
        description: 'Test description',
        price: 100.50,
        category: ProductCategory.filtro,
        stock: 10,
        brand: 'TestBrand',
        sku: 'TEST-001',
        createdAt: DateTime.parse('2024-01-01T00:00:00Z'),
        updatedAt: DateTime.parse('2024-01-01T00:00:00Z'),
      );

      final json = product.toJson();

      expect(json['name'], 'Test Product');
      expect(json['price'], 100.50);
      expect(json['category'], 'filtro');
      expect(json['sku'], 'TEST-001');
    });

    test('Product isLowStock returns true when stock < 10', () {
      final lowStockProduct = Product(
        id: 1,
        name: 'Test',
        price: 100,
        category: ProductCategory.aceite,
        stock: 5,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(lowStockProduct.isLowStock, true);
    });

    test('Product isLowStock returns false when stock >= 10', () {
      final normalProduct = Product(
        id: 1,
        name: 'Test',
        price: 100,
        category: ProductCategory.aceite,
        stock: 15,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(normalProduct.isLowStock, false);
    });
  });

  group('ProductCategory Extension Tests', () {
    test('value returns correct string', () {
      expect(ProductCategory.aceite.value, 'aceite');
      expect(ProductCategory.filtro.value, 'filtro');
      expect(ProductCategory.frenos.value, 'frenos');
    });

    test('displayName returns user friendly name', () {
      expect(ProductCategory.aceite.displayName, 'Aceite');
      expect(ProductCategory.neumaticos.displayName, 'Neumáticos');
      expect(ProductCategory.bateria.displayName, 'Batería');
    });

    test('fromString parses correctly', () {
      expect(ProductCategoryExtension.fromString('aceite'),
          ProductCategory.aceite);
      expect(ProductCategoryExtension.fromString('filtro'),
          ProductCategory.filtro);
      expect(
          ProductCategoryExtension.fromString('unknown'), ProductCategory.otro);
    });
  });
}
