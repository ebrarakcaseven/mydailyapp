import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mydailyapp/service/database_service.dart';
import 'package:mydailyapp/top/appbar.dart';

class CollaborativePageSelector extends StatefulWidget {
  @override
  _CollaborativePageSelectorState createState() =>
      _CollaborativePageSelectorState();
}

class _CollaborativePageSelectorState extends State<CollaborativePageSelector> {
  final DatabaseService _databaseService = DatabaseService();
  String? _selectedDocId;

  @override
  void initState() {
    super.initState();
    _loadUserPages();
  }

  Future<void> _loadUserPages() async {
    List<String> pageIds = await _databaseService.getUserCollaborativePages();
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedDocId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Ortak Çalışma Sayfası'),
        ),
        body: const Center(
          child: Text('Erişilebilir ortak çalışma sayfası bulunamadı.'),
        ),
      );
    }

    return CollaborativePage(docId: _selectedDocId!);
  }
}

class CollaborativePage extends StatefulWidget {
  final String docId;

  CollaborativePage({required this.docId});

  @override
  _CollaborativePageState createState() => _CollaborativePageState();
}

class _CollaborativePageState extends State<CollaborativePage> {
  final DatabaseService _databaseService = DatabaseService();
  TextEditingController _controller = TextEditingController();
  bool _isEditing = false;
  bool _isAuthorized = false;

  @override
  void initState() {
    super.initState();
    _checkAuthorization();
  }

//Veritabanında kullanıcı id sinin kayıtlı olduğu ortak çalışma sayfası var mı kontrol eder.
  Future<void> _checkAuthorization() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot doc =
          await _databaseService.getCollaborativeDocumentOnce(widget.docId);
      var documentData = doc.data() as Map<String, dynamic>?;

      if (documentData != null) {
        var members = documentData['members'];

        if (members is List<dynamic> && members.contains(user.uid)) {
          setState(() {
            _isAuthorized = true;
          });
        } else {
          setState(() {
            _isAuthorized = false;
          });
        }
      } else {
        setState(() {
          _isAuthorized = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAuthorized) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Ortak Çalışma Sayfası'),
        ),
        body: const Center(
          child: Text('Bu sayfaya erişim yetkiniz yok.'),
        ),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Ortak Çalışma Sayfası',
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.check : Icons.edit),
            onPressed: () {
              //Veriyi düzenler.
              setState(() {
                if (_isEditing) {
                  // Düzenleme modundan çıkarken veriyi kaydet
                  _databaseService.updateCollaborativeDocument(
                      widget.docId, {'content': _controller.text});
                }
                _isEditing = !_isEditing;
              });
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _databaseService.getCollaborativeDocument(widget.docId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var documentData = snapshot.data!.data();
          if (documentData == null) {
            return const Center(child: Text('Veri bulunamadı.'));
          }

          var data = documentData as Map<String, dynamic>;
          String content = data['content'] ?? '';

          if (!_isEditing) {
            _controller.text = content;
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: _isEditing
                ? TextField(
                    controller: _controller,
                    maxLines: null,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Ortak Çalışma Metni',
                    ),
                  )
                : SingleChildScrollView(
                    child: Text(
                      content,
                      style: const TextStyle(fontSize: 16.0),
                    ),
                  ),
          );
        },
      ),
    );
  }
}
