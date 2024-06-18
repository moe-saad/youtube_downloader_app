import 'package:flutter/material.dart';

class WarningDialog extends StatelessWidget {
  final String title;

  final String content;

  const WarningDialog({super.key, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(
        Icons.warning,
      ),
      iconColor: Colors.red,
      title: Text(title),
      titleTextStyle: const TextStyle(
        fontSize: 20.0,
        fontWeight: FontWeight.bold,
      ),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Ok'),
        ),
      ],
    );
  }
}
