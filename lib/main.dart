import 'package:flutter/material.dart';
import 'package:youtube_downloader_app/pages/home.dart';
import 'package:youtube_downloader_app/pages/settings.dart';

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
        elevatedButtonTheme: const ElevatedButtonThemeData(
          style: ButtonStyle(
            fixedSize: WidgetStatePropertyAll(Size.fromWidth(200)),
            padding: WidgetStatePropertyAll(
              EdgeInsets.symmetric(vertical: 5),
            ),
          ),
        ),
      ),
      home: Home(),
      routes: {
        SettingsScreend.screenRoute: (context) => SettingsScreend(),
      },
    );
  }
}
