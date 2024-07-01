import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:weddingcheck/app/model/users.dart';
import 'package:weddingcheck/app/provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

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
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse(
          'https://fluttermysql.arvandhaa.my.id/sqlitemysqlsync/get_management.php'));
      if (response.statusCode == 200) {
        final cleanedResponseBody = _cleanResponseBody(response.body);
        print('Cleaned Response Body: $cleanedResponseBody');
        final data = json.decode(cleanedResponseBody);
        if (mounted) {
          setState(() {
            _users = (data['users'] as List)
                .map((json) => Users.fromMap(json))
                .toList();
            _isLoading = false;
          });
          print('Fetched Users: $_users');
        }
      } else {
        throw Exception('Failed to load users');
      }
    } catch (e) {
      print('Error fetching users: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _cleanResponseBody(String responseBody) {
    final jsonStartIndex = responseBody.indexOf('{');
    if (jsonStartIndex != -1) {
      return responseBody.substring(jsonStartIndex);
    }
    return responseBody;
  }

  Future<void> _addUserToManagement(int usrId) async {
    try {
      final response = await http.post(
        Uri.parse(
            'https://fluttermysql.arvandhaa.my.id/sqlitemysqlsync/add_management.php'),
        body: {
          'id_users': usrId.toString(),
        },
      );

      if (response.statusCode == 200) {
        final cleanedResponseBody = _cleanResponseBody(response.body);
        final data = json.decode(cleanedResponseBody);
        if (data['success']) {
          _fetchUsers();
        } else {
          throw Exception(data['message']);
        }
      } else {
        throw Exception('Failed to add user to management');
      }
    } catch (e) {
      print('Error adding user to management: $e');
    }
  }

  Future<void> _updateUser(Users user) async {
    try {
      print(
          'Updating user: ${user.toMap()}'); // Log data user yang akan diupdate
      final response = await http.post(
        Uri.parse(
            'https://fluttermysql.arvandhaa.my.id/sqlitemysqlsync/update_management.php'),
        body: {
          'id': user.usrId.toString(),
          'id_users': user.usrId.toString(),
          'usrName': user.usrName,
          'usrPassword': user.usrPassword,
          'id_role': user.id_role.toString(),
          'isVerified': user.isVerified.toString(),
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final cleanedResponseBody = _cleanResponseBody(response.body);
        final data = json.decode(cleanedResponseBody);
        if (data['success']) {
          setState(() {
            _fetchUsers();
          });
        } else {
          throw Exception(data['message']);
        }
      } else {
        throw Exception('Failed to update user');
      }
    } catch (e) {
      print('Error updating user: $e');
    }
  }

  Future<void> _deleteUser(int id) async {
    try {
      final response = await http.post(
        Uri.parse(
            'https://fluttermysql.arvandhaa.my.id/sqlitemysqlsync/delete_management.php'),
        body: {
          'id': id.toString(),
        },
      );

      if (response.statusCode == 200) {
        final cleanedResponseBody = _cleanResponseBody(response.body);
        final data = json.decode(cleanedResponseBody);
        if (data['success']) {
          setState(() {
            _fetchUsers();
          });
        } else {
          throw Exception(data['message']);
        }
      } else {
        throw Exception('Failed to delete user');
      }
    } catch (e) {
      print('Error deleting user: $e');
    }
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

                print(
                    'New user data: ${newUser.toMap()}'); // Log data user baru

                if (isEditing) {
                  await _updateUser(newUser);
                } else {
                  final addedUser = await _addUser(newUser);
                  if (addedUser != null) {
                    await _addUserToManagement(addedUser.usrId!);
                  }
                }

                Navigator.of(context).pop();
              },
              child: Text(isEditing ? 'Update' : 'Add'),
            ),
          ],
        );
      },
    );
  }

  Future<Users?> _addUser(Users user) async {
    try {
      final response = await http.post(
        Uri.parse(
            'https://fluttermysql.arvandhaa.my.id/sqlitemysqlsync/add_user.php'),
        body: {
          'usrName': user.usrName,
          'usrPassword': user.usrPassword,
          'id_role': user.id_role.toString(),
          'isVerified': user.isVerified.toString(),
        },
      );

      if (response.statusCode == 200) {
        final cleanedResponseBody = _cleanResponseBody(response.body);
        final data = json.decode(cleanedResponseBody);
        if (data['success']) {
          return Users.fromMap(data['user']);
        } else {
          throw Exception(data['message']);
        }
      } else {
        throw Exception('Failed to add user');
      }
    } catch (e) {
      print('Error adding user: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = Provider.of<UiProvider>(context).role;

    print('User Role: $role');

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
          : RefreshIndicator(
              onRefresh: _fetchUsers,
              child: ListView.builder(
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
                    subtitle: FutureBuilder<Map<String, dynamic>?>(
                      // FutureBuilder untuk mendapatkan nama peran
                      future: _getRoleById(user.id_role),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Text('Loading...');
                        } else if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        } else if (snapshot.hasData) {
                          return Text('Role: ${snapshot.data!['nama_role']}');
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
                            onPressed: () => _showUserDialog(user: user),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteUser(user.usrId!),
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
                            onPressed: () async {
                              setState(() {
                                user.isVerified = user.isVerified == 1 ? 0 : 1;
                              });
                              await _updateUser(user);
                            },
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }

  Future<Map<String, dynamic>?> _getRoleById(int id_role) async {
    try {
      final response = await http.get(Uri.parse(
          'https://fluttermysql.arvandhaa.my.id/sqlitemysqlsync/get_role_by_id.php?id_role=$id_role'));
      if (response.statusCode == 200) {
        final cleanedResponseBody = _cleanResponseBody(response.body);
        final data = json.decode(cleanedResponseBody);
        if (data['success']) {
          return data['role'];
        } else {
          throw Exception(data['message']);
        }
      } else {
        throw Exception('Failed to load role');
      }
    } catch (e) {
      print('Error fetching role: $e');
      return null;
    }
  }
}
