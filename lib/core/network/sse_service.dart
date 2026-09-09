import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../storage/secure_storage_service.dart';

class SSESubscription {
  final void Function() _cancel;

  SSESubscription(this._cancel);

  void cancel() => _cancel();
}

class SSEService {
  final SecureStorageService _storage;

  SSEService({SecureStorageService? storage})
      : _storage = storage ?? SecureStorageService();

  /// Subscribes to SSE stream for a given [taskId].
  /// Returns a [SSESubscription] that can be cancelled anytime.
  SSESubscription subscribeTaskSSE({
    required String taskId,
    required void Function(Map<String, dynamic> data) onEvent,
    required void Function() onDone,
    required void Function(dynamic error) onError,
  }) {
    final client = http.Client();
    bool isClosed = false;

    void cleanup() {
      if (!isClosed) {
        isClosed = true;
        try {
          client.close();
        } catch (_) {}
      }
    }

    () async {
      try {
        final token = await _storage.getToken();
        final urlStr = '${AppConstants.baseUrl}/wardrobe-items/tasks/$taskId/sse'
            '${token != null && token.isNotEmpty ? '?token=$token' : ''}';
        final uri = Uri.parse(urlStr);
        debugPrint('[SSE] Connecting to: $uri');

        final request = http.Request('GET', uri);
        request.headers['Accept'] = 'text/event-stream';
        request.headers['Cache-Control'] = 'no-cache';
        if (token != null && token.isNotEmpty && token != 'web_session_active') {
          request.headers['Authorization'] = 'Bearer $token';
        }

        final response = await client.send(request);

        if (response.statusCode != 200) {
          debugPrint('[SSE] Connection failed: HTTP ${response.statusCode}');
          onError(Exception('SSE Connection failed: HTTP ${response.statusCode}'));
          cleanup();
          return;
        }

        debugPrint('[SSE] Connection opened successfully for task: $taskId');

        String buffer = '';
        response.stream.transform(utf8.decoder).listen(
          (chunk) {
            if (isClosed) return;
            buffer += chunk;

            // RFC 8895: SSE frames delimited by double newline
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
              if (eventType == 'ping') continue;

              final rawData = dataLines.join('\n');
              try {
                final json = jsonDecode(rawData);
                if (json is Map<String, dynamic>) {
                  debugPrint('[SSE] Received event: $json');
                  onEvent(json);
                  final status = (json['status'] ?? '').toString().toLowerCase();
                  if (status == 'completed' || status == 'failed' || status == 'needs_review') {
                    debugPrint('[SSE] Terminal status reached: $status');
                    onDone();
                    cleanup();
                    return;
                  }
                }
              } catch (e) {
                debugPrint('[SSE] Parse error: $e, raw: $rawData');
              }
            }
          },
          onDone: () {
            debugPrint('[SSE] Stream completed for task: $taskId');
            onDone();
            cleanup();
          },
          onError: (err) {
            debugPrint('[SSE] Stream error: $err');
            onError(err);
            cleanup();
          },
          cancelOnError: true,
        );
      } catch (e) {
        debugPrint('[SSE] Connection setup error: $e');
        onError(e);
        cleanup();
      }
    }();

    return SSESubscription(cleanup);
  }
}
