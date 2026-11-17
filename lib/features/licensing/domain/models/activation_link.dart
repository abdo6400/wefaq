/// Parse only the configured HTTPS activation endpoint. The signed credential
/// is carried in the fragment so HTTP requests do not send it to the server.
String? activationCodeFromLink(Uri uri, String host) {
  if (host.isEmpty ||
      uri.scheme != 'https' ||
      uri.host.toLowerCase() != host.toLowerCase() ||
      uri.hasPort ||
      uri.userInfo.isNotEmpty ||
      uri.path != '/activate' ||
      uri.hasQuery ||
      uri.fragment.length > 16384) {
    return null;
  }
  final code = uri.fragment;
  if (!RegExp(r'^[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+$').hasMatch(code)) return null;
  return code;
}
