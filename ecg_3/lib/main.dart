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
      theme: ThemeData(primarySwatch: Colors.blue),
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
  StreamSubscription? scanSubscription;

  @override
  void initState() {
    super.initState();
    startScan();
  }

  void startScan() {
    scanSubscription = flutterBlue.scan(timeout: const Duration(seconds: 10)).listen((scanResult) {
      if (!devicesList.any((device) => device.id == scanResult.device.id)) {
        setState(() {
          devicesList.add(scanResult.device);
        });
      }
    }, onDone: stopScan);
  }

  void stopScan() {
    scanSubscription?.cancel();
    scanSubscription = null;
  }

  @override
  void dispose() {
    stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Available Bluetooth Devices')),
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
  int currentHeartRate = 0;

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
    for (var service in services) {
      var characteristic = service.characteristics.firstWhere(
        (c) => c.uuid.toString().toUpperCase().contains('HEART_RATE_MEASUREMENT'), // Replace with your characteristic UUID
        orElse: () => throw Exception('Characteristic not found.'),
      );
      await characteristic.setNotifyValue(true);
      dataSubscription = characteristic.value.listen((data) {
        setState(() {
          currentHeartRate = int.parse(String.fromCharCodes(data));
        });
      });
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
      appBar: AppBar(title: const Text('Heart Rate Monitor')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite, color: Colors.red, size: 48),
            const SizedBox(height: 24),
            Text('Current Heart Rate: $currentHeartRate bpm', style: TextStyle(fontSize: 24)),
          ],
        ),
      ),
    );
  }
}
