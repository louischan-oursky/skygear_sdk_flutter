import 'dart:io';

import 'package:dio/dio.dart';
import 'package:meta/meta.dart';

import 'error.dart';
import 'cookie.dart' show CookieStore, NaiveCookieStore, httpHeaderCookie;
import 'types.dart';

String _removeTrailingSlash(String s) {
  return s.replaceAll(RegExp(r'/+$'), '');
}

class CookieInterceptor extends Interceptor {
  final CookieStore cookieStore;

  CookieInterceptor(this.cookieStore);

  @override
  Future onRequest(RequestOptions options) async {
    final cookies = await cookieStore.load(options.uri);
    final cookie = httpHeaderCookie(cookies);
    if (cookie != null && cookie.isNotEmpty) {
      options.headers[HttpHeaders.cookieHeader] = cookie;
    }
  }

  @override
  Future onResponse(Response response) async => _saveCookies(response);

  @override
  Future onError(DioError err) async => _saveCookies(err.response);

  Future _saveCookies(Response response) async {
    if (response != null && response.headers != null) {
      final setCookieHeaders = response.headers[HttpHeaders.setCookieHeader];
      if (setCookieHeaders != null) {
        final cookies = setCookieHeaders
            .map((str) => Cookie.fromSetCookieValue(str))
            .toList();
        await cookieStore.save(response.request.uri, cookies);
      }
    }
  }
}

class ApiClient {
  String apiKey;
  String _endpoint;
  final Dio _dio;
  final CookieStore _cookieStore;

  ApiClient({this.apiKey = "", String endpoint = "", CookieStore cookieStore})
      : _endpoint = _removeTrailingSlash(endpoint),
        _dio = Dio(),
        _cookieStore = cookieStore ?? NaiveCookieStore() {
    _dio.interceptors
      ..add(InterceptorsWrapper(
        onRequest: (RequestOptions options) {
          options.headers["x-skygear-api-key"] = apiKey;
        },
      ))
      ..add(CookieInterceptor(_cookieStore));
    _dio.options.baseUrl = endpoint;
  }

  String get endpoint => _endpoint;
  set endpoint(String v) {
    _endpoint = _removeTrailingSlash(v);
    _dio.options.baseUrl = _endpoint;
  }

  Future<Response<T>> request<T>(
    String path, {
    dynamic data,
    Map<String, dynamic> queryParameters,
    CancelToken cancelToken,
    Options options,
    ProgressCallback onSendProgress,
    ProgressCallback onReceiveProgress,
  }) async {
    return _dio.request(
      path,
      data: data,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
      options: options,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  dynamic parseSkygearResponse(Response<dynamic> resp) {
    return parseSkygearJson(resp.data);
  }

  dynamic parseSkygearJson(dynamic jsonBody) {
    if (jsonBody["result"] != null) {
      return jsonBody["result"];
    } else if (jsonBody["error"] != null) {
      throw decodeError(jsonBody["error"]);
    }
    throw decodeError();
  }

  Future<dynamic> _skygearRequest(
    String path, {
    dynamic data,
    Map<String, dynamic> queryParameters,
    Options options,
  }) async {
    try {
      return parseSkygearResponse(await request(path,
          data: data, queryParameters: queryParameters, options: options));
    } on DioError catch (e) {
      if (e.type == DioErrorType.RESPONSE) {
        return parseSkygearResponse(e.response);
      }
      rethrow;
    }
  }

  Future<AuthResponse> _postAndReturnAuthResponse(String path,
      {dynamic data,
      Map<String, dynamic> queryParameters,
      Options options}) async {
    final j = await _skygearRequest(path,
        data: data,
        queryParameters: queryParameters,
        options: (options ?? Options()).merge(method: "POST"));
    return AuthResponse.fromJson(j);
  }

  Future<AuthResponse> login(String loginId, String password,
      {String loginIdKey}) async {
    final data = {
      "login_id": loginId,
      "password": password,
    };
    if (loginIdKey != null) {
      data["login_id_key"] = loginIdKey;
    }
    return _postAndReturnAuthResponse("/_auth/login", data: data);
  }

  Future<AuthResponse> me() async {
    return _postAndReturnAuthResponse("/_auth/me", data: {});
  }

  Future<void> logout() async {
    await _skygearRequest("/_auth/logout",
        data: {}, options: Options(method: "POST"));
  }

  Future<String> oauthAuthorizationURL({
    @required String providerId,
    @required String codeChallenge,
    @required String action,
    @required String callbackUrl,
    String onUserDuplicate,
  }) async {
    final encoded = Uri.encodeComponent(providerId);
    var path = "";
    switch (action) {
      case "login":
        path = "/_auth/sso/$encoded/login_auth_url";
        break;
      case "link":
        path = "/_auth/sso/$encoded/link_auth_url";
        break;
      default:
        throw Exception("unreachable");
    }

    final data = {
      "code_challenge": codeChallenge,
      "callback_url": callbackUrl,
      "ux_mode": "mobile_app",
    };

    if (onUserDuplicate != null) {
      data["on_user_duplicate"] = onUserDuplicate;
    }

    final url = await _skygearRequest(path,
        data: data, options: Options(method: "POST")) as String;
    return url;
  }

  Future<AuthResponse> getOAuthResult(
      {@required String authorizationCode, @required String codeVerifier}) {
    final data = {
      "authorization_code": authorizationCode,
      "code_verifier": codeVerifier,
    };
    return _postAndReturnAuthResponse("/_auth/sso/auth_result", data: data);
  }
}
