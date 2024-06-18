import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Toggle Switch',
      home: ToggleSwitchExample(),
    );
  }
}

class ToggleSwitchExample extends StatefulWidget {
  @override
  _ToggleSwitchExampleState createState() => _ToggleSwitchExampleState();
}

class _ToggleSwitchExampleState extends State<ToggleSwitchExample> {
  List<bool> _selections = [true, false];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Toggle Switch Example'),
      ),
      body: Center(
        child: ToggleButtons(
          borderRadius: BorderRadius.circular(30.0),
          isSelected: _selections,
          selectedColor: Colors.white,
          fillColor: Colors.grey,
          color: Colors.black,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text('Skins'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text('Details'),
            ),
          ],
          onPressed: (int index) {
            setState(() {
              for (int i = 0; i < _selections.length; i++) {
                _selections[i] = i == index;
              }
            });
          },
        ),
      ),
    );
  }
}
