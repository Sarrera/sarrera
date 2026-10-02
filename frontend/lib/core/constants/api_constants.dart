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
  static const String appVersion = 'v1.1.0';

  // Navigation Links
  static const String chatUrl = '/chat';
  static const String docsUrl = 'https://sarrera.github.io/sarrera/';
  static const String changelogUrl = 'https://sarrera.github.io/sarrera/#/operations/changelog';
  static const String auditUrl = '/admin/audit/';
  static const String storageUrl = '/admin/storage/';
}
