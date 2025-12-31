enum UserRole { user, driver }

UserRole? userRoleFromString(String? value) {
  switch (value) {
    case 'user':
      return UserRole.user;
    case 'driver':
      return UserRole.driver;
    default:
      return null;
  }
}

String userRoleToString(UserRole role) {
  switch (role) {
    case UserRole.user:
      return 'user';
    case UserRole.driver:
      return 'driver';
  }
}