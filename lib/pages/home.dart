import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youtube_downloader_app/pages/settings.dart';
import 'package:youtube_downloader_app/widgets/audio_item.dart';
import 'package:youtube_downloader_app/widgets/video_item.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'dart:io';
import '../utils/methods.dart';

enum MediaType { audio, video }

class Home extends StatefulWidget {
  static const screenRoute = 'homeScreen';
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final String _savePathKey = 'savePath'; //shared preferences key for the
  //location of the download folder
  String videoURL = ''; //youtube video url
  String? _savePath;
  double _progress = 0.0; //downloading progress
  bool _isDownloading = false;
  bool _isLoading = false;
  YoutubeExplode ytExplode = YoutubeExplode();
  Video? video; //video instance when fetched from youtube
  final TextEditingController _controller =
      TextEditingController(); //controller for textInput
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>(); //form key
  // the default selected radio button
  MediaType? _selectedMediaType = MediaType.audio;
  List<AudioOnlyStreamInfo> _audioList = []; //list of audios
  List<MuxedStreamInfo> _videoList = []; //list of videos
  final Future<SharedPreferences> _sharedPref = SharedPreferences.getInstance();
  //toggle button list to specify which button is selected
  final List<bool> _selections = [true, false];

  Future<void> loadVideoInfo(String url) async {
    try {
      video = await ytExplode.videos.get(url);
      //call the manifest
      var manifest = await ytExplode.videos.streamsClient.getManifest(url);
      _audioList = manifest.audioOnly.toList();
      _videoList = manifest.muxed.toList();

      setState(() {
        _isLoading = true;
      });
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            icon: const Icon(
              Icons.error,
              color: Colors.red,
              size: 50,
            ),
            title: const Text('Invalid Youtube URL'),
            content: const Text(
                'please check if this url reffere to a Youtube Video not a playlist,not a live Stream  or others'),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  child: const Text('OK'))
            ],
          );
        },
      );
    }
  }

  void _updateProgress(double progress) {
    setState(() {
      _progress = progress;
    });
  }

