import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mydailyapp/pages/detailpage.dart';
import 'package:mydailyapp/service/database_service.dart';
import 'package:mydailyapp/service/authservice.dart';
import 'package:mydailyapp/top/drawer.dart';
import 'package:provider/provider.dart';
import 'package:mydailyapp/top/appbar.dart';

class CollectionsPage extends StatefulWidget {
  const CollectionsPage({super.key});

  @override
  State<CollectionsPage> createState() => _CollectionsPageState();
}

class _CollectionsPageState extends State<CollectionsPage> {
  final DatabaseService _databaseService = DatabaseService();
  List<Map<String, dynamic>> _collections = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCollections();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: "Koleksiyonlarım",
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black),
            onPressed: _addCollection,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _collections.isEmpty
              ? const Center(
                  child: Text("henüz bir koleksiyon eklenmemiş"),
                )
              : Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, // 2 sütun
                        crossAxisSpacing: 8.0,
                        mainAxisSpacing: 8.0,
                        childAspectRatio: 3 / 2,
                      ),
                      itemCount: _collections.length,
                      itemBuilder: (context, index) {
                        final collection = _collections[index];
                        final collectionId = collection['uid'];
                        final collectionName = collection['name'];
                        if (collectionId != null && collectionName != null) {
                          return InkWell(
                            onTap: () async {
                              bool? shouldReload = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CollectionDetailPage(
                                    collectionName: collectionName,
                                    collectionId: collectionId,
                                  ),
                                ),
                              );

                              if (shouldReload == true) {
                                _loadCollections();
                              }
                            },
                            child: Card(
                              color: const Color.fromARGB(255, 244, 233, 237),
                              child: Center(
                                child: Text(
                                  _collections[index]['name'],
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          );
                        } else {
                          return const Text("Koleksiyon bilgisi eksik");
                        }
                      }),
                ),
      drawer: const MyDrawer(),
    );
  }
}

//Koleksiyonun detay kısmı
class CollectionDetailPage extends StatefulWidget {
  final String collectionName;
  final String collectionId;

  const CollectionDetailPage(
      {super.key, required this.collectionName, required this.collectionId});

  @override
  _CollectionDetailPageState createState() => _CollectionDetailPageState();
}

class _CollectionDetailPageState extends State<CollectionDetailPage> {
  final DatabaseService _databaseService = DatabaseService();
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() async {
    try {
      List<Map<String, dynamic>> items =
          await _databaseService.getCollectionsItems(widget.collectionId);
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      print("Veriler yüklenirken hata: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

//Koleksiyonu veri tabanından siler.
  void _deleteCollection() async {
    try {
      await _databaseService.deleteCollection(widget.collectionId);
      Navigator.of(context).pop(true);
    } catch (e) {
      print("Hata: $e");
    }
  }

  String formatDate(Timestamp timestamp) {
    DateTime date = timestamp.toDate();
    return "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: widget.collectionName,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.black),
            onPressed: () {
              showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text("koleksiyonu sil"),
                      content: const Text(
                          "Bu koleksiyonu silmek istediğinizden emin misiniz?"),
                      actions: [
                        TextButton(
                          child: const Text("İptal"),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        TextButton(
                          child: const Text("Sil"),
                          onPressed: () {
                            Navigator.of(context).pop();
                            _deleteCollection();
                          },
                        ),
                      ],
                    );
                  });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _items.isEmpty
              ? const Center(
                  child: Text("Bu koleksiyonda henüz öğe yok"),
                )
              : ListView.builder(
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(
                          vertical: 5, horizontal: 10),
                      decoration: BoxDecoration(
                          color: const Color.fromARGB(131, 249, 227, 247),
                          borderRadius: BorderRadius.circular(15)),
                      height: 80,
                      child: ListTile(
                        title: Text(
                          item['data'],
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                        subtitle: item['timestamp'] != null
                            ? Text(
                                item['timestamp'].toDate().toString(),
                                overflow: TextOverflow.ellipsis,
                              )
                            : const Text(
                                'Zaman bilgisi yok',
                                overflow: TextOverflow.ellipsis,
                              ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailPage(
                                data: item['data'],
                                timestamp: item['timestamp']?.toDate(),
                                docId: item['uid'],
                                collection: 'user_data',
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
