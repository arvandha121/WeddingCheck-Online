class Users {
  final int? usrId;
  final String usrName;
  final String usrPassword;
  final String role;
  final int isVerified;

  Users({
    this.usrId,
    required this.usrName,
    required this.usrPassword,
    required this.role,
    this.isVerified = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'usrId': usrId,
      'usrName': usrName,
      'usrPassword': usrPassword,
      'role': role,
      'isVerified': isVerified,
    };
  }

  factory Users.fromMap(Map<String, dynamic> map) {
    return Users(
      usrId: map['usrId'],
      usrName: map['usrName'],
      usrPassword: map['usrPassword'],
      role: map['role'],
      isVerified: map['isVerified'],
    );
  }
}
