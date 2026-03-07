void main() {
  final queryParams = {
    'embed': 'null',
    'sort': 'created_at',
    'perPage': '100',
    'token': 'TEST_TOKEN',
  };
  final uriPart = Uri(queryParameters: queryParams);
  print('Uri(queryParameters: ...) toString: $uriPart');
  
  const apiUrl = 'https://cfast.ng/api/savedSearches';
  final fullUrl = '$apiUrl?${Uri(queryParameters: queryParams)}';
  print('Full URL: $fullUrl');
}
