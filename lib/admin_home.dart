import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:FoundIt_admin_panel/admin_login.dart'; 

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _selectedIndex = 4;

  final Color _bgDark = const Color.fromARGB(255, 49, 44, 43);
  final Color _cardDark = const Color.fromARGB(255, 49, 44, 43);
  final Color green = const Color(0xFFB5E575);
  final Color _textSecondary =  const Color(0xFFB5E575);
  final Color _borderColor = const Color(0xFFB5E575);


  Future<Map<String, int>> _getDashboardStats() async {
    final users = await FirebaseFirestore.instance.collection('Users').get();
    final pending = await FirebaseFirestore.instance
        .collection('listings')
        .where('status', isEqualTo: 'pending')
        .get();
    final active = await FirebaseFirestore.instance
        .collection('listings')
        .where('status', isEqualTo: 'active')
        .get();
    final cats = await FirebaseFirestore.instance
        .collection('categories')
        .get();

    return {
      'users': users.size,
      'pending': pending.size,
      'active': active.size,
      'categories': cats.size,
    };
  }

  Future<void> _updateListingStatus(String docId, String newStatus) async {
    try {
      await FirebaseFirestore.instance.collection('listings').doc(docId).update(
        {'status': newStatus},
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Item marked as $newStatus!')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _toggleUserSuspension(String uid, bool currentStatus) async {
    try {
      await FirebaseFirestore.instance.collection('Users').doc(uid).update({
        'isSuspended': !currentStatus,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(currentStatus ? 'User restored!' : 'User suspended!'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _deleteCategory(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('categories')
          .doc(docId)
          .delete();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Category deleted!')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting: $e')));
    }
  }

 
  void _showCategoryDialog({
    Map<String, dynamic>? existingCategory,
    String? docId,
  }) {
    final bool isEditing = existingCategory != null;

    final TextEditingController nameCtrl = TextEditingController(
      text: isEditing ? existingCategory['name'] : '',
    );
    final TextEditingController slugCtrl = TextEditingController(
      text: isEditing ? existingCategory['slug'] : '',
    );
    final TextEditingController descCtrl = TextEditingController(
      text: isEditing ? existingCategory['description'] : '',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: _cardDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: _borderColor),
          ),
          title: Text(
            isEditing ? 'Edit Category' : 'Add Category',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Category Name',
                    labelStyle: TextStyle(color: _textSecondary),
                    filled: true,
                    fillColor: _bgDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (val) {
                 
                    if (!isEditing) {
                      slugCtrl.text = val
                          .toLowerCase()
                          .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
                          .replaceAll(RegExp(r'-+$'), '');
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: slugCtrl,
                  style: const TextStyle(color: Colors.white54),
                  decoration: InputDecoration(
                    labelText: 'Slug (URL Friendly)',
                    labelStyle: TextStyle(color: _textSecondary),
                    filled: true,
                    fillColor: _bgDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Description (Optional)',
                    labelStyle: TextStyle(color: _textSecondary),
                    filled: true,
                    fillColor: _bgDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: green),
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty ||
                    slugCtrl.text.trim().isEmpty)
                  return;

                try {
                  final Map<String, dynamic> data = {
                    'name': nameCtrl.text.trim(),
                    'slug': slugCtrl.text.trim(),
                    'description': descCtrl.text.trim(),
                  };

                  if (isEditing) {
                    await FirebaseFirestore.instance
                        .collection('categories')
                        .doc(docId)
                        .update(data);
                  } else {
                    data['createdAt'] = FieldValue.serverTimestamp();
                    await FirebaseFirestore.instance
                        .collection('categories')
                        .add(data);
                  }

                  if (context.mounted)
                    Navigator.pop(context); 
                } catch (e) {
                 
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Firebase Error: $e',
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },

              child: Text(
                isEditing ? 'Save Changes' : 'Add Category',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      body: Row(
        children: [
          Container(
            width: 260,
            color: _bgDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                const Center(
                  child: Text(
                    'FoundIt',
                    style: TextStyle(
                      color: const Color(0xFFB5E575),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                _buildSidebarItem(Icons.dashboard_outlined, 'Dashboard', 0),
                _buildSidebarItem(Icons.people_outline, 'Clients', 1),
                _buildSidebarItem(Icons.list_alt, 'Products', 2),
                // _buildSidebarItem(Icons.sell_outlined, 'Brands', 3),
                _buildSidebarItem(Icons.category_outlined, 'Categories', 4),
                // _buildSidebarItem(Icons.school_outlined, 'Universities', 5),
                const SizedBox(height: 24),
                // _buildSidebarItem(Icons.settings_outlined, 'Settings', 6),
                // _buildSidebarItem(
                //   Icons.admin_panel_settings_outlined,
                //   'Admin Management',
                //   7,
                // ),
              ],
            ),
          ),

    
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(top: 16, right: 16, bottom: 16),
              decoration: BoxDecoration(
                color: _cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _borderColor),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  children: [
                 
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: _borderColor)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.menu_open, color: Colors.white54),
                          const SizedBox(width: 16),
                          const Text(
                            'Admin Dashboard',
                            style: TextStyle(color: Colors.white54),
                          ),
                          const Spacer(),
                          // const Icon(
                          //   Icons.dark_mode_outlined,
                          //   color: Colors.white54,
                          // ),
                          const SizedBox(width: 16),
                          GestureDetector(
                            onTap: () async {
                              await FirebaseAuth.instance.signOut();

                              if (context.mounted) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const AdminLoginScreen(),
                                  ),
                                );
                              }
                            },
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.logout,
                                  color: Colors.redAccent,
                                  size: 18,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Logout',
                                  style: TextStyle(color: Colors.redAccent),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                
                    Expanded(
                      child: IndexedStack(
                        index: _selectedIndex,
                        children: [
                          _buildDashboardTab(), 
                          _buildClientsTab(), 
                          _buildProductsTab(), 
                          const Center(
                            child: Text(
                              'Brands Coming Soon',
                              style: TextStyle(color:const Color(0xFFB5E575)),
                            ),
                          ), 
                          _buildCategoriesTab(), 
                          const Center(
                            child: Text(
                              'Universities Coming Soon',
                              style: TextStyle(color: const Color(0xFFB5E575)),
                            ),
                          ), 
                          const Center(
                            child: Text(
                              'Settings Coming Soon',
                              style: TextStyle(color:const Color(0xFFB5E575)),
                            ),
                          ), 
                          const Center(
                            child: Text(
                              'Admin Management Coming Soon',
                              style: TextStyle(color:const Color(0xFFB5E575)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildCategoriesTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Product Categories',
                    style: TextStyle(
                      color:  Color(0xFFB5E575),
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add, update, or remove categories available for listings.',
                    style: TextStyle(color: _textSecondary),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showCategoryDialog(), 
                icon: const Icon(Icons.add, color: const Color(0xFFB5E575)),
                label: const Text(
                  'Add Category',
                  style: TextStyle(
                    color: const Color(0xFFB5E575),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              border: Border.all(color: _borderColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: _borderColor)),
                  ),
                  child: Row(
                    children: [
                      Expanded(flex: 1, child: _headerText('Image')),
                      Expanded(flex: 3, child: _headerText('Name')),
                      Expanded(flex: 2, child: _headerText('Slug')),
                      Expanded(flex: 3, child: _headerText('Description')),
                      Expanded(flex: 2, child: _headerText('Created At')),
                      const SizedBox(width: 40),
                    ],
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('categories')
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting)
                        return const Center(child: CircularProgressIndicator());
                      if (snapshot.hasError)
                        return Center(
                          child: Text(
                            'Error: ${snapshot.error}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        );

                      final docs = snapshot.data?.docs ?? [];

                      if (docs.isEmpty) {
                        return const Center(
                          child: Text(
                            'No categories found. Click "Add Category" to create one.',
                            style: TextStyle(color: const Color(0xFFB5E575)),
                          ),
                        );
                      }

                      return ListView.separated(
                        itemCount: docs.length,
                        separatorBuilder: (context, index) =>
                            Divider(color: _borderColor, height: 1),
                        itemBuilder: (context, index) {
                          final item =
                              docs[index].data() as Map<String, dynamic>;
                          final docId = docs[index].id;

                          final String name = item['name'] ?? 'Unnamed';
                          final String slug = item['slug'] ?? '';
                          final String desc = item['description'] ?? '--';

                          String dateStr = '--';
                          if (item['createdAt'] != null) {
                            final DateTime date =
                                (item['createdAt'] as Timestamp).toDate();
                            dateStr = DateFormat('MM/dd/yyyy').format(date);
                          }

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: const Color(0xFFB5E575),
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.widgets_outlined,
                                        color: Colors.white54,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    name,
                                    style: const TextStyle(
                                      color: const Color(0xFFB5E575),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFB5E575).withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      slug,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    desc.isEmpty ? '--' : desc,
                                    style: const TextStyle(
                                      color: const Color(0xFFB5E575),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    dateStr,
                                    style: const TextStyle(
                                      color: const Color(0xFFB5E575),
                                    ),
                                  ),
                                ),

                                PopupMenuButton<String>(
                                  icon: const Icon(
                                    Icons.more_horiz,
                                    color: const Color(0xFFB5E575),
                                  ),
                                  color: const Color(0xFFB5E575),
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      _showCategoryDialog(
                                        existingCategory: item,
                                        docId: docId,
                                      );
                                    }
                                    if (value == 'delete')
                                      _deleteCategory(docId);
                                  },
                                  itemBuilder: (BuildContext context) =>
                                      <PopupMenuEntry<String>>[
                                        const PopupMenuItem<String>(
                                          value: 'edit',
                                          child: ListTile(
                                            leading: Icon(
                                              Icons.edit,
                                              color: Colors.white,
                                            ),
                                            title: Text(
                                              'Edit',
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const PopupMenuItem<String>(
                                          value: 'delete',
                                          child: ListTile(
                                            leading: Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                            ),
                                            title: Text(
                                              'Delete',
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }


  Widget _buildDashboardTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Dashboard Overview',
                style: TextStyle(
                  color: const Color(0xFFB5E575),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Welcome back! Here is what is happening on Founit today.',
                style: TextStyle(color: const Color(0xFFB5E575)),
              ),
              const SizedBox(height: 24),

              FutureBuilder<Map<String, int>>(
                future: _getDashboardStats(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Row(
                      children: [
                        _buildStatCard(
                          'Total Users',
                          '...',
                          Icons.people,
                          Colors.blue,
                        ),
                        const SizedBox(width: 16),
                        _buildStatCard(
                          'Pending Approvals',
                          '...',
                          Icons.access_time,
                          Colors.orange,
                        ),
                        const SizedBox(width: 16),
                        _buildStatCard(
                          'Active Listings',
                          '...',
                          Icons.check_circle_outline,
                          Colors.green,
                        ),
                        const SizedBox(width: 16),
                        _buildStatCard(
                          'Categories',
                          '...',
                          Icons.category,
                          Colors.purpleAccent,
                        ),
                      ],
                    );
                  }

                  final stats =
                      snapshot.data ??
                      {'users': 0, 'pending': 0, 'active': 0, 'categories': 0};

                  return Row(
                    children: [
                      _buildStatCard(
                        'Total Users',
                        stats['users'].toString(),
                        Icons.people,
                        Colors.blue,
                      ),
                      const SizedBox(width: 16),
                      _buildStatCard(
                        'Pending Approvals',
                        stats['pending'].toString(),
                        Icons.access_time,
                        Colors.orange,
                      ),
                      const SizedBox(width: 16),
                      _buildStatCard(
                        'Active Listings',
                        stats['active'].toString(),
                        Icons.check_circle_outline,
                        Colors.green,
                      ),
                      const SizedBox(width: 16),
                      _buildStatCard(
                        'Categories',
                        stats['categories'].toString(),
                        Icons.category,
                        Colors.purpleAccent,
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: const Text(
            'Recent Activity',
            style: TextStyle(
              color: const Color(0xFFB5E575),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),

        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFB5E575)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
              
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: const Color(0xFFB5E575))),
                  ),
                  child: Row(
                    children: [
                      Expanded(flex: 3, child: _headerText('Product Title')),
                      Expanded(flex: 2, child: _headerText('Category')),
                      Expanded(flex: 2, child: _headerText('Seller')),
                      Expanded(flex: 1, child: _headerText('Price')),
                      Expanded(flex: 1, child: _headerText('Condition')),
                      Expanded(flex: 1, child: _headerText('Status')),
                      const SizedBox(width: 40),
                    ],
                  ),
                ),
               
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('listings')
                        .orderBy('createdAt', descending: true)
                        .limit(10)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting)
                        return const Center(child: CircularProgressIndicator());

                      final docs = snapshot.data?.docs ?? [];
                      if (docs.isEmpty) {
                        return const Center(
                          child: Text(
                            'No recent activity.',
                            style: TextStyle(color: const Color(0xFFB5E575)),
                          ),
                        );
                      }

                      return ListView.separated(
                        itemCount: docs.length,
                        separatorBuilder: (context, index) =>
                            Divider(color: const Color(0xFFB5E575), height: 1),
                        itemBuilder: (context, index) {
                          final item =
                              docs[index].data() as Map<String, dynamic>;
                          final docId = docs[index].id;
                          return _buildProductRow(
                            item,
                            docId,
                          ); 
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }


  Widget _buildProductRow(Map<String, dynamic> item, String docId) {
    final String title = item['title'] ?? 'No Title';
    final int price = item['price'] ?? 0;
    final String category = item['category'] ?? 'Other';
    final String status = item['status'] ?? 'pending';
    final bool isNew = item['isNew'] ?? false;
    final List<dynamic> images = item['images'] ?? [];
    final String sellerId = item['sellerId'] ?? ''; 
    
  
    final Timestamp? createdAt = item['createdAt'] as Timestamp?;
    
    Color statusColor = (status == 'active' || status == 'approved') ? Colors.green : (status == 'pending' ? Colors.orange : Colors.redAccent);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                ClipRRect(borderRadius: BorderRadius.circular(8), child: SizedBox(width: 40, height: 40, child: _decodeImage(images))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(title, style: const TextStyle(color: const Color(0xFFB5E575), fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text('Listed ${_timeAgo(createdAt)}', style: const TextStyle(color: const Color(0xFFB5E575), fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          
          Expanded(flex: 2, child: Text(category, style: const TextStyle(color: const Color(0xFFB5E575)))),
          
         
          Expanded(
            flex: 2, 
            child: sellerId.isEmpty ? const Text('Unknown', style: TextStyle(color: Colors.redAccent, fontSize: 12)) : FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('Users').doc(sellerId).get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || !snapshot.data!.exists) return const Text('Loading...', style: TextStyle(color: const Color(0xFFB5E575), fontSize: 12));
                final userData = snapshot.data!.data() as Map<String, dynamic>;
                return Text('${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'.trim(), style: const TextStyle(color: const Color(0xFFB5E575), fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis);
              },
            ),
          ),
          
    
          Expanded(flex: 1, child: Text('$price EGP', style: const TextStyle(color: const Color(0xFFB5E575), fontWeight: FontWeight.bold))),
          
         
          Expanded(flex: 1, child: Align(alignment: Alignment.centerLeft, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(border: Border.all(color: const Color(0xFFB5E575)), borderRadius: BorderRadius.circular(12)), child: Text(isNew ? 'New' : 'Used', style: const TextStyle(color: const Color(0xFFB5E575), fontSize: 11))))),
          
        
          Expanded(flex: 1, child: Align(alignment: Alignment.centerLeft, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: statusColor.withOpacity(0.2), borderRadius: BorderRadius.circular(12)), child: Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold))))),
          
       
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz, color: const Color(0xFFB5E575)),
            color: const Color(0xFF1B1B28),
            onSelected: (value) {
              if (value == 'view') _showListingReviewDialog(item, docId);
              if (value == 'approve') _updateListingStatus(docId, 'active');
              if (value == 'reject') _updateListingStatus(docId, 'rejected');
              if (value == 'flag') _updateListingStatus(docId, 'flagged');
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(value: 'view', child: ListTile(leading: Icon(Icons.visibility, color: Colors.white), title: Text('View', style: TextStyle(color: Colors.white)))),
              const PopupMenuItem<String>(value: 'approve', child: ListTile(leading: Icon(Icons.check, color: Colors.green), title: Text('Approve', style: TextStyle(color: Colors.green)))),
              const PopupMenuItem<String>(value: 'reject', child: ListTile(leading: Icon(Icons.close, color: Colors.red), title: Text('Reject', style: TextStyle(color: Colors.red)))),
              const PopupMenuItem<String>(value: 'flag', child: ListTile(leading: Icon(Icons.flag, color: Colors.orange), title: Text('Flag User', style: TextStyle(color: Colors.orange)))),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildClientsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('Users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data?.docs ?? [];
        int totalClients = docs.length;
        int activeUsers = docs
            .where(
              (doc) =>
                  (doc.data() as Map<String, dynamic>)['isSuspended'] != true,
            )
            .length;
        int flaggedUsers = totalClients - activeUsers;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Manage Clients',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'View and manage users of the platform.',
                    style: TextStyle(color: _textSecondary),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      _buildStatCard(
                        'Total Clients',
                        totalClients.toString(),
                        Icons.people,
                        Colors.blue,
                      ),
                      const SizedBox(width: 16),
                      _buildStatCard(
                        'Active Users',
                        activeUsers.toString(),
                        Icons.person_outline,
                        Colors.teal,
                      ),
                      const SizedBox(width: 16),
                      _buildStatCard(
                        'Flagged Users',
                        flaggedUsers.toString(),
                        Icons.error_outline,
                        Colors.redAccent,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFB5E575)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: const Color(0xFFB5E575))),
                      ),
                      child: Row(
                        children: [
                          Expanded(flex: 3, child: _headerText('Name')),
                          // Expanded(flex: 2, child: _headerText('University')),
                          // Expanded(flex: 2, child: _headerText('Faculty')),
                          Expanded(flex: 1, child: _headerText('Gender')),
                          Expanded(flex: 1, child: _headerText('Status')),
                          const SizedBox(width: 40),
                        ],
                      ),
                    ),
                    Expanded(
                      child: docs.isEmpty
                          ? const Center(
                              child: Text(
                                'No users found.',
                                style: TextStyle(color: Colors.white54),
                              ),
                            )
                          : ListView.separated(
                              itemCount: docs.length,
                              separatorBuilder: (context, index) =>
                                  Divider(color: const Color(0xFFB5E575), height: 1),
                              itemBuilder: (context, index) {
                                final user =
                                    docs[index].data() as Map<String, dynamic>;
                                final uid = docs[index].id;
                                final String fName =
                                    user['firstName'] ?? 'Unknown';
                                final String lName = user['lastName'] ?? '';
                                final String email =
                                    user['email'] ?? 'No email provided';
                                // final String uni = user['university'] ?? 'EUI';
                                final String faculty =
                                    user['faculty'] ?? 'Not Specified';
                                final String gender =
                                    user['gender'] ?? 'Not Specified';
                                final bool isSuspended =
                                    user['isSuspended'] ?? false;

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 18,
                                              backgroundColor: green
                                                  .withOpacity(0.2),
                                              child: const Icon(
                                                Icons.person,
                                                size: 20,
                                                color: Colors.white54,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    '$fName $lName'.trim(),
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  Text(
                                                    email,
                                                    style: TextStyle(
                                                      color: _textSecondary,
                                                      fontSize: 11,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Expanded(
                                      //   flex: 2,
                                      //   child: Text(
                                      //     uni,
                                      //     style: const TextStyle(
                                      //       color: Colors.white70,
                                      //     ),
                                      //   ),
                                      // ),
                                      // Expanded(
                                      //   flex: 2,
                                      //   child: Text(
                                      //     faculty,
                                      //     style: const TextStyle(
                                      //       color: Colors.white70,
                                      //     ),
                                      //   ),
                                      // ),
                                      Expanded(
                                        flex: 1,
                                        child: Text(
                                          gender,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isSuspended
                                                  ? Colors.redAccent
                                                        .withOpacity(0.2)
                                                  : green.withOpacity(
                                                      0.2,
                                                    ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              isSuspended
                                                  ? 'INACTIVE'
                                                  : 'ACTIVE',
                                              style: TextStyle(
                                                color: isSuspended
                                                    ? Colors.redAccent
                                                    : green,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        icon: const Icon(
                                          Icons.more_horiz,
                                          color: const Color(0xFFB5E575),
                                        ),
                                        color: _cardDark,
                                        onSelected: (value) {
                                          if (value == 'toggle_suspension')
                                            _toggleUserSuspension(
                                              uid,
                                              isSuspended,
                                            );
                                        },
                                        itemBuilder: (BuildContext context) =>
                                            <PopupMenuEntry<String>>[
                                              const PopupMenuItem<String>(
                                                value: 'view',
                                                child: ListTile(
                                                  leading: Icon(
                                                    Icons.visibility,
                                                    color: Colors.white,
                                                  ),
                                                  title: Text(
                                                    'View Profile',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              PopupMenuItem<String>(
                                                value: 'toggle_suspension',
                                                child: ListTile(
                                                  leading: Icon(
                                                    isSuspended
                                                        ? Icons.restore
                                                        : Icons.block,
                                                    color: isSuspended
                                                        ? Colors.green
                                                        : Colors.red,
                                                  ),
                                                  title: Text(
                                                    isSuspended
                                                        ? 'Restore User'
                                                        : 'Suspend User',
                                                    style: TextStyle(
                                                      color: isSuspended
                                                          ? Colors.green
                                                          : Colors.red,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  Widget _buildProductsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('listings')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data?.docs ?? [];
        int totalListings = docs.length;
        int pendingCount = docs
            .where(
              (doc) =>
                  (doc.data() as Map<String, dynamic>)['status'] == 'pending',
            )
            .length;
        int activeCount = docs.where((doc) {
          final s = (doc.data() as Map<String, dynamic>)['status'];
          return s == 'active' || s == 'approved';
        }).length;
        int flaggedCount = docs.where((doc) {
          final s = (doc.data() as Map<String, dynamic>)['status'];
          return s == 'flagged' || s == 'rejected';
        }).length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Manage Listings',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Comprehensive control over all products listed by sellers.',
                    style: TextStyle(color: _textSecondary),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      _buildStatCard(
                        'Total Listings',
                        totalListings.toString(),
                        Icons.list_alt,
                        Colors.blue,
                      ),
                      const SizedBox(width: 16),
                      _buildStatCard(
                        'Pending Approval',
                        pendingCount.toString(),
                        Icons.access_time,
                        Colors.orange,
                      ),
                      const SizedBox(width: 16),
                      _buildStatCard(
                        'Active',
                        activeCount.toString(),
                        Icons.check_circle_outline,
                        Colors.green,
                      ),
                      const SizedBox(width: 16),
                      _buildStatCard(
                        'Flagged',
                        flaggedCount.toString(),
                        Icons.flag_outlined,
                        Colors.red,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFB5E575)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: _borderColor)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: _headerText('Product Title'),
                          ),
                          Expanded(flex: 2, child: _headerText('Category')),
                          Expanded(flex: 2, child: _headerText('Seller')),
                          Expanded(flex: 1, child: _headerText('Price')),
                          Expanded(flex: 1, child: _headerText('Condition')),
                          Expanded(flex: 1, child: _headerText('Status')),
                          const SizedBox(width: 40),
                        ],
                      ),
                    ),
                    
                    Expanded(
                      child: docs.isEmpty
                          ? const Center(
                              child: Text(
                                'No listings found.',
                                style: TextStyle(color: Colors.white54),
                              ),
                            )
                          : ListView.separated(
                              itemCount: docs.length,
                              separatorBuilder: (context, index) =>
                                  Divider(color: _borderColor, height: 1),
                              itemBuilder: (context, index) {
                                final item =
                                    docs[index].data() as Map<String, dynamic>;
                                final docId = docs[index].id;
                                final String title =
                                    item['title'] ?? 'No Title';
                                final int price = item['price'] ?? 0;
                                final String category =
                                    item['category'] ?? 'Other';
                                final String status =
                                    item['status'] ?? 'pending';
                                final bool isNew = item['isNew'] ?? false;
                                final List<dynamic> images =
                                    item['images'] ?? [];
                                final String sellerId = item['sellerId'] ?? '';

                                Color statusColor =
                                    (status == 'active' || status == 'approved')
                                    ? green
                                    : (status == 'pending'
                                          ? Colors.orange
                                          : Colors.redAccent);

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: Row(
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: SizedBox(
                                                width: 40,
                                                height: 40,
                                                child: _decodeImage(images),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                title,
                                                style: const TextStyle(
                                                  color: const Color(0xFFB5E575),
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          category,
                                          style: const TextStyle(
                                            color: const Color(0xFFB5E575),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: sellerId.isEmpty
                                            ? const Text(
                                                'Unknown Seller',
                                                style: TextStyle(
                                                  color: Colors.redAccent,
                                                  fontSize: 12,
                                                ),
                                              )
                                            : FutureBuilder<DocumentSnapshot>(
                                                future: FirebaseFirestore
                                                    .instance
                                                    .collection('Users')
                                                    .doc(sellerId)
                                                    .get(),
                                                builder: (context, snapshot) {
                                                  if (snapshot
                                                          .connectionState ==
                                                      ConnectionState.waiting)
                                                    return const Text(
                                                      'Loading...',
                                                      style: TextStyle(
                                                        color: const Color(0xFFB5E575),
                                                        fontSize: 12,
                                                      ),
                                                    );
                                                  if (!snapshot.hasData ||
                                                      !snapshot.data!.exists)
                                                    return const Text(
                                                      'User Deleted',
                                                      style: TextStyle(
                                                        color: Colors.redAccent,
                                                        fontSize: 12,
                                                      ),
                                                    );
                                                  final userData =
                                                      snapshot.data!.data()
                                                          as Map<
                                                            String,
                                                            dynamic
                                                          >;
                                                  return Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Text(
                                                        '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'
                                                            .trim(),
                                                        style: const TextStyle(
                                                          color: const Color(0xFFB5E575),
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 13,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                      Text(
                                                        userData['email'] ??
                                                            'No email',
                                                        style: TextStyle(
                                                          color:  Color(0xFFB5E575),
                                                          fontSize: 11,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ],
                                                  );
                                                },
                                              ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Text(
                                          '$price EGP',
                                          style: const TextStyle(
                                            color:const Color(0xFFB5E575),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: const Color(0xFFB5E575)
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              isNew ? 'New' : 'Used',
                                              style: const TextStyle(
                                                color: const Color(0xFFB5E575),
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFB5E575).withOpacity(
                                                0.2,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              status.toUpperCase(),
                                              style: TextStyle(
                                                color: statusColor,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        icon: const Icon(
                                          Icons.more_horiz,
                                          color: const Color(0xFFB5E575),
                                        ),
                                        color: _cardDark,
                                        onSelected: (value) {
                                          if (value == 'view')
                                            _showListingReviewDialog(
                                              item,
                                              docId,
                                            );
                                          if (value == 'approve')
                                            _updateListingStatus(
                                              docId,
                                              'active',
                                            );
                                          if (value == 'reject')
                                            _updateListingStatus(
                                              docId,
                                              'rejected',
                                            );
                                          if (value == 'flag')
                                            _updateListingStatus(
                                              docId,
                                              'flagged',
                                            );
                                        },
                                        itemBuilder: (BuildContext context) =>
                                            <PopupMenuEntry<String>>[
                                              const PopupMenuItem<String>(
                                                value: 'view',
                                                child: ListTile(
                                                  leading: Icon(
                                                    Icons.visibility,
                                                    color: Colors.white,
                                                  ),
                                                  title: Text(
                                                    'View',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const PopupMenuItem<String>(
                                                value: 'approve',
                                                child: ListTile(
                                                  leading: Icon(
                                                    Icons.check,
                                                    color: Colors.green,
                                                  ),
                                                  title: Text(
                                                    'Approve',
                                                    style: TextStyle(
                                                      color: Colors.green,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const PopupMenuItem<String>(
                                                value: 'reject',
                                                child: ListTile(
                                                  leading: Icon(
                                                    Icons.close,
                                                    color: Colors.red,
                                                  ),
                                                  title: Text(
                                                    'Reject',
                                                    style: TextStyle(
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const PopupMenuItem<String>(
                                                value: 'flag',
                                                child: ListTile(
                                                  leading: Icon(
                                                    Icons.flag,
                                                    color: Colors.orange,
                                                  ),
                                                  title: Text(
                                                    'Flag User',
                                                    style: TextStyle(
                                                      color: Colors.orange,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  
  void _showListingReviewDialog(Map<String, dynamic> item, String docId) {
    final String title = item['title'] ?? 'No Title';
    final int price = item['price'] ?? 0;
    final String description =
        item['description'] ?? 'No description provided.';
    final String category = item['category'] ?? 'Other';
    final List<dynamic> images = item['images'] ?? [];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: _borderColor),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Review Product',
              style: TextStyle(
                color: const Color(0xFFB5E575),
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: const Color(0xFFB5E575)),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                
                if (images.isNotEmpty) ...[
                  SizedBox(
                    height: 300,
                    width: double.infinity,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: images.length,
                      itemBuilder: (context, index) {
                        String base64String = images[index] as String;
                        if (base64String.contains(','))
                          base64String = base64String.split(',').last;

                        try {
                          return Padding(
                            padding: const EdgeInsets.only(right: 12.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                color: Colors
                                    .black26,
                                child: Image.memory(
                                  base64Decode(base64String),
                                  fit: BoxFit
                                      .contain, 
                                ),
                              ),
                            ),
                          );
                        } catch (e) {
                          return const SizedBox(
                            width: 300,
                            child: Icon(
                              Icons.broken_image,
                              color: Colors.white24,
                              size: 50,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                 
                  if (images.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                      child: Text(
                        'Scroll horizontally to see all ${images.length} photos ➔',
                        style: TextStyle(
                          color: green,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],

                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          color: green,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '$price EGP',
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Description',
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.all(24),
        actions: [
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.redAccent),
              foregroundColor: Colors.redAccent,
            ),
            icon: const Icon(Icons.close),
            label: const Text('Reject'),
            onPressed: () {
              Navigator.pop(context);
              _updateListingStatus(docId, 'rejected');
            },
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            icon: const Icon(Icons.check, color: Colors.white),
            label: const Text('Approve', style: TextStyle(color: Colors.white)),
            onPressed: () {
              Navigator.pop(context);
              _updateListingStatus(docId, 'active');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(IconData icon, String title, int index) {
    bool isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4, right: 16),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFB5E575) : Colors.transparent,
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
          border: isSelected ? Border.all(color: _borderColor) : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : _textSecondary,
              size: 20,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : _textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

Color dd=const Color(0xFFB5E575);
  Widget _buildStatCard(
    String title,
    String count,
    IconData icon,
    Color dd,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _bgDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: dd.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: const Color(0xFFB5E575), fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  count,
                  style: const TextStyle(
                    color: const Color(0xFFB5E575),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Icon(icon, color: dd, size: 28),
          ],
        ),
      ),
    );
  }

  Widget _headerText(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: const Color(0xFFB5E575),
        fontWeight: FontWeight.bold,
        fontSize: 13,
      ),
    );
  }

  Widget _decodeImage(List<dynamic> images) {
    if (images.isEmpty) {
      return Container(
        color: const Color(0xFFB5E575),
        child: const Icon(Icons.image, color: Colors.white24, size: 20),
      );
    }
    String base64String = images[0] as String;
    if (base64String.contains(',')) base64String = base64String.split(',').last;
    try {
      return Image.memory(base64Decode(base64String), fit: BoxFit.cover);
    } catch (e) {
      return Container(
        color: _bgDark,
        child: const Icon(Icons.broken_image, color: Colors.white24, size: 20),
      );
    }
  }
}


  String _timeAgo(Timestamp? timestamp) {
    if (timestamp == null) return '--';
    
    final DateTime date = timestamp.toDate();
    final Duration diff = DateTime.now().difference(date);

    if (diff.inDays > 365) return '${(diff.inDays / 365).floor()} years ago';
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()} months ago';
    if (diff.inDays > 7) return '${(diff.inDays / 7).floor()} weeks ago';
    if (diff.inDays > 0) return '${diff.inDays} days ago';
    if (diff.inHours > 0) return '${diff.inHours} hours ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes} mins ago';
    return 'Just now';
  }