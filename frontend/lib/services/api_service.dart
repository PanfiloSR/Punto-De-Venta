import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

class ApiService {
  String get _baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000'; // Chrome
    } else {
      return 'http://10.0.100.192:3000'; // Para teléfono
    }
  }

  static String? _jwtToken;

  static void setToken(String token) {
    _jwtToken = token;
  }

  // Helper para generar las cabeceras automáticas con el JWT
  Map<String, String> _getHeaders() {
    return {
      "Content-Type": "application/json",
      "Accept": "application/json",
      if (_jwtToken != null) "Authorization": "Bearer $_jwtToken",
    };
  }

  // --- MÓDULO DE PRODUCTOS (CRUD + VENTA) ---

  // 1. CONSULTA (Read)
  Future<List<dynamic>> obtenerProductos() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/productos'),
        headers: _getHeaders(),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print("Error al obtener productos: $e");
    }
    return [];
  }

  // 2. ALTA (Create)
  Future<bool> crearProducto(Map<String, dynamic> datosProducto) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/productos'),
        headers: _getHeaders(),
        body: jsonEncode(datosProducto),
      );
      return response.statusCode == 201;
    } catch (e) {
      print("Error al crear producto: $e");
      return false;
    }
  }

  // 3. MODIFICACIÓN (Update)
  Future<bool> actualizarProducto(
    String id,
    Map<String, dynamic> datosProducto,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/productos/$id'),
        headers: _getHeaders(),
        body: jsonEncode(datosProducto),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error al actualizar producto: $e");
      return false;
    }
  }

  // ➔ REQUISITO R3: VENDER PRODUCTO (Disminuir número del inventario)
  Future<bool> venderProducto(String id, int cantidad) async {
    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/productos/$id/vender'),
        headers: _getHeaders(),
        body: jsonEncode({
          "cantidad": cantidad,
        }), // Mandamos la cantidad elegida al backend
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error al vender producto: $e");
      return false;
    }
  }

  // 4. BAJA (Delete)
  Future<bool> eliminarProducto(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/productos/$id'),
        headers: _getHeaders(),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error al eliminar producto: $e");
      return false;
    }
  }

  // Tu test original por si lo ocupas
  Future<Map<String, dynamic>?> verificarTest() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/'),
        headers: _getHeaders(),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print("Error conectando al backend: $e");
    }
    return null;
  }
}
