import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/closy_toast.dart';
import '../data/community_error.dart';
import '../data/community_repository.dart';
import '../models/profile_models.dart';
import '../providers/user_social_provider.dart';
import 'widgets/community_user_avatar.dart';
import 'widgets/follow_button.dart';
import 'widgets/post_card.dart';
import 'widgets/user_follows_sheet.dart';

class PublicProfileScreen extends ConsumerStatefulWidget {
  final String username;

  const PublicProfileScreen({
    super.key,
    required this.username,
  });

  @override
  ConsumerState<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends ConsumerState<PublicProfileScreen> {
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
      ref.read(publicProfileProvider(widget.username).notifier).loadMorePosts();
    }
  }

  void _openFollowsSheet(String initialType) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UserFollowsSheet(
        username: widget.username,
        initialType: initialType,
      ),
    );
  }

  Future<void> _handleDeletePost(String publicId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Xóa bài viết', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700)),
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
        ref.read(publicProfileProvider(widget.username).notifier).loadProfile();
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
    final profileState = ref.watch(publicProfileProvider(widget.username));
    final profile = profileState.profile;

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
          '@${widget.username}',
          style: GoogleFonts.beVietnamPro(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: AppColors.primary, size: 22),
            onPressed: () {
              ClosyToast.info(context, 'Đã sao chép liên kết hồ sơ: /users/${widget.username}');
            },
          ),
        ],
      ),
      body: profileState.isLoading && profile == null
          ? const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            )
          : profileState.errorMessage != null && profile == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person_off_outlined, size: 48, color: AppColors.accentSandDark),
                        const SizedBox(height: 12),
                        Text(
                          profileState.errorMessage!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.beVietnamPro(fontSize: 14, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => ref
                              .read(publicProfileProvider(widget.username).notifier)
                              .loadProfile(),
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  ),
                )
              : profile == null
                  ? const SizedBox.shrink()
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () async {
                        await ref
                            .read(publicProfileProvider(widget.username).notifier)
                            .loadProfile();
                      },
                      child: CustomScrollView(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          // 1. Header hồ sơ
                          SliverToBoxAdapter(
                            child: _buildProfileHeader(profile),
                          ),

                          // 2. Thống kê bài viết, follower, following
                          SliverToBoxAdapter(
                            child: _buildStatsRow(profile.stats),
                          ),

                          const SliverToBoxAdapter(child: SizedBox(height: 16)),

                          // 3. Tiêu đề mục bài viết
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              child: Text(
                                'BÀI VIẾT (${profile.stats.postCount})',
                                style: GoogleFonts.beVietnamPro(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),

                          // 4. Danh sách bài viết
                          if (profileState.posts.isEmpty)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Center(
                                  child: Text(
                                    'Chưa có bài viết nào',
                                    style: GoogleFonts.beVietnamPro(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          else
                            SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final post = profileState.posts[index];
                                  return PostCard(
                                    post: post,
                                    onEdit: () {
                                      context.push('/community/create?editId=${post.publicId}');
                                    },
                                    onDelete: () {
                                      _handleDeletePost(post.publicId);
                                    },
                                  );
                                },
                                childCount: profileState.posts.length,
                              ),
                            ),

                          // Bottom loader if hasMorePosts
                          if (profileState.hasMorePosts)
                            const SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child: Center(
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                ),
                              ),
                            ),

                          const SliverToBoxAdapter(child: SizedBox(height: 60)),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildProfileHeader(PublicProfile profile) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        children: [
          CommunityUserAvatar(
            user: profile.user,
            size: 80,
          ),
          const SizedBox(height: 12),
          Text(
            profile.user.displayName,
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '@${profile.user.username}',
            style: GoogleFonts.beVietnamPro(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          if (profile.user.gender != null && profile.user.gender! > 0) ...[
            const SizedBox(height: 4),
            Text(
              profile.user.genderLabel,
              style: GoogleFonts.beVietnamPro(
                fontSize: 12,
                color: AppColors.accentSandDark,
              ),
            ),
          ],
          const SizedBox(height: 14),

          // Nút Theo dõi (tự ẩn nếu là chính mình profile.isMe)
          FollowButton(
            username: widget.username,
            isFollowing: profile.isFollowing,
            isMe: profile.isMe,
            onToggleFollow: () {
              ref.read(publicProfileProvider(widget.username).notifier).toggleFollow();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(PublicProfileStats stats) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Row(
        children: [
          _buildStatItem('Bài viết', stats.postCount.toString(), null),
          Container(width: 1, height: 28, color: AppColors.border),
          _buildStatItem('Người theo dõi', stats.followerCount.toString(), () => _openFollowsSheet('followers')),
          Container(width: 1, height: 28, color: AppColors.border),
          _buildStatItem('Đang theo dõi', stats.followingCount.toString(), () => _openFollowsSheet('following')),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, VoidCallback? onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              Text(
                value,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
