/// Dados de apresentação, nunca usados para autorização.
class UserModel {
  final String id;
  final String email;
  final String displayName;

  /// Conta com senha do EcoLens. Contas que só entram pelo Google não têm.
  final bool hasPassword;

  const UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    this.hasPassword = true,
  });
}
