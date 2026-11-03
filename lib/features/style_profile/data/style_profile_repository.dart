import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../models/style_profile_models.dart';

/// Client for `GET|PUT|DELETE /me/style-profile` and `GET /me/style-profile/suggestions`.
///
/// The profile is a membership entitlement: `GET` always works, while `PUT`/`DELETE` answer 403 when
/// the plan has no personalization or the operator kill switch is on.
class StyleProfileRepository {
  final ApiClient _apiClient;

  StyleProfileRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<StyleProfileModel> getProfile() async {
    try {
      final response = await _apiClient.dio.get('/me/style-profile');
      return StyleProfileModel.fromJson(_data(response.data));
    } on DioException catch (e) {
      throw Exception(_error(e, 'Không tải được gu của bạn'));
    }
  }

  Future<StyleProfileModel> updateProfile({
    List<String>? styles,
    List<String>? excludedStyles,
    bool? enabled,
  }) async {
    try {
      final response = await _apiClient.dio.put(
        '/me/style-profile',
        data: {
          if (styles != null) 'styles': styles,
          if (excludedStyles != null) 'excludedStyles': excludedStyles,
          if (enabled != null) 'enabled': enabled,
        },
      );
      return StyleProfileModel.fromJson(_data(response.data));
    } on DioException catch (e) {
      throw Exception(_error(e, 'Không lưu được gu của bạn'));
    }
  }

  Future<void> deleteProfile() async {
    try {
      // DELETE carries no `data` key; only the message is present.
      await _apiClient.dio.delete('/me/style-profile');
    } on DioException catch (e) {
      throw Exception(_error(e, 'Không xoá được hồ sơ gu'));
    }
  }

  Future<StyleSuggestionModel> getSuggestions() async {
    try {
      final response = await _apiClient.dio.get('/me/style-profile/suggestions');
      return StyleSuggestionModel.fromJson(_data(response.data));
    } on DioException catch (e) {
      throw Exception(_error(e, 'Không tải được gợi ý phong cách'));
    }
  }

  Map<String, dynamic> _data(dynamic body) {
    if (body is Map<String, dynamic>) {
      final data = body['data'];
      if (data is Map<String, dynamic>) return data;
      return body;
    }
    return {};
  }

  String _error(DioException e, String fallback) {
    final body = e.response?.data;
    if (body is Map<String, dynamic>) {
      for (final key in ['message', 'title']) {
        final value = body[key];
        if (value != null && value.toString().isNotEmpty) return value.toString();
      }
    }
    return fallback;
  }
}
