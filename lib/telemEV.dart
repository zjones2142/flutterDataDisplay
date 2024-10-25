// ignore_for_file: file_names

import 'dart:collection';

import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
//import 'package:reorderable_grid/reorderable_grid.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import 'colors.dart'; // Ensure you have this file with the color definitions

class Data {
  String name = "";
  double value = -1;
  int order = -20;
  double convFact = 1;
  double jokeFact = 1;
  String unit = "{unit}";
  int trunc = 0;
  Data(String nm, double val, int ord, double cF, double jF, String un,
      int tru) {
    name = nm;
    value = val;
    order = ord;
    convFact = cF;
    jokeFact = jF;
    unit = un;
    trunc = tru;
  }
  Data.nu(String nm, double val, int ord, double cF, double jF, int tru) {
    name = nm;
    value = val;
    order = ord;
    convFact = cF;
    jokeFact = jF;
    unit = "NA";
    trunc = tru;
  }
  setValue(double val) {
    value = val;
  }
}


List<Data> displayValues = [
  Data("Brake Bias", 8, -1, 1, 1, "%", 4), 
  Data("Front Brake Pressure", 8, 1, .1, 1, "PSI", 1),
  Data("Rear Brake Pressure", 8, 2, .1, 1, "PSI", 1),
  Data("Command Torque", 8, 3, .1, 1, "NM", 1),
  Data.nu("MPH", 8, 4, 1, 1, 1),
  Data("Inv Gate Driver PCB temp", 8, 5, .1, 1, "°C", 1),
  Data("A Inverter Gate Driver temp", 8, 6, .1, 1, "°C", 1),
  Data("B Inverter Gate Driver temp", 8, 7, .1, 1, "°C", 1),
  Data("C Inverter Gate Driver temp", 8, 8, .1, 1, "°C", 1),
  Data("Inverter Hot Spot Temp", 8, 9, .1, 1, "°C", 1),
  Data("Inverter DC-Link Current", 8, 10, .1, 1, "A", 1),
  Data("Water Temp", 8, 11, .1, 1, "°F", 1),
  Data.nu("APPS Plausibility flag", 8, 12, 1, 1, 1),
  Data("Inv Est Coolant Temp", 8, 13, .1, 1, "°C", 1),
  Data("Motor Temp", 8, 14, .1, 1, "°C", 1),
  Data("GLV Voltage", 8, 15, .1, 1, "V", 1),
  Data("Inverter Temp", 8, 16, .1, 1, "°C", 1),
  Data.nu("RPM", 8, 17, 1, 1, 1),
  Data("Tractive System Voltage", 8, 18, .1, 1, "V", 1),
  Data("High cel Temp", 8, 19, 1, 1, "°C", 0),
  Data("Avg cell Temp", 8, 20, 1, 1, "°C", 0),
  Data("Total Pack Voltage", 8, 21, .1, 1, "V", 1),
  Data("Accumulator Current", 8, 22, .1, 1, "A", 1),
  Data.nu("postFault Bytes 0&1", 0, 23, 1, 1, 1),
  Data.nu("postFault Bytes 2&3", 0, 24, 1, 1, 1),
  Data.nu("RunFault Bytes 0&1", 0, 25, 1, 1, 1),
  Data.nu("RunFault Bytes 2&3", 0, 26, 1, 1, 1),
  Data("TS Power", 8, -2, 1, 1, "WATTS", 1),
  Data.nu("Inverter Post Fault", 8, -3, 1, 1, 1),
  Data.nu("Inverter Run Fault", 8, -4, 1, 1, 1),
];

final Map<String, Data> displayValues1 = HashMap.fromIterable(displayValues, key: (i) => i.name, value: (i) => i);

class LiveTelemetryEV extends StatefulWidget {
  const LiveTelemetryEV({super.key});

  @override
  State<LiveTelemetryEV> createState() => _LiveTelemetryState();
}

class _LiveTelemetryState extends State<LiveTelemetryEV> {
  final ScrollController _scrollController = ScrollController();
  String outPutText = "";
  int conBtnState = 0;
  int lengthOfMessageFrame = 0;

