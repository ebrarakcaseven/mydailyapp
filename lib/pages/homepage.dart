import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mydailyapp/pages/data_add.dart';
import 'package:mydailyapp/pages/detailpage.dart';
import 'package:mydailyapp/service/authservice.dart';
import 'package:mydailyapp/service/database_service.dart';
import 'package:mydailyapp/top/appbar.dart';
import 'package:mydailyapp/top/drawer.dart';
import 'package:provider/provider.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final DatabaseService _databaseService =
      DatabaseService(); //veritabanı işlemleri yaptığımı sayfayı bağlıyoruz.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: "Anasayfa",
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: Provider.of<AuthService>(context).getUserData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  //Verileri çekerken hata oluşursa hata mesajı döndürür.
                  return Center(
                      child: Text('Bir hata oluştu: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  //Veritabanında veri yoksa ekrana yazar.
                  return const Center(child: Text('Hiç veri yok'));
                }
                final data = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    final item = data[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(
                          vertical: 5, horizontal: 10),
                      decoration: BoxDecoration(
                          color: const Color.fromARGB(131, 249, 227, 247),
                          borderRadius: BorderRadius.circular(15)),
                      height: 80,
                      child: Center(
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
                                  docId: item.id,
                                  collection: 'user_data',
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color.fromARGB(223, 249, 227, 247),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const DataAdd(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      drawer: const MyDrawer(), //Sol taraftan açılan menü.
    );
  }
}
