import 'dart:io';

import 'package:test/test.dart';
import 'package:skygear_sdk_flutter/cookie.dart';

class Query {
  String toUrl;
  String want;

  Query(this.toUrl, this.want);
}

final tNow = DateTime.utc(2006, 1, 2, 15, 4, 5);

class JarTest {
  String description;
  String fromUrl;
  List<String> setCookies;
  String content;
  List<Query> queries;

  JarTest(this.description, this.fromUrl, this.setCookies, this.content,
      this.queries);

  Future<void> run(NaiveCookieStore store) async {
    var now = tNow;
    final cookies = setCookies
        .map((setCookie) => Cookie.fromSetCookieValue(setCookie))
        .toList();

    store.now = now;
    await store.save(Uri.parse(fromUrl), cookies);
    now = now.add(Duration(milliseconds: 1001));

    final cs = <String>[];
    for (var entry in store.entries) {
      if (entry.isExpired(now: now)) {
        continue;
      }
      cs.add(entry.name + "=" + entry.value);
    }
    cs.sort((a, b) => a.compareTo(b));

    expect(cs.join(" "), equals(content));

    for (var i = 0; i < queries.length; ++i) {
      final query = queries[i];
      now = now.add(Duration(milliseconds: 1001));
      store.now = now;
      final s = <String>[];
      for (var cookie in await store.load(Uri.parse(query.toUrl))) {
        s.add(cookie.name + "=" + cookie.value);
      }
      expect(s.join(" "), equals(query.want));
    }
  }
}

String expiresIn(int seconds) {
  final t = tNow.add(Duration(seconds: seconds));
  return "expires=" + HttpDate.format(t);
}

