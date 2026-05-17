enum UserRole {
  superadmin,
  admin,
  user
}

extension UserRoleExtension on UserRole {
  String get name {
    switch (this) {
      case UserRole.superadmin:
        return 'superadmin';
      case UserRole.admin:
        return 'admin';
      case UserRole.user:
        return 'user';
    }
  }
}

UserRole roleFromString(String roleStr) {
  switch (roleStr.toLowerCase()) {
    case 'superadmin':
      return UserRole.superadmin;
    case 'admin':
      return UserRole.admin;
    default:
      return UserRole.user;
  }
}

enum Currency {
  USD,
  CDF,
  TZS,
  UGX
}
