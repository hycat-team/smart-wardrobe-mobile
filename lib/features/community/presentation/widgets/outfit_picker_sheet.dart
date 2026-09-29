import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/closy_network_image.dart';
import '../../../outfit_studio/providers/outfits_list_provider.dart';
import '../../models/post_models.dart';

class OutfitPickerSheet extends ConsumerWidget {
  const OutfitPickerSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outfitsState = ref.watch(outfitsListProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              // Drag handle
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),

              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Chọn bộ phối từ tủ đồ',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                       IconButton(
                         icon: const Icon(Icons.arrow_back_ios_new_rounded,
                             size: 20, color: AppColors.primary),
                         tooltip: 'Quay lại',
                         onPressed: () => Navigator.of(context).pop(),
                       ),
                  ],
                ),
              ),

              const Divider(height: 1, color: AppColors.border),

              // Outfits List
              Expanded(
                child: outfitsState.isLoading && outfitsState.outfits.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    : outfitsState.outfits.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.style_outlined,
                                      size: 44, color: AppColors.accentSandDark),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Bạn chưa có bộ phối nào',
                                    style: GoogleFonts.playfairDisplay(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Hãy tạo và lưu các bộ phối trong Outfit Studio để chia sẻ lên cộng đồng.',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.beVietnamPro(
                                      fontSize: 12.5,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            itemCount: outfitsState.outfits.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final outfit = outfitsState.outfits[index];
                              return InkWell(
                                onTap: () {
                                  final brief = OutfitBrief(
                                    id: outfit.id,
                                    name: outfit.name,
                                    coverImageUrl: outfit.coverImageUrl,
                                  );
                                  Navigator.of(context).pop(brief);
                                },
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceSubtle,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                        color: AppColors.border, width: 0.8),
                                  ),
                                  child: Row(
                                    children: [
                                      if (outfit.coverImageUrl != null &&
                                          outfit.coverImageUrl!.isNotEmpty)
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: ClosyNetworkImage(
                                            imageUrl: outfit.coverImageUrl!,
                                            width: 50,
                                            height: 50,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      else
                                        Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            color: AppColors.surface,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                                color: AppColors.border,
                                                width: 0.6),
                                          ),
                                          child: const Icon(
                                            Icons.style_outlined,
                                            color: AppColors.accentSandDark,
                                            size: 24,
                                          ),
                                        ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              outfit.name,
                                              style: GoogleFonts.beVietnamPro(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.primary,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${outfit.items.length} món đồ',
                                              style: GoogleFonts.beVietnamPro(
                                                fontSize: 12,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                        Icons.check_circle_outline_rounded,
                                        color: AppColors.accentSandDark,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }
}
