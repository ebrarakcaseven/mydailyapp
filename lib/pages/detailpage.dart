import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mydailyapp/pages/editpage.dart';
import 'package:mydailyapp/service/database_service.dart';
import 'package:mydailyapp/service/authservice.dart';
import 'package:mydailyapp/top/appbar.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class DetailPage extends StatefulWidget {
  final String data;
  final DateTime? timestamp;
  final String docId;
  final String collection;

  DetailPage({
    required this.data,
    this.timestamp,
    required this.docId,
    required this.collection,
  });

  @override
  _DetailPageState createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  List<Map<String, dynamic>> _collections = [];
  final DatabaseService _databaseService = DatabaseService();
  late String _data;
  late String _formattedDate;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _data = widget.data;
    _formattedDate = widget.timestamp != null
        ? DateFormat('yyyy-MM-dd').format(widget.timestamp!)
        : 'Zaman bilgisi yok';
  }

  void _editData() async {
    final editedData = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (context) => EditPage(initialData: _data),
      ),
    );

    if (editedData != null && editedData.isNotEmpty) {
      setState(() {
        _data = editedData;
      });
      await _databaseService.updateDocument(
        widget.collection,
        widget.docId,
        {'data': editedData},
      );
    }
  }

  void _deleteData() async {
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Silmek istediğinize emin misiniz?'),
          content: const Text('Bu işlem geri alınamaz.'),
          actions: [
            TextButton(
              child: const Text('İptal'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('Sil'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      await _databaseService.deleteDocument(widget.collection, widget.docId);
      Navigator.of(context).pop();
    }
  }

  void _loadCollections() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;

    if (user != null) {
      List<Map<String, dynamic>> collections =
          await _databaseService.getCollections(user.uid);
      setState(() {
        _collections = collections;
        _isLoading = false;
      });
    } else {
      print('Kullanıcı oturumu yok');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _addCollection() async {
    TextEditingController _controller = TextEditingController();

    String? collection = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Yeni Koleksiyon Ekle'),
          content: TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'Koleksiyon Adı',
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.black, width: 1.5),
                borderRadius: BorderRadius.circular(8.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.black, width: 1.5),
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
          ),
          actions: [
            TextButton(
              child: const Text('İptal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Kaydet'),
              onPressed: () {
                Navigator.of(context).pop(_controller.text);
              },
            ),
          ],
        );
      },
    );

    if (collection != null && collection.isNotEmpty) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser;

      if (user != null) {
        await _databaseService.addCollection(
            'Collections', collection, user.uid);
        _loadCollections();
      } else {
        print('Kullanıcı oturumu yok');
      }
    }
  }

  void _addToCollection() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;

    if (user == null) {
      print('Kullanıcı oturumu yok');
      return;
    }

    List<Map<String, dynamic>> collections =
        await _databaseService.getCollections(user.uid);

    String? selectedCollectionId = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Koleksiyon Seçin'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _addCollection,
            )
          ],
          content: SingleChildScrollView(
            child: Column(
              children: collections.map((collection) {
                return ListTile(
                  title: Text(collection['name']),
                  onTap: () {
                    Navigator.of(context).pop(collection['uid']);
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );

    if (selectedCollectionId != null) {
      await _databaseService.addDataToCollection(
        'Collections/$selectedCollectionId/items',
        {'data': _data, 'timestamp': FieldValue.serverTimestamp()},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: _formattedDate, //Yazılan günlüğün tarihini appbara yazar.
        actions: [
          IconButton(
            //Veriyi dünler.
            icon: const Icon(Icons.edit, color: Colors.black),
            onPressed: _editData,
          ),
          IconButton(
            //Veriyi siler.
            icon: const Icon(Icons.delete, color: Colors.black),
            onPressed: _deleteData,
          ),
          IconButton(
            //Veriyi klasöre ekler.
            icon: const Icon(Icons.add, color: Colors.black),
            onPressed: _addToCollection,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Text(
                      _data,
                      style: const TextStyle(fontSize: 17),
                    ),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
