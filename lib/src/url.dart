import 'dart:core';

class QueryParam {
  final String name;
  final String value;

  QueryParam(this.name, this.value);
}

String encodeQuery(List<QueryParam> query) {
  if (query == null || query.isEmpty) {
    return '';
  }
  var output = '?';
  for (var param in query) {
    final name = Uri.encodeQueryComponent(param.name);
    final value = Uri.encodeQueryComponent(param.value);

    if (name == '' && value == '') {
      continue;
    }

    if (output != '?') {
      output += '&';
    }

    output += name;
    if (value != '') {
      output += '=';
      output += value;
    }
  }

  return output;
}
