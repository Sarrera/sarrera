import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio dio;
  String? _adminToken;

  static const String _tokenStorageKey = 'sarrera_admin_token';

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Load initial token if in browser
    if (kIsWeb) {
      try {
        _adminToken = html.window.sessionStorage[_tokenStorageKey] ??
            html.window.localStorage[_tokenStorageKey];
      } catch (_) {}
    }

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_adminToken != null && _adminToken!.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $_adminToken';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) {
          debugPrint('API Error [${error.response?.statusCode}]: ${error.requestOptions.path}');
          return handler.next(error);
        },
      ),
    );
  }

  String? get adminToken => _adminToken;

  bool get isAuthenticated => _adminToken != null && _adminToken!.isNotEmpty;

  void setToken(String token, {bool persist = true}) {
    _adminToken = token.trim();
    if (kIsWeb && persist) {
      try {
        html.window.sessionStorage[_tokenStorageKey] = _adminToken!;
      } catch (_) {}
    }
  }

  void clearToken() {
    _adminToken = null;
    if (kIsWeb) {
      try {
        html.window.sessionStorage.remove(_tokenStorageKey);
        html.window.localStorage.remove(_tokenStorageKey);
      } catch (_) {}
    }
  }
}
