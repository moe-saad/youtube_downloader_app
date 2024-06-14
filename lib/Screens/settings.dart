import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreend extends StatefulWidget {
  static const screenRoute = 'settingsScreen';

  const SettingsScreend({
    super.key,
  });

  @override
  State<SettingsScreend> createState() => _SettingsScreendState();
}

class _SettingsScreendState extends State<SettingsScreend> {
  late String _savePathkey;
  late Function getSaveFolder;
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  Future<String?> loadDownloadLocation() async {
    final SharedPreferences prefs = await _prefs;
    return prefs.getString(_savePathkey);
  }

  @override
  Widget build(BuildContext context) {
    Map<dynamic, dynamic>? arguments =
        ModalRoute.of(context)!.settings.arguments as Map;
    _savePathkey = arguments['savePathKey'];
    getSaveFolder = arguments['getuserpath'];
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
          List<Widget> children;
          if (snapshot.hasError) {
            children = <Widget>[
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 60,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text('Error: ${snapshot.error}'),
              ),
            ];
          } else {
            children = <Widget>[
              //show the current path
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
                  '${snapshot.data}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                trailing: TextButton(
                  onPressed: () async {
                    String newpath = await getSaveFolder();
                    final SharedPreferences prefs = await _prefs;
                    setState(() {
                      prefs.setString(_savePathkey, newpath);
                    });
                  },
                  child: const Text('Change'),
                ),
              ),

              Platform.isAndroid
                  ? ElevatedButton(
                      onPressed: () {
                        openAppSettings();
                      },
                      child: const Text('open app settings'),
                    )
                  : const SizedBox.shrink(),
            ];
          }
          // return Flexible(
          //   child: FractionallySizedBox(
          //     widthFactor: 0.5,
          //     heightFactor: 1,
          //     child: Column(
          //       mainAxisAlignment: MainAxisAlignment.start,
          //       children: children,
          //     ),
          //   ),
          // );
          return Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: children,
          );
        },
      ),
    );
  }
}
