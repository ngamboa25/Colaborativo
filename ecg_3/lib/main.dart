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
  // Adding a Key parameter to the constructor
  BluetoothDataStream({Key? key}) : super(key: key);

  @override
  _BluetoothDataStreamState createState() => _BluetoothDataStreamState();
}

class _BluetoothDataStreamState extends State<BluetoothDataStream> {
  FlutterBlue flutterBlue = FlutterBlue.instance;
  List<BluetoothDevice> devicesList = [];
  BluetoothDevice? device;
  List<FlSpot> pulseData = [];
  StreamSubscription? deviceConnection;
  StreamSubscription<List<int>>? dataSubscription;
  List<double> pulseValues = [];

  @override
  void initState() {
    super.initState();
    flutterBlue.startScan(timeout: Duration(seconds: 10));

    // Listen to scan results
    flutterBlue.scanResults.listen((results) {
      for (ScanResult result in results) {
        if (!devicesList.any((device) => device.id == result.device.id)) {
          setState(() {
            devicesList.add(result.device);
          });
        }
      }
    });

    // Stop scanning after a period of time
    Future.delayed(Duration(seconds: 10)).then((_) {
      flutterBlue.stopScan();
    });
  }

  void connectToDevice(BluetoothDevice selectedDevice) async {
    await selectedDevice.connect();
    setState(() {
      device = selectedDevice;
    });
    setNotificationForPulse();
  }

  void setNotificationForPulse() async {
    if (device != null) {
      var services = await device!.discoverServices();
      for (var service in services) {
        BluetoothCharacteristic? characteristic;
        try {
          characteristic = service.characteristics.firstWhere(
            (c) => c.uuid.toString().toUpperCase().contains('YOUR_CHARACTERISTIC_UUID'));
        } catch (e) {
          characteristic = null;
        }

        if (characteristic != null) {
          await characteristic.setNotifyValue(true);
          dataSubscription = characteristic.value.listen((value) {
            double pulse = double.parse(String.fromCharCodes(value));
            setState(() {
              pulseValues.add(pulse);
              pulseData.add(FlSpot(pulseValues.length.toDouble(), pulse));
            });
          }, onError: (e) {
            print('Error receiving data: $e');
          });
        }
      }
    }
  }

  @override
  void dispose() {
    deviceConnection?.cancel();
    dataSubscription?.cancel();
    flutterBlue.stopScan();
    device?.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pulse Data Stream'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: devicesList.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(devicesList[index].name.isEmpty ? '(unknown device)' : devicesList[index].name),
                  subtitle: Text(devicesList[index].id.toString()),
                  onTap: () => connectToDevice(devicesList[index]),
                );
              },
            ),
          ),
          pulseData.isEmpty ? Expanded(child: Center(child: CircularProgressIndicator())) : Expanded(
            child: LineChart(
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
          ),
        ],
      ),
    );
  }
}
