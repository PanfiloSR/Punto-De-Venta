import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiService {
  // Para celular físico conectado por USB:
  // adb reverse tcp:3000 tcp:3000
  static const String baseUrl = 'http://10.0.101.59:3000';

  static String? _token;

  static void setToken(String token) {
    _token = token;
  }

  static void clearToken() {
    _token = null;
  }

  static Map<String, String> get _headers {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }

  static dynamic _decodeResponse(
      http.Response response,
      ) {
    dynamic data;

    if (response.body.isNotEmpty) {
      try {
        data = jsonDecode(response.body);
      } catch (_) {
        data = response.body;
      }
    }

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return data;
    }

    String message = 'Error al comunicarse con el servidor.';

    if (data is Map<String, dynamic>) {
      message =
          data['detalle']?.toString() ??
              data['error']?.toString() ??
              data['mensaje']?.toString() ??
              message;
    }

    throw Exception(message);
  }

  static Future<dynamic> _request(
      String method,
      String path, {
        Map<String, dynamic>? body,
      }) async {
    final Uri uri = Uri.parse('$baseUrl$path');

    late http.Response response;

    switch (method) {
      case 'GET':
        response = await http.get(
          uri,
          headers: _headers,
        );
        break;

      case 'POST':
        response = await http.post(
          uri,
          headers: _headers,
          body: jsonEncode(body),
        );
        break;

      case 'PUT':
        response = await http.put(
          uri,
          headers: _headers,
          body: jsonEncode(body),
        );
        break;

      case 'PATCH':
        response = await http.patch(
          uri,
          headers: _headers,
          body: jsonEncode(body),
        );
        break;

      case 'DELETE':
        response = await http.delete(
          uri,
          headers: _headers,
        );
        break;

      default:
        throw Exception('Método HTTP no soportado.');
    }

    return _decodeResponse(response);
  }

  // =========================================================
  // Dashboard
  // =========================================================

  static Future<Map<String, dynamic>> getSummary() async {
    final dynamic data = await _request(
      'GET',
      '/resumen',
    );

    return Map<String, dynamic>.from(data);
  }

  // =========================================================
  // Productos
  // =========================================================

  static Future<List<Map<String, dynamic>>>
  getProducts() async {
    final dynamic data = await _request(
      'GET',
      '/productos',
    );

    return List<Map<String, dynamic>>.from(
      (data as List).map(
            (dynamic item) =>
        Map<String, dynamic>.from(item),
      ),
    );
  }

  static Future<Map<String, dynamic>> createProduct(
      Map<String, dynamic> product,
      ) async {
    final dynamic data = await _request(
      'POST',
      '/productos',
      body: product,
    );

    return Map<String, dynamic>.from(data);
  }

  static Future<Map<String, dynamic>> updateProduct(
      String id,
      Map<String, dynamic> product,
      ) async {
    final dynamic data = await _request(
      'PUT',
      '/productos/$id',
      body: product,
    );

    return Map<String, dynamic>.from(data);
  }

  static Future<void> deleteProduct(
      String id,
      ) async {
    await _request(
      'DELETE',
      '/productos/$id',
    );
  }

  static Future<Map<String, dynamic>> sellProduct(
      String id,
      int quantity,
      ) async {
    final dynamic data = await _request(
      'PATCH',
      '/productos/$id/vender',
      body: {
        'cantidad': quantity,
      },
    );

    return Map<String, dynamic>.from(data);
  }

  // =========================================================
  // Proveedores
  // =========================================================

  static Future<List<Map<String, dynamic>>>
  getProviders() async {
    final dynamic data = await _request(
      'GET',
      '/proveedores',
    );

    return List<Map<String, dynamic>>.from(
      (data as List).map(
            (dynamic item) =>
        Map<String, dynamic>.from(item),
      ),
    );
  }

  static Future<Map<String, dynamic>> createProvider(
      Map<String, dynamic> provider,
      ) async {
    final dynamic data = await _request(
      'POST',
      '/proveedores',
      body: provider,
    );

    return Map<String, dynamic>.from(data);
  }

  static Future<Map<String, dynamic>> updateProvider(
      String id,
      Map<String, dynamic> provider,
      ) async {
    final dynamic data = await _request(
      'PUT',
      '/proveedores/$id',
      body: provider,
    );

    return Map<String, dynamic>.from(data);
  }

  static Future<void> deleteProvider(
      String id,
      ) async {
    await _request(
      'DELETE',
      '/proveedores/$id',
    );
  }

  // =========================================================
  // Ventas
  // =========================================================

  static Future<Map<String, dynamic>> createSale(
      Map<String, dynamic> sale,
      ) async {
    final dynamic data = await _request(
      'POST',
      '/ventas',
      body: sale,
    );

    return Map<String, dynamic>.from(data);
  }

  static Future<List<Map<String, dynamic>>>
  getSales() async {
    final dynamic data = await _request(
      'GET',
      '/ventas',
    );

    return List<Map<String, dynamic>>.from(
      (data as List).map(
            (dynamic item) =>
        Map<String, dynamic>.from(item),
      ),
    );
  }

  static Future<Map<String, dynamic>> getSale(
      String id,
      ) async {
    final dynamic data = await _request(
      'GET',
      '/ventas/$id',
    );

    return Map<String, dynamic>.from(data);
  }
}