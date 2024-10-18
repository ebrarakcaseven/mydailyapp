import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mydailyapp/pages/collaborativepage.dart';
import 'package:mydailyapp/pages/collectionspage.dart';
import 'package:mydailyapp/pages/data_add.dart';
import 'package:mydailyapp/pages/homepage.dart';
import 'package:mydailyapp/pages/settingspage.dart';
import 'package:mydailyapp/service/authservice.dart';
import 'package:mydailyapp/service/database_service.dart';
import 'package:mydailyapp/top/appbar.dart';
import 'package:mydailyapp/user/login.dart';
import 'package:provider/provider.dart';

class MyDrawer extends StatefulWidget {
  const MyDrawer({super.key});

  @override
  State<MyDrawer> createState() => _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer> {
  final DatabaseService _databaseService = DatabaseService();
  String? _selectedDocId;
  String _userName = 'Kullanıcı';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadUserPages();
  }

  Future<void> _loadUserInfo() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      DocumentSnapshot userInfo = await authService.getUserInfo();
      if (userInfo.exists) {
        setState(() {
          _userName =
              '${userInfo['firstName'].toString().toUpperCase()} ${userInfo['lastName'].toString().toUpperCase()}';
        });
      }
    } catch (e) {
      print('Kullanıcı bilgileri yüklenirken hata oluştu: $e');
    }
  }

  Future<void> _loadUserPages() async {
    try {
      List<String> pageIds = await _databaseService.getUserCollaborativePages();
      if (pageIds.isNotEmpty) {
        setState(() {
          _selectedDocId = pageIds.first; // İlk sayfayı seçiyoruz
        });
      }
    } catch (e) {
      print('Hata: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 35.0),
            child: Center(
              child: Text(
                '$_userName',
                style:
                    const TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const Divider(),
          buildListTile(Icons.home, 'Anasayfa', context, const Homepage()),
          buildListTile(
              Icons.settings, 'Ayarlar', context, const Settingspage()),
          buildListTile(
              Icons.favorite, 'Koleksiyonlarım', context, const CollectionsPage()),
          buildListTile(Icons.edit, 'Günlük Yaz', context, const DataAdd()),
          buildListTile(
            Icons.group,
            'Ortak Günlük Yaz',
            context,
            _selectedDocId != null
                ? CollaborativePage(docId: _selectedDocId!)
                : Scaffold(
                    appBar: CustomAppBar(title: "Ortak Günlük Sayfası Yok..."),
                    body: const Center(child: Text("boş...")),
                  ),
          ),
          buildListTile(Icons.exit_to_app, 'Çıkış', context, const LoginPage()),
        ],
      ),
    );
  }

  Widget buildListTile(
      IconData icon, String title, BuildContext context, Widget page) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => page));
      },
    );
  }
}
