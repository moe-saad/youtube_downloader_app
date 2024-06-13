import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class SettingsScreend extends StatelessWidget {
  static const screenRoute = 'settingsScreen';
  // final String? savePath;
  const SettingsScreend({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        elevation: 12.0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            //title
            const Text('Download Folder:'),
            //show the current path
            const Text('save path here'),
            //change path button
            ElevatedButton(
              onPressed: () {},
              child: const Text('change path'),
            ),
            ElevatedButton(
              onPressed: () {
                openAppSettings();
              },
              child: const Text('open app settings'),
            ),
          ],
        ),
      ),
    );
  }
}
