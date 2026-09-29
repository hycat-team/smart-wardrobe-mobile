class LoginRequest {
  final String loginName;
  final String password;

  const LoginRequest({
    required this.loginName,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        'loginName': loginName,
        'password': password,
      };
}

class RegisterRequest {
  final String username;
  final String email;
  final String password;
  final String confirmPassword;
  final String firstName;
  final String? lastName;
  final String dateOfBirth; // YYYY-MM-DD
  final String address;
  final int gender; // 1 = Male, 2 = Female, 3 = Other

  const RegisterRequest({
    required this.username,
    required this.email,
    required this.password,
    required this.confirmPassword,
    required this.firstName,
    this.lastName,
    required this.dateOfBirth,
    required this.address,
    this.gender = 1,
  });

  Map<String, dynamic> toJson() => {
        'username': username,
        'email': email,
        'password': password,
        'confirmPassword': confirmPassword,
        'firstName': firstName,
        'lastName': (lastName != null && lastName!.isNotEmpty) ? lastName : null,
        'dateOfBirth': dateOfBirth,
        'address': address,
        'gender': gender,
      };
}

class ConfirmRegisterOtpRequest {
  final String email;
  final String otpCode;

  const ConfirmRegisterOtpRequest({
    required this.email,
    required this.otpCode,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'otpCode': otpCode,
      };
}

class ResendOtpRequest {
  final String email;

  const ResendOtpRequest({required this.email});

  Map<String, dynamic> toJson() => {'email': email};
}

class ForgotPasswordRequest {
  final String email;

  const ForgotPasswordRequest({required this.email});

  Map<String, dynamic> toJson() => {'email': email};
}

class ConfirmForgotPasswordOtpRequest {
  final String email;
  final String otpCode;

  const ConfirmForgotPasswordOtpRequest({
    required this.email,
    required this.otpCode,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'otpCode': otpCode,
      };
}

class ResetPasswordRequest {
  final String newPassword;
  final String confirmPassword;
  final bool logoutAllDevices;

  const ResetPasswordRequest({
    required this.newPassword,
    required this.confirmPassword,
    this.logoutAllDevices = true,
  });

  Map<String, dynamic> toJson() => {
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
        'logoutAllDevices': logoutAllDevices,
      };
}

class AuthTokenResponse {
  final String accessToken;
  final String? refreshToken;
  final String? message;

  const AuthTokenResponse({
    required this.accessToken,
    this.refreshToken,
    this.message,
  });

  factory AuthTokenResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic> ? json['data'] : json;
    return AuthTokenResponse(
      accessToken: data['accessToken'] ?? data['token'] ?? data['access_token'] ?? '',
      refreshToken: data['refreshToken'] ?? data['refresh_token'],
      message: json['message'] as String?,
    );
  }
}

class UserModel {
  final String id;
  final String username;
  final String email;
  final String? firstName;
  final String? lastName;
  final String role;
  final String? avatarUrl;
  final String? dateOfBirth;
  final String? address;
  final int? gender;

  const UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.firstName,
    this.lastName,
    this.role = 'CUSTOMER',
    this.avatarUrl,
    this.dateOfBirth,
    this.address,
    this.gender,
  });

  String get displayName => fullName;
  String get fullName {
    final fn = firstName?.trim() ?? '';
    final ln = lastName?.trim() ?? '';
    final combined = '$fn $ln'.trim();
    if (combined.isNotEmpty) return combined;
    final un = username.trim();
    if (un.isNotEmpty) return un;
    final em = email.trim();
    if (em.isNotEmpty) return em;
    return 'Người dùng Closy';
  }

  bool get isAdmin => role.toUpperCase().contains('ADMIN');
  bool get isBrand => role.toUpperCase().contains('BRAND');
  bool get isCustomer => !isAdmin && !isBrand;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      firstName: json['firstName']?.toString(),
      lastName: json['lastName']?.toString(),
      role: json['role']?.toString() ??
          json['roleSlug']?.toString() ??
          (json['roles'] is List && (json['roles'] as List).isNotEmpty
              ? json['roles'][0]?.toString() ?? 'CUSTOMER'
              : 'CUSTOMER'),
      avatarUrl: json['avatarUrl']?.toString() ?? json['avatar']?.toString(),
      dateOfBirth: json['dateOfBirth']?.toString(),
      address: json['address']?.toString(),
      gender: json['gender'] is int
          ? json['gender']
          : int.tryParse(json['gender']?.toString() ?? ''),
    );
  }
}

class GoogleLoginRequest {
  final String idToken;
  final String deviceName;

  const GoogleLoginRequest({
    required this.idToken,
    this.deviceName = 'Android',
  });

