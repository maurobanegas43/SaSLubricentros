import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lubricentros_app/services/api_client.dart';
import 'package:lubricentros_app/services/product_service.dart';

void main() {
  group('ProductService contract tests', () {
    late ProductService productService;
    late List<http.Request> capturedRequests;

    setUp(() {
      capturedRequests = [];

      final mockClient = MockClient((request) async {
        capturedRequests.add(request);
        final path = request.url.path;

        if (path == '/products' && request.method == 'GET') {
          final category = request.url.queryParameters['categoria'];
          final allProducts = [
            {
              'id': 1,
              'nombre': 'Aceite Sintético 5W-30',
              'categoria': 'aceite',
              'precio': 2500.0,
              'stock_actual': 15,
              'created_at': '2024-01-01T00:00:00Z',
              'updated_at': '2024-01-01T00:00:00Z',
            },
            {
              'id': 2,
              'nombre': 'Filtro de Aceite Universal',
              'categoria': 'filtro',
              'precio': 850.0,
              'stock_actual': 5,
              'created_at': '2024-01-01T00:00:00Z',
              'updated_at': '2024-01-01T00:00:00Z',
            },
          ];

          final filtered = category == null
              ? allProducts
              : allProducts.where((p) => p['categoria'] == category).toList();

          return http.Response(
            jsonEncode({
              'success': true,
              'data': filtered,
              'meta': {
                'total': filtered.length,
                'offset': 0,
                'limit': 20,
                'has_more': false,
              }
            }),
            200,
          );
        }

        if (path == '/products/1' && request.method == 'GET') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'id': 1,
                'nombre': 'Aceite Sintético 5W-30',
                'categoria': 'aceite',
                'precio': 2500.0,
                'stock_actual': 15,
                'created_at': '2024-01-01T00:00:00Z',
                'updated_at': '2024-01-01T00:00:00Z',
              }
            }),
            200,
          );
        }

        if (path == '/admin/products/low-stock' && request.method == 'GET') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [
                {
                  'id': 2,
                  'nombre': 'Filtro de Aceite Universal',
                  'categoria': 'filtro',
                  'precio': 850.0,
                  'stock_actual': 5,
                  'created_at': '2024-01-01T00:00:00Z',
                  'updated_at': '2024-01-01T00:00:00Z',
                }
              ]
            }),
            200,
          );
        }

        if (path == '/products/1/stock' && request.method == 'PATCH') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['cantidad'], 100);
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {'message': 'Stock updated successfully'}
            }),
            200,
          );
        }

        return http.Response(
          jsonEncode({'success': false, 'error': 'Not Found'}),
          404,
        );
      });

      final apiClient = ApiClient(client: mockClient)..setToken('test-token');
      productService = ProductService(apiClient: apiClient);
    });

    test('getProducts parses paginated backend envelope', () async {
      final products = await productService.getProducts();

      expect(products, isNotEmpty);
      expect(products.length, 2);
      expect(products.first.name, 'Aceite Sintético 5W-30');
      expect(products.first.category, ProductCategory.aceite);
      expect(products.first.stock, 15);

      final firstRequest = capturedRequests.first;
      expect(firstRequest.url.queryParameters['page'], '1');
      expect(firstRequest.url.queryParameters['limit'], '20');
      expect(firstRequest.headers['authorization'], 'Bearer test-token');
    });

    test('getProducts sends categoria filter in query', () async {
      final aceiteProducts =
          await productService.getProducts(category: ProductCategory.aceite);

      expect(aceiteProducts, isNotEmpty);
      expect(aceiteProducts.every((p) => p.category == ProductCategory.aceite),
          isTrue);

      final request = capturedRequests.first;
      expect(request.url.queryParameters['categoria'], 'aceite');
    });

    test('getProductById parses backend product payload', () async {
      final product = await productService.getProductById(1);

      expect(product, isNotNull);
      expect(product!.id, 1);
      expect(product.name, 'Aceite Sintético 5W-30');
      expect(product.price, 2500.0);
    });

    test('getLowStockProducts parses low stock endpoint', () async {
      final lowStockProducts = await productService.getLowStockProducts();

      expect(lowStockProducts, isNotEmpty);
      expect(lowStockProducts.length, 1);
      expect(lowStockProducts.every((p) => p.stock < 10), isTrue);
    });

    test('updateStock sends cantidad and returns true', () async {
      final result = await productService.updateStock(1, 100);

      expect(result, isTrue);

      final request = capturedRequests.last;
      expect(request.method, 'PATCH');
      expect(request.url.path, '/products/1/stock');
      expect(request.headers['authorization'], 'Bearer test-token');
    });
  });

  group('Product Model Tests', () {
    test('Product fromJson parses backend fields correctly', () {
      final json = {
        'id': 1,
        'nombre': 'Test Product',
        'descripcion': 'Test description',
        'precio': 100.50,
        'categoria': 'aceite',
        'stock_actual': 10,
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
