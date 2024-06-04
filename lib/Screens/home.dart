import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'dart:io';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late String videoURL;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Youtube Downloader'),
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
            const SizedBox(height: 20.0),
            SizedBox(
              width: 300,
              child: TextField(
                decoration: const InputDecoration(hintText: 'Paste URL Here'),
                onChanged: (value) {
                  videoURL = value;
                },
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            ElevatedButton(
                onPressed: () {
                  _downloadVideo(videoURL);
                },
                child: const Text('Download Video'))
          ],
        ),
      ),
    );
  }

  //function to download the video
  void _downloadVideo(String url) async {
    var ytExplode = YoutubeExplode();
    var video = await ytExplode.videos.get(url);

    print('\n--------------------manifest-------------------------\n');
    var manifest = await ytExplode.videos.streamsClient.getManifest(url);
    print(manifest);

    print('\n-----------------------streamInfo----------------------\n');
//select audio only here
    var streamInfo = manifest.audioOnly.first;
    print(streamInfo);

    print('\n----------------------stream-----------------------\n');
    // Get the actual stream
    var stream = ytExplode.videos.streamsClient.get(streamInfo);
    print(stream);

    print('\n-----------------------savePath----------------------\n');
    //open a file for writing
    final Directory? downloadsDir = await getDownloadsDirectory();
    final savePath = '${downloadsDir!.path}/${video.title}.mp3';
    print(savePath);
    print('\n---------------------------------------------\n');
    var file = File(savePath);
    var fileStream = file.openWrite(mode: FileMode.append);

    // Pipe all the content of the stream into the file.
    await stream.pipe(fileStream);

    print('\nafter the stream pipe\n');

    // Close the file.
    await fileStream.flush();
    await fileStream.close();
  }
}