//initial state to check internet connection at the startup of the app
  @override
  void initState() {
    super.initState();
    checkConnection(context);
    _isLoading = false;
  }

  Future<void> downloadFunction(String itemtype, StreamInfo streamInfo) async {
    setState(() {
      //to show the progress bar
      _isDownloading = true;
      // Reset progress to 0 at the beginning of the download
      _progress = 0.0;
    });
    try {
      // Get the actual stream
      var stream = ytExplode.videos.streamsClient.get(streamInfo);

      if (await Permission.storage.request().isGranted) {
        // Either the permission was already granted before or the user just granted it.
        SharedPreferences sharedPref = await _sharedPref;
        if (sharedPref.getString(_savePathKey) == null) {
          _savePath = await getUserSavePath();
          sharedPref.setString(_savePathKey, _savePath!);
        } else {
          _savePath = sharedPref.getString(_savePathKey);
        }

        if (Platform.isAndroid) {
          _savePath = '$_savePath/${sanitizeFileName(video!.title)}.$itemtype';
        }

        //windows
        else if (Platform.isWindows) {
          _savePath =
              '${_savePath!}\\${sanitizeFileName(video!.title)}.$itemtype';
        }

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

        showToastmessage(context, 'Download Complete: ${video!.title}');

        // Close the file.
        await fileStream.flush();
        await fileStream.close();
      } else {
        // The permission was denied or not yet requested.
        requestPermission();
      }
    } catch (e) {
      showToastmessage(context, 'Download Failed: ${e.toString()}');
      if (kDebugMode) {
        print('\n----------------------catch error----------------------\n');
      }
      if (kDebugMode) {
        print(e.toString());
      }
    }
    //finally
    finally {
      setState(() {
        _isDownloading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    //TextStyle of primary text
    TextStyle primaryText = TextStyle(
        color: Theme.of(context).primaryColor,
        fontSize: screenSize.width < 600 ? 20 : 25);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Youtube Downloader',
          style: TextStyle(
              color: Theme.of(context).primaryTextTheme.titleLarge!.color),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        centerTitle: true,
        shadowColor: Theme.of(context).primaryColor,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, SettingsScreend.screenRoute,
                  arguments: {
                    'savePathKey': _savePathKey,
                    'getuserpath': getUserSavePath,
                  });
            },
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(top: 20.0, left: 15, right: 15.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                        suffix: IconButton(
                          onPressed: () {
                            setState(() {
                              _controller.clear();
                              _isLoading = false;
                              _audioList.clear();
                              _videoList.clear();
                              video = null;
                            });
                          },
                          icon: const Icon(
                            Icons.cleaning_services_outlined,
                            color: Colors.deepPurple,
                          ),
                        ),
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
                    //progress line indicator shown only when downloading
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
                          if (await checkConnection(context)) {
                            loadVideoInfo(videoURL);
                          }
                        }
                      },
                      child: Text(
                        'Search',
                        style: primaryText,
                      ),
                    ),
                    FilledButton(
                      onPressed: () {},
                      child: const Text('Cancel Download'),
                    ),
                  ],
                ),
              ),
              //load video info
              const SizedBox(
                height: 20.0,
              ),
              _isLoading
                  ? LayoutBuilder(
                      builder: (context, constraints) {
                        List<Widget> children = [
                          Image.network(
                            video!.thumbnails.highResUrl,
                            height: 200,
                          ),
                          Padding(
                            padding: const EdgeInsets.all(18.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  video!.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: primaryText,
                                ),
                                Text(
                                  video!.author,
                                  style: const TextStyle(
                                    fontSize: 18,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.remove_red_eye,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                    const SizedBox(
                                      width: 8.0,
                                    ),
                                    Text(
                                      ' ${video!.engagement.viewCount.toString().trim()}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                    const SizedBox(
                                      width: 8.0,
                                    ),
                                    Text(
                                      formatDuration(
                                        video!.duration.toString(),
                                      ),
                                      style: const TextStyle(
                                        fontSize: 18,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )
                        ];

                        return Container(
                          alignment: Alignment.topLeft,
                          // decoration: BoxDecoration(
                          //   border: Border.all(color: Colors.black),
                          // ),
                          child: screenSize.width < 600
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: children,
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: children,
                                ),
                        );
                      },
                    )
                  : const SizedBox.shrink(),

              const Divider(),
              // Row(
              //   children: [
              //     Expanded(
              //       flex: 1,
              //       child: ListTile(
              //         title: const Text('Audio'),
              //         leading: Radio<MediaType>(
              //           value: MediaType.audio,
              //           groupValue: _selectedMediaType,
              //           onChanged: (MediaType? value) {
              //             setState(() {
              //               _selectedMediaType = value;
              //             });
              //           },
              //         ),
              //       ),
              //     ),
              //     Expanded(
              //       flex: 1,
              //       child: ListTile(
              //         title: const Text('Video'),
              //         leading: Radio<MediaType>(
              //           value: MediaType.video,
              //           groupValue: _selectedMediaType,
              //           onChanged: (MediaType? value) {
              //             setState(() {
              //               _selectedMediaType = value;
              //             });
              //           },
              //         ),
              //       ),
              //     ),
              //   ],
              // ),
              Center(
                child: ToggleButtons(
                  borderRadius: BorderRadius.circular(30.0),
                  isSelected: _selections,
                  selectedColor: Colors.white,
                  fillColor: Theme.of(context).primaryColor,
                  color: Colors.black,
                  children: const [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.0),
                      child: Text('Audio'),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.0),
                      child: Text('Video'),
                    ),
                  ],
                  onPressed: (int index) {
                    setState(() {
                      for (int i = 0; i < _selections.length; i++) {
                        _selections[i] = i == index;
                        _selectedMediaType = MediaType.values[index];
                      }

                      print(_selectedMediaType);
                    });
                  },
                ),
              ),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _selectedMediaType == MediaType.audio
                    ? _audioList.length
                    : _videoList.length,
                itemBuilder: (context, index) {
                  return _selectedMediaType == MediaType.audio
                      ? AudioItem(
                          audio: _audioList[index],
                          saveAudio: downloadFunction,
                        )
                      : VideoItem(
                          video: _videoList[index],
                          saveVideo: downloadFunction,
                        );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
