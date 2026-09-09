import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/stylist_repository.dart';
import '../models/stylist_models.dart';

final stylistRepositoryProvider = Provider<StylistRepository>((ref) {
  return StylistRepository();
});

class StylistState {
  final List<ChatSessionModel> sessions;
  final ChatSessionModel? currentSession;
  final List<ChatMessageModel> messages;
  final bool isLoadingSessions;
  final bool isLoadingMessages;
  final bool isStreaming;
  final String? errorMessage;

  const StylistState({
    this.sessions = const [],
    this.currentSession,
    this.messages = const [],
    this.isLoadingSessions = false,
    this.isLoadingMessages = false,
    this.isStreaming = false,
    this.errorMessage,
  });

  StylistState copyWith({
    List<ChatSessionModel>? sessions,
    ChatSessionModel? currentSession,
    bool clearCurrentSession = false,
    List<ChatMessageModel>? messages,
    bool? isLoadingSessions,
    bool? isLoadingMessages,
    bool? isStreaming,
    String? errorMessage,
  }) {
    return StylistState(
      sessions: sessions ?? this.sessions,
      currentSession: clearCurrentSession ? null : (currentSession ?? this.currentSession),
      messages: messages ?? this.messages,
      isLoadingSessions: isLoadingSessions ?? this.isLoadingSessions,
      isLoadingMessages: isLoadingMessages ?? this.isLoadingMessages,
      isStreaming: isStreaming ?? this.isStreaming,
      errorMessage: errorMessage,
    );
  }
}

class StylistNotifier extends StateNotifier<StylistState> {
  final StylistRepository _repository;

  StylistNotifier(this._repository) : super(const StylistState()) {
    loadSessions();
  }

