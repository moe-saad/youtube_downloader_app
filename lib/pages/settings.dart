import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  static const screenRoute = 'settingsScreen';

  const SettingsScreen({
    super.key,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreendState();
}

class _SettingsScreendState extends State<SettingsScreen> {
  late String _savePathKey;
  late Function getSaveFolder;
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  Future<String?> loadDownloadLocation() async {
    final SharedPreferences prefs = await _prefs;
    return prefs.getString(_savePathKey);
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    Map<dynamic, dynamic>? arguments =
        ModalRoute.of(context)!.settings.arguments as Map?;
    if (arguments != null) {
      _savePathKey = arguments['savePathKey'];
      getSaveFolder = arguments['getuserpath'];
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
        ),
        centerTitle: true,
        elevation: 12.0,
      ),
      body: FutureBuilder(
        future: loadDownloadLocation(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 60,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text('Error: ${snapshot.error}'),
                  ),
                ],
              ),
            );
          } else {
            return Center(
              child: FractionallySizedBox(
                widthFactor: screenSize.width < 700 ? 1 : 0.5,
                heightFactor: 1,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    // Show the current path
                    ListTile(
                      leading: Icon(
                        Icons.download,
                        color: Theme.of(context).primaryColor,
                      ),
                      title: Text(
                        'Download Location',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      subtitle: Text(
                        snapshot.data ?? 'Not set',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      trailing: TextButton(
                        onPressed: () async {
                          try {
                            String newpath = await getSaveFolder();
                            final SharedPreferences prefs = await _prefs;
                            setState(() {
                              prefs.setString(_savePathKey, newpath);
                            });
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: ${e.toString()}'),
                              ),
                            );
                          }
                        },
                        child: const Text('Change'),
                      ),
                    ),
                    if (Platform.isAndroid)
                      ElevatedButton(
                        onPressed: () {
                          openAppSettings();
                        },
                        child: const Text('Open app settings'),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Text(
                        'Note: To avoid potential errors, please refrain from saving your files in system folders such as Documents or Downloads. Instead, create and use a dedicated folder for your files.',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
