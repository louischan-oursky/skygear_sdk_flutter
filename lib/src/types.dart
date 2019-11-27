import 'dart:convert' show jsonEncode;

class AuthResponse {
  final User user;
  final Identity identity;
  final String accessToken;
  final String refreshToken;
  final String sessionId;
  final String mfaBearerToken;

  AuthResponse.fromJson(dynamic j)
      : user = User.fromJson(j["user"]),
        identity =
            j["identity"] != null ? Identity.fromJson(j["identity"]) : null,
        accessToken = j["access_token"],
        refreshToken = j["refresh_token"],
        sessionId = j["session_id"],
        mfaBearerToken = j["mfa_bearer_token"];

  dynamic toJson() {
    final j = {
      "user": user.toJson(),
    };
    if (identity != null) {
      j["identity"] = identity.toJson();
    }
    if (accessToken != null) {
      j["access_token"] = accessToken;
    }
    if (refreshToken != null) {
      j["refresh_token"] = refreshToken;
    }
    if (sessionId != null) {
      j["session_id"] = sessionId;
    }
    if (mfaBearerToken != null) {
      j["mfa_bearer_token"] = mfaBearerToken;
    }
    return j;
  }

  String toString() {
    return jsonEncode(toJson());
  }
}

class User {
  final String id;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final bool isVerified;
  final bool isDisabled;
  final Map<String, dynamic> metadata;

  User.fromJson(dynamic j)
      : id = j["id"],
        createdAt = DateTime.parse(j["created_at"]),
        lastLoginAt = DateTime.parse(j["last_login_at"]),
        isVerified = j["is_verified"],
        isDisabled = j["is_disabled"],
        metadata = j["metadata"];

  dynamic toJson() => {
        "id": id,
        "created_at": createdAt.toIso8601String(),
        "last_login_at": lastLoginAt.toIso8601String(),
        "is_verified": isVerified,
        "is_disabled": isDisabled,
        "metadata": metadata,
      };

  String toString() {
    return jsonEncode(toJson());
  }
}

abstract class Identity {
  static const String IdentityTypePassword = "password";
  static const String IdentityTypeOAuth = "oauth";
  static const String IdentityTypeCustomToken = "custom_token";

  final String id;
  final String type;

  dynamic toJson();
  String toString();

  factory Identity.fromJson(dynamic j) {
    final type = j["type"];
    switch (type) {
      case IdentityTypePassword:
        return PasswordIdentity.fromJson(j);
      case IdentityTypeOAuth:
        return OAuthIdentity.fromJson(j);
      case IdentityTypeCustomToken:
        return CustomTokenIdentity.fromJson(j);
      default:
        throw Exception("unknown identity type: $type");
    }
  }
}

class PasswordIdentity implements Identity {
  final String id;
  final String type;
  final String loginIdKey;
  final String loginId;
  final Claims claims;

  PasswordIdentity.fromJson(dynamic j)
      : id = j["id"],
        type = j["type"],
        loginIdKey = j["login_id_key"],
        loginId = j["login_id"],
        claims = Claims.fromJson(j["claims"]);

  dynamic toJson() => {
        "id": id,
        "type": type,
        "login_id_key": loginIdKey,
        "login_id": loginId,
        "claims": claims,
      };

  String toString() {
    return jsonEncode(toJson());
  }
}

class OAuthIdentity implements Identity {
  final String id;
  final String type;
  final String providerType;
  final String providerUserId;
  final Map<String, dynamic> rawProfile;
  final Claims claims;

  OAuthIdentity.fromJson(dynamic j)
      : id = j["id"],
        type = j["type"],
        providerType = j["provider_type"],
        providerUserId = j["provider_user_id"],
        rawProfile = j["raw_profile"],
        claims = Claims.fromJson(j["claims"]);

  dynamic toJson() => {
        "id": id,
        "type": type,
        "provider_type": providerType,
        "providerUserId": providerUserId,
        "raw_profile": rawProfile,
        "claims": claims,
      };

  String toString() {
    return jsonEncode(toJson());
  }
}

class CustomTokenIdentity implements Identity {
  final String id;
  final String type;
  final String providerUserId;
  final Map<String, dynamic> rawProfile;
  final Claims claims;

  CustomTokenIdentity.fromJson(dynamic j)
      : id = j["id"],
        type = j["type"],
        providerUserId = j["provider_user_id"],
        rawProfile = j["raw_profile"],
        claims = Claims.fromJson(j["claims"]);

  dynamic toJson() => {
        "id": id,
        "type": type,
        "provider_user_id": providerUserId,
        "raw_profile": rawProfile,
        "claims": claims,
      };

  String toString() {
    return jsonEncode(toJson());
  }
}

class Claims {
  final String email;

  Claims.fromJson(dynamic j) : email = j["email"];

  dynamic toJson() {
    final j = {};
    if (email != null) {
      j["email"] = email;
    }
    return j;
  }

  String toString() {
    return jsonEncode(toJson());
  }
}
