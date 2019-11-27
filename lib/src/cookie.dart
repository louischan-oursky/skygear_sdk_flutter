import 'dart:io' show Cookie;
import 'dart:convert' show jsonEncode, jsonDecode;

import 'package:punycode/punycode.dart' show punycodeEncode;
import 'package:flutter_secure_storage/flutter_secure_storage.dart'
    show FlutterSecureStorage;

/// domainMatches implements domain-matches of RFC 6265 section 5.1.3
bool domainMatches({String s, String domain}) {
  if (s == domain) {
    return true;
  }
  return s.endsWith("." + domain);
}

/// defaultPath implements default-path of RFC 6265 section 5.1.4
String defaultPath(String path) {
  // Step 2
  if (path == null || path == "" || !path.startsWith("/")) {
    return "/";
  }
  final idx = path.lastIndexOf("/");
  // Step 3
  if (idx == 0) {
    return "/";
  }
  // Step 4
  return path.substring(0, idx);
}

/// pathMatches implements path-matches of RFC 6265 section 5.1.4
bool pathMatches({String requestPath, String cookiePath}) {
  if (requestPath == null || requestPath == "") {
    requestPath = "/";
  }
  if (requestPath == cookiePath) {
    return true;
  }
  if (requestPath.startsWith(cookiePath)) {
    if (cookiePath.length > 0 && cookiePath[cookiePath.length - 1] == "/") {
      return true;
    }
    if (requestPath[cookiePath.length] == "/") {
      return true;
    }
  }
  return false;
}

/// canonicalizeHost implements RFC 6265 section 5.1.2
String canonicalizeHost(String host) {
  try {
    // IPv4 address
    Uri.parseIPv4Address(host);
    return host;
  } on FormatException {
    try {
      // IPv6 address
      Uri.parseIPv6Address(host);
      return host;
    } on FormatException {
      // domain name
      // NOTE: Uri.host may be percent encoded in Dart.
      try {
        return toASCII(Uri.decodeFull(host));
      } on ArgumentError {
        return toASCII(host);
      }
    }
  }
}

/// toASCII turns [domain] into ASCII only using punycode.
String toASCII(String domain) {
  if (isASCII(domain)) {
    return domain;
  }
  final labels = domain.split(".");
  for (var i = 0; i < labels.length; ++i) {
    final label = labels[i];
    if (!isASCII(label)) {
      labels[i] = "xn--" + punycodeEncode(label);
    }
  }
  return labels.join(".");
}

/// isASCII tells if [s] is ASCII.
bool isASCII(String s) {
  for (var codePoint in s.runes) {
    if (codePoint >= 0x80) {
      return false;
    }
  }
  return true;
}

/// cookieDomain implements RFC 6265 section 5.2.3
String cookieDomain(String domain) {
  if (domain.isNotEmpty && domain[0] == ".") {
    domain = domain.substring(1);
  }
  return domain.toLowerCase();
}

/// isCookiePath implements RFC 6265 section 5.2.4
bool isCookiePath(String path) {
  return path != null && path.isNotEmpty && path[0] == "/";
}

/// httpHeaderCookie implements RFC 6265 section 5.4 Step 4
String httpHeaderCookie(List<Cookie> cookies) {
  if (cookies == null) {
    return "";
  }
  return cookies.map((cookie) => "${cookie.name}=${cookie.value}").join("; ");
}

final _endOfTime = DateTime.utc(2999);

class CookieEntry {
  String name;
  String value;
  String domain;
  String path;
  bool secure = false;
  bool httpOnly = false;

  DateTime creationTime;
  DateTime lastAccessTime;
  DateTime expiryTime;
  bool persistent = false;
  bool hostOnly = false;

  CookieEntry.fromCookie(Uri url, Cookie cookie, {DateTime now}) {
    // RFC 6265 section 5.3
    // Step 2
    this.name = cookie.name;
    this.value = cookie.value;
    if (now == null) {
      now = DateTime.now();
    }
    now = now.toUtc();
    this.creationTime = now;
    this.lastAccessTime = now;
    // Step 3
    if (cookie.maxAge != null) {
      this.persistent = true;
      this.expiryTime = now.add(Duration(seconds: cookie.maxAge));
    } else if (cookie.expires != null) {
      this.persistent = true;
      this.expiryTime = cookie.expires.toUtc();
    } else {
      this.persistent = false;
      this.expiryTime = _endOfTime;
    }
    // Step 4
    if (cookie.domain != null) {
      this.domain = cookieDomain(cookie.domain);
    } else {
      this.domain = "";
    }
    // Step 5 is public suffix list. We do not support it.
    // Step 6
    final requestHost = canonicalizeHost(url.host);
    if (this.domain != "") {
      if (!domainMatches(s: requestHost, domain: this.domain)) {
        throw ArgumentError(
            "canonicalized request-host does not domain-match the domain attribute");
      }
      this.hostOnly = false;
    } else {
      this.hostOnly = true;
      this.domain = requestHost;
    }
    // Step 7
    this.path = isCookiePath(cookie.path) ? cookie.path : defaultPath(url.path);
    // Step 8
    this.secure = cookie.secure ?? false;
    // Step 9
    this.httpOnly = cookie.httpOnly ?? false;
    // Step 10 is irrelevant
    // Remaining steps are performed by the cookie store.
  }

