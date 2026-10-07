import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/http_client_factory.dart';
import '../../../core/storage/secure_storage_service.dart';
// Spec 015 — T032: tái dùng bộ model ĐÃ CÓ SẴN khớp đúng hợp đồng máy chủ
// (dùng cho màn AI Outfit Studio). Không viết lại model mới — chính việc có hai
// bộ model song song đã khiến ảnh gợi ý ra rỗng.
import '../../outfit_studio/models/outfit_models.dart';
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
    final client = createHttpClient();
    bool isDone = false;

    try {
      final token = await _storage.getToken();
      final hasBearer =
          token != null && token.isNotEmpty && token != 'web_session_active';
      final urlStr = '${AppConstants.baseUrl}/ai/chat/sessions/$contextId/messages/stream'
          '${hasBearer ? '?token=$token' : ''}';
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
        options: Options(
          connectTimeout: const Duration(seconds: 120),
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 120),
        ),
      );

      final body = response.data;
      final data = body['data'] is Map<String, dynamic> ? body['data'] : body;
      // Spec 015 — T032/T033: máy chủ trả `RecommendedOutfitRes` với `items` là
      // danh sách **NHÓM theo vai trò**, mỗi nhóm có `primary` + `alternatives`,
      // và món nằm ở `fashionItem` hoặc `brandItem`.
      //
      // Trước đây ứng dụng đọc `data.items[i].imageUrl` — ở cấp SAI, nên mọi món ra
      // `imageUrl` rỗng và thẻ gợi ý hiện ra trống ("ảnh không xem được").
      final parsed = RecommendedOutfitRes.fromJson(data);

      final flat = flattenRecommendationGroups(parsed.items);


      return OutfitRecommendationModel(
        id: 'rec_${DateTime.now().millisecondsSinceEpoch}',
        title: parsed.title,
        occasion: occasion,
        explanation: parsed.explanation.isEmpty ? null : parsed.explanation,
        items: flat,
        // FR-029/FR-030: mang cờ dự phòng + số hạn mức còn lại tới tận UI.
        isFallback: parsed.isFallback,
        remainingQuota: parsed.remainingQuota,
      );
    } on DioException catch (e) {
      // FR-022/FR-023/FR-025: thất bại thì GIỮ NGUYÊN phần trả lời văn bản đã có
      // và KHÔNG tự chế ra danh sách món. Khối fallback Unsplash từng nhúng sẵn ở
      // đây chính là nguồn của cảm giác "AI không chính xác": người dùng tưởng đó là
      // gợi ý thật nhưng không khớp tủ đồ của họ.
      debugPrint('[StylistRepository] getOutfitRecommendation failed: '
          '${e.type} ${e.response?.statusCode} ${e.message}');
      return const OutfitRecommendationModel(
        id: '',
        title: '',
      );
    } catch (e) {
      debugPrint('[StylistRepository] getOutfitRecommendation unexpected: $e');
      return const OutfitRecommendationModel(id: '', title: '');
    }
  }
}

/// Làm phẳng danh sách **nhóm vai trò** của máy chủ thành danh sách món phẳng mà
/// carousel hiển thị (spec 015 — T032/T033/T053).
///
/// Tách thành hàm thuần ở cấp thư viện thay vì closure lồng trong
/// `getOutfitRecommendation()` để **test gọi được đúng mã đang chạy thật** —
/// trước đó test sao chép lại logic, nên bug `brand!` không bao giờ bị bắt.
List<OutfitRecommendationItem> flattenRecommendationGroups(
  List<RecommendedItemGroup> groups,
) {
  final flat = <OutfitRecommendationItem>[];

  void addItem(RecommendedItemRes? res, RecommendedItemGroup group,
      {required bool isAlternative}) {
    if (res == null) return;

    // FR-017: món thiếu CẢ `fashionItem` lẫn `brandItem` thì bỏ qua hẳn — đó là
    // nguyên nhân gốc tạo thẻ rỗng.
    final fashion = res.fashionItem;
    final brand = res.brandItem;
    if (fashion == null && brand == null) return;

    // FR-018: định danh lấy từ cả hai nguồn.
    //
    // Không dùng `brand!` ở đây. Bản trước viết
    // `(fashion?.id.isNotEmpty ?? false) ? fashion!.id : (brand!.id...)`, nên khi
    // `fashionItem` tồn tại nhưng `id` rỗng **và** không có `brandItem`, biểu
    // thức ép buộc đọc `brand!.id` ném lỗi null-check — làm hỏng **cả** lượt gợi
    // ý thay vì chỉ bỏ qua một món.
    final id = _firstNonEmptyId(fashion?.id, brand?.id, res.id);
    if (id.isEmpty) return;

    // FR-018: ảnh và danh mục lấy từ cả hai nguồn.
    final categoryName = fashion?.category?.name ?? brand?.category?.name ?? '';
    final rawImage = fashion?.imageUrl ?? brand?.imageUrl ?? '';

    flat.add(
      OutfitRecommendationItem(
        id: id,
        // FR-017: thẻ phải có tên. Món không rõ danh mục thì dùng nhãn vai trò
        // thay vì để trống.
        title: categoryName.isNotEmpty
            ? categoryName
            : outfitRoleLabelVi(group.role),
        role: group.role,
        isAlternative: isAlternative,
        category: categoryName.isEmpty ? null : categoryName,
        // FR-019: để null khi không có ảnh, UI sẽ hiện nhãn vai trò.
        imageUrl: rawImage.isEmpty ? null : rawImage,
        color: fashion?.color ?? brand?.color,
        brand: brand?.brandName,
      ),
    );
  }

  for (final group in groups) {
    addItem(group.primary, group, isAlternative: false);
    for (final alt in group.alternatives) {
      addItem(alt, group, isAlternative: true);
    }
  }

  return flat;
}

/// Định danh đầu tiên khác rỗng trong danh sách. Không ép buộc null ở bất kỳ
/// tham số nào (spec 015 — T053).
String _firstNonEmptyId(String? a, String? b, String? c) {
  for (final candidate in [a, b, c]) {
    final value = candidate?.trim() ?? '';
    if (value.isNotEmpty) return value;
  }
  return '';
}

