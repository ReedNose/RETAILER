// Named app_user (not User) to avoid clashing with other libraries.

enum UserRole { retailer, customer }

extension UserRoleDb on UserRole {
  String get db_value => name.toUpperCase(); // RETAILER | CUSTOMER
}

class AppUser {
  const AppUser({
    required this.user_id,
    required this.role,
    required this.customer_id,
    required this.pin_hash,
  });

  final String user_id;
  final UserRole role;
  final String? customer_id; // null for the retailer
  final String pin_hash; // mock: plain PIN for now. Swap for real auth later.
}
