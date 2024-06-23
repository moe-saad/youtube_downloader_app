import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';

//return true of false based on internet connection
Future<bool> hasInternetConnection() async {
  var connectivityResult = await (Connectivity().checkConnectivity());
  if (connectivityResult.first == ConnectivityResult.mobile ||
      connectivityResult.first == ConnectivityResult.wifi) {
    return true;
  }
  return false;
}

//show AlertDialog when no internet connection
void showNoInternetDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('No Internet Connection'),
        content: const Text('Please connect to the internet and try again.'),
        actions: <Widget>[
          TextButton(
            child: const Text('Try Again'),
            onPressed: () async {
              bool isConnected = await hasInternetConnection();
              if (isConnected) {
                Navigator.of(context).pop(); // Close the dialog
              }
            },
          ),
          TextButton(
            child: const Text('Exit'),
            onPressed: () {
              SystemNavigator.pop(); // Exit the app
            },
          ),
        ],
      );
    },
  );
}

//check internet Connection
Future<bool> checkConnection(BuildContext ctx) async {
  bool isConnected = await hasInternetConnection();
  if (!isConnected) {
    showNoInternetDialog(ctx);
  }
  return isConnected;
}

void showToastmessage(BuildContext ctx, String message) {
  Platform.isAndroid
      ? Fluttertoast.showToast(
          msg: message,
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.white,
          textColor: Theme.of(ctx).primaryColor,
          fontSize: 16.0,
        )
      : null;
}

bool isValidYouTubeUrl(String url) {
  final youtubeRegex = RegExp(
    r'^(https?\:\/\/)?(www\.)?(youtube\.com|music\.youtube\.com|youtu\.be)\/.+$',
    caseSensitive: false,
    multiLine: false,
  );
  return youtubeRegex.hasMatch(url);
}

//get the directory path from the user
Future<String> getUserSavePath() async {
  String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

  if (selectedDirectory != null) {
    return selectedDirectory;
  } else {
    // User canceled the picker
    throw 'user canceled file picking';
  }
}

//this function to show only the hours,minutes,seconds of the duration video
String formatDuration(String durationString) {
  // Split the duration string by the colon
  List<String> parts = durationString.split(':');

  // Extract hours, minutes, and seconds
  String hours = parts[0].padLeft(2, '0');
  String minutes = parts[1].padLeft(2, '0');
  String seconds = parts[2].split('.')[0].padLeft(2, '0');

  // Combine hours, minutes, and seconds into the desired format
  return '$hours:$minutes:$seconds';
}

String sanitizeFileName(String input) {
  // Characters that are not allowed in file names on Windows or Android
  final invalidChars = RegExp(r'[\\/*?:"<>|\.]');

  // Replace all invalid characters with an empty string
  return input.replaceAll(invalidChars, '');
}

Future<void> cleanupFile(String savePath) async {
  try {
    var file = File(savePath);
    if (await file.exists()) {
      await file.delete();
    }
  } catch (e) {
    throw 'error while deleting the file ${e.toString()}';
  }
}
