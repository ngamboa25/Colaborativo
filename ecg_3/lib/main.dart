import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Heart Rate Monitor',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const BluetoothDevicesScreen(),
    );
  }
}

class BluetoothDevicesScreen extends StatefulWidget {
  const BluetoothDevicesScreen({Key? key}) : super(key: key);

  @override
  _BluetoothDevicesScreenState createState() => _BluetoothDevicesScreenState();
}

class _BluetoothDevicesScreenState extends State<BluetoothDevicesScreen> {
  FlutterBlue flutterBlue = FlutterBlue.instance;
  List<BluetoothDevice> devicesList = [];

  @override
  void initState() {
    super.initState();
    flutterBlue.startScan(timeout: Duration(seconds: 4));

    flutterBlue.scanResults.listen((results) {
      for (ScanResult result in results) {
        if (!devicesList.any((device) => device.id == result.device.id)) {
          setState(() {
            devicesList.add(result.device);
          });
        }
      }
    });

    Future.delayed(Duration(seconds: 5)).then((_) {
      flutterBlue.stopScan();
    });
  }

  @override
  void dispose() {
    flutterBlue.stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Bluetooth Devices'),
      ),
      body: ListView.builder(
        itemCount: devicesList.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(devicesList[index].name.isEmpty ? '(unknown device)' : devicesList[index].name),
            subtitle: Text(devicesList[index].id.toString()),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => HeartRateMonitor(device: devicesList[index]),
            )),
          );
        },
      ),
    );
  }
}

class HeartRateMonitor extends StatefulWidget {
  final BluetoothDevice device;

  const HeartRateMonitor({Key? key, required this.device}) : super(key: key);

  @override
  _HeartRateMonitorState createState() => _HeartRateMonitorState();
}

class _HeartRateMonitorState extends State<HeartRateMonitor> {
  StreamSubscription<List<int>>? dataSubscription;
  String heartRate = "Waiting for data...";

  @override
  void initState() {
    super.initState();
    connectToDevice();
  }

  void connectToDevice() async {
    await widget.device.connect();
    discoverServices();
  }

  void discoverServices() async {
    List<BluetoothService> services = await widget.device.discoverServices();
    var targetServiceUuid = "0000180d-0000-1000-8000-00805f9b34fb"; // Heart Rate Service UUID
    var targetCharUuid = "00002a37-0000-1000-8000-00805f9b34fb"; // Heart Rate Measurement Characteristic UUID

    for (var service in services) {
      if (service.uuid.toString() == targetServiceUuid) {
        var characteristic = service.characteristics.firstWhere(
            (c) => c.uuid.toString() == targetCharUuid, orElse: () => throw Exception('Characteristic not found.'));
        await characteristic.setNotifyValue(true);
        dataSubscription = characteristic.value.listen((data) {
          setState(() {
            heartRate = String.fromCharCodes(data);
          });
        });
      }
    }
  }

  @override
  void dispose() {
    dataSubscription?.cancel();
    widget.device.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Heart Rate from ${widget.device.name}')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite, color: Colors.red, size: 48, key: Key('heart_icon')),
            SizedBox(height: 20),
            Text('Heart Rate: $heartRate bpm', style: TextStyle(fontSize: 24)),
          ],
        ),
      ),
    );
  }
}
