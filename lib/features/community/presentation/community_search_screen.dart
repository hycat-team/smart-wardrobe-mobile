import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../models/community_user.dart';
import '../providers/community_feed_provider.dart';
import '../providers/community_search_provider.dart';
import 'widgets/community_user_avatar.dart';
import 'widgets/post_card.dart';

class CommunitySearchScreen extends ConsumerStatefulWidget {
  const CommunitySearchScreen({super.key});

  @override
  ConsumerState<CommunitySearchScreen> createState() => _CommunitySearchScreenState();
}

class _CommunitySearchScreenState extends ConsumerState<CommunitySearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<String> _suggestedQueries = [
    'Quiet Luxury',
    'Tối giản',
    'Thanh lịch thường ngày',
    'Trang phục công sở',
    'Đơn sắc',
    'Phong cách cuối tuần',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (currentScroll >= maxScroll - 300) {
      final state = ref.read(communitySearchProvider);
      final notifier = ref.read(communitySearchProvider.notifier);
      if (state.searchType == 'all' || state.searchType == 'posts') {
        notifier.loadMorePosts();
      }
      if (state.searchType == 'users') {
        notifier.loadMoreUsers();
      }
    }
  }

  void _selectSuggested(String query) {
    _searchController.text = query;
    ref.read(communitySearchProvider.notifier).executeSearch(query);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(communitySearchProvider);
    final notifier = ref.read(communitySearchProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, width: 0.8),
            ),
            child: TextField(
              controller: _searchController,
              autofocus: false,
              style: GoogleFonts.beVietnamPro(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textSecondary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18, color: AppColors.textSecondary),
                        onPressed: () {
                          _searchController.clear();
                          notifier.clearSearch();
                          setState(() {});
                        },
                      )
                    : null,
                hintText: 'Tìm kiếm phong cách, tác giả...',
                hintStyle: GoogleFonts.beVietnamPro(
                  fontSize: 14,
                  color: AppColors.textSecondary.withOpacity(0.7),
                ),
                border: InputBorder.none,
              ),
              onChanged: (val) {
                setState(() {});
                notifier.onQueryChanged(val);
              },
              onSubmitted: (val) {
                notifier.executeSearch(val);
              },
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Column(
            children: [
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildTabChip('Tất cả', 'all', state.searchType, () {
                      notifier.changeSearchType('all');
                    }),
                    const SizedBox(width: 8),
                    _buildTabChip('Tác giả', 'users', state.searchType, () {
                      notifier.changeSearchType('users');
                    }),
                    const SizedBox(width: 8),
                    _buildTabChip('Bài viết', 'posts', state.searchType, () {
                      notifier.changeSearchType('posts');
                    }),
                    if (state.searchType == 'posts') ...[
                      const SizedBox(width: 12),
                      Container(height: 20, width: 1, color: AppColors.border),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildPostTypeChip('Tất cả bài', null, state.postTypeFilter, () {
                                notifier.changePostTypeFilter(null);
                              }),
                              const SizedBox(width: 6),
                              _buildPostTypeChip('Bộ phối', 'outfit', state.postTypeFilter, () {
                                notifier.changePostTypeFilter('outfit');
                              }),
                              const SizedBox(width: 6),
                              _buildPostTypeChip('Ảnh/Video', 'media', state.postTypeFilter, () {
                                notifier.changePostTypeFilter('media');
                              }),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(height: 1, color: AppColors.border.withOpacity(0.5)),
            ],
          ),
        ),
      ),
      body: _buildBody(state, notifier),
    );
  }

  Widget _buildTabChip(String label, String value, String currentValue, VoidCallback onTap) {
    final isSelected = value == currentValue;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.beVietnamPro(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildPostTypeChip(String label, String? value, String? currentValue, VoidCallback onTap) {
    final isSelected = value == currentValue;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentSand.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.accentSand : AppColors.border,
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.beVietnamPro(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildBody(CommunitySearchState state, CommunitySearchNotifier notifier) {
    if (state.query.isEmpty && _searchController.text.trim().isEmpty) {
      return _buildInitialExplore();
    }

    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.accentSand,
        ),
      );
    }

    if (state.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_outlined, size: 48, color: AppColors.textSecondary),
              const SizedBox(height: 12),
              Text(
                state.errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.beVietnamPro(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => notifier.executeSearch(state.query),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Thử lại', style: GoogleFonts.beVietnamPro(fontSize: 14)),
              ),
            ],
          ),
        ),
      );
    }

    final hasNoUsers = state.users.isEmpty;
    final hasNoPosts = state.posts.isEmpty;

    if (hasNoUsers && hasNoPosts) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off_outlined, size: 56, color: AppColors.textSecondary.withOpacity(0.5)),
              const SizedBox(height: 16),
              Text(
                'Không tìm thấy kết quả',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Không có người dùng hoặc bài viết nào phù hợp với từ khóa "${state.query}"',
                textAlign: TextAlign.center,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.accentSand,
      onRefresh: () => notifier.executeSearch(state.query),
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
          if (state.searchType == 'all') ...[
            if (state.users.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: _buildSectionHeader(
                  title: 'Nhà sáng tạo',
                  count: state.totalUsers,
                  onActionTap: () => notifier.changeSearchType('users'),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 142,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: state.users.take(8).length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final user = state.users[index];
                      return _buildUserMiniCard(user);
                    },
                  ),
                ),
              ),
            ],
            if (state.posts.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: _buildSectionHeader(
                    title: 'Bài viết phong cách',
                    count: state.totalPosts,
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final post = state.posts[index];
                    return PostCard(
                      post: post,
                      onLikeToggle: () {
                        ref.read(communityFeedProvider.notifier).toggleLike(post.publicId);
                      },
                      onCommentTap: () {
                        context.push('/community/posts/${post.publicId}?focus=comment');
                      },
                    );
                  },
                  childCount: state.posts.length,
                ),
              ),
              if (state.isLoadingMorePosts)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentSand),
                    ),
                  ),
                ),
            ],
          ] else if (state.searchType == 'users') ...[
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final user = state.users[index];
                  return _buildUserListTile(user);
                },
                childCount: state.users.length,
              ),
            ),
            if (state.isLoadingMoreUsers)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentSand),
                  ),
                ),
              ),
          ] else if (state.searchType == 'posts') ...[
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final post = state.posts[index];
                  return PostCard(
                    post: post,
                    onLikeToggle: () {
                      ref.read(communityFeedProvider.notifier).toggleLike(post.publicId);
                    },
                    onCommentTap: () {
                      context.push('/community/posts/${post.publicId}?focus=comment');
                    },
                  );
                },
                childCount: state.posts.length,
              ),
            ),
            if (state.isLoadingMorePosts)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentSand),
                  ),
                ),
              ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required int count,
    VoidCallback? onActionTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$title ($count)',
            style: GoogleFonts.playfairDisplay(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          if (onActionTap != null)
            GestureDetector(
              onTap: onActionTap,
              child: Text(
                'Xem tất cả',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.accentSand,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUserMiniCard(CommunityUser user) {
    return GestureDetector(
      onTap: () => context.push('/users/${user.username}'),
      child: Container(
        width: 110,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CommunityUserAvatar(
              user: user,
              size: 52,
            ),
            const SizedBox(height: 8),
            Text(
              user.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.beVietnamPro(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '@${user.username}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.beVietnamPro(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserListTile(CommunityUser user) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          onTap: () => context.push('/users/${user.username}'),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: CommunityUserAvatar(
            user: user,
            size: 44,
          ),
          title: Text(
            user.displayName,
            style: GoogleFonts.beVietnamPro(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          subtitle: Text(
            '@${user.username} • ${user.genderLabel}',
            style: GoogleFonts.beVietnamPro(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          trailing: const Icon(
            Icons.chevron_right,
            size: 20,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildInitialExplore() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.accentSand.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 30,
                color: AppColors.accentSand,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              'Cảm hứng phong cách ClosY',
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Tìm kiếm trang phục tinh tế, các bản phối thịnh hành hoặc người truyền cảm hứng thời trang.',
              textAlign: TextAlign.center,
              style: GoogleFonts.beVietnamPro(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 36),
          Text(
            'Gợi ý phong cách nổi bật',
            style: GoogleFonts.playfairDisplay(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _suggestedQueries.map((query) {
              return ActionChip(
                backgroundColor: AppColors.surface,
                side: const BorderSide(color: AppColors.border, width: 0.8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                avatar: const Icon(Icons.trending_up, size: 16, color: AppColors.accentSand),
                label: Text(
                  query,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onPressed: () => _selectSuggested(query),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
