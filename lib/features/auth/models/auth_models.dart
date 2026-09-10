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
