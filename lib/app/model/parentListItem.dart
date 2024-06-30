class ParentListItem {
  int? id;
  int id_created;
  String title;
  String namapria;
  String namawanita;
  String tanggal;
  String akad;
  String resepsi;
  String lokasi;
  String? tanggalResepsi;

  ParentListItem({
    this.id,
    required this.id_created,
    required this.title,
    required this.namapria,
    required this.namawanita,
    required this.tanggal,
    required this.akad,
    required this.resepsi,
    required this.lokasi,
    this.tanggalResepsi,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'id_created': id_created,
      'title': title,
      'namapria': namapria,
      'namawanita': namawanita,
      'tanggal': tanggal,
      'akad': akad,
      'resepsi': resepsi,
      'lokasi': lokasi,
      'tanggalResepsi': tanggalResepsi,
    };
  }

  factory ParentListItem.fromMap(Map<String, dynamic> map) {
    return ParentListItem(
      id: map['id'],
      id_created: map['id_created'],
      title: map['title'],
      namapria: map['namapria'],
      namawanita: map['namawanita'],
      tanggal: map['tanggal'],
      akad: map['akad'],
      resepsi: map['resepsi'],
      lokasi: map['lokasi'],
      tanggalResepsi: map['tanggalResepsi'],
    );
  }
}
