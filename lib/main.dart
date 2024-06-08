import 'package:flutter/material.dart';
import 'package:youtube_downloader_app/Screens/home.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'YouTube Downloader',
      theme: ThemeData(
        appBarTheme: const AppBarTheme(
          actionsIconTheme: IconThemeData(
            color: Colors.white,
          ),
        ),
      ),
      home: Home(),
    );
  }
}
