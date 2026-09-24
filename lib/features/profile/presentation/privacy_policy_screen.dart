import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';

/// Màn hình Chính sách bảo mật — nội dung tĩnh, xem được ở mọi bản build
/// (kể cả bản Play `ENABLE_PAID_FEATURES=false`, vì route này KHÔNG gate).
///
/// Nguồn nội dung: `docs/privacy-policy.md`. Bản web công khai tương ứng:
/// `https://closy.hycat.online/privacy` (repo smart-wardrobe-fe).
class PrivacyPolicyScreen extends StatelessWidget {
  /// Email hỗ trợ duy nhất — phải trùng email trên Store listing.
  static const supportEmail = 'hycat.support@gmail.com';

  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Chính sách bảo mật',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Smart Wardrobe (Closy) tôn trọng và bảo vệ dữ liệu cá nhân của bạn. '
              'Chính sách này mô tả những dữ liệu chúng tôi thu thập, '
              'cách sử dụng và quyền của bạn.',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Cập nhật: tháng 9/2026.',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: '1. Dữ liệu chúng tôi thu thập',
              bullets: const [
                'Thông tin tài khoản: email, tên, thông tin hồ sơ do bạn cung cấp.',
                'Nội dung của bạn: ảnh trang phục tải lên, dữ liệu tủ đồ và outfit.',
                'Ảnh từ camera/thư viện: chỉ khi bạn chủ động chụp hoặc chọn ảnh để thêm vào tủ đồ.',
                'Thông tin thiết bị và kỹ thuật cần thiết để vận hành app.',
              ],
              note:
                  'Chúng tôi không thu thập vị trí của bạn. App không tích hợp '
                  'SDK quảng cáo/phân tích của bên thứ ba.',
            ),
            _buildSection(
              title: '2. Cách chúng tôi dùng dữ liệu',
              bullets: const [
                'Cung cấp tính năng: quản lý tủ đồ, gợi ý phối đồ, đồng bộ tài khoản.',
                'Lưu trữ ảnh qua hạ tầng lưu trữ đám mây (Cloudinary) và máy chủ của đội.',
                'Bảo mật: mọi dữ liệu truyền qua mạng đều được mã hóa (HTTPS).',
              ],
            ),
            _buildSection(
              title: '3. Chia sẻ dữ liệu',
              bullets: const [
                'Chúng tôi không bán dữ liệu của bạn.',
                'Dữ liệu chỉ được xử lý bởi máy chủ của đội và nhà cung cấp hạ tầng lưu ảnh (Cloudinary).',
              ],
            ),
            _buildSection(
              title: '4. Quyền của bạn',
              bullets: const [
                'Yêu cầu xem, sửa hoặc xóa dữ liệu tài khoản qua email hỗ trợ bên dưới.',
                'Gỡ cài đặt app không tự động xóa dữ liệu máy chủ — hãy gửi yêu cầu xóa nếu bạn muốn xóa toàn bộ.',
              ],
            ),
            _buildSection(
              title: '5. Thời gian lưu trữ',
              bullets: const [
                'Dữ liệu được lưu cho đến khi bạn xóa tài khoản hoặc gửi yêu cầu xóa.',
                'Sau khi xóa, ảnh và dữ liệu tủ đồ của bạn bị gỡ khỏi máy chủ; bản sao lưu kỹ thuật (nếu có) được xóa cuốn chiếu trong vòng 30 ngày.',
              ],
            ),
            _buildSection(
              title: '6. Trẻ em',
              bullets: const [
                'App không dành cho trẻ em dưới 13 tuổi. Người dưới 13 tuổi chỉ được dùng app dưới sự giám sát của phụ huynh hoặc người giám hộ.',
              ],
            ),
            _buildSection(
              title: '7. Thay đổi chính sách',
              bullets: const [
                'Khi chính sách thay đổi, chúng tôi cập nhật tại trang này kèm ngày hiệu lực mới. Thay đổi quan trọng được thông báo trong app trước khi áp dụng.',
              ],
            ),
            _buildSection(
              title: '8. Liên hệ',
              bullets: const [
                'Mọi câu hỏi về chính sách này, vui lòng liên hệ: $supportEmail.',
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<String> bullets,
    String? note,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.playfairDisplay(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 10),
          for (final b in bullets) _buildBullet(b),
          if (note != null) ...[
            const SizedBox(height: 8),
            Text(
              note,
              style: const TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '•  ',
            style: TextStyle(fontSize: 13, color: AppColors.primary),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
