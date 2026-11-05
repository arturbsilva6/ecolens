/// Dados de apresentação, nunca usados para autorização.
class UserModel {
  final String id;
  final String email;
  final String displayName;

  const UserModel({
    required this.id,
    required this.email,
    required this.displayName,
  });
}
