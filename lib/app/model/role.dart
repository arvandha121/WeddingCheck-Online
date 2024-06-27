class Role {
  final int? roleId;
  final String roleName;

  Role({
    this.roleId,
    required this.roleName,
  });

  Map<String, dynamic> toMap() {
    return {
      'roleId': roleId,
      'roleName': roleName,
    };
  }

  factory Role.fromMap(Map<String, dynamic> map) {
    return Role(
      roleId: map['roleId'],
      roleName: map['roleName'],
    );
  }
}
