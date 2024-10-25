import 'package:flutter/material.dart';
import 'colors.dart';

class LapTime extends StatefulWidget {
  const LapTime({super.key});

  @override
  State<LapTime> createState() => _LapTimeState();
}

class _LapTimeState extends State<LapTime> {

  bool _isRecieving = false;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1000,
      child: Scaffold(
        body: Column(
          children: [
            OutlinedButton(
              onPressed: () {startTelem();}, 
              style: OutlinedButton.styleFrom(
                backgroundColor: mainColor,
                foregroundColor: background,
                minimumSize: const Size(150, 75)),
              child: switch (_isRecieving) {false => const Text('Start ▶️',style: TextStyle(fontSize: 20)), true => const Text('Stop 🛑',style: TextStyle(fontSize: 20))},
              ),
            Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(8),
              height: 75,
              decoration: BoxDecoration(
                  border: Border.all(color: mainColor), color: background),
              //color: background,
              child: const Text("test",style: TextStyle(color: mainColor, fontSize: 20)),
            ),
          ],
        ),
      )
    );
  }

  void startTelem(){
    setState(() => _isRecieving = !_isRecieving);
    //implement data recieving functionality
  }
}
