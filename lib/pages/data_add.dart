import 'package:flutter/material.dart';
import 'package:mydailyapp/pages/homepage.dart';
import 'package:mydailyapp/service/authservice.dart';
import 'package:mydailyapp/top/appbar.dart';
import 'package:mydailyapp/top/drawer.dart';
import 'package:mydailyapp/user/login.dart';
import 'package:provider/provider.dart';

class DataAdd extends StatefulWidget {
  const DataAdd({super.key});

  @override
  State<DataAdd> createState() => _DataAddState();
}

class _DataAddState extends State<DataAdd> {
  final TextEditingController _dataController = TextEditingController();
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: "Günlük Yaz",
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _dataController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.all(8.0),
                      ),
                      minLines: 10, //TextFieldın minimum uzunluğu
                      maxLines:
                          null, //TextFieldın maximum uzunluğu null değeri verdim çünkü metin boyutu kadar uzaması gerek.
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 20),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        //Eğer textfield'a metin girilmezse ekrana hata mesajı döner ve veritabanına kaydetmez.
                        if (_dataController.text.trim().isEmpty) {
                          setState(() {
                            _errorMessage = 'Mesaj boş olamaz!';
                          });
                        } else {
                          try {
                            await Provider.of<AuthService>(context,
                                    listen: false)
                                .saveUserData(_dataController.text);
                            setState(() {
                              _errorMessage = null;
                            });
                            _dataController.clear();
                            ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(
                              content: Text('Günlük kaydedildi'),
                            ));
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const Homepage(), // Kayıt başarıyla oluştuktan sonra anasayfaya yönlendirir.
                              ),
                            );
                          } catch (e) {
                            setState(() {
                              _errorMessage = e.toString();
                            });
                          }
                        }
                      },
                      child: const Text('Kaydet'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      drawer: const MyDrawer(),
    );
  }
}
