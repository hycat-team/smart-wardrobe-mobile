import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/community_repository.dart';
import '../../models/community_user.dart';
import 'community_user_avatar.dart';

class PostLikesSheet extends ConsumerStatefulWidget {
  final String publicId;

  const PostLikesSheet({
    super.key,
    required this.publicId,
  });

  @override
  ConsumerState<PostLikesSheet> createState() => _PostLikesSheetState();
}

class _PostLikesSheetState extends ConsumerState<PostLikesSheet> {
  final List<CommunityUser> _users = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _page = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchLikes();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100) {
      _loadMore();
    }
  }

  Future<void> _fetchLikes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(communityRepositoryProvider);
      final res = await repo.getPostLikes(widget.publicId, page: 1, limit: 20);
      if (!mounted) return;
      setState(() {
        _users.clear();
        _users.addAll(res.items);
        _hasMore = res.metadata.hasMore;
        _page = 1;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Không thể tải danh sách người thích';
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);

    try {
      final repo = ref.read(communityRepositoryProvider);
      final res = await repo.getPostLikes(widget.publicId, page: _page + 1, limit: 20);
      if (!mounted) return;
      setState(() {
        _users.addAll(res.items);
        _page = _page + 1;
        _hasMore = res.metadata.hasMore;
        _isLoadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.85,
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
              const SizedBox(height: 12),
              // Title bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Người thích bài viết',
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
              // Body
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(AppColors.primary),
                        ),
                      )
                    : _errorMessage != null
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                                TextButton(onPressed: _fetchLikes, child: const Text('Thử lại')),
                              ],
                            ),
                          )
                        : _users.isEmpty
                            ? Center(
                                child: Text(
                                  'Chưa có lượt thích nào',
                                  style: GoogleFonts.beVietnamPro(
                                    color: AppColors.textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                controller: scrollController,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                itemCount: _users.length + (_hasMore ? 1 : 0),
                                separatorBuilder: (_, __) => const Divider(height: 1, indent: 64, color: AppColors.border),
                                itemBuilder: (context, index) {
                                  if (index == _users.length) {
                                    return const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(12),
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                    );
                                  }
                                  final user = _users[index];
                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    leading: CommunityUserAvatar(
                                      user: user,
                                      size: 42,
                                    ),
                                    title: Text(
                                      user.displayName,
                                      style: GoogleFonts.beVietnamPro(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '@${user.username}',
                                      style: GoogleFonts.beVietnamPro(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    onTap: () {
                                      Navigator.of(context).pop();
                                      context.push('/users/${user.username}');
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
}
