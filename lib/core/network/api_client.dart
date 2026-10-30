// Initializing formals would force the private field names into the public
// constructor, so callers would have to write `HttpApiClient(_tokenStore: ...)`.
// The named parameters are the API; the underscored fields are not.
// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../storage/token_store.dart';
import 'api_exception.dart';

/// The one way this app talks to the CRM.
///
/// Repositories depend on this interface, never on `http`, so a repository can
/// be unit-tested with a fake client and no network. Every method either
/// returns a decoded JSON object or throws an [ApiException] -- callers never
/// see a status code.
abstract interface class ApiClient {
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String?> query,
  });

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic> body,
  });
}

/// [ApiClient] over `package:http`.
///
/// Responsibilities kept to three: attach the bearer token, turn transport
/// failures into [ApiException]s, and decode the body. It holds no app state
/// and knows nothing about screens.
class HttpApiClient implements ApiClient {
  HttpApiClient({
    required TokenStore tokenStore,
    http.Client? client,
    String baseUrl = AppConfig.apiBaseUrl,
    Duration timeout = AppConfig.requestTimeout,
    this.onUnauthorized,
  })  : _tokenStore = tokenStore,
        // Named `client` rather than `_client` so a test can pass a MockClient
        // without the leading underscore leaking into the call site.
        _client = client ?? http.Client(),
        _baseUrl = baseUrl,
        _timeout = timeout;

  final TokenStore _tokenStore;
  final http.Client _client;
  final String _baseUrl;
  final Duration _timeout;

  /// Fired once per 401, before the exception is thrown. The session layer
  /// uses it to drop the stored token and send the user back to login, which
  /// keeps that policy out of here.
  final void Function()? onUnauthorized;

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String?> query = const {},
  }) {
    return _send(() async {
      final Uri uri = _uri(path, query);
      return _client.get(uri, headers: await _headers()).timeout(_timeout);
    });
  }

  @override
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic> body = const {},
  }) {
    return _send(() async {
      final Uri uri = _uri(path, const {});
      return _client
          .post(uri, headers: await _headers(), body: jsonEncode(body))
          .timeout(_timeout);
    });
  }

  Uri _uri(String path, Map<String, String?> query) {
    // Null and empty values are dropped rather than sent as `?status=`, which
    // Laravel's `!empty()` filter checks would treat as a real filter.
    final Map<String, String> params = <String, String>{
      for (final MapEntry<String, String?> entry in query.entries)
        if (entry.value != null && entry.value!.isNotEmpty)
          entry.key: entry.value!,
    };

    final Uri base = Uri.parse('$_baseUrl/${path.replaceFirst(RegExp(r'^/'), '')}');

    return params.isEmpty ? base : base.replace(queryParameters: params);
  }

  Future<Map<String, String>> _headers() async {
    final String? token = await _tokenStore.read();

    return <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Runs [send] and maps everything that can go wrong onto [ApiException].
  Future<Map<String, dynamic>> _send(
    Future<http.Response> Function() send,
  ) async {
    final http.Response response;

    try {
      response = await send();
    } on SocketException {
      throw const NetworkException();
    } on http.ClientException {
      throw const NetworkException();
    } on TimeoutException {
      throw const RequestTimeoutException();
    }

    return _decode(response);
  }

  Map<String, dynamic> _decode(http.Response response) {
    final int status = response.statusCode;

    if (status == 401) {
      onUnauthorized?.call();
      throw const UnauthorizedException();
    }
    if (status == 403) {
      throw ForbiddenException(_messageOf(response) ?? 'This account does not have access.');
    }
    if (status == 404) {
      throw const NotFoundException();
    }
    if (status == 422) {
      throw ValidationException(
        _messageOf(response) ?? 'Please check what you entered.',
        _errorsOf(response),
      );
    }
    if (status >= 500) {
      throw const ServerException();
    }
    if (status < 200 || status > 299) {
      throw UnexpectedResponseException(
        _messageOf(response) ?? 'The server sent an unexpected response.',
      );
    }

    // 204, or any success with nothing to decode.
    if (response.body.isEmpty) {
      return const <String, dynamic>{};
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw const UnexpectedResponseException();
    }

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    // A bare list, as `/meta` style endpoints can return. Wrapped so callers
    // always get an object and never have to type-test the top level.
    if (decoded is List) {
      return <String, dynamic>{'data': decoded};
    }

    throw const UnexpectedResponseException();
  }

  /// Laravel's `{"message": "..."}`, when the body is JSON at all.
  String? _messageOf(http.Response response) {
    try {
      final Object? decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic> && decoded['message'] is String) {
        final String message = decoded['message'] as String;
        return message.isEmpty ? null : message;
      }
    } on FormatException {
      // An HTML error page. Fall through to the caller's default.
    }
    return null;
  }

  /// Laravel's `{"errors": {"field": ["..."]}}`.
  Map<String, List<String>> _errorsOf(http.Response response) {
    try {
      final Object? decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic> && decoded['errors'] is Map) {
        final Map<String, dynamic> errors =
            (decoded['errors'] as Map).cast<String, dynamic>();

        return <String, List<String>>{
          for (final MapEntry<String, dynamic> entry in errors.entries)
            entry.key: (entry.value is List)
                ? (entry.value as List).map((m) => '$m').toList()
                : <String>['${entry.value}'],
        };
      }
    } on FormatException {
      // Not JSON; no field errors to report.
    }
    return const <String, List<String>>{};
  }
}
