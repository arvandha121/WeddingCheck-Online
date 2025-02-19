import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:weddingcheck/app/database/dbHelper.dart';
import 'package:weddingcheck/app/model/listItem.dart';

class Edits extends StatefulWidget {
  final ListItem item;
  final VoidCallback onEditSuccess; // Callback to be called on successful edit

  const Edits({Key? key, required this.item, required this.onEditSuccess})
      : super(key: key);

  @override
  _EditsState createState() => _EditsState();
}

class _EditsState extends State<Edits> {
  late TextEditingController nameController;
  late TextEditingController alamatController;
  late TextEditingController kotaController;
  late TextEditingController kecamatanController;
  late TextEditingController keluargaController;
  late TextEditingController nohpController;
  late TextEditingController gambarController;
  late TextEditingController keteranganController;

  String? currentStatus;
  final formKey = GlobalKey<FormState>();
  final DatabaseHelper dbHelper = DatabaseHelper();
  List<String> statusOptions = ['belum hadir', 'hadir'];

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.item.nama);
    alamatController = TextEditingController(text: widget.item.alamat);
    kotaController = TextEditingController(text: widget.item.kota);
    kecamatanController = TextEditingController(text: widget.item.kecamatan);
    keluargaController = TextEditingController(text: widget.item.keluarga);
    nohpController = TextEditingController(text: widget.item.nohp);
    gambarController = TextEditingController(text: widget.item.gambar);
    keteranganController = TextEditingController(text: widget.item.keterangan);
    currentStatus = widget.item.keterangan;
  }

  void updateListItem() async {
    if (keluargaController.text.isEmpty || nohpController.text.isEmpty) {
      keluargaController.text = "-";
      nohpController.text = "-";
    }
    if (formKey.currentState!.validate()) {
      ListItem updatedItem = ListItem(
        id: widget.item.id,
        parentId: widget.item.parentId,
        nama: nameController.text,
        alamat: alamatController.text,
        kota: kotaController.text,
        kecamatan: kecamatanController.text,
        keluarga: keluargaController.text,
        nohp: nohpController.text,
        gambar: gambarController.text,
        keterangan: currentStatus ?? widget.item.keterangan,
      );

      await dbHelper.updateListItem(updatedItem);

      // Display a Snackbar with a success message
      Get.snackbar(
        "Success", // title
        "Item updated successfully", // message
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        borderRadius: 20,
        margin: EdgeInsets.all(10),
        snackStyle: SnackStyle.FLOATING,
        duration: Duration(seconds: 3), // Duration the Snackbar is visible
      );

      // Optionally, you can call the callback to inform any parent widgets of the update
      widget.onEditSuccess();

      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Item',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple,
        iconTheme: IconThemeData(
          color: Colors.white, // Set the back arrow color to white
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Form(
          key: formKey,
          child: ListView(
            children: <Widget>[
              SizedBox(height: 8),
              _buildTextField(
                controller: nameController,
                labelText: "Nama",
                icon: Icons.person,
                validator: (value) =>
                    value!.isEmpty ? "Nama tidak boleh kosong" : null,
              ),
              SizedBox(height: 20),
              _buildTextField(
                controller: keluargaController,
                labelText: "Keluarga",
                icon: Icons.group,
                validator: (value) =>
                    value!.isEmpty ? "Keluarga tidak boleh kosong" : null,
              ),
              SizedBox(height: 20),
              _buildTextField(
                controller: alamatController,
                labelText: "Alamat",
                icon: Icons.location_city,
                validator: (value) =>
                    value!.isEmpty ? "Alamat tidak boleh kosong" : null,
              ),
              SizedBox(height: 20),
              _buildTextField(
                controller: kotaController,
                labelText: "Kota",
                icon: Icons.location_on,
                validator: (value) =>
                    value!.isEmpty ? "Kota tidak boleh kosong" : null,
              ),
              SizedBox(height: 20),
              _buildTextField(
                controller: kecamatanController,
                labelText: "Kecamatan",
                icon: Icons.map,
                validator: (value) =>
                    value!.isEmpty ? "Kecamatan tidak boleh kosong" : null,
              ),
              SizedBox(height: 20),
              _buildTextField(
                controller: nohpController,
                labelText: "Nomor HP (boleh kosong)",
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                onChanged: (value) {
                  if (!value.startsWith("+62")) {
                    nohpController.text = "+62";
                    nohpController.selection = TextSelection.fromPosition(
                      TextPosition(offset: nohpController.text.length),
                    );
                  }
                },
              ),
              Visibility(
                visible: false, // Set to false to hide the TextFormField
                child: TextFormField(
                  controller: gambarController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: "Tanggal",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? "Tanggal tidak boleh kosong" : null,
                ),
              ),
              SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: currentStatus,
                decoration: InputDecoration(
                  labelText: 'Keterangan',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  prefixIcon: Icon(Icons.info),
                ),
                items: statusOptions.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    currentStatus = newValue;
                  });
                },
                validator: (value) =>
                    value == null ? 'Please select a status' : null,
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: updateListItem,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                  textStyle:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                child: Text(
                  "Update",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        prefixIcon: Icon(icon),
        filled: true,
      ),
      validator: validator ?? (value) => null,
      onChanged: onChanged,
      keyboardType: keyboardType,
    );
  }
}
