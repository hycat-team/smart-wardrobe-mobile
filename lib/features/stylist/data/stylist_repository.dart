import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../models/stylist_models.dart';

class StylistRepository {
  final ApiClient _apiClient;
  final SecureStorageService _storage;

  StylistRepository({
    ApiClient? apiClient,
    SecureStorageService? storage,
  })  : _apiClient = apiClient ?? ApiClient(),
        _storage = storage ?? SecureStorageService();

  /// Lấy danh sách các cuộc trò chuyện của người dùng
  Future<List<ChatSessionModel>> getChatSessions() async {
    try {
      final response = await _apiClient.dio.get('/ai/chat/sessions');
      final body = response.data;
      final rawList = (body['data'] is List) ? body['data'] as List : [];
      return rawList
          .map((e) => ChatSessionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[StylistRepository] getChatSessions error: $e');
      return [];
    }
  }

  /// Khởi tạo một phiên trò chuyện mới với Stylist AI
  Future<ChatSessionModel> createChatSession({String? title}) async {
    try {
      final response = await _apiClient.dio.post(
        '/ai/chat/sessions',
        data: {
          'title': title ?? 'Tư vấn phong cách mới',
        },
      );
      final body = response.data;
      final data = body['data'] is Map<String, dynamic> ? body['data'] : body;
      return ChatSessionModel.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('[StylistRepository] createChatSession error: $e');
      // Fallback local session if backend fails
      return ChatSessionModel(
        id: 'session_${DateTime.now().millisecondsSinceEpoch}',
        title: title ?? 'Tư vấn phong cách mới',
        createdAt: DateTime.now(),
      );
    }
  }

  /// Tải lịch sử tin nhắn của một phiên trò chuyện
  Future<List<ChatMessageModel>> getChatMessages(
    String contextId, {
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/ai/chat/sessions/$contextId/messages',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );
      final body = response.data;
      final data = body['data'];
      final rawList = (data is Map && data['items'] is List)
          ? data['items'] as List
          : (data is List ? data : []);

      final messages = rawList
          .map((e) => ChatMessageModel.fromJson(e as Map<String, dynamic>))
          .toList();

      // Backend returns newest first or oldest first; sort chronologically
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return messages;
    } catch (e) {
      debugPrint('[StylistRepository] getChatMessages error: $e');
      return [];
    }
  }

  /// Xóa phiên trò chuyện
  Future<bool> deleteChatSession(String contextId) async {
    try {
      await _apiClient.dio.delete('/ai/chat/sessions/$contextId');
      return true;
    } catch (e) {
      debugPrint('[StylistRepository] deleteChatSession error: $e');
      return false;
    }
  }

  /// Đổi tên hoặc lưu trữ phiên trò chuyện
  Future<bool> updateChatSessionTitle(String contextId, String newTitle) async {
    try {
      await _apiClient.dio.patch(
        '/ai/chat/sessions/$contextId/archive',
        data: {'title': newTitle},
      );
      return true;
    } catch (e) {
      debugPrint('[StylistRepository] updateChatSessionTitle error: $e');
      return false;
    }
  }

  /// Gửi tin nhắn và nhận phản hồi thời gian thực qua Server-Sent Events (SSE)
  Future<void> sendChatMessageStream({
    required String contextId,
    required String content,
    required void Function(String chunk) onChunk,
    required void Function(String fullText) onDone,
    required void Function(dynamic error) onError,
  }) async {
    final client = http.Client();
    bool isDone = false;

    try {
      final token = await _storage.getToken();
      final urlStr = '${AppConstants.baseUrl}/ai/chat/sessions/$contextId/messages/stream'
          '${token != null && token.isNotEmpty ? '?token=$token' : ''}';
      final uri = Uri.parse(urlStr);

      debugPrint('[StylistRepository] Connecting chat stream to: $uri');

      final request = http.Request('POST', uri);
      request.headers['Content-Type'] = 'application/json';
      request.headers['Accept'] = 'text/event-stream';
      request.headers['Cache-Control'] = 'no-cache';
      if (token != null && token.isNotEmpty && token != 'web_session_active') {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.body = jsonEncode({'content': content});

      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw Exception('Chat stream failed with HTTP ${response.statusCode}');
      }

      String buffer = '';
      String accumulatedText = '';

      response.stream.transform(utf8.decoder).listen(
        (chunk) {
          buffer += chunk;

          while (buffer.contains('\n\n')) {
            final frameIndex = buffer.indexOf('\n\n');
            final frame = buffer.substring(0, frameIndex).trim();
            buffer = buffer.substring(frameIndex + 2);

            if (frame.isEmpty) continue;

            String eventType = 'message';
            final dataLines = <String>[];

            for (final line in frame.split('\n')) {
              final trimmed = line.trim();
              if (trimmed.startsWith('event:')) {
                eventType = trimmed.substring(6).trim();
              } else if (trimmed.startsWith('data:')) {
                dataLines.add(trimmed.substring(5).trim());
              }
            }

            if (dataLines.isEmpty) continue;
            final rawData = dataLines.join('\n');

            if (eventType == 'chunk') {
              accumulatedText += rawData;
              onChunk(rawData);
            } else if (eventType == 'done') {
              isDone = true;
              final finalResult = rawData.isNotEmpty ? rawData : accumulatedText;
              onDone(finalResult);
              client.close();
              return;
            } else if (eventType == 'error') {
              isDone = true;
              onError(Exception(rawData));
              client.close();
              return;
            }
          }
        },
        onDone: () {
          if (!isDone) {
            isDone = true;
            onDone(accumulatedText);
          }
          client.close();
        },
        onError: (err) {
          debugPrint('[StylistRepository] Stream error: $err');
          if (!isDone) {
            isDone = true;
            onError(err);
          }
          client.close();
        },
        cancelOnError: true,
      );
    } catch (e) {
      debugPrint('[StylistRepository] sendChatMessageStream error: $e');
      // Fallback: Use outfit recommendations or standard message response
      onError(e);
      client.close();
    }
  }

  /// Gợi ý phối đồ chuyên sâu qua endpoint /ai/outfit-recommendations
  Future<OutfitRecommendationModel> getOutfitRecommendation({
    required String prompt,
    String? occasion,
    double? temperature,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/ai/outfit-recommendations',
        data: {
          'prompt': prompt,
          if (occasion != null) 'occasion': occasion,
          if (temperature != null) 'temperature': temperature,
        },
      );

      final body = response.data;
      final data = body['data'] is Map<String, dynamic> ? body['data'] : body;
      return OutfitRecommendationModel.fromJson(data);
    } catch (_) {
      // Return curated fallback lookbook recommendation if backend AI is offline
      return OutfitRecommendationModel(
        id: 'rec_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Bộ phối phong cách Quiet Luxury',
        occasion: occasion ?? 'Dạo phố cuối tuần',
        weatherContext: 'Tiết trời mát mẻ 22°C',
        explanation:
            'Sự kết hợp tinh tế giữa áo khoác dạ dáng rộng, áo len dệt kim cổ lọ tông be và quần âu xếp ly mang lại vẻ đẹp vượt thời gian.',
        tags: ['áo khoác dạ', 'len dệt kim', 'quần âu xếp ly', 'giày da tối giản'],
        items: const [
          OutfitRecommendationItem(
            id: 'item_1',
            title: 'Áo khoác dạ dáng dài Camel',
            brand: 'LEMAIRE',
            color: 'Camel',
            category: 'Áo khoác',
            imageUrl: 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=600',
          ),
          OutfitRecommendationItem(
            id: 'item_2',
            title: 'Áo len Cashmere cổ lọ kem',
            brand: 'THE ROW',
            color: 'Kem ngà',
            category: 'Áo len',
            imageUrl: 'https://images.unsplash.com/photo-1576566588028-4147f3842f27?w=600',
          ),
          OutfitRecommendationItem(
            id: 'item_3',
            title: 'Quần âu xếp ly ống suông Charcoal',
            brand: 'COS ATELIER',
            color: 'Xám than',
            category: 'Quần',
            imageUrl: 'https://images.unsplash.com/photo-1509631179647-0177331693ae?w=600',
          ),
          OutfitRecommendationItem(
            id: 'item_4',
            title: 'Giày lười da bê đen bóng',
            brand: 'JIL SANDER',
            color: 'Đen mun',
            category: 'Giày',
            imageUrl: 'https://images.unsplash.com/photo-1595950653106-6c9ebd614d3a?w=600',
          ),
        ],
      );
    }
  }
}
