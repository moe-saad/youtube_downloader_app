import 'package:flutter/material.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Youtube Downloader'),
      ),
      body: const Center(
        child: Text('just a test'),
      ),
    );
  }
}
