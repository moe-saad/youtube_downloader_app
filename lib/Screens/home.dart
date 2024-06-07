import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'dart:io';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  //variables declaration
  //https://youtu.be/HwWb5xelC7s?si=QDdzOWoSdeJ5uqYH
  String videoURL = '';
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

  //function to download the video
  void _downloadVideo(String? url) async {
    var ytExplode = YoutubeExplode();
    var video = await ytExplode.videos.get(url);
    // Get user chosen save path
    String? savePath = await _getUserSavePath();

    print('\n--------------------manifest-------------------------\n');
    var manifest = await ytExplode.videos.streamsClient.getManifest(url);
    print(manifest);

    print('\n-----------------------streamInfo----------------------\n');
//select audio only here
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

    print('\n-----------------------savePath----------------------\n');
//android
    if (Platform.isAndroid) {
      savePath = savePath! + '/${video.title}.mp3';
    }
    //windows
    else if (Platform.isWindows) {
      savePath = savePath! + '\\${video.title}.mp3';
    }
    //open a file for writing
    // final Directory? downloadsDir = await getDownloadsDirectory();
    // final savePath = '${downloadsDir!.path}/${video.title}.mp3';

    print(savePath);
    print('\n---------------------------------------------\n');

    var status = await Permission.storage.status;
    print(status);
    if (status.isDenied) {
      if (await Permission.storage.request().isGranted) {
        //permission granted
        //open the file
        var fileStream = File(savePath!).openWrite(mode: FileMode.append);

        // Pipe all the content of the stream into the file.
        await stream.pipe(fileStream);

        // Close the file.
        await fileStream.flush();
        await fileStream.close();
      } else {
        //permission denied
        print('permission denied');
      }
    } else {
      //open the file
      var fileStream = File(savePath!).openWrite(mode: FileMode.append);

      // Pipe all the content of the stream into the file.
      await stream.pipe(fileStream);

      // Close the file.
      await fileStream.flush();
      await fileStream.close();
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
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Enter Youtube URL',
              style: TextStyle(
                fontSize: 16,
              ),
            ),
            const SizedBox(
              height: 20.0,
            ),
            Form(
              key: _formKey,
              child: Column(
                children: <Widget>[
                  SizedBox(
                    width: 300,
                    child: TextFormField(
                      controller: _controller,
                      initialValue:
                          'https://www.youtube.com/watch?v=HwWb5xelC7s',
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
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        if (await checkConnection()) {
                          _downloadVideo(videoURL);
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
