import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class VideoItem extends StatelessWidget {
  final MuxedStreamInfo video;
  final Function saveVideo;
  const VideoItem({super.key, required this.video, required this.saveVideo});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.video_file),
      iconColor: Theme.of(context).primaryColor,
      enableFeedback: true,
      title: Text(
          '${video.videoResolution} - ${video.size} - ${video.framerate.framesPerSecond.toString()} fps'),
      trailing: IconButton(
        icon: const Icon(Icons.download),
        onPressed: () {
          saveVideo('mp4', video);
        },
      ),
    );
  }
}
