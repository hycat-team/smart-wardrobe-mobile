class CommunityUser {
  final String userId;
  final String username;
  final String? firstName;
  final String? lastName;
  final String? avatarUrl;
  final int? gender; // 1=Nam, 2=Nữ, 3=Khác, 0 hoặc null=không xác định

  const CommunityUser({
    required this.userId,
    required this.username,
    this.firstName,
    this.lastName,
    this.avatarUrl,
    this.gender,
  });

  factory CommunityUser.fromJson(Map<String, dynamic> json) {
    return CommunityUser(
      userId: json['userId']?.toString() ?? json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      firstName: json['firstName']?.toString(),
      lastName: json['lastName']?.toString(),
      avatarUrl: json['avatarUrl']?.toString(),
      gender: json['gender'] is int ? json['gender'] as int : int.tryParse(json['gender']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      if (firstName != null) 'firstName': firstName,
      if (lastName != null) 'lastName': lastName,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      if (gender != null) 'gender': gender,
    };
  }

  /// Tên hiển thị ưu tiên First + Last -> Username -> 'Thành viên Closy'
  String get displayName {
    final fn = firstName?.trim() ?? '';
    final ln = lastName?.trim() ?? '';
    if (fn.isNotEmpty || ln.isNotEmpty) {
      return '$fn $ln'.trim();
    }
    if (username.trim().isNotEmpty) {
      return username.trim();
    }
    return 'Thành viên Closy';
  }

  /// Ký tự viết tắt 1-2 chữ cái cho avatar fallback
  String get initials {
    final fn = firstName?.trim() ?? '';
    final ln = lastName?.trim() ?? '';
    if (fn.isNotEmpty && ln.isNotEmpty) {
      return '${fn[0]}${ln[0]}'.toUpperCase();
    }
    if (fn.isNotEmpty) {
      return fn.substring(0, fn.length >= 2 ? 2 : 1).toUpperCase();
    }
    if (username.trim().isNotEmpty) {
      final un = username.trim();
      return un.substring(0, un.length >= 2 ? 2 : 1).toUpperCase();
    }
    return 'CL';
  }

  /// Nhãn giới tính tiếng Việt
  String get genderLabel {
    switch (gender) {
      case 1:
        return 'Nam';
      case 2:
        return 'Nữ';
      case 3:
        return 'Khác';
      default:
        return 'Chưa xác định';
    }
  }
}
