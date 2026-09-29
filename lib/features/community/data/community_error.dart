import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wardrobe/core/router/app_router.dart';
import 'package:smart_wardrobe/shared/widgets/closy_toast.dart';

/// Trích xuất thông điệp lỗi tiếng Việt từ phản hồi của Backend
String extractCommunityErrorMessage(
  dynamic error, {
  String fallback = 'Đã có lỗi xảy ra. Vui lòng thử lại.',
}) {
  if (error is DioException) {
    final res = error.response;
    if (res != null) {
      final statusCode = res.statusCode;
      final data = res.data;

      // Trích xuất từ errors list: [{field, message}]
      if (data is Map<String, dynamic>) {
        if (data['errors'] is List && (data['errors'] as List).isNotEmpty) {
          final firstError = (data['errors'] as List).first;
          if (firstError is Map && firstError['message'] != null) {
            return firstError['message'].toString();
          }
        }
        if (data['message'] != null && data['message'].toString().trim().isNotEmpty) {
          return data['message'].toString();
        }
        if (data['title'] != null && data['title'].toString().trim().isNotEmpty) {
          return data['title'].toString();
        }
      }

      // Xử lý theo mã lỗi HTTP chuẩn
      switch (statusCode) {
        case 400:
          return 'Yêu cầu không hợp lệ hoặc dữ liệu không đúng quy cách.';
        case 401:
          return 'Phiên làm việc đã hết hạn hoặc cần đăng nhập để thực hiện.';
        case 403:
          return 'Bạn không có quyền thực hiện thao tác này.';
        case 404:
          return 'Nội dung hoặc bài viết không tồn tại hoặc đã bị ẩn.';
        case 409:
          return 'Dữ liệu bị trùng lặp hoặc xung đột.';
        case 429:
          return 'Bạn đang thao tác quá nhanh. Vui lòng đợi trong giây lát.';
        case 500:
        case 502:
        case 503:
          return 'Máy chủ đang bận. Vui lòng thử lại sau.';
      }
    } else {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return 'Kết nối mạng quá thời gian chờ. Vui lòng kiểm tra đường truyền.';
      }
      if (error.type == DioExceptionType.connectionError) {
        return 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra internet.';
      }
    }
  }

  if (error is Exception) {
    final msg = error.toString().replaceFirst('Exception: ', '');
    if (msg.trim().isNotEmpty) {
      return msg;
    }
  }

  return fallback;
}

/// Kiểm tra xem lỗi có phải do chưa đăng nhập (401) hay không
bool isUnauthorizedError(dynamic error) {
  if (error is DioException) {
    return error.response?.statusCode == 401;
  }
  return false;
}

/// Điều hướng người dùng tới trang đăng nhập kèm ghi nhớ đích đến (pendingRedirect)
void requireLogin(
  BuildContext context,
  WidgetRef ref, {
  String? targetRoute,
  String message = 'Vui lòng đăng nhập để tiếp tục thao tác.',
}) {
  final destination = targetRoute ?? GoRouterState.of(context).uri.toString();
  ref.read(pendingRedirectProvider.notifier).state = destination;

  ClosyToast.info(context, message);
  context.push('/login');
}
