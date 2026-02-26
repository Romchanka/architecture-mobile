class LoginRequest {
  final String phone;
  final String password;
  LoginRequest({required this.phone, required this.password});
  Map<String, dynamic> toJson() => {'phone': phone, 'password': password};
}

class RegisterRequest {
  final String phone;
  final String password;
  final String firstName;
  final String lastName;
  final String? middleName;
  final String? email;

  RegisterRequest({
    required this.phone,
    required this.password,
    required this.firstName,
    required this.lastName,
    this.middleName,
    this.email,
  });

  Map<String, dynamic> toJson() => {
    'phone': phone,
    'password': password,
    'firstName': firstName,
    'lastName': lastName,
    if (middleName != null) 'middleName': middleName,
    if (email != null) 'email': email,
  };
}

class LoginResponse {
  final String token;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;

  LoginResponse({
    required this.token,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) => LoginResponse(
    token: json['token'],
    refreshToken: json['refreshToken'],
    tokenType: json['tokenType'] ?? 'Bearer',
    expiresIn: json['expiresIn'] ?? 86400,
  );
}

class UserInfo {
  final int id;
  final String firstName;
  final String lastName;
  final String? middleName;
  final String fullName;
  final String phone;
  final String? email;

  UserInfo({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.middleName,
    required this.fullName,
    required this.phone,
    this.email,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) => UserInfo(
    id: json['id'],
    firstName: json['firstName'] ?? '',
    lastName: json['lastName'] ?? '',
    middleName: json['middleName'],
    fullName: json['fullName'] ?? '',
    phone: json['phone'] ?? '',
    email: json['email'],
  );
}
