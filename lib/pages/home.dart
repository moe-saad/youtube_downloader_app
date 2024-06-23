import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youtube_downloader_app/pages/settings.dart';
import 'package:youtube_downloader_app/widgets/audio_item.dart';
import 'package:youtube_downloader_app/widgets/video_item.dart';
import 'package:youtube_downloader_app/widgets/warning_dialog.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../utils/methods.dart';

enum MediaType { audio, video }

class Home extends StatefulWidget {
  static const screenRoute = 'homeScreen';
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  //shared preferences key for the location of the download folder
  final String _savePathKey = 'savePath';
  //youtube video url
  String videoURL = '';
  late StreamSubscription _intentSub;
  var _sharedFiles = <SharedMediaFile>[];
  //save path is where the downloaded file should be saved
  late String _savePath;
  //downloading progress
  double _progress = 0.0;
  bool _isDownloading = false;
  YoutubeExplode ytExplode = YoutubeExplode();
  //video instance when fetched from youtube
  Video? video;
  //controller for textInput
  final TextEditingController _controller = TextEditingController();
  //form key the default selected radio buttons
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  MediaType? _selectedMediaType = MediaType.audio;
  //list of audios
  List<AudioOnlyStreamInfo> _audioList = [];
  //list of videos
  List<MuxedStreamInfo> _videoList = [];
  final Future<SharedPreferences> _sharedPref = SharedPreferences.getInstance();
  //toggle button list to specify which button is selected
  final List<bool> _selections = [true, false];
  Future<StreamManifest>? _future;
  StreamSubscription<List<int>>? subscription;
  IOSink? _fileStream;

  Future<StreamManifest> loadVideoInfo(String url, BuildContext ctx) async {
    try {
      video = await ytExplode.videos.get(url);
      //call the manifest
      var manifest = await ytExplode.videos.streamsClient.getManifest(url);
      _audioList = manifest.audioOnly.toList();
      _videoList = manifest.muxed.toList();

      //setstate to make the audio and video lists shown when the information are ready
      setState(() {});
      return manifest;
    } catch (e) {
      throw e.toString();
    }
  }

  void _updateProgress(double progress) {
    setState(() {
      _progress = progress;
    });
  }

  void _pasteText() async {
    ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null) {
      setState(() {
        _controller.text = data.text!;
      });
    }
  }

