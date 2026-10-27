class AppSettings {
  const AppSettings({required this.uiLocale, this.installationId});

  final String uiLocale;
  final String? installationId;

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final locale = json['ui_locale'];
    final id = json['installation_id'];
    if (locale is! String ||
        locale.isEmpty ||
        (id != null &&
            (id is! String || !RegExp(r'^[a-f0-9]{32}$').hasMatch(id)))) {
      throw const FormatException('Invalid app settings');
    }
    return AppSettings(uiLocale: locale, installationId: id as String?);
  }

  Map<String, dynamic> toJson() => {
    'ui_locale': uiLocale,
    'installation_id': installationId,
  };

  AppSettings copyWith({String? uiLocale, String? installationId}) =>
      AppSettings(
        uiLocale: uiLocale ?? this.uiLocale,
        installationId: installationId ?? this.installationId,
      );
}