void main() {
  group('domainMatches', () {
    test('match identical', () {
      expect(
          domainMatches(s: 'example.com', domain: 'example.com'), equals(true));
    });
    test('match dot suffix', () {
      expect(domainMatches(s: '.example.com', domain: 'example.com'),
          equals(true));
    });
  });

  group('defaultPath', () {
    test('not starting with /', () {
      expect(defaultPath(null), equals('/'));
      expect(defaultPath(''), equals('/'));
      expect(defaultPath('a'), equals('/'));
    });

    test('only one /', () {
      expect(defaultPath('/'), equals('/'));
      expect(defaultPath('/a'), equals('/'));
    });

    test('other cases', () {
      expect(defaultPath('/a/b'), equals('/a'));
      expect(defaultPath('/a/b/'), equals('/a/b'));
    });
  });

  group('pathMatches', () {
    test('match identical', () {
      expect(
          pathMatches(requestPath: '/a/b', cookiePath: '/a/b'), equals(true));
    });

    test('cookiePath is prefix of requestPath and cookiePath ends with /', () {
      expect(pathMatches(requestPath: '/a/b/c', cookiePath: '/a/b/'),
          equals(true));
    });

    test('cookiePath is prefix of requestPath and / is after the prefix', () {
      expect(
          pathMatches(requestPath: '/a/b/c', cookiePath: '/a/b'), equals(true));
    });
  });

  group('canonicalizeHost', () {
    test('IPv4', () {
      expect(canonicalizeHost("127.0.0.1"), equals("127.0.0.1"));
    });
    test('IPv6', () {
      expect(canonicalizeHost("::1"), equals("::1"));
      expect(canonicalizeHost("FEDC:BA98:7654:3210:FEDC:BA98:7654:3210"),
          equals("FEDC:BA98:7654:3210:FEDC:BA98:7654:3210"));
      expect(canonicalizeHost("3ffe:2a00:100:7031::1"),
          equals("3ffe:2a00:100:7031::1"));
      expect(canonicalizeHost("::FFFF:129.144.52.38"),
          equals("::FFFF:129.144.52.38"));
      expect(canonicalizeHost("2010:836B:4179::836B:4179"),
          equals("2010:836B:4179::836B:4179"));
    });
    test('ASCII domain name', () {
      expect(canonicalizeHost("example.com"), equals("example.com"));
    });
    test('Unicode domain name', () {
      expect(canonicalizeHost("bücher.tld"), equals("xn--bcher-kva.tld"));
      expect(canonicalizeHost(Uri.parse("http://bücher.tld").host),
          equals("xn--bcher-kva.tld"));
      expect(canonicalizeHost("🥺.hk"), equals("xn--ts9h.hk"));
      expect(canonicalizeHost(Uri.parse("http://🥺.hk").host),
          equals("xn--ts9h.hk"));
    });
  });

  group('cookieDomain', () {
    test('without leading dot', () {
      expect(cookieDomain("example.com"), equals("example.com"));
      expect(cookieDomain("EXAMPLE.COM"), equals("example.com"));
    });
    test('with leading dot', () {
      expect(cookieDomain(".example.com"), equals("example.com"));
      expect(cookieDomain(".EXAMPLE.COM"), equals("example.com"));
    });
  });

  group('isCookiePath', () {
    test('not a cookie path', () {
      expect(isCookiePath(null), equals(false));
      expect(isCookiePath(""), equals(false));
      expect(isCookiePath("a"), equals(false));
    });
    test('cookie path', () {
      expect(isCookiePath("/"), equals(true));
      expect(isCookiePath("/a"), equals(true));
    });
  });

  group('CookieEntry', () {
    test('session cookie', () {
      final now = DateTime.utc(2006, 1, 2, 15, 4, 5);
      final cookie = Cookie("name", "value");
      final url = Uri.parse("http://example.com/path");

      var c = CookieEntry.fromCookie(url, cookie, now: now);

      expect(c.name, equals(cookie.name));
      expect(c.value, equals(cookie.value));
      expect(c.creationTime, equals(now));
      expect(c.lastAccessTime, equals(now));

      expect(c.persistent, equals(false));
      expect(c.secure, equals(false));
      expect(c.httpOnly, equals(true));
    });

    test('max age', () {
      final now = DateTime.utc(2006, 1, 2, 15, 4, 5);
      final cookie = Cookie("name", "value");
      cookie.maxAge = 5;
      final url = Uri.parse("http://example.com/path");

      var c = CookieEntry.fromCookie(url, cookie, now: now);

      expect(c.persistent, equals(true));
      expect(c.expiryTime, now.add(Duration(seconds: 5)));
    });

    test('expires', () {
      final now = DateTime.utc(2006, 1, 2, 15, 4, 5);
      final cookie = Cookie("name", "value");
      cookie.expires = now.add(Duration(seconds: 5));
      final url = Uri.parse("http://example.com/path");

      var c = CookieEntry.fromCookie(url, cookie, now: now);

      expect(c.persistent, equals(true));
      expect(c.expiryTime, cookie.expires);
    });

    test('max age takes precedence over expires', () {
      final now = DateTime.utc(2006, 1, 2, 15, 4, 5);
      final cookie = Cookie("name", "value");
      cookie.maxAge = 6;
      cookie.expires = now.add(Duration(seconds: 7));
      final url = Uri.parse("http://example.com/path");

      var c = CookieEntry.fromCookie(url, cookie, now: now);

      expect(c.persistent, equals(true));
      expect(c.expiryTime, now.add(Duration(seconds: 6)));
    });

    test('host only cookie', () {
      final now = DateTime.utc(2006, 1, 2, 15, 4, 5);
      final cookie = Cookie("name", "value");
      final url = Uri.parse("http://example.com/path");

      var c = CookieEntry.fromCookie(url, cookie, now: now);

      expect(c.hostOnly, equals(true));
    });

    test('non host only cookie', () {
      final now = DateTime.utc(2006, 1, 2, 15, 4, 5);
      final cookie = Cookie("name", "value");
      cookie.domain = "example.com";
      final url = Uri.parse("http://www.example.com/path");

      var c = CookieEntry.fromCookie(url, cookie, now: now);

      expect(c.hostOnly, equals(false));
      expect(c.domain, equals("example.com"));
    });

    test("default path", () {
      final now = DateTime.utc(2006, 1, 2, 15, 4, 5);
      final cookie = Cookie("name", "value");
      final url = Uri.parse("http://example.com/a/b");

      var c = CookieEntry.fromCookie(url, cookie, now: now);

      expect(c.path, equals("/a"));
    });

    test("explicit path", () {
      final now = DateTime.utc(2006, 1, 2, 15, 4, 5);
      final cookie = Cookie("name", "value");
      cookie.path = "/c/d";
      final url = Uri.parse("http://example.com/a/b");

      var c = CookieEntry.fromCookie(url, cookie, now: now);

      expect(c.path, equals("/c/d"));
    });

    test("secure", () {
      final now = DateTime.utc(2006, 1, 2, 15, 4, 5);
      final cookie = Cookie("name", "value");
      cookie.secure = true;
      final url = Uri.parse("http://example.com/path");

      var c = CookieEntry.fromCookie(url, cookie, now: now);

      expect(c.secure, equals(true));
    });

    test("http only", () {
      final now = DateTime.utc(2006, 1, 2, 15, 4, 5);
      final cookie = Cookie("name", "value");
      cookie.httpOnly = false;
      final url = Uri.parse("http://example.com/path");

      var c = CookieEntry.fromCookie(url, cookie, now: now);

      expect(c.secure, equals(false));
    });

    test("toJson and fromJson", () {
      final setCookies = [
        "a=b",
        "a=b; httponly",
        "a=b; httponly; secure",
        "a=b; httponly; secure; max-age=500",
        "a=b; httponly; secure; expires=Mon, 02 Jan 2006 15:04:05 GMT",
      ];
      final url = "http://example.com";
      for (var setCookie in setCookies) {
        final e = CookieEntry.fromCookie(
            Uri.parse(url), Cookie.fromSetCookieValue(setCookie));
        expect(CookieEntry.fromJson(e.toJson()).toJson(), equals(e.toJson()));
      }
    });
  });

  test('httpHeaderCookie', () {
    expect(httpHeaderCookie(null), equals(""));
    expect(httpHeaderCookie([]), equals(""));
    expect(httpHeaderCookie([Cookie("a", "a")]), equals("a=a"));
    expect(httpHeaderCookie([Cookie("a", "a"), Cookie("b", "b")]),
        equals("a=a; b=b"));
  });

  // The following tests are from golang stdlib.

  group('Basic JarTest', () {
    final jarTests = [
      JarTest(
        "Retrieval of a plain host cookie.",
        "http://www.host.test/",
        ["A=a"],
        "A=a",
        [
          Query("http://www.host.test", "A=a"),
          Query("http://www.host.test/", "A=a"),
          Query("http://www.host.test/some/path", "A=a"),
          Query("https://www.host.test", "A=a"),
          Query("https://www.host.test/", "A=a"),
          Query("https://www.host.test/some/path", "A=a"),
          Query("ftp://www.host.test", ""),
          Query("ftp://www.host.test/", ""),
          Query("ftp://www.host.test/some/path", ""),
          Query("http://www.other.org", ""),
          Query("http://sibling.host.test", ""),
          Query("http://deep.www.host.test", ""),
        ],
      ),
      JarTest(
        "Secure cookies are not returned to http.",
        "http://www.host.test/",
        ["A=a; secure"],
        "A=a",
        [
          Query("http://www.host.test", ""),
          Query("http://www.host.test/", ""),
          Query("http://www.host.test/some/path", ""),
          Query("https://www.host.test", "A=a"),
          Query("https://www.host.test/", "A=a"),
          Query("https://www.host.test/some/path", "A=a"),
        ],
      ),
      JarTest(
        "Explicit path.",
        "http://www.host.test/",
        ["A=a; path=/some/path"],
        "A=a",
        [
          Query("http://www.host.test", ""),
          Query("http://www.host.test/", ""),
          Query("http://www.host.test/some", ""),
          Query("http://www.host.test/some/", ""),
          Query("http://www.host.test/some/path", "A=a"),
          Query("http://www.host.test/some/paths", ""),
          Query("http://www.host.test/some/path/foo", "A=a"),
          Query("http://www.host.test/some/path/foo/", "A=a"),
        ],
      ),
      JarTest(
        "Implicit path #1: path is a directory.",
        "http://www.host.test/some/path/",
        ["A=a"],
        "A=a",
        [
          Query("http://www.host.test", ""),
          Query("http://www.host.test/", ""),
          Query("http://www.host.test/some", ""),
          Query("http://www.host.test/some/", ""),
          Query("http://www.host.test/some/path", "A=a"),
          Query("http://www.host.test/some/paths", ""),
          Query("http://www.host.test/some/path/foo", "A=a"),
          Query("http://www.host.test/some/path/foo/", "A=a"),
        ],
      ),
      JarTest(
        "Implicit path #2: path is not a directory.",
        "http://www.host.test/some/path/index.html",
        ["A=a"],
        "A=a",
        [
          Query("http://www.host.test", ""),
          Query("http://www.host.test/", ""),
          Query("http://www.host.test/some", ""),
          Query("http://www.host.test/some/", ""),
          Query("http://www.host.test/some/path", "A=a"),
          Query("http://www.host.test/some/paths", ""),
          Query("http://www.host.test/some/path/foo", "A=a"),
          Query("http://www.host.test/some/path/foo/", "A=a"),
        ],
      ),
      JarTest(
        "Implicit path #3: no path in URL at all.",
        "http://www.host.test",
        ["A=a"],
        "A=a",
        [
          Query("http://www.host.test", "A=a"),
          Query("http://www.host.test/", "A=a"),
          Query("http://www.host.test/some/path", "A=a"),
        ],
      ),
      JarTest(
        "Cookies are sorted by path length.",
        "http://www.host.test/",
        [
          "A=a; path=/foo/bar",
          "B=b; path=/foo/bar/baz/qux",
          "C=c; path=/foo/bar/baz",
          "D=d; path=/foo",
        ],
        "A=a B=b C=c D=d",
        [
          Query("http://www.host.test/foo/bar/baz/qux", "B=b C=c A=a D=d"),
          Query("http://www.host.test/foo/bar/baz/", "C=c A=a D=d"),
          Query("http://www.host.test/foo/bar", "A=a D=d"),
        ],
      ),
      JarTest(
        "Creation time determines sorting on same length paths.",
        "http://www.host.test/",
        [
          "A=a; path=/foo/bar",
          "X=x; path=/foo/bar",
          "Y=y; path=/foo/bar/baz/qux",
          "B=b; path=/foo/bar/baz/qux",
          "C=c; path=/foo/bar/baz",
          "W=w; path=/foo/bar/baz",
          "Z=z; path=/foo",
          "D=d; path=/foo",
        ],
        "A=a B=b C=c D=d W=w X=x Y=y Z=z",
        [
          Query("http://www.host.test/foo/bar/baz/qux",
              "Y=y B=b C=c W=w A=a X=x Z=z D=d"),
          Query("http://www.host.test/foo/bar/baz/", "C=c W=w A=a X=x Z=z D=d"),
          Query("http://www.host.test/foo/bar", "A=a X=x Z=z D=d"),
        ],
      ),
      JarTest(
        "Sorting of same-name cookies.",
        "http://www.host.test/",
        [
          "A=1; path=/",
          "A=2; path=/path",
          "A=3; path=/quux",
          "A=4; path=/path/foo",
          "A=5; domain=.host.test; path=/path",
          "A=6; domain=.host.test; path=/quux",
          "A=7; domain=.host.test; path=/path/foo",
        ],
        "A=1 A=2 A=3 A=4 A=5 A=6 A=7",
        [
          Query("http://www.host.test/path", "A=2 A=5 A=1"),
          Query("http://www.host.test/path/foo", "A=4 A=7 A=2 A=5 A=1"),
        ],
      ),
      JarTest(
        "Host cookie on IP.",
        "http://192.168.0.10",
        ["a=1"],
        "a=1",
        [Query("http://192.168.0.10", "a=1")],
      ),
      JarTest(
          "Port is ignored #1.",
          "http://www.host.test/",
          ["a=1"],
          "a=1",
          [
            Query("http://www.host.test", "a=1"),
            Query("http://www.host.test:8080/", "a=1"),
          ]),
      JarTest(
        "Port is ignored #2.",
        "http://www.host.test:8080/",
        ["a=1"],
        "a=1",
        [
          Query("http://www.host.test", "a=1"),
          Query("http://www.host.test:8080/", "a=1"),
          Query("http://www.host.test:1234/", "a=1"),
        ],
      ),
    ];
    for (var jarTest in jarTests) {
      test(jarTest.description, () async {
        await jarTest.run(NaiveCookieStore());
      });
    }
  });

  group('Update and Delete tests', () {
    final jarTests = [
      JarTest(
        "Set initial cookies.",
        "http://www.host.test",
        [
          "a=1",
          "b=2; secure",
          "c=3; httponly",
          "d=4; secure; httponly",
        ],
        "a=1 b=2 c=3 d=4",
        [
          Query("http://www.host.test", "a=1 c=3"),
          Query("https://www.host.test", "a=1 b=2 c=3 d=4"),
        ],
      ),
      JarTest(
        "Update value via http.",
        "http://www.host.test",
        [
          "a=w",
          "b=x; secure",
          "c=y; httponly",
          "d=z; secure; httponly",
        ],
        "a=w b=x c=y d=z",
        [
          Query("http://www.host.test", "a=w c=y"),
          Query("https://www.host.test", "a=w b=x c=y d=z"),
        ],
      ),
      JarTest(
        "Clear Secure flag from a http.",
        "http://www.host.test/",
        [
          "b=xx",
          "d=zz; httponly",
        ],
        "a=w b=xx c=y d=zz",
        [Query("http://www.host.test", "a=w b=xx c=y d=zz")],
      ),
      JarTest(
        "Delete all.",
        "http://www.host.test/",
        [
          "a=1; max-Age=-1", // delete via MaxAge
          "b=2; " + expiresIn(-10), // delete via Expires
          "c=2; max-age=-1; " + expiresIn(-10), // delete via both
          "d=4; max-age=-1; " + expiresIn(10), // MaxAge takes precedence
        ],
        "",
        [Query("http://www.host.test", "")],
      ),
      JarTest(
        "Refill #1.",
        "http://www.host.test",
        [
          "A=1",
          "A=2; path=/foo",
          "A=3; domain=.host.test",
          "A=4; path=/foo; domain=.host.test",
        ],
        "A=1 A=2 A=3 A=4",
        [Query("http://www.host.test/foo", "A=2 A=4 A=1 A=3")],
      ),
      JarTest(
        "Refill #2.",
        "http://www.google.com",
        [
          "A=6",
          "A=7; path=/foo",
          "A=8; domain=.google.com",
          "A=9; path=/foo; domain=.google.com",
        ],
        "A=1 A=2 A=3 A=4 A=6 A=7 A=8 A=9",
        [
          Query("http://www.host.test/foo", "A=2 A=4 A=1 A=3"),
          Query("http://www.google.com/foo", "A=7 A=9 A=6 A=8"),
        ],
      ),
      JarTest(
        "Delete A7.",
        "http://www.google.com",
        ["A=; path=/foo; max-age=-1"],
        "A=1 A=2 A=3 A=4 A=6 A=8 A=9",
        [
          Query("http://www.host.test/foo", "A=2 A=4 A=1 A=3"),
          Query("http://www.google.com/foo", "A=9 A=6 A=8"),
        ],
      ),
      JarTest(
        "Delete A4.",
        "http://www.host.test",
        ["A=; path=/foo; domain=host.test; max-age=-1"],
        "A=1 A=2 A=3 A=6 A=8 A=9",
        [
          Query("http://www.host.test/foo", "A=2 A=1 A=3"),
          Query("http://www.google.com/foo", "A=9 A=6 A=8"),
        ],
      ),
      JarTest(
        "Delete A6.",
        "http://www.google.com",
        ["A=; max-age=-1"],
        "A=1 A=2 A=3 A=8 A=9",
        [
          Query("http://www.host.test/foo", "A=2 A=1 A=3"),
          Query("http://www.google.com/foo", "A=9 A=8"),
        ],
      ),
      JarTest(
        "Delete A3.",
        "http://www.host.test",
        ["A=; domain=host.test; max-age=-1"],
        "A=1 A=2 A=8 A=9",
        [
          Query("http://www.host.test/foo", "A=2 A=1"),
          Query("http://www.google.com/foo", "A=9 A=8"),
        ],
      ),
      JarTest(
        "No cross-domain delete.",
        "http://www.host.test",
        [
          "A=; domain=google.com; max-age=-1",
          "A=; path=/foo; domain=google.com; max-age=-1",
        ],
        "A=1 A=2 A=8 A=9",
        [
          Query("http://www.host.test/foo", "A=2 A=1"),
          Query("http://www.google.com/foo", "A=9 A=8"),
        ],
      ),
      JarTest(
        "Delete A8 and A9.",
        "http://www.google.com",
        [
          "A=; domain=google.com; max-age=-1",
          "A=; path=/foo; domain=google.com; max-age=-1",
        ],
        "A=1 A=2",
        [
          Query("http://www.host.test/foo", "A=2 A=1"),
          Query("http://www.google.com/foo", ""),
        ],
      ),
    ];

    final store = NaiveCookieStore();
    for (var jarTest in jarTests) {
      test(jarTest.description, () async {
        await jarTest.run(store);
      });
    }
  });

  group('Expiration test', () {
    final store = NaiveCookieStore();
    final jarTest = JarTest(
      "Expiration.",
      "http://www.host.test",
      [
        "a=1",
        "b=2; max-age=3",
        "c=3; " + expiresIn(3),
        "d=4; max-age=5",
        "e=5; " + expiresIn(5),
        "f=6; max-age=100",
      ],
      "a=1 b=2 c=3 d=4 e=5 f=6", // executed at t0 + 1001 ms
      [
        Query(
            "http://www.host.test", "a=1 b=2 c=3 d=4 e=5 f=6"), // t0 + 2002 ms
        Query("http://www.host.test", "a=1 d=4 e=5 f=6"), // t0 + 3003 ms
        Query("http://www.host.test", "a=1 d=4 e=5 f=6"), // t0 + 4004 ms
        Query("http://www.host.test", "a=1 f=6"), // t0 + 5005 ms
        Query("http://www.host.test", "a=1 f=6"), // t0 + 6006 ms
      ],
    );
    test(jarTest.description, () async {
      await jarTest.run(store);
    });
  });

  // TODO: port more tests from golang stdlib
}
