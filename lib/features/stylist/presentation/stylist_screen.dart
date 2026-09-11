import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/closy_network_image.dart';
import '../models/stylist_models.dart';
import '../providers/stylist_provider.dart';

class StylistScreen extends ConsumerStatefulWidget {
  const StylistScreen({super.key});

  @override
  ConsumerState<StylistScreen> createState() => _StylistScreenState();
}

class _StylistScreenState extends ConsumerState<StylistScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSend() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    ref.read(stylistProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  void _showRenameDialog(ChatSessionModel session) {
    final renameController = TextEditingController(text: session.title);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Đổi tên cuộc trò chuyện',
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        content: TextField(
          controller: renameController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Nhập tiêu đề mới...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final newTitle = renameController.text.trim();
              if (newTitle.isNotEmpty) {
                ref.read(stylistProvider.notifier).updateSessionTitle(session.id, newTitle);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteSession(ChatSessionModel session) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa cuộc trò chuyện "${session.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              ref.read(stylistProvider.notifier).deleteSession(session.id);
              Navigator.pop(ctx);
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stylistState = ref.watch(stylistProvider);
    final currentSession = stylistState.currentSession;
    final messages = stylistState.messages;

    // Tự động cuộn xuống khi có tin nhắn mới hoặc streaming
    ref.listen<StylistState>(stylistProvider, (prev, next) {
      if (next.messages.length != prev?.messages.length || next.isStreaming) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: AppColors.primary),
          tooltip: 'Lịch sử trò chuyện',
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              currentSession?.title ?? 'AI Stylist',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                const Text(
                  'Trợ lý phong cách Closy',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment_outlined, color: AppColors.primary),
            tooltip: 'Cuộc trò chuyện mới',
            onPressed: () {
              ref.read(stylistProvider.notifier).createNewSession();
            },
          ),
        ],
      ),

      // Drawer Quản lý lịch sử các cuộc trò chuyện
      drawer: Drawer(
        backgroundColor: AppColors.surface,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.auto_awesome, color: AppColors.accentSand, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Lịch sử Stylist',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        ref.read(stylistProvider.notifier).createNewSession();
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Cuộc trò chuyện mới'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
              Expanded(
                child: stylistState.isLoadingSessions
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : stylistState.sessions.isEmpty
                        ? const Center(
                            child: Text(
                              'Chưa có cuộc trò chuyện nào',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            itemCount: stylistState.sessions.length,
                            itemBuilder: (ctx, idx) {
                              final s = stylistState.sessions[idx];
                              final isSelected = s.id == currentSession?.id;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Material(
                                  color: isSelected ? AppColors.accentSand.withOpacity(0.18) : Colors.transparent,
                                  clipBehavior: Clip.antiAlias,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: isSelected ? AppColors.accentSand : Colors.transparent,
                                      width: 1,
                                    ),
                                  ),
                                  child: ListTile(
                                  dense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                  leading: Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    size: 18,
                                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                                  ),
                                  title: Text(
                                    s.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                      fontSize: 14,
                                    ),
                                  ),
                                  subtitle: Text(
                                    s.formattedDate,
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                  ),
                                  trailing: PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert, size: 18, color: AppColors.textSecondary),
                                    onSelected: (val) {
                                      if (val == 'rename') {
                                        _showRenameDialog(s);
                                      } else if (val == 'delete') {
                                        _confirmDeleteSession(s);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'rename',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit_outlined, size: 16),
                                            SizedBox(width: 8),
                                            Text('Đổi tên'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                                            SizedBox(width: 8),
                                            Text('Xóa', style: TextStyle(color: Colors.redAccent)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                    Navigator.pop(context);
                                    if (!isSelected) {
                                      ref.read(stylistProvider.notifier).selectSession(s.id);
                                    }
                                  },
                                ),
                              ),
                            );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),

      body: Column(
        children: [
          // Khu vực tin nhắn hoặc Welcome Hero khi chưa có tin nhắn
          Expanded(
            child: stylistState.isLoadingMessages
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : messages.isEmpty
                    ? _buildWelcomeHero()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: messages.length,
                        itemBuilder: (ctx, idx) {
                          final msg = messages[idx];
                          return _buildMessageBubble(msg);
                        },
                      ),
          ),

          // Thanh gợi ý nhanh (Quick Chips)
          _buildQuickChipsBar(),

          // Ô nhập tin nhắn
          _buildInputBar(stylistState.isStreaming),
        ],
      ),
    );
  }

  Widget _buildWelcomeHero() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(color: AppColors.border, width: 0.8),
            ),
            child: const Icon(Icons.auto_awesome, size: 36, color: Color(0xFFB8975A)),
          ),
          const SizedBox(height: 16),
          Text(
            'Stylist Cá Nhân Closy',
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hàng ngàn gợi ý phối đồ thông minh từ chính tủ đồ của bạn.\nChia sẻ dịp sự kiện hoặc phong cách bạn yêu thích:',
            textAlign: TextAlign.center,
            style: GoogleFonts.beVietnamPro(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 24),

          // Nhóm Dịp sự kiện
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '✨ Dịp sự kiện',
              style: GoogleFonts.playfairDisplay(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildPromptChip('💼 Đi làm công sở thanh lịch'),
              _buildPromptChip('☕ Dạo phố cuối tuần năng động'),
              _buildPromptChip('🍷 Dự tiệc tối sang trọng'),
              _buildPromptChip('🌹 Hẹn hò lãng mạn tinh tế'),
              _buildPromptChip('✈️ Du lịch nghỉ dưỡng thoải mái'),
            ],
          ),

          const SizedBox(height: 20),
          // Nhóm Phong cách
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '🎨 Phong cách thời trang',
              style: GoogleFonts.playfairDisplay(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildPromptChip('Tối giản (Minimalism)'),
              _buildPromptChip('Thanh lịch (Old Money)'),
              _buildPromptChip('Cổ điển (Classic Vintage)'),
              _buildPromptChip('Năng động (Streetwear)'),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildPromptChip(String label) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border, width: 0.8),
      ),
      onPressed: () {
        ref.read(stylistProvider.notifier).sendMessage('Gợi ý cho tôi set đồ theo phong cách: $label');
      },
    );
  }

  Widget _buildQuickChipsBar() {
    final quickPrompts = [
      '✨ Hôm nay mặc gì đẹp?',
      '💼 Set đồ đi làm thanh lịch',
      '👖 Phối đồ với quần âu',
      '👠 Gợi ý trang phục dự tiệc',
      '🎨 Mẹo phối màu trang phục',
    ];

    return Container(
      height: 42,
      margin: const EdgeInsets.only(bottom: 6),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: quickPrompts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, idx) {
          final prompt = quickPrompts[idx];
          return ActionChip(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
            label: Text(
              prompt,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.primary),
            ),
            backgroundColor: AppColors.surface,
            side: const BorderSide(color: AppColors.border, width: 0.8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onPressed: () {
              ref.read(stylistProvider.notifier).sendMessage(prompt);
            },
          );
        },
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessageModel msg) {
    final isUser = msg.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome, color: Color(0xFFD9C5B2), size: 14),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUser ? const Color(0xFFE5D5C5) : AppColors.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: isUser ? const Radius.circular(18) : const Radius.circular(4),
                      bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border.all(
                      color: isUser ? Colors.transparent : AppColors.border,
                      width: 0.6,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        msg.cleanContent.isEmpty && msg.isStreaming ? 'Đang suy nghĩ...' : msg.cleanContent,
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 14,
                          color: isUser ? const Color(0xFF1A1A1A) : AppColors.textPrimary,
                          height: 1.5,
                        ),
                      ),
                      if (msg.isStreaming) ...[
                        const SizedBox(height: 6),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            SizedBox(
                              width: 10,
                              height: 10,
                              child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.primary),
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Stylist đang trả lời...',
                              style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Thẻ Lookbook trực quan cuộn ngang nếu AI gợi ý món đồ
                if (msg.suggestedItems.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _buildLookbookCarousel(msg.suggestedItems),
                ],

                // Nút hành động mở Studio nếu AI phát hiện nhu cầu phối đồ
                if (msg.hasOutfitRedirect) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => context.push('/outfits/create'),
                    icon: const Icon(Icons.style_outlined, size: 16, color: AppColors.primary),
                    label: const Text('Mở Outfit Studio để thử ngay', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.surface,
                      side: const BorderSide(color: AppColors.accentSand, width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLookbookCarousel(List<OutfitRecommendationItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            'Gợi ý trang phục trong set đồ:',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
        ),
        SizedBox(
          height: 185,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (ctx, idx) {
              final it = items[idx];
              return Container(
                width: 135,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border, width: 0.8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        color: const Color(0xFFF2EFE9),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ClosyNetworkImage(
                              imageUrl: it.imageUrl ?? '',
                              fit: BoxFit.contain,
                              memCacheWidth: 200,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (it.brand != null && it.brand!.isNotEmpty)
                            Text(
                              it.brand!.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                                color: Color(0xFFB8975A),
                              ),
                            ),
                          Text(
                            it.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                          ),
                          if (it.color != null && it.color!.isNotEmpty)
                            Text(
                              it.color!,
                              maxLines: 1,
                              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInputBar(bool isStreaming) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.border, width: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border, width: 0.8),
                ),
                child: TextField(
                  controller: _textController,
                  maxLines: 4,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _handleSend(),
                  style: GoogleFonts.beVietnamPro(fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Nhắn tin cho Stylist AI...',
                    hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: isStreaming
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
                tooltip: 'Gửi tin nhắn',
                onPressed: isStreaming ? null : _handleSend,
              ),
            ),
          ],
        ),
      ),
    );
  }

}
