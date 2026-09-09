import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/app_constants.dart';
import '../../features/wardrobe/models/wardrobe_models.dart';

/// Helper to apply Cloudinary background removal transformation (t_bg_remove)
String applyCloudinaryBackgroundRemoval(String? url) {
  if (url == null || url.isEmpty || !url.contains('cloudinary.com')) {
    return url ?? '';
  }
  String newUrl = url.replaceAll(RegExp(r'\.[^/.]+$'), '.png');
  if (newUrl.contains('/upload/')) {
    if (!newUrl.contains('t_bg_remove') && !newUrl.contains('t_trim') && !newUrl.contains('e_trim')) {
      return newUrl.replaceFirst('/upload/', '/upload/t_bg_remove/');
    }
  }
  return newUrl;
}

class CloudinaryUploadResult {
  final String secureUrl;
  final String publicId;

  const CloudinaryUploadResult({
    required this.secureUrl,
    required this.publicId,
  });
}

class CloudinaryService {
  final Dio _dio;

  CloudinaryService({Dio? dio}) : _dio = dio ?? Dio();

  Future<CloudinaryUploadResult> uploadImage({
    required XFile file,
    required UploadSignatureModel signature,
  }) async {
    final cloudName = AppConstants.cloudinaryCloudName;
    final url = 'https://api.cloudinary.com/v1_1/$cloudName/image/upload';

    final bytes = await file.readAsBytes();
    final fileName = file.name.isNotEmpty ? file.name : 'upload.png';

    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: fileName),
      'api_key': signature.apiKey,
      'timestamp': signature.timestamp.toString(),
      'signature': signature.signature,
      'folder': signature.folder,
      if (signature.publicId != null && signature.publicId!.isNotEmpty) ...{
        'public_id': signature.publicId,
        'overwrite': 'true',
      },
    });

    final response = await _dio.post(
      url,
      data: formData,
      options: Options(
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      ),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = response.data;
      final rawUrl = data['secure_url'] as String;
      final publicId = data['public_id'] as String;

      // Apply named transformation t_bg_remove matching web
      final optimizedUrl = applyBackgroundRemoval(rawUrl);

      return CloudinaryUploadResult(
        secureUrl: optimizedUrl,
        publicId: publicId,
      );
    } else {
      throw Exception('Failed to upload image to Cloudinary: ${response.statusMessage}');
    }
  }

  /// Transforms a Cloudinary URL using Named Transformation: t_bg_remove
  String applyBackgroundRemoval(String url) {
    return applyCloudinaryBackgroundRemoval(url);
  }
}
