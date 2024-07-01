class Users {
  int? usrId;
  String usrName;
  String usrPassword;
  int id_role;
  int isVerified;

  Users({
    this.usrId,
    required this.usrName,
    required this.usrPassword,
    required this.id_role,
    this.isVerified = 0,
  });

  factory Users.fromMap(Map<String, dynamic> map) {
    return Users(
      usrId:
          map['usrId'] != null ? int.tryParse(map['usrId'].toString()) : null,
      usrName: map['usrName'] ?? '',
      usrPassword: map['usrPassword'] ?? '',
      id_role: int.tryParse(map['id_role'].toString()) ?? 0,
      isVerified: int.tryParse(map['isVerified'].toString()) ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'usrId': usrId,
      'usrName': usrName,
      'usrPassword': usrPassword,
      'id_role': id_role,
      'isVerified': isVerified,
    };
  }
}