  bool needsScroll = false;
  bool realConversionrate = true;

  Timer? _dataFetchTimer;
  // 0 = no, 1 = yes, 2 = request timout
  int _isFetching = 0;
  final int _timeoutmilliseconds = 180;

  terminalPrint(String newLine) {
    setState(() {
      outPutText = "$outPutText\n>$newLine";
    });
    needsScroll = true;
  }

  void startFetchingData() {
    _terminalPrint("Attempting to read data");
    _dataFetchTimer =
        Timer.periodic(const Duration(milliseconds: 200), (timer) {
      fetchDataFromESP();
    });
  }

  void stopFetchingData() {
    _terminalPrint("Data reading closed");
    setState(() => _isFetching = 0);
    // Cancel the timer
    _dataFetchTimer?.cancel();
  }

  void fetchDataFromESP() async {
    try {
      final response = await http
          .get(Uri.parse('http://192.168.4.1/'))
          .timeout(Duration(milliseconds: _timeoutmilliseconds), onTimeout: () {
        return http.Response("no lol", 1208);
      });
      if (response.statusCode == 200) {
        setState(() {
          _updateUIValues(jsonDecode(response.body));
          _isFetching = 1;
        });
      } else {
        if (_isFetching != 2) {
          _terminalPrint("request Timeout");
          _terminalPrint(
              'Failed to load data Status code: ${response.statusCode}, Attempting to reconnect');
          setState(() {
            _isFetching = 2;
          });
        }
      }
    } catch (e) {
      if (_isFetching != 2) {
        _terminalPrint("Connection error");
      }
      setState(() {
        _isFetching = 2;
      });

      // _terminalPrint(e.toString());
    }
  }

  void _updateUIValues(Map<String, dynamic> data) {
    if (data.containsKey('Length') && data.containsKey('Data')) {
      //int lengthOfMessageFrame = data['Length'];
      List<dynamic> dataArray = data['Data'];
      for (var element in dataArray) {
        if (element.containsKey('index') && element.containsKey('value')) {
          int index = element['index'];
          int value = element['value'];
          for (int i = 0; i < displayValues.length; i++) {
            if (index == displayValues[i].order) {
              displayValues[i].value = value *
                  ((realConversionrate)
                      ? displayValues[i].convFact
                      : displayValues[i].jokeFact);
            }

            if (index == 2) {
              double front = 0;
              double back = 0;
              for (int j = 0; j < displayValues.length; j++) {
                if (displayValues[j].order == 1) {
                  front = displayValues[j].value;
                }
                if (displayValues[j].order == 2) {
                  back = displayValues[j].value;
                }
              }
              for (int j = 0; j < displayValues.length; j++) {
                if (displayValues[j].order == -1) {
                  if (back + front != 0) {
                    displayValues[j].setValue((front / (back + front)) * 100);
                  } else {
                    displayValues[j].setValue(-2);
                  }
                }
              }
            }
            if (index == 18) {
              double current = 0;
              double voltage = 0;
              current = displayValues[10].value;
              voltage = displayValues[18].value;
              displayValues[27].value =
                  current * voltage * 0.001; //figure it out
            }
            if (index == 24) {
              int byte01 = 0;
              int byte23 = 0;
              byte01 = displayValues[23].value.toInt();
              byte23 = displayValues[24].value.toInt();
              displayValues[28].value = ((byte23 << 16) | byte01).toDouble();
              //figure it out
            }
            if (index == 26) {
              int byte01 = 0;
              int byte23 = 0;
              byte01 = displayValues[25].value.toInt();
              byte23 = displayValues[26].value.toInt();
              displayValues[29].value = ((byte23 << 16) | byte01).toDouble();
              //figure it out
            }
          }
        }
      }
    }
  }

