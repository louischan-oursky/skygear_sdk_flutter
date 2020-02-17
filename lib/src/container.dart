import 'dart:convert';

import 'package:meta/meta.dart';
import 'package:url_launcher/url_launcher.dart';

import 'client.dart';
import 'cookie.dart';
import 'types.dart';
import 'pkce.dart';
import 'error.dart';

// TODO: Support header session transport
// TODO: Support user agent
// TODO: Support x-skygear-extra-info
class SkygearContainer {
  final String name;

  ApiClient _apiClient;
  ApiClient get apiClient => _apiClient;

  final FlutterSecureCookieStore _cookieStore;

  AuthContainer _auth;
  AuthContainer get auth => _auth;

  SkygearContainer({this.name = "default"})
      : _cookieStore = FlutterSecureCookieStore("skygear2_cookie_$name") {
    _apiClient = ApiClient(cookieStore: _cookieStore);
    _auth = AuthContainer(this);
  }

  Future<void> configure(
      {@required String apiKey, @required String endpoint}) async {
    apiClient.apiKey = apiKey;
    apiClient.endpoint = endpoint;
    await _cookieStore.init();
  }
}

class AuthContainer {
  SkygearContainer _parent;
  SkygearContainer get parent => _parent;

  String _codeVerifier;

  AuthContainer(this._parent);

  Future<User> login(String loginId, String password,
      {String loginIdKey}) async {
    return _handleAuthResponse(
        _parent._apiClient.login(loginId, password, loginIdKey: loginIdKey));
  }

  Future<User> me() async {
    return _handleAuthResponse(_parent._apiClient.me());
  }

  Future<void> logout() async {
    await _parent._apiClient.logout();
  }

  Future<void> requestForgotPasswordEmail(String email) async {
    await _parent._apiClient.requestForgotPasswordEmail(email);
  }

  Future<User> _handleAuthResponse(Future<AuthResponse> p) async {
    // TODO: persist auth response
    return p.then((resp) => resp.user);
  }

  Future<void> loginOAuthProvider(
      {@required String providerId,
      @required String callbackUrl,
      String onUserDuplicate}) async {
    _codeVerifier = generateCodeVerifier();
    final codeChallenge = computeCodeChallenge(_codeVerifier);
    final url = await _parent._apiClient.oauthAuthorizationURL(
        providerId: providerId,
        codeChallenge: codeChallenge,
        action: "login",
        callbackUrl: callbackUrl,
        onUserDuplicate: onUserDuplicate);
    await launch(url,
        forceSafariVC: false,
        forceWebView: false,
        enableJavaScript: true,
        enableDomStorage: true);
  }

  Future<User> handleRedirectUri(Uri uri) async {
    final result = uri.queryParameters["x-skygear-result"];
    final j = jsonDecode(utf8.decode(base64Decode(result)));
    if (j["result"]["error"] != null) {
      throw decodeError(j["result"]["error"]);
    }
    final authorizationCode = j["result"]["result"] as String;
    final authResponse = await _parent._apiClient.getOAuthResult(
      authorizationCode: authorizationCode,
      codeVerifier: _codeVerifier,
    );
    return _handleAuthResponse(Future.value(authResponse));
  }
}

final skygear = SkygearContainer();
