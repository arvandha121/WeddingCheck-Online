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
  List<Users> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    final users = await DatabaseHelper().getAllUsers();
    setState(() {
      _users = users;
      _isLoading = false;
    });
  }

  void _addUser() {
    _showUserDialog();
  }

  void _editUser(Users user) {
    _showUserDialog(user: user);
  }

  void _deleteUser(int id) async {
    await DatabaseHelper().deleteUser(id);
    _fetchUsers();
  }

  void _verifyUser(int id, int isVerified) async {
    await DatabaseHelper().updateUserVerification(id, isVerified);
    _fetchUsers();
  }

  void _showDeleteConfirmationDialog(int userId) {
    final TextEditingController confirmationController =
        TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Confirm Deletion',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Type "hapus" to confirm deletion.'),
              SizedBox(height: 10),
              TextField(
                controller: confirmationController,
                decoration: InputDecoration(
                  labelText: 'Confirmation',
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
              onPressed: () {
                if (confirmationController.text == 'hapus') {
                  _deleteUser(userId);
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Incorrect confirmation text.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showUserDialog({Users? user}) {
    final isEditing = user != null;
    final usernameController =
        TextEditingController(text: isEditing ? user!.usrName : '');
    final passwordController =
        TextEditingController(text: isEditing ? user!.usrPassword : '');
    String role = isEditing ? user!.role : 'pegawai';
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
              DropdownButtonFormField<String>(
                value: role,
                items: [
                  DropdownMenuItem(
                    value: 'admin',
                    child: Text('Admin'),
                  ),
                  DropdownMenuItem(
                    value: 'pegawai',
                    child: Text('Pegawai'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    role = value!;
                    if (role == 'admin') {
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
                  role: role,
                  isVerified: isVerified ? 1 : 0,
                );

                if (isEditing) {
                  await DatabaseHelper().updateUser(newUser);
                } else {
                  await DatabaseHelper().register(newUser);
                }

                _fetchUsers();
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
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                return ListTile(
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  leading: CircleAvatar(
                    backgroundColor: Colors.blueAccent,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(user.usrName,
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Role: ${user.role}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (user.usrId != 1 && user.usrName != 'admin') ...[
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _editUser(user),
                        ),
                        SizedBox(width: 8),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () =>
                              _showDeleteConfirmationDialog(user.usrId!),
                        ),
                        SizedBox(width: 8),
                        if (user.role == 'pegawai')
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
                    ],
                  ),
                );
              },
            ),
    );
  }
}
