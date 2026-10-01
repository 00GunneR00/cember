/// Photo and cover URLs are presigned: the path names the stored file, the query carries a signature
/// that changes on every API response. Caching by the path alone keeps an image cached across
/// refreshes instead of re-downloading (and flickering) each time. Stored files never change in place —
/// a new cover gets a new path — so the path is a safe key.
String storageCacheKey(String url) {
  final uri = Uri.tryParse(url);
  return uri == null ? url : uri.replace(query: '').toString();
}
