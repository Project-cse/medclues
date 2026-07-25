class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    this.isNewUser = false,
  });

  final String accessToken;
  final String refreshToken;
  final bool isNewUser;
}
