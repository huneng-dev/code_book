class PasswordItem {
  final String id;
  final String name;
  final String category;
  final String plainPassword;
  final String? encryptedPassword;
  final DateTime createdAt;
  final DateTime lastUsed;

  PasswordItem({
    required this.id,
    required this.name,
    required this.category,
    required this.plainPassword,
    this.encryptedPassword,
    required this.createdAt,
    required this.lastUsed,
  });
} 