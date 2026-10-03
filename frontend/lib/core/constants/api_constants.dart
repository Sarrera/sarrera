import 'package:flutter/foundation.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class ApiConstants {
  // Base URLs (relative to Caddy reverse proxy on same host)
  static const String litellmBase = '/admin/litellm';
  static const String langfuseBase = '/admin/audit';
  static const String v1Base = '/v1';

  // LiteLLM Team / Tier Endpoints
  static const String teamList = '$litellmBase/team/list';
  static const String teamNew = '$litellmBase/team/new';
  static const String teamUpdate = '$litellmBase/team/update';
  static const String teamInfo = '$litellmBase/team/info';
  static const String teamDelete = '$litellmBase/team/delete';
  static const String teamMemberAdd = '$litellmBase/team/member_add';
  static const String teamMemberDelete = '$litellmBase/team/member_delete';

  // LiteLLM User Endpoints
  static const String userList = '$litellmBase/user/list';
  static const String userNew = '$litellmBase/user/new';
  static const String userInfo = '$litellmBase/user/info';
  static const String userUpdate = '$litellmBase/user/update';
  static const String userDelete = '$litellmBase/user/delete';

  // LiteLLM Key Endpoints
  static const String keyGenerate = '$litellmBase/key/generate';
  static const String keyDelete = '$litellmBase/key/delete';
  static const String keyInfo = '$litellmBase/key/info';

  // LiteLLM Node / Model Endpoints
  static const String modelInfo = '$litellmBase/model/info';
  static const String modelNew = '$litellmBase/model/new';
  static const String modelDelete = '$litellmBase/model/delete';

  // Telemetry & Spend Endpoints
  static const String spendReport = '$litellmBase/global/spend/report';

  // Langfuse Telemetry
  static const String langfuseHealth = '$langfuseBase/api/public/health';
  static const String langfuseTraces = '$langfuseBase/api/public/traces';

  // Platform Versioning (SemVer: MAJOR.MINOR.PATCH)
  static const String appVersion = 'v1.2.0';

  // Navigation Links & URLs
  static const String docsUrl = 'https://sarrera.github.io/sarrera/';
  static const String changelogUrl = 'https://sarrera.github.io/sarrera/#/operations/changelog';
  static const String chatUrl = '/chat';
  static const String auditUrl = '/admin/audit/';
  static const String storageUrl = '/admin/storage/';

  /// Dynamically computes the dedicated subdomain URL for Open WebUI Chat
  static String getChatUrl() {
    if (kIsWeb) {
      final host = html.window.location.hostname ?? 'localhost';
      final port = html.window.location.port;
      final portSuffix = (port.isNotEmpty && port != '80' && port != '443') ? ':$port' : '';
      return 'https://chat.$host$portSuffix/';
    }
    return '/chat';
  }

  /// Dynamically computes the dedicated subdomain URL for Langfuse Audit Suite with Single Sign-On (SSO)
  static String getAuditUrl() {
    if (kIsWeb) {
      final host = html.window.location.hostname ?? 'localhost';
      final port = html.window.location.port;
      final portSuffix = (port.isNotEmpty && port != '80' && port != '443') ? ':$port' : '';
      return 'https://audit.$host$portSuffix/sso';
    }
    return '/admin/audit/';
  }

  /// Dynamically computes the dedicated subdomain URL for Ollama Inference Engine & Model Inspector
  static String getOllamaUrl() {
    if (kIsWeb) {
      final host = html.window.location.hostname ?? 'localhost';
      final port = html.window.location.port;
      final portSuffix = (port.isNotEmpty && port != '80' && port != '443') ? ':$port' : '';
      return 'https://ollama.$host$portSuffix/';
    }
    return '/admin/ollama/';
  }

  /// Dynamically computes the dedicated subdomain URL for LiteLLM Gateway & Proxy UI
  static String getGatewayUrl() {
    if (kIsWeb) {
      final host = html.window.location.hostname ?? 'localhost';
      final port = html.window.location.port;
      final portSuffix = (port.isNotEmpty && port != '80' && port != '443') ? ':$port' : '';
      return 'https://gateway.$host$portSuffix/';
    }
    return '/admin/litellm/';
  }

  /// Dynamically computes the dedicated subdomain URL for MinIO Object Storage
  static String getStorageUrl() {
    if (kIsWeb) {
      final host = html.window.location.hostname ?? 'localhost';
      final port = html.window.location.port;
      final portSuffix = (port.isNotEmpty && port != '80' && port != '443') ? ':$port' : '';
      return 'https://storage.$host$portSuffix/';
    }
    return '/admin/storage/';
  }
}