  Map<String, dynamic> toJson() => {
        'idToken': idToken,
        'deviceName': deviceName,
      };
}

class RefreshTokenRequest {
  final String oldRefreshToken;
  final String deviceName;

  const RefreshTokenRequest({
    required this.oldRefreshToken,
    this.deviceName = 'Android',
  });

  Map<String, dynamic> toJson() => {
        'oldRefreshToken': oldRefreshToken,
        'deviceName': deviceName,
      };
}

enum AuthErrorCode {
  cancelled,
  emailUnverified,
  emailRegistered,
  accountLinked,
  accountDisabled,
  exchangeFailed,
  invalidToken,
  serverError,
  network;

  String get defaultMessage {
    switch (this) {
      case AuthErrorCode.cancelled:
        return 'Đăng nhập đã bị huỷ.';
      case AuthErrorCode.emailUnverified:
        return 'Email Google chưa được xác thực.';
      case AuthErrorCode.emailRegistered:
        return 'Email đã được đăng ký. Vui lòng đăng nhập bằng mật khẩu.';
      case AuthErrorCode.accountLinked:
        return 'Email đã liên kết với tài khoản Google khác.';
      case AuthErrorCode.accountDisabled:
        return 'Tài khoản đã bị khoá. Vui lòng liên hệ CSKH.';
      case AuthErrorCode.exchangeFailed:
        return 'Không hoàn tất được đăng nhập, vui lòng thử lại.';
      case AuthErrorCode.invalidToken:
        return 'Phiên Google không hợp lệ, thử đăng nhập lại.';
      case AuthErrorCode.serverError:
        return 'Có lỗi xảy ra, vui lòng thử lại sau.';
      case AuthErrorCode.network:
        return 'Không thể kết nối đến máy chủ.';
    }
  }

  static AuthErrorCode fromErrorAndStatus({
    String? rawError,
    int? statusCode,
    String? message,
  }) {
    final err = (rawError ?? '').toLowerCase().trim();
    final msg = (message ?? '').toLowerCase().trim();

    if (err.contains('access_denied') ||
        err.contains('canceled') ||
        err.contains('cancelled') ||
        msg.contains('huỷ') ||
        msg.contains('hủy')) {
      return AuthErrorCode.cancelled;
    }
    if (err.contains('email_unverified') ||
        msg.contains('email google chưa được xác thực') ||
        msg.contains('chưa được xác thực')) {
      return AuthErrorCode.emailUnverified;
    }
    if (err.contains('email_registered') ||
        msg.contains('email đã được đăng ký') ||
        msg.contains('đăng nhập bằng mật khẩu')) {
      return AuthErrorCode.emailRegistered;
    }
    if (statusCode == 409 ||
        err.contains('account_linked') ||
        msg.contains('liên kết')) {
      return AuthErrorCode.accountLinked;
    }
    if (statusCode == 403 ||
        err.contains('account_disabled') ||
        msg.contains('khoá') ||
        msg.contains('khóa') ||
        msg.contains('vô hiệu')) {
      return AuthErrorCode.accountDisabled;
    }
    if (err.contains('exchange_failed')) {
      return AuthErrorCode.exchangeFailed;
    }
    if (err.contains('invalid_token') ||
        msg.contains('token') ||
        msg.contains('không hợp lệ')) {
      return AuthErrorCode.invalidToken;
    }
    if (statusCode != null && statusCode >= 500) {
      return AuthErrorCode.serverError;
    }
    if (statusCode == 400) {
      return AuthErrorCode.exchangeFailed;
    }
    return AuthErrorCode.network;
  }
}

class GoogleSignInOutcome {
  final bool success;
  final bool linkedExistingAccount;
  final AuthErrorCode? errorCode;
  final String? message;

  const GoogleSignInOutcome({
    required this.success,
    this.linkedExistingAccount = false,
    this.errorCode,
    this.message,
  });

  factory GoogleSignInOutcome.succeeded({
    bool linkedExistingAccount = false,
    String? message,
  }) {
    return GoogleSignInOutcome(
      success: true,
      linkedExistingAccount: linkedExistingAccount,
      message: message,
    );
  }

  factory GoogleSignInOutcome.failed({
    required AuthErrorCode errorCode,
    String? customMessage,
  }) {
    return GoogleSignInOutcome(
      success: false,
      errorCode: errorCode,
      message: customMessage ?? errorCode.defaultMessage,
    );
  }

  factory GoogleSignInOutcome.cancelled() {
    return const GoogleSignInOutcome(
      success: false,
      errorCode: AuthErrorCode.cancelled,
      message: null,
    );
  }
}
