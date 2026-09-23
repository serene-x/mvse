import 'package:mvse/data/repositories/personal_storage.dart';

class MemoryStorage extends PersonalStorage {
  final data = <String, Map<String, dynamic>>{};
  bool fail = false;
  @override
  Future<Map<String, dynamic>?> read(
          String? userId, String kind, String guestKey) async =>
      data['$userId:$kind'];
  @override
  Future<void> write(String? userId, String kind, String guestKey,
      Map<String, dynamic> value) async {
    if (fail) throw StateError('Connection unavailable');
    data['$userId:$kind'] = value;
  }
}
