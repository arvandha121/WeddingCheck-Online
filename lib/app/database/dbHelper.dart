import 'dart:convert';

import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/material.dart';
import 'package:weddingcheck/app/model/listItem.dart';
import 'package:weddingcheck/app/model/parentListItem.dart';
import 'package:weddingcheck/app/model/users.dart';
import 'package:http/http.dart' as http;

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  final String baseUrl = 'https://fluttermysql.arvandhaa.my.id/sqlitemysqlsync';
  // final String baseUrl = "http://localhost/sqlitemysqlsync";

  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await initDB();
    return _db!;
  }

  Future<Database> initDB() async {
    var databasesPath = await getDatabasesPath();
    String path = join(databasesPath, 'weddingcheck.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    // Create role table
    await db.execute('''
      CREATE TABLE role (
        id_role INTEGER PRIMARY KEY AUTOINCREMENT,
        nama_role TEXT UNIQUE
      );
    ''');

    // Insert default roles
    await db.insert('role', {'nama_role': 'admin'});
    await db.insert('role', {'nama_role': 'pegawai'});

    // Create users table users auth
    await db.execute('''
      CREATE TABLE users (
        usrId INTEGER PRIMARY KEY AUTOINCREMENT,
        usrName TEXT UNIQUE,
        usrPassword TEXT,
        id_role INTEGER,
        isVerified INTEGER DEFAULT 0,
        FOREIGN KEY (id_role) REFERENCES role(id_role)
      );
    ''');

    // Insert default admin user
    await db.insert('users', {
      'usrName': 'admin',
      'usrPassword': 'password',
      'id_role': 1,
      'isVerified': 1,
    });

    // Create management table
    await db.execute('''
      CREATE TABLE management (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        id_users INTEGER,
        FOREIGN KEY (id_users) REFERENCES users(usrId)
      );
    ''');

    // Create list table children list (tamu)
    await db.execute('''
      CREATE TABLE list (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        parentId INTEGER,
        nama TEXT NOT NULL,
        alamat TEXT NOT NULL,
        kota TEXT NOT NULL,
        kecamatan TEXT NOT NULL,
        keluarga TEXT,
        nohp TEXT,
        gambar TEXT NOT NULL,
        keterangan TEXT NOT NULL DEFAULT 'belum hadir' CHECK(keterangan IN ('hadir', 'belum hadir')),
        FOREIGN KEY (parentId) REFERENCES parentlist(id)
      );
    ''');

    // Create list table parent list
    await db.execute('''
      CREATE TABLE parentlist (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        id_created INTEGER,
        title TEXT NOT NULL,
        namapria TEXT NOT NULL,
        namawanita TEXT NOT NULL,
        tanggal TEXT NOT NULL,
        akad TEXT NOT NULL,
        resepsi TEXT NOT NULL,
        lokasi TEXT NOT NULL,
        tanggalResepsi TEXT,
        FOREIGN KEY (id_created) REFERENCES users(usrId)
      );
    ''');
  }

  // User-related operations

  // Future<Users?> login(Users user) async {
  //   final db = await database;
  //   var result = await db.rawQuery(
  //     "SELECT * FROM users WHERE usrName = ? AND usrPassword = ?",
  //     [user.usrName, user.usrPassword],
  //   );

  //   if (result.isNotEmpty) {
  //     return Users.fromMap(result.first);
  //   } else {
  //     return null;
  //   }
  // }

  // Register
  // Future<int> register(Users user) async {
  //   final db = await database;
  //   return db.insert('users', user.toMap());
  // }

  Future<Users?> getUsers(String usrName) async {
    final db = await database;
    var res =
        await db.query("users", where: "usrName = ?", whereArgs: [usrName]);
    return res.isNotEmpty ? Users.fromMap(res.first) : null;
  }

  Future<int> updateUserVerification(int id, int isVerified) async {
    final db = await database;
    return db.update(
      'users',
      {'isVerified': isVerified},
      where: 'usrId = ?',
      whereArgs: [id],
    );
  }

  Future<List<Users>> getAllUsers() async {
    final db = await database;
    var result = await db.query('users');
    return result.map((map) => Users.fromMap(map)).toList();
  }

  Future<Map<String, dynamic>?> getRoleById(int id_role) async {
    final db = await database;
    var result = await db.query(
      'role',
      where: 'id_role = ?',
      whereArgs: [id_role],
    );
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  Future<Map<String, dynamic>?> getRoleByName(String roleName) async {
    final db = await database;
    var result = await db.query(
      'role',
      where: 'nama_role = ?',
      whereArgs: [roleName],
    );
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  Future<int> updateUser(Users user) async {
    final db = await database;
    return db.update(
      'users',
      user.toMap(),
      where: 'usrId = ?',
      whereArgs: [user.usrId],
    );
  }

  Future<int> deleteUser(int id) async {
    final db = await database;
    return db.delete(
      'users',
      where: 'usrId = ?',
      whereArgs: [id],
    );
  }

  // Management-related operations
  Future<int> insertManagement(int id_users) async {
    final db = await database;
    return db.insert('management', {'id_users': id_users});
  }

  Future<List<Map<String, dynamic>>> getAllManagement() async {
    final db = await database;
    final result = await db.query('management');
    print('Management Data: $result'); // Tambahkan log ini
    return result;
  }

  Future<int> deleteManagement(int id) async {
    final db = await database;
    return db.delete(
      'management',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> copyUsersToManagement() async {
    final db = await database;
    // Ambil semua data dari tabel users
    final users = await db.query('users');
    // Hapus semua data yang ada di tabel management
    await db.delete('management');
    // Masukkan semua data dari tabel users ke tabel management
    for (var user in users) {
      await db.insert('management', {'id_users': user['usrId']});
    }
  }

  Future<Users?> getUsersById(int usrId) async {
    final db = await database;
    var res = await db.query("users", where: "usrId = ?", whereArgs: [usrId]);
    return res.isNotEmpty ? Users.fromMap(res.first) : null;
  }

  // List-related operations
  Future<int> insertListItem(ListItem listItem) async {
    final db = await database;
    return db.insert('list', listItem.toMap());
  }

  // List-related operations
  Future<List<ListItem>> readListItem({String query = ''}) async {
    final db = await database;
    List<Map<String, dynamic>> maps;
    if (query.isEmpty) {
      maps = await db.query('list');
    } else {
      maps = await db.query(
        'list',
        where:
            'nama LIKE ? OR kota LIKE ? OR keluarga LIKE ? OR keterangan LIKE ?',
        whereArgs: ['%$query%', '%$query%', '%$query%', '%$query%'],
      );
    }
    return List.generate(maps.length, (i) {
      return ListItem.fromMap(maps[i]);
    });
  }

  Future<int> updateListItem(ListItem listItem) async {
    final db = await database;
    return db.update(
      'list',
      listItem.toMap(),
      where: 'id = ?',
      whereArgs: [listItem.id],
    );
  }

  Future<int> deleteListItem(int id) async {
    final db = await database;

    // Delete the specified item
    int result = await db.delete(
      'list',
      where: 'id = ?',
      whereArgs: [id],
    );

    // Reorder the remaining items
    await _reorderListItems();

    return result;
  }

  Future<void> _reorderListItems() async {
    final db = await database;

    // Fetch all remaining items ordered by their current id
    List<Map<String, dynamic>> items = await db.query(
      'list',
      orderBy: 'id ASC',
    );

    // Start a transaction to ensure atomicity
    await db.transaction((txn) async {
      // Reset the auto-increment counter
      await txn.execute('DELETE FROM sqlite_sequence WHERE name="list"');

      // Update the id of each item to be sequential starting from 1
      for (int i = 0; i < items.length; i++) {
        await txn.update(
          'list',
          {'id': i + 1},
          where: 'id = ?',
          whereArgs: [items[i]['id']],
        );
      }
    });
  }

  Future<int> updateKeteranganHadir(int id) async {
    final db = await database;
    return await db.update(
      'list',
      {'keterangan': 'hadir'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearAllListItems() async {
    final db = await database;

    // Delete all items from the list table
    await db.delete('list');

    // Reset the auto-increment counter
    await db.execute('DELETE FROM sqlite_sequence WHERE name="list"');
  }

  Future<void> deleteListItemsByParentId(int parentId) async {
    final db = await database;
    await db.delete(
      'list',
      where: 'parentId = ?',
      whereArgs: [parentId],
    );
  }

  Future<ListItem?> getListItemByGambar(String gambar) async {
    var db = await database;
    var result =
        await db.query('list', where: 'gambar = ?', whereArgs: [gambar]);
    if (result.isNotEmpty) {
      return ListItem.fromMap(result.first);
    }
    return null;
  }

  Future<ListItem?> fetchDetail(int id) async {
    final db = await database;
    var res = await db.query('list', where: 'id = ?', whereArgs: [id]);
    if (res.isNotEmpty) {
      return ListItem.fromMap(res.first);
    }
    return null;
  }

  Future<int?> getCurrentUserId() async {
    final db = await database;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? currentUserName =
        prefs.getString('currentUserName'); // Replace with actual key

    if (currentUserName == null) {
      print("Current user name is null");
      return null;
    }

    print("Current user name: $currentUserName");

    var result = await db.query(
      'users',
      where: 'usrName = ?',
      whereArgs: [currentUserName],
    );

    if (result.isNotEmpty) {
      print("User ID found: ${result.first['usrId']}");
      return result.first['usrId'] as int?;
    } else {
      print("No user found with username: $currentUserName");
      return null;
    }
  }

  Future<int> insertParentListItem(ParentListItem parentListItem) async {
    final db = await database;
    return db.insert('parentlist', parentListItem.toMap());
  }

  Future<List<ParentListItem>> getParent() async {
    final db = await _instance.database;
    final result = await db.query('parentlist');
    return result.map((json) => ParentListItem.fromMap(json)).toList();
  }

  Future<List<ListItem>> getChildren(int parentId, {String query = ''}) async {
    final db = await database;
    List<Map<String, dynamic>> maps;
    if (query.isEmpty) {
      maps = await db.query(
        'list',
        where: 'parentId = ?',
        whereArgs: [parentId],
      );
    } else {
      maps = await db.query(
        'list',
        where:
            'parentId = ? AND (nama LIKE ? OR kota LIKE ? OR keluarga LIKE ? OR (keterangan LIKE ? AND keterangan NOT LIKE ?))',
        whereArgs: [
          parentId,
          '%$query%',
          '%$query%',
          '%$query%',
          '%$query%',
          '%belum $query%'
        ],
      );
    }

    return List.generate(maps.length, (i) {
      return ListItem.fromMap(maps[i]);
    });
  }

  Future<ParentListItem?> getParentItem(int id) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'parentlist',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isNotEmpty) {
      return ParentListItem.fromMap(result.first);
    }
    return null;
  }

  Future<void> close() async {
    final db = await _instance.database;
    db.close();
  }

  Future<void> updateParentListItem(ParentListItem item) async {
    final db = await database;
    await db.update(
      'parentlist',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> deleteParentListItem(int? id) async {
    final db = await database;

    // Start a transaction to ensure atomicity
    await db.transaction((txn) async {
      // Delete associated list items
      await txn.delete(
        'list',
        where: 'parentId = ?',
        whereArgs: [id],
      );

      // Delete the specified parent item
      await txn.delete(
        'parentlist',
        where: 'id = ?',
        whereArgs: [id],
      );

      // Reorder the remaining parent items
      await _reorderParentListItems(txn);
    });
  }

  Future<void> _reorderParentListItems(Transaction txn) async {
    // Fetch all remaining items ordered by their current id
    List<Map<String, dynamic>> items = await txn.query(
      'parentlist',
      orderBy: 'id ASC',
    );

    // Reset the auto-increment counter
    await txn.execute('DELETE FROM sqlite_sequence WHERE name="parentlist"');

    // Update the id of each item to be sequential starting from 1
    for (int i = 0; i < items.length; i++) {
      await txn.update(
        'parentlist',
        {'id': i + 1},
        where: 'id = ?',
        whereArgs: [items[i]['id']],
      );
    }
  }

  Future<Map<String, dynamic>> getInvitationData(int parentId) async {
    final db = await database;

    // Get parent data
    var parentResult = await db.query(
      'parentlist',
      where: 'id = ?',
      whereArgs: [parentId],
    );
    ParentListItem? parentItem;
    if (parentResult.isNotEmpty) {
      parentItem = ParentListItem.fromMap(parentResult.first);
    }

    // Get children data
    var childrenResult = await db.query(
      'list',
      where: 'parentId = ?',
      whereArgs: [parentId],
    );
    List<ListItem> childrenItems =
        childrenResult.map((map) => ListItem.fromMap(map)).toList();

    return {
      'parent': parentItem,
      'children': childrenItems,
    };
  }

  Future<ListItem?> getListItem(int id) async {
    final db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'list', // Assuming 'list' is the table name where ListItems are stored
      where: 'id = ?',
      whereArgs: [id],
    );
    if (results.isNotEmpty) {
      return ListItem.fromMap(results.first);
    }
    return null;
  }

  // Import data from CSV / Excel to database
  Future<void> insertListItems(List<ListItem> listItems) async {
    final db = await database;
    Batch batch = db.batch();
    for (var listItem in listItems) {
      batch.insert('list', listItem.toMap());
    }
    await batch.commit(noResult: true);
  }

  Future<List<ListItem>> getAllDownloadListItems(int parentId) async {
    final db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'list',
      where: 'parentId = ?',
      whereArgs: [parentId],
    );
    return List.generate(maps.length, (i) {
      return ListItem.fromMap(maps[i]);
    });
  }
}
