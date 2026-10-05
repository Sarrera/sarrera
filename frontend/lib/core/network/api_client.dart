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
        if ((_adminToken == null || _adminToken!.isEmpty) &&
            (html.window.location.hostname == 'localhost' || html.window.location.hostname == '127.0.0.1')) {
          _adminToken = 'sk-master-platform-key-change-me';
          html.window.sessionStorage[_tokenStorageKey] = _adminToken!;
        }
        if (_adminToken != null && _adminToken!.isNotEmpty) {
          syncSsoCookies(
            email: 'admin@sarrera.local',
            name: 'Platform Administrator',
            role: 'admin',
          );
        }
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
        syncSsoCookies(
          email: 'admin@sarrera.local',
          name: 'Platform Administrator',
          role: 'admin',
        );
      } catch (_) {}
    }
  }

  void clearToken() {
    _adminToken = null;
    if (kIsWeb) {
      try {
        html.window.sessionStorage.remove(_tokenStorageKey);
        html.window.localStorage.remove(_tokenStorageKey);
        clearSsoCookies();
      } catch (_) {}
    }
  }

  /// Sets cross-subdomain SSO cookies so Open WebUI and Caddy pick up user identity
  void syncSsoCookies({
    required String email,
    required String name,
    required String role,
  }) {
    if (kIsWeb) {
      try {
        html.document.cookie = 'sarrera_user_email=$email; path=/; SameSite=Lax';
        html.document.cookie = 'sarrera_user_name=$name; path=/; SameSite=Lax';
        html.document.cookie = 'sarrera_user_role=$role; path=/; SameSite=Lax';

        final host = html.window.location.hostname ?? '';
        if (host.isNotEmpty && host != 'localhost') {
          html.document.cookie = 'sarrera_user_email=$email; path=/; domain=.$host; SameSite=Lax';
          html.document.cookie = 'sarrera_user_name=$name; path=/; domain=.$host; SameSite=Lax';
          html.document.cookie = 'sarrera_user_role=$role; path=/; domain=.$host; SameSite=Lax';
        }
      } catch (_) {}
    }
  }

  /// Clears cross-subdomain SSO cookies on logout
  void clearSsoCookies() {
    if (kIsWeb) {
      try {
        html.document.cookie = 'sarrera_user_email=; path=/; max-age=0; expires=Thu, 01 Jan 1970 00:00:00 GMT';
        html.document.cookie = 'sarrera_user_name=; path=/; max-age=0; expires=Thu, 01 Jan 1970 00:00:00 GMT';
        html.document.cookie = 'sarrera_user_role=; path=/; max-age=0; expires=Thu, 01 Jan 1970 00:00:00 GMT';

        final host = html.window.location.hostname ?? '';
        if (host.isNotEmpty && host != 'localhost') {
          html.document.cookie = 'sarrera_user_email=; path=/; domain=.$host; max-age=0; expires=Thu, 01 Jan 1970 00:00:00 GMT';
          html.document.cookie = 'sarrera_user_name=; path=/; domain=.$host; max-age=0; expires=Thu, 01 Jan 1970 00:00:00 GMT';
          html.document.cookie = 'sarrera_user_role=; path=/; domain=.$host; max-age=0; expires=Thu, 01 Jan 1970 00:00:00 GMT';
        }
      } catch (_) {}
    }
  }
}
