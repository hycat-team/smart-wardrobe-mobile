import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../providers/user_social_provider.dart';
import 'community_user_avatar.dart';

class UserFollowsSheet extends ConsumerStatefulWidget {
  final String username;
  final String initialType; // 'following' | 'followers'

  const UserFollowsSheet({
    super.key,
    required this.username,
    this.initialType = 'following',
  });

  @override
  ConsumerState<UserFollowsSheet> createState() => _UserFollowsSheetState();
}

class _UserFollowsSheetState extends ConsumerState<UserFollowsSheet> {
  late String _currentType;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _currentType = widget.initialType;
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 150) {
      ref.read(userFollowsProvider((widget.username, _currentType)).notifier).loadMore();
    }
  }

  void _switchType(String newType) {
    if (_currentType == newType) return;
    setState(() => _currentType = newType);
    ref
        .read(userFollowsProvider((widget.username, newType)).notifier)
        .changeType(newType);
  }

  @override
  Widget build(BuildContext context) {
    final followsState =
        ref.watch(userFollowsProvider((widget.username, _currentType)));
    final followsNotifier =
        ref.read(userFollowsProvider((widget.username, _currentType)).notifier);

    return DraggableScrollableSheet(
      // `expand: false` giữ chiều cao sheet ở `initialChildSize` thay vì
      // tràn kín màn hình. Nhờ vậy khoảng trống phía trên thuộc về vùng
      // barrier của `showModalBottomSheet` → bấm vào đó sẽ đóng sheet.
      // (Mặc định `expand: true` làm sheet phủ kín, nuốt mất vùng bấm này.)
      expand: false,
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
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),

              // Tab Switcher — thống nhất với hồ sơ: "Người theo dõi" (người
              // theo dõi bạn) đứng trước, "Đang theo dõi" (bạn đang theo dõi
              // ai) đứng sau.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _buildTabItem('Người theo dõi', 'followers'),
                    const SizedBox(width: 10),
                    _buildTabItem('Đang theo dõi', 'following'),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Search field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _searchController,
                  onChanged: (q) => followsNotifier.search(q),
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm theo tên hoặc @username...',
                    hintStyle: GoogleFonts.beVietnamPro(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.surfaceSubtle,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Divider(height: 1, color: AppColors.border),

              // Content List
              Expanded(
                child: followsState.isLoading && followsState.items.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    : followsState.items.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.people_outline_rounded,
                                      size: 40, color: AppColors.accentSandDark),
                                  const SizedBox(height: 10),
                                  Text(
                                    _currentType == 'following'
                                        ? 'Chưa theo dõi người dùng nào'
                                        : 'Chưa có người theo dõi',
                                    style: GoogleFonts.playfairDisplay(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            itemCount: followsState.items.length +
                                (followsState.hasMore ? 1 : 0),
                            separatorBuilder: (_, __) => const Divider(
                                height: 1, indent: 64, color: AppColors.border),
                            itemBuilder: (context, index) {
                              if (index == followsState.items.length) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(12),
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                );
                              }

                              final item = followsState.items[index];
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                leading: CommunityUserAvatar(
                                  user: item.user,
                                  size: 42,
                                ),
                                title: Text(
                                  item.user.displayName,
                                  style: GoogleFonts.beVietnamPro(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                                subtitle: Text(
                                  '@${item.user.username}',
                                  style: GoogleFonts.beVietnamPro(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                trailing: item.relation.isNotEmpty
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceSubtle,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          item.isFollowingRelation
                                              ? 'Đang theo dõi'
                                              : 'Người theo dõi',
                                          style: GoogleFonts.beVietnamPro(
                                            fontSize: 10.5,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      )
                                    : null,
                                onTap: () {
                                  Navigator.of(context).pop();
                                  context.push('/users/${item.user.username}');
                                },
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

  Widget _buildTabItem(String title, String typeKey) {
    final isActive = _currentType == typeKey;
    return Expanded(
      child: InkWell(
        onTap: () => _switchType(typeKey),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.surfaceSubtle,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? AppColors.primary : AppColors.border,
              width: 0.8,
            ),
          ),
          child: Center(
            child: Text(
              title,
              style: GoogleFonts.beVietnamPro(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
