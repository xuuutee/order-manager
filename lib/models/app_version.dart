/// App 版本信息（从 Supabase 读取，用于检查更新）
class AppVersion {
  final int id;
  final int versionCode;
  final String versionName;
  final String apkUrl;
  final String changelog;
  final bool isRequired;

  const AppVersion({
    required this.id,
    required this.versionCode,
    required this.versionName,
    required this.apkUrl,
    required this.changelog,
    required this.isRequired,
  });

  factory AppVersion.fromJson(Map<String, dynamic> json) {
    return AppVersion(
      id: json['id'] as int,
      versionCode: json['version_code'] as int,
      versionName: json['version_name'] as String,
      apkUrl: (json['apk_url'] as String?) ?? '',
      changelog: (json['changelog'] as String?) ?? '',
      isRequired: (json['is_required'] as bool?) ?? false,
    );
  }
}
