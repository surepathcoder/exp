enum UserRole {
  superadmin,
  admin,
  user
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
  TZS,
  KES
}
