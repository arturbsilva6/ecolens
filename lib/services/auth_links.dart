import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

import '../data/auth_repository.dart';

abstract class AuthLinks {
  Future<Uri?> initial();
  Stream<Uri> get stream;
}

class PlatformAuthLinks implements AuthLinks {
  final AppLinks _links = AppLinks();
  // Preserva o callback web antes de o Navigator renderizar a Home.
  final Uri? _initialWebUri = kIsWeb ? Uri.base : null;
  @override
  Future<Uri?> initial() async =>
      kIsWeb ? _initialWebUri : _links.getInitialLink();
  @override
  Stream<Uri> get stream =>
      kIsWeb ? const Stream.empty() : _links.uriLinkStream;
}

class AuthRedirects {
  static const android = 'br.com.ecolens://auth/callback';

  static String get target {
    if (kIsWeb) {
      const configured = String.fromEnvironment('AUTH_WEB_REDIRECT_URL');
      final uri = configured.isEmpty
          ? Uri(
              scheme: Uri.base.scheme,
              host: Uri.base.host,
              port: Uri.base.hasPort ? Uri.base.port : null,
              path: Uri.base.path,
            )
          : Uri.tryParse(configured);
      if (uri == null ||
          !['http', 'https'].contains(uri.scheme) ||
          uri.host.isEmpty ||
          uri.hasQuery ||
          uri.hasFragment) {
        throw const AuthFailure(
          'Configure a URL de retorno web da autenticação.',
        );
      }
      return uri.toString();
    }
    if (defaultTargetPlatform != TargetPlatform.android) {
      throw const AuthFailure(
        'O retorno da autenticação está configurado para Android e web nesta versão.',
      );
    }
    return android;
  }

  static bool accepts(Uri uri, Uri expected) =>
      uri.userInfo.isEmpty &&
      uri.scheme == expected.scheme &&
      uri.host == expected.host &&
      uri.port == expected.port &&
      uri.path == expected.path;

  // URLs normais do Flutter web podem conter #/ ou parâmetros de navegação.
  static bool hasAuthParameters(Uri uri) {
    final parameters = {
      ...uri.queryParameters,
      ...Uri.splitQueryString(uri.fragment),
    };
    return [
      'code',
      'error',
      'error_code',
      'error_description',
      'access_token',
      'type',
    ].any(parameters.containsKey);
  }
}
