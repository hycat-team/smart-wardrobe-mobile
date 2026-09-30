import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wardrobe/features/auth/data/auth_repository.dart';
import 'package:smart_wardrobe/features/auth/models/auth_models.dart';
import 'package:smart_wardrobe/features/auth/providers/auth_provider.dart';
import 'package:smart_wardrobe/features/community/data/community_repository.dart';
import 'package:smart_wardrobe/features/community/models/comment_models.dart';
import 'package:smart_wardrobe/features/community/models/community_user.dart';
import 'package:smart_wardrobe/features/community/models/post_models.dart';
import 'package:smart_wardrobe/features/community/presentation/post_detail_screen.dart';

/// Repository giả: trả về 1 bài viết cố định, không gọi mạng.
class _FakeDetailRepository extends CommunityRepository {
  @override
  Future<Post> getPostDetail(String publicId) async => _post(publicId);

  @override
  Future<List<Comment>> getPostComments(String publicId) async => const [];

  @override
  Future<List<Comment>> getCommentReplies(String publicId, String commentId) async =>
      const [];

  static Post _post(String publicId) => Post(
        id: 'p1',
        publicId: publicId,
        user: const CommunityUser(
            userId: 'u1', username: 'linh', firstName: 'Linh', lastName: 'Nguyễn'),
        postType: 'media',
        status: 'published',
        title: 'Set cuối tuần',
        content: 'Một bộ đồ đơn giản cho cuối tuần đi dạo phố.',
        likeCount: 3,
        commentCount: 2,
        isLiked: false,
        isFollowingAuthor: false,
        sharePath: '/community/posts/$publicId',
        createdAt: '2026-09-29T10:00:00Z',
        updatedAt: '2026-09-29T10:00:00Z',
      );
}

/// Repository auth không chạm mạng.
class _NoopAuthRepository extends AuthRepository {
  _NoopAuthRepository() : super(apiClient: null, storage: null);

  @override
  Future<bool> isAuthenticated() async => true;

  @override
  Future<UserModel> getCurrentUser() async => throw Exception('no user');
}

/// Notifier auth giả: luôn đã đăng nhập, không gọi mạng.
class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(super.repo, super.ref) {
    state = const AuthState(
      isAuthenticated: true,
      user: UserModel(
        id: 'me-1',
        username: 'linh',
        email: 'linh@example.com',
        firstName: 'Linh',
        lastName: 'Nguyễn',
      ),
    );
  }

  @override
  Future<void> checkAuthStatus() async {}
}

Widget _wrap() {
  final authRepo = _NoopAuthRepository();
  return ProviderScope(
    overrides: [
      communityRepositoryProvider.overrideWithValue(_FakeDetailRepository()),
      authRepositoryProvider.overrideWithValue(authRepo),
      authStateProvider.overrideWith((ref) => _FakeAuthNotifier(authRepo, ref)),
    ],
    child: const MaterialApp(home: PostDetailScreen(publicId: 'pub-1')),
  );
}

/// Mở ô nhập bình luận bằng cách bấm nút Bình luận trong thanh tương tác.
Future<void> _openCommentBar(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('postActionComment')));
  await tester.pumpAndSettle();
}

const _likeKey = ValueKey('postActionLike');
const _commentKey = ValueKey('postActionComment');
const _shareKey = ValueKey('postActionShare');

void main() {
  // Màn hình chuẩn 1080x2400 @3x → 360x800 logical.
  // Nội dung bài viết có padding ngang 20 mỗi bên → vùng nội dung rộng 320.
  const logicalSize = Size(360, 800);
  const contentWidth = 320.0;
  const dpr = 3.0;

  void useTestScreen(WidgetTester tester) {
    tester.view.physicalSize = logicalSize * dpr;
    tester.view.devicePixelRatio = dpr;
    addTearDown(tester.view.reset);
  }

  testWidgets('Ô nhập bình luận ẩn mặc định, chỉ mở khi bấm nút Bình luận',
      (tester) async {
    useTestScreen(tester);

    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    // Mặc định không có ô nhập.
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Thêm bình luận của bạn...'), findsNothing);

    await _openCommentBar(tester);

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Thêm bình luận của bạn...'), findsOneWidget);
  });

  testWidgets('Bấm nút đóng thì ẩn ô nhập', (tester) async {
    useTestScreen(tester);

    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    await _openCommentBar(tester);
    expect(find.byType(TextField), findsOneWidget);

    // Nút đóng nằm cạnh nút gửi trong thanh nhập.
    await tester.tap(find.byIcon(Icons.close_rounded).last);
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('Thanh tương tác: 3 nút mỗi nút 1/3 chiều ngang, chỉ icon + số',
      (tester) async {
    useTestScreen(tester);

    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    // Không còn nhãn dài làm vỡ hàng.
    expect(find.text('Chia sẻ'), findsNothing);
    expect(find.text('lượt thích'), findsNothing);
    expect(find.text('bình luận'), findsNothing);

    // Chia sẻ không lặp lại ở AppBar.
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byIcon(Icons.share_outlined),
      ),
      findsNothing,
    );

    // 3 nút canh giữa đều nhau: lần lượt ở 1/6, 1/2, 5/6 chiều ngang.
    final like = tester.getCenter(find.byKey(_likeKey));
    final comment = tester.getCenter(find.byKey(_commentKey));
    final share = tester.getCenter(find.byKey(_shareKey));

    final expected = [
      20 + contentWidth / 6,
      20 + contentWidth / 2,
      20 + contentWidth * 5 / 6,
    ];
    final actual = [like.dx, comment.dx, share.dx];

    for (var i = 0; i < 3; i++) {
      expect(
        actual[i],
        closeTo(expected[i], 2),
        reason: 'nút thứ ${i + 1} phải chiếm đúng 1/3 chiều ngang',
      );
    }

    // Chiều rộng mỗi nút = 1/3 màn hình, chiều cao ≥ 44px để dễ bấm.
    for (final key in const [_likeKey, _commentKey, _shareKey]) {
      final box = tester.getSize(find.byKey(key));
      expect(box.width, closeTo(contentWidth / 3, 2),
          reason: '$key phải rộng đúng 1/3');
      expect(box.height, greaterThanOrEqualTo(44),
          reason: '$key cao tối thiểu 44px');
    }
  });

  testWidgets('Khi bàn phím mở, ô nhập nằm TRÊN bàn phím (không bị che)',
      (tester) async {
    useTestScreen(tester);

    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    await _openCommentBar(tester);
    expect(find.byType(TextField), findsOneWidget);

    // Giả lập bàn phím cao 300 logical px.
    const keyboardHeight = 300.0;
    tester.view.viewInsets = FakeViewPadding(bottom: keyboardHeight * dpr);
    addTearDown(tester.view.reset);
    await tester.pumpAndSettle();

    // Đáy thanh nhập phải nằm trên đỉnh bàn phím.
    final sendBottom = tester.getBottomLeft(find.byIcon(Icons.send_rounded)).dy;
    expect(
      sendBottom,
      lessThanOrEqualTo(logicalSize.height - keyboardHeight),
      reason: 'ô nhập phải nhảy lên trên bàn phím, không nằm dưới bàn phím',
    );
  });
}
