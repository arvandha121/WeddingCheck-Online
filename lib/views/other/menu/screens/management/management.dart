import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:weddingcheck/app/database/dbHelper.dart';
import 'package:weddingcheck/app/model/users.dart';
import 'package:weddingcheck/app/provider/provider.dart';

class Management extends StatefulWidget {
  const Management({super.key});

  @override
  State<Management> createState() => _ManagementState();
}

class _ManagementState extends State<Management> {
  List<Map<String, dynamic>> _management = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    // Salin data dari tabel users ke tabel management
    await DatabaseHelper().copyUsersToManagement();
    // Ambil data dari tabel management
    await _fetchManagement();
  }

  Future<void> _fetchManagement() async {
    final management = await DatabaseHelper().getAllManagement();
    print('Fetched Management Data: $management'); // Tambahkan log ini
    setState(() {
      _management = management;
      _isLoading = false;
    });
  }

  void _addManagement(int id_users) async {
    await DatabaseHelper().insertManagement(id_users);
    _fetchManagement();
  }

  void _deleteManagement(int id) async {
    if (id == 1) {
      // Tidak boleh menghapus admin dengan id = 1
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Admin dengan id 1 tidak bisa dihapus.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    await DatabaseHelper().deleteManagement(id);
    _fetchManagement();
  }

  void _verifyUser(int id, int isVerified) async {
    await DatabaseHelper().updateUserVerification(id, isVerified);
    _fetchManagement();
  }

  void _editUser(Users user) {
    _showUserDialog(user: user);
  }

  void _showUserDialog({Users? user}) {
    final isEditing = user != null;
    final usernameController =
        TextEditingController(text: isEditing ? user!.usrName : '');
    final passwordController =
        TextEditingController(text: isEditing ? user!.usrPassword : '');
    int id_role = isEditing ? user!.id_role : 2; // Default to 'pegawai'
    bool isVerified = isEditing ? user!.isVerified == 1 : false;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            isEditing ? 'Edit User' : 'Add User',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              SizedBox(height: 10),
              DropdownButtonFormField<int>(
                value: id_role,
                items: [
                  DropdownMenuItem(
                    value: 1, // Assuming 'admin' role has id_role = 1
                    child: Text('Admin'),
                  ),
                  DropdownMenuItem(
                    value: 2, // Assuming 'pegawai' role has id_role = 2
                    child: Text('Pegawai'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    id_role = value!;
                    if (id_role == 1) {
                      isVerified = true;
                    } else {
                      isVerified = false;
                    }
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final newUser = Users(
                  usrId: isEditing ? user!.usrId : null,
                  usrName: usernameController.text,
                  usrPassword: passwordController.text,
                  id_role: id_role,
                  isVerified: isVerified ? 1 : 0,
                );

                if (isEditing) {
                  await DatabaseHelper().updateUser(newUser);
                } else {
                  await DatabaseHelper().register(newUser);
                }

                _fetchManagement();
                Navigator.of(context).pop();
              },
              child: Text(isEditing ? 'Update' : 'Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = Provider.of<UiProvider>(context).role;

    if (role != 'admin') {
      return Scaffold(
        body: Center(
          child: Text('Access Denied'),
        ),
      );
    }

    return Scaffold(
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _management.length,
              itemBuilder: (context, index) {
                final management = _management[index];
                return FutureBuilder<Users?>(
                  future: DatabaseHelper().getUsersById(management['id_users']),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return ListTile(
                        title: Text('Loading...'),
                      );
                    } else if (snapshot.hasError) {
                      return ListTile(
                        title: Text('Error: ${snapshot.error}'),
                      );
                    } else if (snapshot.hasData) {
                      final user = snapshot.data!;
                      return ListTile(
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        leading: CircleAvatar(
                          backgroundColor: Colors.blueAccent,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text(user.usrName,
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: FutureBuilder<Map<String, dynamic>?>(
                          future: DatabaseHelper().getRoleById(user.id_role),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Text('Loading...');
                            } else if (snapshot.hasError) {
                              return Text('Error: ${snapshot.error}');
                            } else if (snapshot.hasData) {
                              return Text(
                                  'Role: ${snapshot.data!['nama_role']}');
                            } else {
                              return Text('Role: Unknown');
                            }
                          },
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (user.usrId != 1) ...[
                              IconButton(
                                icon: Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _editUser(user),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () =>
                                    _deleteManagement(management['id']),
                              ),
                            ],
                            if (user.id_role ==
                                2) // Assuming 'pegawai' role has id_role = 2
                              IconButton(
                                icon: Icon(
                                  user.isVerified == 1
                                      ? Icons.check_box
                                      : Icons.check_box_outline_blank,
                                  color: user.isVerified == 1
                                      ? Colors.green
                                      : Colors.grey,
                                ),
                                onPressed: () => _verifyUser(
                                    user.usrId!, user.isVerified == 1 ? 0 : 1),
                              ),
                          ],
                        ),
                      );
                    } else {
                      return ListTile(
                        title: Text('User not found'),
                      );
                    }
                  },
                );
              },
            ),
    );
  }
}
