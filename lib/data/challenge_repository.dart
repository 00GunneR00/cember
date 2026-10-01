import '../core/api_client.dart';
import '../models/challenge_template.dart';

abstract class ChallengeRepository {
  const ChallengeRepository();

  Future<List<ChallengeTemplate>> fetchAll();
}

class HttpChallengeRepository extends ChallengeRepository {
  const HttpChallengeRepository(this._client);

  final ApiClient _client;

  @override
  Future<List<ChallengeTemplate>> fetchAll() async {
    final response = await _client.dio.get('/challenges');
    return (response.data as List).map((e) => ChallengeTemplate.fromJson(e as Map<String, dynamic>)).toList();
  }
}
