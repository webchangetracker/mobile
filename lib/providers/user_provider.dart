import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wct_mobile/models/user.dart';
import 'dio_provider.dart';

const apiUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'http://localhost:3000',
);

final userProvider = FutureProvider<User>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('$apiUrl/user/me');

  if (response.statusCode == 200) {
    return User.fromJson(response.data);
  }

  throw Exception('Failed to load user');
});
