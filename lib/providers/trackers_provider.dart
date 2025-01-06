import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/tracker.dart';
import 'dio_provider.dart';

final trackersProvider = FutureProvider<List<Tracker>>((ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('/trackers/');

  return (response.data as List).map((json) => Tracker.fromJson(json)).toList();
});
