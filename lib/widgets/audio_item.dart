import 'dart:io';

import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class AudioItem extends StatelessWidget {
  final AudioOnlyStreamInfo audio;
  final Function saveAudio;

  const AudioItem({super.key, required this.audio, required this.saveAudio});

  String audioType() {
    String mainType = audio.codec.toString().split('/')[1].split(';')[0];
    if (Platform.isAndroid) {
      return 'mp3';
    } else {
      return mainType == 'webm' ? 'wav' : 'mp3';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.audio_file),
      iconColor: Theme.of(context).primaryColor,
      enableFeedback: true,
      title: Text('${audio.bitrate} - ${audio.size} - ${audioType()}'),
      trailing: IconButton(
        icon: const Icon(Icons.download),
        onPressed: () {
          saveAudio(audioType(), audio);
        },
      ),
    );
  }
}
