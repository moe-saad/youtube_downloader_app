import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class VideoItem extends StatelessWidget {
  final MuxedStreamInfo video;
  final Function saveVideo;
  final bool isEnabled;
  final int index;
  const VideoItem(
      {super.key,
      required this.video,
      required this.saveVideo,
      required this.isEnabled,
      required this.index});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.video_file),
      iconColor: Theme.of(context).primaryColor,
      enableFeedback: true,
      title: Text(
          '${video.videoResolution} - ${video.size} - ${video.framerate.framesPerSecond.toString()} fps'),
      trailing: IconButton(
        icon: Icon(isEnabled ? Icons.download : Icons.file_download_off),
        onPressed: () {
          isEnabled ? saveVideo('mp4', video, index) : null;
        },
      ),
    );
  }
}
