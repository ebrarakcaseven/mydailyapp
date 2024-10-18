import 'package:flutter/material.dart';
import 'package:mydailyapp/pages/homepage.dart';
import 'package:mydailyapp/service/authservice.dart';
import 'package:mydailyapp/user/signup.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Container(
          margin: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _header(context),
              _inputField(context),
              _forgotPassword(context),
              _signup(context),
            ],
          ),
        ),
      ),
    );
  }

  _header(context) {
    return const Column(
      children: [
        Text(
          "Hoş Geldin",
          style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  _inputField(context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _emailController,
          decoration: InputDecoration(
              hintText: "Eposta",
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none),
              fillColor:
                  const Color.fromARGB(77, 208, 89, 129).withOpacity(0.1),
              filled: true,
              prefixIcon: const Icon(Icons.person)),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _passwordController,
          decoration: InputDecoration(
            hintText: "Şifre",
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none),
            fillColor: const Color.fromARGB(77, 208, 89, 129).withOpacity(0.1),
            filled: true,
            prefixIcon: const Icon(Icons.password),
          ),
          obscureText: true,
        ),
        if (_errorMessage != null) ...[
          const SizedBox(
            height: 20,
          ),
          Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.red),
          )
        ],
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () async {
            try {
              await Provider.of<AuthService>(context, listen: false)
                  .signIn(_emailController.text, _passwordController.text);
              setState(() {
                _errorMessage = null;
              });
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) => const Homepage()));
            } catch (e) {
              setState(() {
                _errorMessage = e.toString();
              });
            }
          },
          style: ElevatedButton.styleFrom(
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: const Color.fromARGB(255, 236, 229, 238),
          ),
          child: Text(
            "Giriş",
            style: TextStyle(color: Colors.grey[700], fontSize: 20),
          ),
        )
      ],
    );
  }

  _forgotPassword(context) {
    return TextButton(
      onPressed: () {}, //Tıklandığında şifre kurtrma adımları yapılmalı.
      child: const Text(
        "Şifremi Unuttum",
        style: TextStyle(color: Color.fromARGB(182, 208, 89, 129)),
      ),
    );
  }

  _signup(context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Hesabın Yok Mu? "),
        TextButton(
            onPressed: () {
              //Yeni hesap oluşturmak için kayıt ol sayfasına yönlendirir.
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SignupPage()),
              );
            },
            child: const Text(
              "Kayıt Ol",
              style: TextStyle(color: Color.fromARGB(182, 208, 89, 129)),
            ))
      ],
    );
  }
}
