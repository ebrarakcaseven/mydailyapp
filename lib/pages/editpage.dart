import 'package:flutter/material.dart';
import 'package:mydailyapp/top/appbar.dart';

class EditPage extends StatefulWidget {
  final String initialData;

  EditPage({required this.initialData});

  @override
  _EditPageState createState() => _EditPageState();
}

class _EditPageState extends State<EditPage> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialData);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: CustomAppBar(
          title: "Düzenle",
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  minLines: null,
                  maxLines: null,
                  controller: _controller,
                  decoration: const InputDecoration(
                    enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                      color: Colors.black,
                      width: 1.5,
                    )),
                    border: OutlineInputBorder(),
                    labelText: 'Veriyi düzenleyin',
                  ),
                ),
                const SizedBox(height: 15),
                ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(_controller.text);
                    },
                    child: const Text(
                      "kaydet",
                      style: TextStyle(color: Colors.black),
                    ))
              ],
            ),
          ),
        ));
  }
}
