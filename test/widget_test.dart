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

// _isLoading
//     ? LayoutBuilder(
//         builder: (context, constraints) {
//           List<Widget> children = [
//             Image.network(
//               video!.thumbnails.highResUrl,
//               height: 200,
//             ),
//             Padding(
//               padding: const EdgeInsets.all(18.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     video!.title,
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                     style: primaryText,
//                   ),
//                   Text(
//                     video!.author,
//                     style: const TextStyle(
//                       fontSize: 18,
//                     ),
//                   ),
//                   Row(
//                     children: [
//                       Icon(
//                         Icons.remove_red_eye,
//                         color: Theme.of(context).primaryColor,
//                       ),
//                       const SizedBox(
//                         width: 8.0,
//                       ),
//                       Text(
//                         ' ${video!.engagement.viewCount.toString().trim()}',
//                         style: const TextStyle(
//                           fontSize: 18,
//                         ),
//                       ),
//                     ],
//                   ),
//                   Row(
//                     children: [
//                       Icon(
//                         Icons.access_time,
//                         color: Theme.of(context).primaryColor,
//                       ),
//                       const SizedBox(
//                         width: 8.0,
//                       ),
//                       Text(
//                         formatDuration(
//                           video!.duration.toString(),
//                         ),
//                         style: const TextStyle(
//                           fontSize: 18,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             )
//           ];

//           return Container(
//             alignment: Alignment.topLeft,
//             // decoration: BoxDecoration(
//             //   border: Border.all(color: Colors.black),
//             // ),
//             child: screenSize.width < 600
//                 ? Column(
//                     mainAxisAlignment: MainAxisAlignment.start,
//                     children: children,
//                   )
//                 : Row(
//                     mainAxisAlignment: MainAxisAlignment.start,
//                     children: children,
//                   ),
//           );
//         },
//       )
//     : const SizedBox.shrink(),

import 'package:flutter/material.dart';

void main() => runApp(const SnackBarDemo());

class SnackBarDemo extends StatelessWidget {
  const SnackBarDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SnackBar Demo',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('SnackBar Demo'),
        ),
        body: const SnackBarPage(),
      ),
    );
  }
}

class SnackBarPage extends StatelessWidget {
  const SnackBarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          final snackBar = SnackBar(
            content: const Text('Yay! A SnackBar!'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                // Some code to undo the change.
              },
            ),
          );

          // Find the ScaffoldMessenger in the widget tree
          // and use it to show a SnackBar.
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        },
        child: const Text('Show SnackBar'),
      ),
    );
  }
}