  CookieEntry.fromJson(dynamic j) {
    this.name = j["name"];
    this.value = j["value"];
    this.domain = j["domain"];
    this.path = j["path"];
    this.secure = j["secure"];
    this.httpOnly = j["httpOnly"];
    this.creationTime = DateTime.parse(j["creationTime"]);
    this.lastAccessTime = DateTime.parse(j["lastAccessTime"]);
    this.expiryTime = DateTime.parse(j["expiryTime"]);
    this.persistent = j["persistent"];
    this.hostOnly = j["hostOnly"];
  }

  bool isSameReference(CookieEntry that) {
    return this.name == that.name &&
        this.domain == that.domain &&
        this.path == that.path;
  }

  bool isExpired({DateTime now}) {
    if (now == null) {
      now = DateTime.now().toUtc();
    }
    return !expiryTime.isAfter(now);
  }

  Cookie toRequestCookie() {
    return Cookie(name, value);
  }

  dynamic toJson() {
    return {
      "name": name,
      "value": value,
      "domain": domain,
      "path": path,
      "secure": secure,
      "httpOnly": httpOnly,
      "creationTime": creationTime.toIso8601String(),
      "lastAccessTime": lastAccessTime.toIso8601String(),
      "expiryTime": expiryTime.toIso8601String(),
      "persistent": persistent,
      "hostOnly": hostOnly,
    };
  }

  String toString() {
    return jsonEncode(toJson());
  }
}

/// CookieStore is the cookie store
abstract class CookieStore {
  Future<void> save(Uri url, List<Cookie> cookies);
  Future<List<Cookie>> load(Uri url);
}

/// NaiveCookieStore is a naive cookie store that stores cookies in a List.
class NaiveCookieStore implements CookieStore {
  List<CookieEntry> entries;
  DateTime now;

  NaiveCookieStore([List<CookieEntry> initialEntries])
      : entries = initialEntries ?? [];

  Future<void> save(Uri url, List<Cookie> cookies) async {
    evictExpired();
    for (var cookie in cookies) {
      saveCookie(url, cookie);
    }
  }

  Future<List<Cookie>> load(Uri url) async {
    // RFC 6265 section 5.4
    evictExpired();

    final requestHost = canonicalizeHost(url.host);

    List<CookieEntry> cookieList = [];

    DateTime lastAccessTime;
    if (now != null) {
      lastAccessTime = now;
    } else {
      lastAccessTime = DateTime.now().toUtc();
    }

    for (var entry in entries) {
      // Step 1
      final domainCond = (entry.hostOnly && entry.domain == requestHost) ||
          (!entry.hostOnly &&
              domainMatches(s: requestHost, domain: entry.domain));
      final pathCond =
          pathMatches(requestPath: url.path, cookiePath: entry.path);
      final secureCond = entry.secure ? url.scheme == "https" : true;
      final httpCond = url.scheme == "http" || url.scheme == "https";
      if (domainCond && pathCond && secureCond && httpCond) {
        // Step 3
        entry.lastAccessTime = lastAccessTime;
        cookieList.add(entry);
      }
    }

    // Step 2
    cookieList.sort((a, b) {
      if (a.path.length > b.path.length) {
        return -1;
      }
      if (a.path.length < b.path.length) {
        return 1;
      }
      return a.creationTime.compareTo(b.creationTime);
    });

    return cookieList.map((entry) => entry.toRequestCookie()).toList();
  }

  void saveCookie(Uri url, Cookie cookie) {
    try {
      final newEntry = CookieEntry.fromCookie(url, cookie, now: now);
      // RFC 6265 section 5.3
      // Step 11 and Step 12
      for (var i = 0; i < entries.length; ++i) {
        final oldEntry = entries[i];
        if (oldEntry.isSameReference(newEntry)) {
          newEntry.creationTime = oldEntry.creationTime;
          // Update case
          entries[i] = newEntry;
          return;
        }
      }
      // Insert case
      entries.add(newEntry);
    } on ArgumentError {
      // ignore invalid cookie
    }
  }

  void evictExpired() {
    entries.removeWhere((entry) => entry.isExpired(now: now));
  }

  List<CookieEntry> getPersistentEntries() {
    return entries.where((entry) => entry.persistent).toList();
  }
}

/// FlutterSecureCookieStore stores cookies with flutter_secure_storage.
class FlutterSecureCookieStore implements CookieStore {
  final String keyName;
  final NaiveCookieStore naiveStore;
  final FlutterSecureStorage storage;

  FlutterSecureCookieStore(this.keyName)
      : naiveStore = NaiveCookieStore(),
        storage = FlutterSecureStorage();

  Future<void> save(Uri url, List<Cookie> cookies) async {
    await naiveStore.save(url, cookies);
    await persist();
  }

  Future<List<Cookie>> load(Uri url) async {
    final cookies = await naiveStore.load(url);
    await persist();
    return cookies;
  }

  Future<void> init() async {
    final jsonString = await storage.read(key: keyName);
    if (jsonString == null) {
      return;
    }

    final entries = (jsonDecode(jsonString) as List<dynamic>)
        .map((j) => CookieEntry.fromJson(j))
        .toList();
    naiveStore.entries = entries;
    naiveStore.evictExpired();
  }

  Future<void> persist() async {
    final entries = naiveStore.getPersistentEntries();
    final jsonString =
        jsonEncode(entries.map((entry) => entry.toJson()).toList());
    await storage.write(key: keyName, value: jsonString);
  }
}
