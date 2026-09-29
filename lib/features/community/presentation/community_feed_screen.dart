import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/closy_toast.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/community_error.dart';
import '../data/community_repository.dart';
import '../providers/community_feed_provider.dart';
import 'widgets/post_card.dart';

class CommunityFeedScreen extends ConsumerStatefulWidget {
  const CommunityFeedScreen({super.key});

  @override
  ConsumerState<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends ConsumerState<CommunityFeedScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(communityFeedProvider.notifier).loadMore();
    }
  }

  void _onTabChanged(String tabKey) {
    if (tabKey == 'following') {
      final isAuth = ref.read(authStateProvider).isAuthenticated;
      if (!isAuth) {
        requireLogin(
          context,
          ref,
          message: 'Vui lòng đăng nhập để xem bài viết từ người bạn theo dõi.',
        );
        return;
      }
    }
    ref.read(communityFeedProvider.notifier).changeTab(tabKey);
  }

  void _onCreatePost() {
    final isAuth = ref.read(authStateProvider).isAuthenticated;
    if (!isAuth) {
      requireLogin(
        context,
        ref,
        message: 'Vui lòng đăng nhập để tạo bài viết mới.',
      );
      return;
    }
    context.push('/community/create');
  }

  Future<void> _handleDeletePost(String publicId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Xóa bài viết',
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700),
        ),
        content: const Text('Bạn có chắc chắn muốn xóa bài viết này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(communityRepositoryProvider).deletePost(publicId);
        ref.read(communityFeedProvider.notifier).removePost(publicId);
        if (mounted) {
          ClosyToast.success(context, 'Đã xóa bài viết thành công');
        }
      } catch (e) {
        if (mounted) {
          ClosyToast.error(context, extractCommunityErrorMessage(e));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(communityFeedProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.primary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Cộng đồng',
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 24),
            tooltip: 'Tìm kiếm',
            onPressed: () => context.push('/community/search'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // 1. Unified Tab Bar (Khám phá & Đang theo dõi với Remotion spring animation)
          _buildUnifiedTabBar(feedState.tab),

          // 2. Sort Selector (Nổi bật / Mới nhất)
          _buildSortBar(feedState.sort),

          // 3. Main Feed Content
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.surface,
              onRefresh: () async {
                await ref.read(communityFeedProvider.notifier).loadFeed(isRefresh: true);
              },
              child: _buildFeedBody(feedState),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onCreatePost,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.edit_note_rounded, size: 22),
        label: Text(
          'Đăng bài',
          style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildUnifiedTabBar(String currentTab) {
    final isFollowing = currentTab == 'following';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3EFEA),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final pillWidth = constraints.maxWidth / 2;

          return Stack(
            children: [
              // 1. Sliding pill indicator with Remotion spring physics
              AnimatedPositioned(
                duration: const Duration(milliseconds: 340),
                curve: Curves.easeOutBack, // Remotion spring overshoot & settle
                left: isFollowing ? pillWidth : 0,
                top: 0,
                bottom: 0,
                width: pillWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Tab labels overlay
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _onTabChanged('explore'),
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 14,
                            fontWeight: !isFollowing ? FontWeight.w600 : FontWeight.w500,
                            color: !isFollowing ? Colors.white : AppColors.textSecondary,
                            letterSpacing: -0.1,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.explore_outlined,
                                size: 17,
                                color: !isFollowing ? Colors.white : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 7),
                              const Text('Khám phá'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _onTabChanged('following'),
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 14,
                            fontWeight: isFollowing ? FontWeight.w600 : FontWeight.w500,
                            color: isFollowing ? Colors.white : AppColors.textSecondary,
                            letterSpacing: -0.1,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people_outline_rounded,
                                size: 17,
                                color: isFollowing ? Colors.white : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 7),
                              const Text('Đang theo dõi'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSortBar(String currentSort) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _buildSortChip(
            label: 'Nổi bật',
            icon: Icons.whatshot_rounded,
            isSelected: currentSort == 'hot',
            onTap: () => ref.read(communityFeedProvider.notifier).changeSort('hot'),
          ),
          const SizedBox(width: 8),
          _buildSortChip(
            label: 'Mới nhất',
            icon: Icons.access_time_rounded,
            isSelected: currentSort == 'latest',
            onTap: () => ref.read(communityFeedProvider.notifier).changeSort('latest'),
          ),
        ],
      ),
    );
  }

  Widget _buildSortChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentSand.withOpacity(0.5) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppColors.accentSandDark.withOpacity(0.5)
                : AppColors.border.withOpacity(0.6),
            width: 0.6,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.beVietnamPro(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedBody(CommunityFeedState state) {
    if (state.isLoading && state.items.isEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.only(top: 8),
        itemCount: 3,
        itemBuilder: (_, __) => _buildPlaceholderCard(),
      );
    }

    if (state.errorMessage != null && state.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.accentSandDark),
              const SizedBox(height: 12),
              Text(
                state.errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.beVietnamPro(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(communityFeedProvider.notifier).loadFeed(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.items.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3EFEA),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(Icons.style_outlined, size: 34, color: AppColors.accentSandDark),
              ),
              const SizedBox(height: 16),
              Text(
                state.tab == 'following'
                    ? 'Chưa có bài viết từ người bạn theo dõi'
                    : 'Chưa có bài viết nào',
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                state.tab == 'following'
                    ? 'Hãy theo dõi thêm nhiều nhà sáng tạo thời trang để cập nhật xu hướng.'
                    : 'Hãy là người đầu tiên chia sẻ cảm hứng phối đồ hôm nay!',
                textAlign: TextAlign.center,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: state.tab == 'following'
                    ? () => ref.read(communityFeedProvider.notifier).changeTab('explore')
                    : _onCreatePost,
                icon: Icon(
                  state.tab == 'following' ? Icons.explore_outlined : Icons.add_rounded,
                  size: 18,
                ),
                label: Text(state.tab == 'following' ? 'Khám phá cộng đồng' : 'Đăng bài ngay'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 4, bottom: 80),
      itemCount: state.items.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == state.items.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            ),
          );
        }

        final post = state.items[index];
        return PostCard(
          post: post,
          onLikeToggle: () {
            ref.read(communityFeedProvider.notifier).toggleLike(post.publicId);
          },
          onCommentTap: () {
            context.push('/community/posts/${post.publicId}?focus=comment');
          },
          onEdit: () {
            context.push('/community/create?editId=${post.publicId}');
          },
          onDelete: () {
            _handleDeletePost(post.publicId);
          },
        );
      },
    );
  }

  Widget _buildPlaceholderCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 220,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.accentSandDark),
      ),
    );
  }
}
