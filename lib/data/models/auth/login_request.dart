/// Request body for POST /auth/login
class LoginRequest {
  final String? email;
  final String? phone;
  final String password;

  const LoginRequest({
    this.email,
    this.phone,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'password': password};
    if (email != null && email!.isNotEmpty) map['email'] = email;
    if (phone != null && phone!.isNotEmpty) map['phone'] = phone;
    return map;
  }
}