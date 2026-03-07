void main() {
  const apiUrl = 'https://cfast.ng/api/savedSearches';
  final queryParams = {
    'embed': 'null',
    'sort': 'created_at',
    'perPage': '100',
    'token': 'TEST_TOKEN',
  };

  print('--- Original Logic (Buggy) ---');
  final buggyUrl = '$apiUrl?${Uri(queryParameters: queryParams)}';
  print('Buggy URL: $buggyUrl');

  print('\n--- New Logic (Fixed) ---');
  final fixedUri = Uri.parse(apiUrl).replace(queryParameters: queryParams);
  print('Fixed URL: $fixedUri');
  
  if (!fixedUri.toString().contains('??')) {
      print('\nSUCCESS: Fixed URL does not contain double ??');
  } else {
      print('\nFAILURE: Fixed URL still contains double ??');
  }
}
