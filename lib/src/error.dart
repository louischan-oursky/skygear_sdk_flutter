import 'dart:convert' show jsonEncode;

dynamic decodeError([dynamic err]) {
  // Construct SkygearException if it looks like one.
  if (err != null &&
      err is Map<String, dynamic> &&
      err["name"] is String &&
      err["reason"] is String &&
      err["message"] is String &&
      err["code"] is num) {
    return SkygearException(
        name: err["name"],
        reason: err["reason"],
        message: err["message"],
        code: err["code"].toInt(),
        info: err["info"]);
  }
  // Otherwise we just return it.
  return err;
}

class SkygearException implements Exception {
  final String name;
  final String reason;
  final String message;
  final int code;
  final dynamic info;

  const SkygearException(
      {this.name, this.reason, this.message, this.code, this.info});

  dynamic toJson() {
    final j = {
      "name": name,
      "reason": reason,
      "message": message,
      "code": code,
    };
    if (info != null) {
      j["info"] = info;
    }
    return j;
  }

  String toString() {
    return jsonEncode(toJson());
  }
}
