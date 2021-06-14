import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:equatable/equatable.dart';
import 'package:flutter_beep/flutter_beep.dart';

import 'package:scan/scan.dart';

void main() async {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '출입자 명부',
      home: Body(),
    );
  }
}

class Body extends StatefulWidget {
  @override
  _BodyState createState() => _BodyState();
}

class _BodyState extends State<Body> {
  Map<String, Data> database = {};
  String? recent;
  SnackBar dataSnackBar(String text) => SnackBar(content: Text(text));

  String loadCSV(String date, List<Data> contents) {
    var syncPath = '/storage/emulated/0/Download';
    var fileTemp = File(syncPath + '/$date.csv');
    if (!Directory(syncPath).existsSync())
      Directory(syncPath).createSync(recursive: true);
    if (!fileTemp.existsSync()) fileTemp.createSync();
    var oldData = fileTemp.readAsStringSync();
    if (oldData != '') {
      List<Data> oldDataList = oldData.split('\n').map((e) {
        var tmp = e.split(',');
        return Data(
          tmp[0],
          tmp[1],
          tmp[2],
        );
      }).toList();
      oldDataList.addAll(contents);
      oldDataList = oldDataList.toSet().toList()
        ..sort((a, b) => a.time.compareTo(b.time));
      String newDataText = oldDataList
          .map((e) => '${e.date},${e.time},${e.value}')
          .toList()
          .join('\n');

      File(syncPath + '/$date.csv').writeAsStringSync(newDataText);
    } else {
      contents.sort((a, b) => a.time.compareTo(b.time));
      File(syncPath + '/$date.csv').writeAsStringSync(contents
          .map((e) => '${e.date},${e.time},${e.value}')
          .toList()
          .join('\n'));
    }
    return oldData;
  }

  var ctr = ScanController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ScanView(
            controller: ctr,
            scanLineColor: Colors.white,
            scanAreaScale: 0.8,
            onCapture: (data) {
              print('data is $data\n-base is $database');
              FlutterBeep.beep(true);

              ctr.resume();

              ScaffoldMessenger.of(context)
                  .showSnackBar(dataSnackBar('$data 인증됨'));

              // 'date': DateFormat('yyyyMMdd').format(DateTime.now()),
              // 'time': DateFormat('HHmm').format(DateTime.now()),
              // 'info': arguments.toString(),

              setState(() {
                database[DateFormat('yyyyMMddHHmm').format(DateTime.now()) +
                    '-' +
                    data] = Data(
                  DateFormat('yyyyMMdd').format(DateTime.now()),
                  DateFormat('HHmm').format(DateTime.now()),
                  data,
                );
                recent = data;
                print('$database');
              });

              print('loading');
              print(loadCSV(DateFormat('yyyyMMdd').format(DateTime.now()),
                  database.values.toList()));
              print('done');
            }),
      ),
    );
  }
}

class Data extends Equatable {
  final String date;
  final String time;
  final String value;

  const Data(
    this.date,
    this.time,
    this.value,
  );

  List<Object> get props => [
        date,
        time,
        value,
      ];
}
