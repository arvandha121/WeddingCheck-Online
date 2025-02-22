import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:weddingcheck/app/database/dbHelper.dart';
import 'package:weddingcheck/app/model/parentListItem.dart';
import 'package:weddingcheck/app/provider/provider.dart';
import 'package:weddingcheck/views/splashscreen.dart';

class Settings extends StatefulWidget {
  final String role;

  Settings({required this.role});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  ParentListItem? _selectedParentItem;
  List<ParentListItem> _parentItems = [];

  @override
  void initState() {
    super.initState();
    _loadParentItems();
  }

  Future<void> _loadParentItems() async {
    final parentItems = await DatabaseHelper().getParent();
    setState(() {
      _parentItems = parentItems;
    });
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Consumer<UiProvider>(
            builder: (context, UiProvider notifier, child) {
          return AlertDialog(
            title: const Text('Konfirmasi Logout'),
            content:
                const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () {
                  Provider.of<UiProvider>(context, listen: false)
                      .logout(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const Splash(),
                    ),
                  );
                },
                child: const Text(
                  'Logout',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          );
        });
      },
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, Color textColor) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  SizedBox(width: 8),
                  Text('Pilih List Berkas'),
                ],
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ..._parentItems.map((parentItem) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: RadioListTile<ParentListItem>(
                              title: Text(
                                parentItem.title,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              value: parentItem,
                              groupValue: _selectedParentItem,
                              onChanged: (ParentListItem? value) {
                                setState(() {
                                  _selectedParentItem = value;
                                });
                              },
                              activeColor: Colors.deepPurple,
                            ),
                          ),
                        );
                      }).toList(),
                      if (_parentItems.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Tidak ada Parent List yang tersedia.',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Batal'),
                ),
                TextButton(
                  onPressed: () {
                    if (_selectedParentItem != null) {
                      Navigator.of(context).pop();
                      _showFinalDeleteConfirmationDialog(context, textColor);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Pilih list berkas terlebih dahulu.'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  child: const Text(
                    'Lanjutkan',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showFinalDeleteConfirmationDialog(
      BuildContext context, Color textColor) {
    TextEditingController _textEditingController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  SizedBox(width: 3),
                  Text('Konfirmasi'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      text: 'Ketik "',
                      style: TextStyle(color: textColor, fontSize: 16),
                      children: [
                        TextSpan(
                          text: 'hapus semua',
                          style: TextStyle(color: Colors.red),
                        ),
                        TextSpan(
                          text: '" untuk konfirmasi:',
                          style: TextStyle(color: textColor),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _textEditingController,
                    decoration: InputDecoration(
                      hintText: 'Masukkan kode konfirmasi',
                      hintStyle: TextStyle(color: textColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Color.fromARGB(124, 245, 245, 245),
                      contentPadding: EdgeInsets.all(10),
                    ),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Batal'),
                ),
                TextButton(
                  onPressed: () {
                    if (_textEditingController.text.toLowerCase() ==
                        'hapus semua') {
                      Navigator.of(context).pop();
                      DatabaseHelper()
                          .deleteListItemsByParentId(_selectedParentItem!.id!);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Semua item dalam parent list "${_selectedParentItem!.title}" telah dihapus.'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Kata kunci salah, masukkan "hapus semua" untuk mengkonfirmasi.'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  child: const Text(
                    'Hapus',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<bool> _onWillPop() async {
    return (await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Konfirmasi'),
            content: Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Tidak'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  'Iya',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        )) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    Color textColor = isDarkMode ? Colors.white : Colors.black;
    Color disabledColor = Colors.grey; // Color for disabled state

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: ListView(
          children: [
            SwitchListTile(
              title: Text('Dark Mode'),
              value: Provider.of<UiProvider>(context).darkMode,
              onChanged: (bool value) {
                Provider.of<UiProvider>(context, listen: false)
                    .toggleDarkMode();
              },
            ),
            ListTile(
              leading: Icon(
                Icons.delete_forever,
                color:
                    widget.role == 'pegawai' ? disabledColor : Colors.redAccent,
                size: 40,
              ),
              title: Text(
                'Hapus List',
                style: TextStyle(
                  color: widget.role == 'pegawai' ? disabledColor : textColor,
                ),
              ),
              subtitle: Text(
                'Menghapus semua list tamu yang dipilih',
                style: TextStyle(
                  color: widget.role == 'pegawai' ? disabledColor : textColor,
                ),
              ),
              onTap: widget.role == 'pegawai'
                  ? null
                  : () => _showDeleteConfirmationDialog(context, textColor),
              tileColor: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            SizedBox(height: 8), // Replaced Divider with SizedBox
            ListTile(
              leading: Icon(
                Icons.exit_to_app,
                color: Colors.redAccent,
                size: 40,
              ),
              title: Text('Logout'),
              subtitle: Text('Keluar dari akun Anda'),
              onTap: _confirmLogout,
              tileColor: Theme.of(context).cardColor, // Adjusted for theme
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
