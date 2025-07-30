import 'dart:convert';
import 'package:http/http.dart' as http;

Future<List<Map<String, dynamic>>> getSearchByEmailOrUsernameService(
  String text,
  List<String> _selectedExtensions,
) async {
  final String baseUrl = "http://1.1.1.1:1111/whois_api/check_domains";

  final uri = Uri.parse(baseUrl);

  final response = await http.post(
    uri,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'siteName': text.trim(),
      'extensions': _selectedExtensions,
    }),
  );

  if (response.statusCode == 200) {
    final dynamic rawData = jsonDecode(response.body);
    final List<Map<String, dynamic>> data = List<Map<String, dynamic>>.from(
      rawData.map((item) => item as Map<String, dynamic>),
    );
    return data;
  } else {
    print('Failed to search domain by text ex_CODE: ${response.statusCode}');
    return [];
  }
}

Future<List<String>> getExtensions() async {
  final String baseUrl = "http://1.1.1.1:1111/whois_api/get_extensions";

  final uri = Uri.parse(baseUrl);

  final response = await http.get(
    uri,
    headers: {'Content-Type': 'application/json'},
  );
  if (response.statusCode == 200) {
    final dynamic data = jsonDecode(response.body);
    final Map<String, dynamic> rawData = Map<String, dynamic>.from(data);
    final List<dynamic> dynamicExtensions = rawData["supported_extensions"];
    final List<String> extensions =
        dynamicExtensions.map((e) => e.toString()).toList();

    return extensions;
  } else {
    print('Failed to fetch customer by id ex_CODE: ${response.statusCode}');
    return [];
  }
}
