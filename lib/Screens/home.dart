import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:youtube_downloader_app/Screens/settings.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'dart:io';

class Home extends StatefulWidget {
  static const screenRoute = 'homeScreen';
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  //variables declaration
  //https://youtu.be/HwWb5xelC7s?si=QDdzOWoSdeJ5uqYH
  String videoURL = '';
  String? _savePath;
  double _progress = 0.0;
  bool _isDownloading = false;
  final TextEditingController _controller = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

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
                } else {
                  // Show some message if needed
                  print('\nstill without connection\n');
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
  Future<bool> checkConnection() async {
    bool isConnected = await hasInternetConnection();
    if (!isConnected) {
      showNoInternetDialog(context);
    }
    return isConnected;
  }

//get the directory path from the user
  Future<String?> _getUserSavePath() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

    if (selectedDirectory != null) {
      return selectedDirectory;
    } else {
      // User canceled the picker
      throw UnsupportedError("User canceled the picker");
    }
  }

//request permission if it's not granted
  Future<void> requestPermission() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }
  }

  void _updateProgress(double progress) {
    setState(() {
      _progress = progress;
    });
  }

  void _showToastmessage(String message) {
    Platform.isAndroid
        ? Fluttertoast.showToast(
            msg: message,
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.black,
            textColor: Colors.white,
            fontSize: 16.0,
          )
        : null;
  }

  //function to download the video
  void _downloadFunction(String? url) async {
    setState(() {
      //to show the progress bar
      _isDownloading = true;
      // Reset progress to 0 at the beginning of the download
      _progress = 0.0;
    });
    try {
      var ytExplode = YoutubeExplode();
      var video = await ytExplode.videos.get(url);

      print('\n--------------------manifest-------------------------\n');
      var manifest = await ytExplode.videos.streamsClient.getManifest(url);
      print(manifest);

      // print('\n-----------------------streamInfo----------------------\n');
      var streamInfo = manifest.audioOnly.first;

      // var bestAudio = manifest.audioOnly.sortByBitrate().last;
      // print(streamInfo.audioCodec + '\n');
      // print(streamInfo.audioTrack);
      // print(bestAudio.bitrate);
      // print(streamInfo.codec);
      // print(streamInfo.container);
      // print(streamInfo.fragments);
      // print(streamInfo.qualityLabel);
      // print(streamInfo.size);
      // print(streamInfo.tag);
      // print(streamInfo.url);
      // print(streamInfo.videoId);

      // Get the actual stream
      var stream = ytExplode.videos.streamsClient.get(streamInfo);

      if (await Permission.storage.request().isGranted) {
        // Either the permission was already granted before or the user just granted it.
        print('\n-----------------------savePath----------------------\n');

        //android
        if (Platform.isAndroid) {
          _savePath = '/storage/emulated/0/Download/${video.title}.mp3';
        }

        //windows
        else if (Platform.isWindows) {
          _savePath = await _getUserSavePath();
          _savePath = '${_savePath!}\\${video.title}.mp3';
        }
        print(_savePath);
        //open the file
        var fileStream = File(_savePath!).openWrite(mode: FileMode.append);

        var totalBytes = streamInfo.size.totalBytes;
        var downloadedBytes = 0;

        await for (var data in stream) {
          downloadedBytes += data.length;
          fileStream.add(data);
          double progress = downloadedBytes / totalBytes;
          _updateProgress(progress);
        }

        // Pipe all the content of the stream into the file.
        await stream.pipe(fileStream);
        _showToastmessage('Download Complete: ${video.title}');
        // Close the file.
        await fileStream.flush();
        await fileStream.close();
      } else {
        // The permission was denied or not yet requested.
        requestPermission();
      }
    } catch (e) {
      _showToastmessage('Download Failed: ${e.toString()}');
      print(e.toString());
    } finally {
      setState(() {
        _isDownloading = false;
      });
    }
  }

  bool isValidYouTubeUrl(String url) {
    final youtubeRegex = RegExp(
      r'^(https?\:\/\/)?(www\.youtube\.com|youtu\.?be)\/.+$',
      caseSensitive: false,
      multiLine: false,
    );
    return youtubeRegex.hasMatch(url);
  }

//initial state to check internet connection at the startup of the app
  @override
  void initState() {
    super.initState();
    checkConnection();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Youtube Downloader',
          style: TextStyle(
              color: Theme.of(context).primaryTextTheme.titleLarge!.color),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 3,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, SettingsScreend.screenRoute);
            },
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 20.0, left: 15, right: 15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Youtube URL',
              style: TextStyle(
                fontSize: 16,
              ),
            ),
            const SizedBox(
              height: 15.0,
            ),
            Form(
              key: _formKey,
              child: Column(
                children: <Widget>[
                  TextFormField(
                    controller: _controller,
                    keyboardType: TextInputType.url,
                    decoration: InputDecoration(
                      hintText: 'Paste Youtube URL Here',
                      icon: const Icon(Icons.link_rounded),
                      iconColor: Theme.of(context).primaryColor,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'This field is required';
                      } else if (!isValidYouTubeUrl(value)) {
                        return 'Please enter a valid YouTube URL';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      videoURL = value;
                    },
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Visibility(
                    visible: _isDownloading,
                    child: Column(
                      children: [
                        LinearProgressIndicator(value: _progress),
                        const SizedBox(height: 20),
                        Text('${(_progress * 100).toStringAsFixed(0)}%'),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        if (await checkConnection()) {
                          _downloadFunction(videoURL);
                        }
                      }
                    },
                    child: const Text('Download'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
