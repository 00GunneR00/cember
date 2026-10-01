import '../../core/api_client.dart';
import '../../models/notification_page.dart';
import '../notifications_repository.dart';

class HttpNotificationsRepository extends NotificationsRepository {
  const HttpNotificationsRepository(this._client);

  final ApiClient _client;

  @override
  Future<NotificationPage> fetch({String? cursor}) async {
    final response = await _client.dio.get('/notifications', queryParameters: {'pageSize': 30, 'cursor': ?cursor});
    return NotificationPage.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<int> fetchUnreadCount() async {
    final response = await _client.dio.get('/notifications/unread-count');
    return response.data as int;
  }

  @override
  Future<void> markRead(String id) async {
    await _client.dio.post('/notifications/$id/read');
  }

  @override
  Future<void> markAllRead() async {
    await _client.dio.post('/notifications/read-all');
  }
}
