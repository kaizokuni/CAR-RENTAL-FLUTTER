import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/api_config.dart';

class ApiService {
  String? _token;

  void setToken(String? token) {
    _token = token;
  }

  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  Future<Map<String, dynamic>> get(String endpoint) async {
    final response = await http.get(
      Uri.parse(ApiConfig.fullUrl(endpoint)),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse(ApiConfig.fullUrl(endpoint)),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> put(String endpoint, Map<String, dynamic> body) async {
    final response = await http.put(
      Uri.parse(ApiConfig.fullUrl(endpoint)),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> delete(String endpoint) async {
    final response = await http.delete(
      Uri.parse(ApiConfig.fullUrl(endpoint)),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Future<List<dynamic>> getList(String endpoint) async {
    final response = await http.get(
      Uri.parse(ApiConfig.fullUrl(endpoint)),
      headers: _headers,
    );
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      // Handle empty or null response body
      if (response.body.isEmpty) return [];
      final decoded = jsonDecode(response.body);
      // Handle null or non-list response
      if (decoded == null) return [];
      if (decoded is! List) return [];
      return decoded;
    } else {
      final error = jsonDecode(response.body);
      throw ApiException(
        statusCode: response.statusCode,
        message: error['error'] ?? 'Request failed',
      );
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      Map<String, dynamic> error = {};
      try {
        error = jsonDecode(response.body);
      } catch (_) {}
      throw ApiException(
        statusCode: response.statusCode,
        message: error['error'] ?? 'Request failed with status ${response.statusCode}',
      );
    }
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException({required this.statusCode, required this.message});

  @override
  String toString() => message;
}

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());
