import 'package:flutter/material.dart';
import 'package:weddingcheck/app/model/parentListItem.dart';
import 'package:weddingcheck/views/other/menu/screens/homes-child/create-form/create.dart';
import 'package:weddingcheck/app/database/dbHelper.dart';
import 'package:weddingcheck/app/model/listItem.dart';
import 'package:weddingcheck/views/other/menu/screens/homes-child/detail-form/detail.dart';
import 'package:weddingcheck/views/other/menu/screens/homes-child/edit-form/edit.dart';
import 'package:weddingcheck/views/other/menu/screens/homes-parent/undangan/invite.dart';
import '../homes-parent/undangan/inviteall.dart';
import 'export-data/exportListItemsToExcel.dart';
import 'import-data/import-excel.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class HomesChild extends StatefulWidget {
  final int parentId;
  final String role;

  HomesChild({required this.parentId, required this.role});

  @override
  State<HomesChild> createState() => _HomesChildState();
}

class _HomesChildState extends State<HomesChild> {
  late Future<List<ListItem>> childItems;
  TextEditingController _searchController = TextEditingController();
  List<ListItem> _items = [];
  int hadirCount = 0;
  int belumHadirCount = 0;
  ParentListItem? _parentData;

  final DatabaseHelper list = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _loadParentData();
    _loadItems();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadParentData() async {
    try {
      var parentData = await list.getParentItem(widget.parentId);
      setState(() {
        _parentData = parentData;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading parent data: $e')),
      );
    }
  }

  void _loadItems() async {
    try {
      var items = await list.getChildren(widget.parentId,
          query: _searchController.text);
      int hadir = items.where((item) => item.keterangan == 'hadir').length;
      int belumHadir =
          items.where((item) => item.keterangan == 'belum hadir').length;
      setState(() {
        _items = items;
        hadirCount = hadir;
        belumHadirCount = belumHadir;
      });
    } catch (e) {
      print('Error loading items: $e');
    }
  }

  void _onSearchChanged() {
    _loadItems();
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    Color textColor = isDarkMode ? Colors.white : Colors.black;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "List Tamu",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple,
        iconTheme: IconThemeData(
          color: Colors.white, // Set the back arrow color to white
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert),
            tooltip: "Lainnya",
            onSelected: (String result) {
              switch (result) {
                case 'import_excel':
                  importFromExcel(context, widget.parentId, _loadItems);
                  break;
                case 'export_excel':
                  exportListItemsToExcel(context, _items);
                  break;
                case 'download_all':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          AllInvitationsPage(parentId: widget.parentId),
                    ),
                  );
                  break;
              }
            },
            itemBuilder: (BuildContext context) {
              bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
              Color iconColor = isDarkMode ? Colors.white : Colors.deepPurple;
              Color textColor = isDarkMode ? Colors.white : Colors.black;

              List<PopupMenuEntry<String>> menuItems = [];

              if (widget.role == 'admin') {
                menuItems.addAll([
                  PopupMenuItem<String>(
                    value: 'import_excel',
                    child: Row(
                      children: [
                        FaIcon(FontAwesomeIcons.fileImport,
                            color: iconColor, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Import from Excel',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: textColor),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'export_excel',
                    child: Row(
                      children: [
                        FaIcon(FontAwesomeIcons.fileExport,
                            color: iconColor, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Export to Excel',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: textColor),
                        ),
                      ],
                    ),
                  ),
                ]);
              }

              menuItems.add(
                PopupMenuItem<String>(
                  value: 'download_all',
                  child: Row(
                    children: [
                      FaIcon(FontAwesomeIcons.download,
                          color: iconColor, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Download Semua List Tamu',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: textColor),
                      ),
                    ],
                  ),
                ),
              );

              return menuItems;
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            color: Theme.of(context).cardColor, // Adjusted for theme
            elevation: 5,
          )
        ],
      ),
      body: Column(
        children: [
          if (_parentData != null) _buildParentInfo(),
          _buildSearchBar(),
          _buildItemList(textColor),
        ],
      ),
    );
  }

  Widget _buildParentInfo() {
    return Card(
      margin: EdgeInsets.all(12),
      color: Colors.purple[100],
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${_parentData!.namapria} & ${_parentData!.namawanita}",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              "${_parentData!.tanggal}",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _buildStatusChip("Hadir", hadirCount, Colors.green),
                SizedBox(width: 8),
                _buildStatusChip("Belum Hadir", belumHadirCount, Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, int count, Color color) {
    return Chip(
      label: Text(
        "$label: $count",
        style: TextStyle(color: Colors.white),
      ),
      backgroundColor: color,
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari...',
                prefixIcon: Icon(Icons.search, color: Colors.deepPurple),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          SizedBox(width: 8),
          ElevatedButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Create(parentId: widget.parentId),
                ),
              );
              if (result == true) {
                _loadItems();
              }
            },
            child: Icon(Icons.add, color: Colors.white),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.deepPurple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemList(Color textColor) {
    return Expanded(
      child: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: _items.isEmpty
            ? Center(
                child: Text(
                  "DATA KOSONG",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              )
            : Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: ListView.builder(
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Detail(item: item),
                          ),
                        );
                      },
                      child: Card(
                        elevation: 4,
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        child: ListTile(
                          title: Text(
                            item.nama,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            item.keterangan,
                            style: TextStyle(
                              color: item.keterangan == 'hadir'
                                  ? Colors.green
                                  : Colors.red,
                              fontSize: 14,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, color: Colors.amber),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => Edits(
                                        item: item,
                                        onEditSuccess: _loadItems,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  final shouldDelete = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text('Konfirmasi'),
                                      content: Text(
                                          'Apakah Anda yakin ingin menghapus item ini?'),
                                      actions: <Widget>[
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(false),
                                          child: Text('Tidak'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(true),
                                          child: Text(
                                            'Iya',
                                            style: TextStyle(
                                              color: Colors.red,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (shouldDelete == true) {
                                    await DatabaseHelper()
                                        .deleteListItem(item.id ?? 0);
                                    _loadItems(); // Refresh the list after deletion
                                  }
                                },
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.mobile_screen_share,
                                  color: Color.fromARGB(255, 0, 242, 255),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => InvitationPage(
                                        parentId: widget.parentId,
                                        guestId: item.id!,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }

  Future<void> _handleRefresh() async {
    // Call your method to reload data
    _loadItems();
  }
}
