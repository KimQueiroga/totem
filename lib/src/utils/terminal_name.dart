String? extractTerminalName(Uri uri) {
  final queryValue = uri.queryParameters['terminal'];
  if (queryValue != null && queryValue.trim().isNotEmpty) {
    return queryValue.trim();
  }

  final hostNameValue = uri.queryParameters['hostName'];
  if (hostNameValue != null && hostNameValue.trim().isNotEmpty) {
    return hostNameValue.trim();
  }

  for (final segment in uri.pathSegments) {
    if (segment.startsWith('terminal=')) {
      final value = segment.substring('terminal='.length).trim();
      return value.isEmpty ? null : value;
    }
  }

  return null;
}
