import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mydailyapp/main.dart';
import 'package:mydailyapp/service/authservice.dart';
import 'package:mydailyapp/top/appbar.dart';
import 'package:mydailyapp/top/drawer.dart';
import 'package:mydailyapp/user/login.dart';
import 'package:provider/provider.dart';

class Settingspage extends StatefulWidget {
  const Settingspage({super.key});

  @override
  State<Settingspage> createState() => _SettingspageState();
}

class _SettingspageState extends State<Settingspage> {
  final List<Map<String, dynamic>> settingsOptions = [
    {'icon': Icons.person, 'title': 'Hesap Ayarları'},
    {'icon': Icons.color_lens, 'title': 'Tema Ayarları'},
    {'icon': Icons.notifications, 'title': 'Bildirim Ayarları'},
    {'icon': Icons.lock, 'title': 'Güvenlik Ayarları'},
    {'icon': Icons.info, 'title': 'Uygulama Hakkında'},
    {'icon': Icons.exit_to_app, 'title': 'Çıkış Yap'},
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Ayarlar',
      ),
      body: ListView.builder(
        itemCount: settingsOptions.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: Icon(settingsOptions[index]['icon']),
            title: Text(settingsOptions[index]['title']),
            onTap: () {
              if (settingsOptions[index]['title'] == 'Tema Ayarları') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ThemeSettingsPage(),
                  ),
                );
              } else if (settingsOptions[index]['title'] ==
                  'Uygulama Hakkında') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AppInfoPage(),
                  ),
                );
              } else if (settingsOptions[index]['title'] == 'Hesap Ayarları') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AccountSettingsPage(),
                  ),
                );
              } else if (settingsOptions[index]['title'] == 'Çıkış Yap') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginPage(),
                  ),
                );
              }
            },
          );
        },
      ),
      drawer: const MyDrawer(),
    );
  }
}

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  _AccountSettingsPageState createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  late final AuthService _authService;
  String _firstName = '';
  String _lastName = '';
  String _email = '';
  String _profileImageUrl = '';
  bool _isLoading = true;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  @override
  void initState() {
    super.initState();
    _authService = Provider.of<AuthService>(context, listen: false);
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final docSnapshot = await _authService.getUserInfo();
      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        setState(() {
          _firstName = data['firstName'] ?? '';
          _lastName = data['lastName'] ?? '';
          _email = data['email'] ?? '';
          _profileImageUrl = data['profileImageUrl'] ?? '';
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateUserInfo(
      String newFirstName, String newLastName, String newEmail) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'firstName': newFirstName,
          'lastName': newLastName,
          'email': newEmail,
        });
        setState(() {
          _firstName = newFirstName;
          _lastName = newLastName;
          _email = newEmail;
        });
      }
    } catch (e) {
      print(e); //hatayı terminale yazar.
    }
  }

  Future<void> _deleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userId = user.uid;

      try {
        // Silme işlemleri
        // 1. Firestore'daki kullanıcı verilerini siler.
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .delete();

        // 2. Kullanıcının yazdığı günlükleri siler.
        await FirebaseFirestore.instance
            .collection('user_data')
            .where('uid', isEqualTo: userId)
            .get()
            .then((querySnapshot) {
          for (var doc in querySnapshot.docs) {
            doc.reference.delete();
          }
        });

        // 3. Firebase Authentication'dan kullanıcıyı siler.
        await user.delete();

        // Başarıyla silindikten sonra uygulamadan çıkış yapar.
        Navigator.of(context)
            .pushReplacementNamed('/login'); // Giriş sayfasına yönlendirir.
      } catch (error) {
        print('Hata: $error');
      }
    }
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hesabı Sil'),
          content: const Text(
              'Hesabınızı silmek istediğinize emin misiniz? Bu işlem geri alınamaz.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Dialogu kapat
              },
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Dialogu kapat
                _deleteAccount(); // Hesabı sil
              },
              child: const Text('Sil'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Hesap Ayarları',
        actions: [
          IconButton(
            // Ad, soyad ve eposta kısımlarını düzenler.
            icon: const Icon(Icons.edit, color: Colors.black),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return EditNameDialog(
                    currentFirstName: _firstName,
                    currentLastName: _lastName,
                    currentEmail: _email,
                    onUpdate: (newFirstName, newLastName, newEmail) {
                      _updateUserInfo(newFirstName, newLastName, newEmail);
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(
                      height: 50,
                    ),
                    _profileImageUrl.isNotEmpty
                        ? CircleAvatar(
                            radius: 50,
                            backgroundImage: NetworkImage(_profileImageUrl),
                          )
                        : const CircleAvatar(
                            radius: 50,
                            child: Icon(Icons.person, size: 50),
                          ),
                    const SizedBox(
                      height: 20,
                    ),
                    buildTextContainer(
                      'Ad: $_firstName',
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    buildTextContainer(
                      'Soyad: $_lastName',
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    buildTextContainer(
                      'E-posta: $_email',
                    ),
                    const SizedBox(
                      height: 25,
                    ),
                    TextButton(
                      onPressed: () {
                        // Veritabanında şifreyi günceller.
                        showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return ChangePasswordDialog(auth: _auth);
                            });
                      },
                      child: const Text(
                        "Şifre Değiştir",
                        style:
                            TextStyle(color: Color.fromARGB(182, 208, 89, 129)),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        //Hesabı veritabanından siler
                        _showDeleteAccountDialog();
                      },
                      child: const Text(
                        "Hesabı Sil",
                        style:
                            TextStyle(color: Color.fromARGB(182, 208, 89, 129)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget buildTextContainer(String text) {
    return Container(
      padding: const EdgeInsets.all(10.0),
      width: 280.0,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16),
      ),
    );
  }
}

class ThemeSettingsPage extends StatelessWidget {
  //Tema ayarları kodları.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Tema Ayarları',
      ),
      body: Column(
        children: [
          RadioListTile<ThemeMode>(
            title: const Text('Aydınlık Mod'),
            value: ThemeMode.light,
            groupValue: Provider.of<ThemeProvider>(context).themeMode,
            onChanged: (ThemeMode? value) {
              if (value != null) {
                Provider.of<ThemeProvider>(context, listen: false)
                    .setThemeMode(value);
                Navigator.pop(context);
              }
            },
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Sistem Modu'),
            value: ThemeMode.system,
            groupValue: Provider.of<ThemeProvider>(context).themeMode,
            onChanged: (ThemeMode? value) {
              if (value != null) {
                Provider.of<ThemeProvider>(context, listen: false)
                    .setThemeMode(value);
                Navigator.pop(context);
              }
            },
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Karanlık Mod'),
            value: ThemeMode.dark,
            groupValue: Provider.of<ThemeProvider>(context).themeMode,
            onChanged: (ThemeMode? value) {
              if (value != null) {
                Provider.of<ThemeProvider>(context, listen: false)
                    .setThemeMode(value);
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }
}

class AppInfoPage extends StatelessWidget {
  //Uygulama hakkında kodları bu veriyi veritabanından çekiyoruz.
  const AppInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Uygulama Hakkında',
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future:
            FirebaseFirestore.instance.collection('appInfo').doc('info').get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Bir hata oluştu: ${snapshot.error}'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Veri bulunamadı.'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final info = data['info'] ?? 'Bilgi mevcut değil';

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              info,
              style: const TextStyle(fontSize: 16),
            ),
          );
        },
      ),
    );
  }
}
//Şifre değiştirme kodları

class ChangePasswordDialog extends StatefulWidget {
  final FirebaseAuth auth;

  ChangePasswordDialog({required this.auth});

  @override
  _ChangePasswordDialogState createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Şifre Değiştir"),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _currentPasswordController,
              decoration: const InputDecoration(
                labelText: "Mevcut Şifre",
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Mevcut şifreyi girin";
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _newPasswordController,
              decoration: const InputDecoration(
                labelText: "Yeni Şifre",
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              validator: (value) {
                if (value == null || value.length < 6) {
                  return "Yeni şifre en az 6 karakter olmalı";
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text("İptal"),
        ),
        TextButton(
          onPressed: _isLoading ? null : _changePassword,
          child: _isLoading
              ? const CircularProgressIndicator()
              : const Text("Değiştir"),
        ),
      ],
    );
  }

  Future<void> _changePassword() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        User? user = widget.auth.currentUser;
        if (user != null) {
          String email = user.email!;
          String currentPassword = _currentPasswordController.text;
          String newPassword = _newPasswordController.text;

          // Kullanıcıyı yeniden doğrula
          AuthCredential credential = EmailAuthProvider.credential(
              email: email, password: currentPassword);
          await user.reauthenticateWithCredential(credential);

          // Şifreyi güncelle
          await user.updatePassword(newPassword);

          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Şifre başarıyla değiştirildi")));
          Navigator.of(context).pop();
        }
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Hata: ${e.toString()}")));
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

//Ad, soyad ve eposta kısımlarını veritabanında güncelleyen kodlar.
class EditNameDialog extends StatefulWidget {
  final String currentFirstName;
  final String currentLastName;
  final String currentEmail;
  final void Function(String, String, String) onUpdate;

  const EditNameDialog({
    required this.currentFirstName,
    required this.currentLastName,
    required this.currentEmail,
    required this.onUpdate,
  });

  @override
  _EditNameDialogState createState() => _EditNameDialogState();
}

class _EditNameDialogState extends State<EditNameDialog> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.currentFirstName);
    _lastNameController = TextEditingController(text: widget.currentLastName);
    _emailController = TextEditingController(text: widget.currentEmail);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Düzenle'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _firstNameController,
            decoration: const InputDecoration(labelText: 'Ad'),
          ),
          TextField(
            controller: _lastNameController,
            decoration: const InputDecoration(labelText: 'Soyad'),
          ),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'E-posta'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            widget.onUpdate(
              _firstNameController.text,
              _lastNameController.text,
              _emailController.text,
            );
            Navigator.of(context).pop();
          },
          child: const Text('Kaydet'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('İptal'),
        ),
      ],
    );
  }
}
