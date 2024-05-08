import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bluetooth Data Stream',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: BluetoothDataStream(),
    );
  }
}

class BluetoothDataStream extends StatefulWidget {
  @override
  _BluetoothDataStreamState createState() => _BluetoothDataStreamState();
}

class _BluetoothDataStreamState extends State<BluetoothDataStream> {
  FlutterBlue flutterBlue = FlutterBlue.instance;
  StreamSubscription? scanSubscription;
  BluetoothDevice? device;
  List<FlSpot> pulseData = [];
  StreamSubscription? deviceConnection;
  List<double> pulseValues = [];

  @override
  void initState() {
    super.initState();
    startScan();
  }

  void startScan() {
    scanSubscription = flutterBlue.scan(timeout: Duration(seconds: 10)).listen((scanResult) {
      // Check if the device is the one we are looking for
      if (scanResult.device.name == 'HC-05') {
        setState(() {
          device = scanResult.device;
          stopScan();
          connectToDevice();
        });
      }
    });
  }

  void stopScan() {
    scanSubscription?.cancel();
    scanSubscription = null;
    flutterBlue.stopScan();
  }

  void connectToDevice() {
    if (device != null) {
      // Use the device's connect method instead of FlutterBlue instance
      deviceConnection = device!.connect().listen((state) {
        if (state == BluetoothDeviceState.connected) {
          print('Connected to ${device!.name}');
          setNotificationForPulse();
        }
      }, onError: (err) {
        print('Failed to connect: $err');
      });
    }
  }

  void setNotificationForPulse() {
    device?.discoverServices().then((services) {
      var service = services.firstWhere(
        (s) => s.uuid.toString().toUpperCase().contains('YOUR_SERVICE_UUID'),
        orElse: () => null
      );
      if (service != null) {
        var characteristic = service.characteristics.firstWhere(
          (c) => c.uuid.toString().toUpperCase().contains('YOUR_CHARACTERISTIC_UUID'),
          orElse: () => null
        );
        if (characteristic != null) {
          characteristic.setNotifyValue(true);
          characteristic.value.listen((value) {
            double pulse = double.parse(String.fromCharCodes(value));
            setState(() {
              pulseValues.add(pulse);
              pulseData.add(FlSpot(pulseValues.length.toDouble(), pulse));
            });
          });
        }
      }
    });
  }

  @override
  void dispose() {
    deviceConnection?.cancel();
    scanSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pulse Data Stream'),
      ),
      body: pulseData.isEmpty ? Center(child: CircularProgressIndicator()) : LineChart(
        LineChartData(
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(show: true),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: pulseData,
              isCurved: true,
              barWidth: 2,
              color: Colors.blue, 
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
            ),
          ],
        ),
      ),
    );
  }
}
