import 'package:cloud_functions/cloud_functions.dart';
import 'package:flexwolf/features/home/domain/home_content_repository.dart';

class FirebaseHomeContentDataSource implements RemoteHomeContentDataSource {
  const FirebaseHomeContentDataSource();

  @override
  Future<Map<String, Object?>> fetchHomeConfig() async {
    final response = await FirebaseFunctions.instanceFor(region: 'us-central1')
        .httpsCallable('getPublishedHomeConfig')
        .call<Map<String, dynamic>>();
    final config = response.data['config'];
    if (config is! Map) {
      throw const FormatException('Home CMS has no published config');
    }
    return Map<String, Object?>.from(config);
  }
}