//initial state to check internet connection at the startup of the app
  @override
  void initState() {
    super.initState();
    checkConnection(context);
    // Listen to media sharing coming from outside the app while the app is in the memory.
    _intentSub = ReceiveSharingIntent.instance.getMediaStream().listen(
        (List<SharedMediaFile> value) {
      WidgetsBinding.instance.addPostFrameCallback((_) => setState(() {
            _sharedFiles = value;
            if (_sharedFiles.isNotEmpty) {
              _controller.text = _sharedFiles.first.path;
            }
            print(_sharedFiles.map((f) => f.toMap()).toString());
          }));
    }, onError: (err) {
      print("getIntentDataStream error: $err");
    });

    // Get the media sharing coming from outside the app while the app is closed.
    ReceiveSharingIntent.instance.getInitialMedia().then((value) {
      WidgetsBinding.instance.addPostFrameCallback((_) => setState(() {
            _sharedFiles = value;
            if (_sharedFiles.isNotEmpty) {
              _controller.text = _sharedFiles.first.path;
            }
            print(_sharedFiles.map((f) => f.toMap()).toString());

            // Tell the library that we are done processing the intent
            ReceiveSharingIntent.instance.reset();
          }));
    });
  }

  @override
  void dispose() {
    _intentSub.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> downloadFunction(String itemtype, StreamInfo streamInfo) async {
    if (await Permission.storage.request().isGranted) {
      setState(() {
        //to show the progress bar
        _isDownloading = true;

        // Reset progress to 0 at the beginning of the download
        _progress = 0.0;
      });
      try {
        // Get the actual stream
        var stream = ytExplode.videos.streamsClient.get(streamInfo);

        // Either the permission was already granted before or the user just granted it.
        SharedPreferences sharedPref = await _sharedPref;
        if (sharedPref.getString(_savePathKey) == null) {
          _savePath = await getUserSavePath();
          sharedPref.setString(_savePathKey, _savePath);
        } else {
          _savePath = sharedPref.getString(_savePathKey)!;
        }

        _savePath = path.join(_savePath,
            '${sanitizeFileName('${video!.title}-${streamInfo.bitrate}').trim()}.$itemtype');

        //open the file
        _fileStream = File(_savePath).openWrite(mode: FileMode.append);
        var totalBytes = streamInfo.size.totalBytes;
        var downloadedBytes = 0;

        // Create a StreamSubscription to handle the stream
        subscription = stream.listen(
          (data) {
            downloadedBytes += data.length;
            _fileStream!.add(data);
            double progress = downloadedBytes / totalBytes;
            _updateProgress(progress);
          },
          onError: (error) {
            // Handle the stream error
            throw Exception('Data connection lost: $error');
          },
          cancelOnError: true, // Cancel the subscription on error
        );

        // Wait for the subscription to complete
        await subscription!.asFuture();

        //show snack bar about downloading status
        downloadedBytes == totalBytes
            ? ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Download Finished'),
                ),
              )
            : ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Download Failed'),
                ),
              );

        // Close the file.
        await _fileStream!.flush();
        await _fileStream!.close();
      } catch (e) {
        throw e.toString();
      }
      //finally
      finally {
        setState(() {
          _isDownloading = false;

          subscription = null;
          _fileStream = null;
        });
      }
    } else {
      // The permission was denied
      showDialog(
        context: context,
        builder: (context) {
          return const WarningDialog(
              title: 'Permission Denied',
              content: 'Storage permission is required to save your Downloads');
        },
      );
    }
  }

  Future<void> _cancelDownload() async {
    await subscription?.cancel();
    await _fileStream?.flush();
    await _fileStream?.close();
    await cleanupFile(_savePath);
    setState(() {
      subscription = null;
      _fileStream = null;
    });
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
              Navigator.pushNamed(context, SettingsScreen.screenRoute,
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
                        suffix: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            IconButton(
                              onPressed: _pasteText,
                              icon: const Icon(
                                Icons.paste_rounded,
                                color: Colors.deepPurple,
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _controller.clear();
                                });
                              },
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.deepPurple,
                              ),
                            ),
                          ],
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
                    FilledButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          if (await checkConnection(context)) {
                            setState(() {
                              _future = loadVideoInfo(videoURL, context);
                            });
                          }
                        }
                      },
                      child: const Text(
                        'Search',
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (subscription != null) {
                          await _cancelDownload();
                          setState(() {
                            _isDownloading = false;
                          });
                        }
                      },
                      child: const Text('Cancel Download'),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 20.0,
              ),

              //load video info
              FutureBuilder(
                future: _future,
                builder: (context, snapshot) {
                  List<Widget> childrenlist;
                  if (snapshot.hasData) {
                    childrenlist = [
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
                            //view count
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
                            //video duration
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
                      ),
                    ];
                  } else if (snapshot.hasError) {
                    showDialog(
                      barrierDismissible: true,
                      context: context,
                      builder: (context) => const WarningDialog(
                          title: 'some Error(s) Occured',
                          content:
                              'Please check your internet connection or you are using a valid Youutbe URL'),
                    );
                    childrenlist = [];
                  } else if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    childrenlist = [
                      const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ];
                  } else {
                    childrenlist = [];
                  }
                  return screenSize.width < 600
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: childrenlist,
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: childrenlist,
                        );
                },
              ),

              // const Divider(),

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
                          isEnabled: !_isDownloading,
                        )
                      : VideoItem(
                          video: _videoList[index],
                          saveVideo: downloadFunction,
                          isEnabled: !_isDownloading,
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