  /// Tải toàn bộ danh sách các phiên trò chuyện
  Future<void> loadSessions() async {
    state = state.copyWith(isLoadingSessions: true, errorMessage: null);
    try {
      final sessionList = await _repository.getChatSessions();
      if (sessionList.isNotEmpty) {
        state = state.copyWith(
          sessions: sessionList,
          isLoadingSessions: false,
        );
        // Tự động chọn phiên đầu tiên nếu chưa chọn phiên nào
        if (state.currentSession == null) {
          await selectSession(sessionList.first.id);
        }
      } else {
        state = state.copyWith(
          sessions: [],
          isLoadingSessions: false,
        );
        // Tự động khởi tạo phiên mới khi chưa có phiên nào
        await createNewSession();
      }
    } catch (e) {
      state = state.copyWith(
        isLoadingSessions: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  /// Chuyển sang phiên trò chuyện khác
  Future<void> selectSession(String sessionId) async {
    final target = state.sessions.cast<ChatSessionModel?>().firstWhere(
          (s) => s?.id == sessionId,
          orElse: () => null,
        );

    state = state.copyWith(
      currentSession: target,
      isLoadingMessages: true,
      messages: [],
      errorMessage: null,
    );

    try {
      final msgList = await _repository.getChatMessages(sessionId);
      state = state.copyWith(
        messages: msgList,
        isLoadingMessages: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMessages: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  /// Khởi tạo phiên trò chuyện mới
  Future<void> createNewSession({String? title}) async {
    try {
      final newSession = await _repository.createChatSession(title: title);
      final updatedSessions = [newSession, ...state.sessions.where((s) => s.id != newSession.id)];
      state = state.copyWith(
        sessions: updatedSessions,
        currentSession: newSession,
        messages: [],
        isLoadingMessages: false,
      );
    } catch (e) {
      debugPrint('[StylistNotifier] createNewSession error: $e');
    }
  }

  /// Xóa phiên trò chuyện
  Future<void> deleteSession(String sessionId) async {
    await _repository.deleteChatSession(sessionId);
    final remaining = state.sessions.where((s) => s.id != sessionId).toList();

    if (state.currentSession?.id == sessionId) {
      if (remaining.isNotEmpty) {
        state = state.copyWith(sessions: remaining);
        await selectSession(remaining.first.id);
      } else {
        state = state.copyWith(sessions: [], clearCurrentSession: true, messages: []);
        await createNewSession();
      }
    } else {
      state = state.copyWith(sessions: remaining);
    }
  }

  /// Đổi tên tiêu đề phiên trò chuyện
  Future<void> updateSessionTitle(String sessionId, String newTitle) async {
    if (newTitle.trim().isEmpty) return;
    final success = await _repository.updateChatSessionTitle(sessionId, newTitle.trim());
    if (success) {
      final updatedList = state.sessions.map((s) {
        if (s.id == sessionId) {
          return ChatSessionModel(
            id: s.id,
            title: newTitle.trim(),
            contextSummary: s.contextSummary,
            isArchived: s.isArchived,
            createdAt: s.createdAt,
            updatedAt: DateTime.now(),
          );
        }
        return s;
      }).toList();

      ChatSessionModel? cur = state.currentSession;
      if (cur?.id == sessionId) {
        cur = ChatSessionModel(
          id: cur!.id,
          title: newTitle.trim(),
          contextSummary: cur.contextSummary,
          isArchived: cur.isArchived,
          createdAt: cur.createdAt,
          updatedAt: DateTime.now(),
        );
      }

      state = state.copyWith(sessions: updatedList, currentSession: cur);
    }
  }

  /// Gửi tin nhắn và nhận stream thời gian thực
  Future<void> sendMessage(String text) async {
    final cleanPrompt = text.trim();
    if (cleanPrompt.isEmpty || state.isStreaming) return;

    // Đảm bảo có session hợp lệ trước khi gửi
    if (state.currentSession == null) {
      await createNewSession(title: cleanPrompt.length > 25 ? '${cleanPrompt.substring(0, 25)}...' : cleanPrompt);
    }

    final currentContextId = state.currentSession!.id;

    // 1. Thêm tin nhắn của User
    final userMsg = ChatMessageModel(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      content: cleanPrompt,
      sender: 'USER',
      timestamp: DateTime.now(),
    );

    // 2. Thêm bong bóng tạm của AI với trạng thái streaming
    final aiMsgId = 'ai_${DateTime.now().millisecondsSinceEpoch}';
    final aiPlaceholder = ChatMessageModel(
      id: aiMsgId,
      content: '',
      sender: 'ASSISTANT',
      timestamp: DateTime.now(),
      isStreaming: true,
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg, aiPlaceholder],
      isStreaming: true,
      errorMessage: null,
    );

    String streamAccumulated = '';

    await _repository.sendChatMessageStream(
      contextId: currentContextId,
      content: cleanPrompt,
      onChunk: (chunk) {
        streamAccumulated += chunk;
        _updateAiMessage(aiMsgId, streamAccumulated, isStreaming: true);
      },
      onDone: (fullText) async {
        final finalText = fullText.isNotEmpty ? fullText : streamAccumulated;
        final hasRedirect = finalText.contains('[ACTION:REDIRECT_OUTFIT]');

        // Nếu có lệnh gợi ý trang phục, tải lookbook đính kèm
        OutfitRecommendationModel? rec;
        if (hasRedirect || cleanPrompt.toLowerCase().contains('phối') || cleanPrompt.toLowerCase().contains('outfit')) {
          try {
            rec = await _repository.getOutfitRecommendation(prompt: cleanPrompt);
          } catch (_) {}
        }

        _finalizeAiMessage(aiMsgId, finalText, recommendation: rec);
        state = state.copyWith(isStreaming: false);

        // Cập nhật tiêu đề phiên tự động nếu là tin nhắn đầu tiên
        if (state.messages.length <= 2 && state.currentSession?.title == 'Tư vấn phong cách mới') {
          final autoTitle = cleanPrompt.length > 25 ? '${cleanPrompt.substring(0, 25)}...' : cleanPrompt;
          updateSessionTitle(currentContextId, autoTitle);
        }
      },
      onError: (err) async {
        debugPrint('[StylistNotifier] Stream error, executing fallback: $err');
        try {
          final rec = await _repository.getOutfitRecommendation(prompt: cleanPrompt);
          final fallbackContent = rec.explanation ?? 'Dưới đây là gợi ý phối đồ phù hợp với phong cách của bạn:';
          _finalizeAiMessage(aiMsgId, fallbackContent, recommendation: rec);
        } catch (_) {
          _finalizeAiMessage(
            aiMsgId,
            'Tôi có thể giúp bạn phối trang phục từ tủ đồ cho nhiều dịp như đi làm, dạo phố hoặc dự tiệc. Bạn hãy cho tôi biết sở thích của mình nhé!',
          );
        }
        state = state.copyWith(isStreaming: false);
      },
    );
  }

  void _updateAiMessage(String msgId, String currentText, {required bool isStreaming}) {
    final updated = state.messages.map((m) {
      if (m.id == msgId) {
        return m.copyWith(content: currentText, isStreaming: isStreaming);
      }
      return m;
    }).toList();
    state = state.copyWith(messages: updated);
  }

  void _finalizeAiMessage(
    String msgId,
    String finalText, {
    OutfitRecommendationModel? recommendation,
  }) {
    final updated = state.messages.map((m) {
      if (m.id == msgId) {
        return m.copyWith(
          content: finalText,
          isStreaming: false,
          outfitRecommendation: recommendation,
          suggestedItems: recommendation?.items ?? [],
        );
      }
      return m;
    }).toList();
    state = state.copyWith(messages: updated);
  }

  void sendQuickPrompt(String prompt) {
    sendMessage(prompt);
  }
}

final stylistProvider = StateNotifierProvider<StylistNotifier, StylistState>((ref) {
  final repo = ref.watch(stylistRepositoryProvider);
  return StylistNotifier(repo);
});