  void _terminalPrint(String message) {
    setState(() {
      outPutText += "\n> $message";
      // Auto-scroll to new messages
      Future.delayed(const Duration(milliseconds: 50), () {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 100),
            curve: Curves.bounceIn);
      });
    });
  }

  @override
  void dispose() {
    _dataFetchTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color mainColor = Color(0xFFF1B82D);
    const Color accent = Color.fromARGB(255, 254, 254, 254);
    return SizedBox(
      height: 1000,
      child: Scaffold(
        body: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(8),
              height: 75,
              decoration: BoxDecoration(
                  border: Border.all(color: mainColor), color: background),
              //color: background,
              child: Stack(alignment: Alignment.center, children: [
                Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                      child: ElevatedButton(
                          onPressed: () {
                            switch (_isFetching) {
                              case 0:
                                //startScanning();
                                startFetchingData();
                                break;
                              case 1:
                                //stopSearching();
                                stopFetchingData();
                                break;
                              default:
                                //disconnect();
                                stopFetchingData();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: mainColor,
                              foregroundColor: background,
                              minimumSize: const Size(150, 100),
                              shape: const RoundedRectangleBorder()),
                          child: switch (_isFetching) {
                            0 => const Text("Connect"),
                            2 => LoadingAnimationWidget.newtonCradle(
                                color: background,
                                size: 50,
                              ),
                            int() => const Text("Disconnect"),
                          }
                          //Text("Connect")
                          ),
                    )),
                const Align(
                  alignment: Alignment.center,
                  child: Text(
                    'EV Live Telemetry',
                    style: TextStyle(color: mainColor, fontSize: 40),
                  ),
                ),
                Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
      
                      child: ElevatedButton(
                          onPressed: () {
                            terminalPrint("Lmao this might be a while");
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: mainColor,
                              foregroundColor: background,
                              minimumSize: const Size(150, 100),
                              shape: const RoundedRectangleBorder()),
                          child: const Text(
                              "Graphs Coming Soon")), //TODO far in the future
                    )),
              ]),
            ),
            SingleChildScrollView(
              clipBehavior: Clip.antiAliasWithSaveLayer,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    margin: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: mainColor,
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          margin: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(color: background),
                          child: const SizedBox(
                            width: 70000,
                            child: Center(
                              child: Text(
                                "Temps & Voltages",
                                style: TextStyle(
                                  color: accent,
                                  fontSize: 40,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            display(100, 3, 21, 1, 2, accent,
                                background), //High voltage
                            display(100, 3, 15, 0, 3, accent,
                                background), //Low Voltage
                            display(100, 2, 19, 0, 3, accent,
                                background), //Highest temp
                            display(100, 2, 20, 0, 3, accent,
                                background), //Avgerage temp
                            display(100, 3, 3, 0, 3, accent,
                                background), //Command torque
                            display(100, 3, 4, 0, 3, accent,
                                background), //MPH  mmm  .
                            display(100, 4, 17, 2, 3, accent,
                                background), //RPM      .
                          ],
                        ),
                      ],
                    ),
                  ),
                  //note the end
                  Container(
                    margin: const EdgeInsets.all(0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                margin: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: mainColor,
                                ),
                                child: const SizedBox(
                                  child: Center(
                                    child: Text(
                                      "SO MANY TEMPS",
                                      style: TextStyle(
                                        color: background,
                                        fontSize: 40,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  display(100, 1, 6, 1, 1, mainColor,
                                      mainColor), //Gate driver temp A
                                  display(100, 1, 7, 0, 1, mainColor,
                                      mainColor), //Gate driver temp B
                                  display(100, 1, 8, 2, 1, mainColor,
                                      mainColor), //Gate driver temp C
                                ],
                              ),
                              Row(
                                children: [
                                  display(100, 1, 5, 1, 0, mainColor,
                                      mainColor), //Inverter gate driver PCB temp
                                  display(100, 1, 9, 0, 0, mainColor,
                                      mainColor), //Inverter Hot spot temp
                                  display(100, 1, 13, 2, 0, mainColor,
                                      mainColor), //Inverter Est coolant temp
                                ],
                              ),
                              Row(
                                children: [
                                  display(100, 1, 11, 1, 2, mainColor,
                                      mainColor), //Water Temp
                                  display(100, 1, 14, 0, 2, mainColor,
                                      mainColor), //Motor Temp
                                  display(100, 1, 16, 2, 2, mainColor,
                                      mainColor), //Inverter Temp
                                ],
                              )
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                margin: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(color: mainColor),
                                child: const SizedBox(
                                  child: Center(
                                    child: Text(
                                      "Horrors beyond your imagination",
                                      style: TextStyle(
                                        color: background,
                                        fontSize: 40,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  display(100, 1, 18, 1, 1, mainColor,
                                      mainColor), //Tractive system voltage
                                  display(100, 1, 9, 0, 1, mainColor,
                                      mainColor), //Inverter DC-link Current
                                  display(100, 1, 27, 2, 1, mainColor,
                                      mainColor), //TS power
                                ],
                              ),
                              Row(
                                children: [
                                  display(100, 1, 1, 1, 0, mainColor,
                                      mainColor), //front brake
                                  display(100, 1, 2, 0, 0, mainColor,
                                      mainColor), //rear brake
                                  display(100, 1, 0, 2, 0, mainColor,
                                      mainColor), //brake biass
                                ],
                              ),
                              Row(
                                children: [
                                  display(100, 1, 28, 1, 2, mainColor,
                                      mainColor), //PostFault
                                  display(100, 1, 29, 0, 2, mainColor,
                                      mainColor), //RunFault
                                  display(100, 1, 12, 2, 2, mainColor,
                                      mainColor), //APPS Flag
                                ],
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(4),
              color: const Color.fromRGBO(100, 100, 100, 1),
              child: const SizedBox(
                height: 30,
                child: Text(
                  "Terminal:",
                  style: TextStyle(color: mainColor, fontSize: 20),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Text(
                    outPutText,
                    style: const TextStyle(color: accent),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    //*/
  }
}

Widget display(
  double height,
  int digits,
  int dP,
  int loREdge,
  int toBEdge,
  Color labelColor,
  Color borderColor,
) {
  TextStyle valTextStyle = const TextStyle(
    color: accent,
    fontSize: 40,
  );
  TextStyle labelTextStyle = const TextStyle(
    color: background,
    fontSize: 15,
  );
  double leftmar;
  double rightmar;
  double topmar;
  double botmar;
  Data dp = displayValues[dP];
  switch (loREdge) {
    case 1:
      leftmar = 8;
      rightmar = 4;
      break;
    case 2:
      leftmar = 4;
      rightmar = 8;
      break;
    default:
      leftmar = 4;
      rightmar = 4;
  }
  switch (toBEdge) {
    case 1:
      topmar = 4;
      botmar = 4;
      break;
    case 2:
      topmar = 4;
      botmar = 8;
      break;
    case 3:
      topmar = 4;
      botmar = 8;
      break;
    default:
      topmar = 4;
      botmar = 4;
  }
  EdgeInsets iNSETS = EdgeInsets.fromLTRB(leftmar, topmar, rightmar, botmar);
  return Expanded(
    flex: digits,
    child: Container(
      margin: iNSETS,
      decoration: BoxDecoration(color: borderColor),
      padding: const EdgeInsets.all(2),
      child: Container(
        padding: const EdgeInsets.all(0),
        decoration: const BoxDecoration(color: background),
        child: Column(
          children: [
            SizedBox(
              height: height,
              //width: digits * 50 + 20,
              child: Center(
                child: Text(
                  dp.value.toStringAsFixed(dp.trunc),
                  style: valTextStyle,
                ),
              ),
            ),
            Container(
                color: labelColor,
                child: SizedBox(
                  height: 30,
                  //width: digits * 50 + 20,
                  child: Center(
                    child: (dp.unit != "NA")
                        ? Text(
                            "${dp.name} (${dp.unit})",
                            style: labelTextStyle,
                          )
                        : Text(
                            dp.name,
                            style: labelTextStyle,
                          ),
                  ),
                ))
          ],
        ),
      ),
    ),
  );
}