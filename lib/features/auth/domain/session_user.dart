import 'package:flutter/foundation.dart';

/// The signed-in account, mirroring `CrmPayload::user()` on the server.
///
/// `region`/`city` are what the CRM scopes every list by, so the app shows
/// them in the header and never sends them as filters -- the server has
/// already applied them.
@immutable
class SessionUser {
  const SessionUser({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.role,
    required this.roleLabel,
    required this.initials,
    required this.scoped,
    this.branch,
    this.region,
    this.regionLabel,
    this.city,
    this.cities = const <String>[],
  });

  factory SessionUser.fromJson(Map<String, dynamic> json) {
    return SessionUser(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'telecaller',
      roleLabel: json['role_label'] as String? ?? '',
      initials: json['initials'] as String? ?? '',
      scoped: json['scoped'] as bool? ?? false,
      branch: json['branch'] as String?,
      region: json['region'] as String?,
      regionLabel: json['region_label'] as String?,
      city: json['city'] as String?,
      cities: switch (json['cities']) {
        final List<dynamic> list => list
            .map((city) => '$city'.trim())
            .where((city) => city.isNotEmpty)
            .toList(),
        // Older servers send only the single `city`.
        _ => <String>[
            if (json['city'] is String && (json['city'] as String).isNotEmpty)
              json['city'] as String,
          ],
      },
    );
  }

  final int id;
  final String name;
  final String username;
  final String email;
  final String role;
  final String roleLabel;
  final String initials;

  /// True when the server is filtering this account's lists by region or city.
  final bool scoped;

  final String? branch;
  final String? region;
  final String? regionLabel;
  final String? city;

  /// Every town this account covers. **Empty means all cities in the region**,
  /// not none — the same convention the server scopes by.
  final List<String> cities;

  bool get isAdmin => role == 'admin';

  /// What the home app bar prints under the name. Falls back through the
  /// scope fields so an unscoped admin still sees something meaningful.
  ///
  /// Several cities are summarised rather than listed: "Mumbai, 3 cities"
  /// fits a bar that "Mumbai, Bhiwandi, Thane, Kalyan" does not.
  String get scopeLabel {
    final String region = regionLabel ?? this.region ?? '';
    final String places = switch (cities.length) {
      0 => '',
      1 => cities.first,
      _ => '${cities.length} cities',
    };

    if (region.isNotEmpty && places.isNotEmpty) {
      return '$region, $places';
    }
    if (region.isNotEmpty) {
      return region;
    }
    if (places.isNotEmpty) {
      return places;
    }
    return 'All regions';
  }
}
