import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'dart:async';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Heart Rate Monitor',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: BluetoothDevicesScreen(),
    );
  }
}

class BluetoothDeviceMock {
  //dispositivos dummy
  final String name;
  final String id;

  BluetoothDeviceMock({required this.name, required this.id});
}

class BluetoothDevicesScreen extends StatelessWidget {
  final List<BluetoothDeviceMock> dummyDevices = [
    BluetoothDeviceMock(name: 'Dummy Device 1', id: '1'),
    BluetoothDeviceMock(name: 'Dummy Device 2', id: '2'),
    BluetoothDeviceMock(name: 'Dummy Device 3', id: '3'),
  ];

  BluetoothDevicesScreen({super.key});

  /*
  FlutterBlue flutterBlue = FlutterBlue.instance;
  List<BluetoothDevice> devicesList = [];

  @override
  void initState() {
    super.initState();
    flutterBlue.startScan(timeout: const Duration(seconds: 4));

    flutterBlue.scanResults.listen((results) {
      for (ScanResult result in results) {
        if (!devicesList.any((device) => device.id == result.device.id)) {
          setState(() {
            devicesList.add(result.device);
          });
        }
      }
    });

    Future.delayed(const Duration(seconds: 5)).then((_) {
      flutterBlue.stopScan();
    });
  }

  @override
  void dispose() {
    flutterBlue.stopScan();
    super.dispose();
  }

  */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Bluetooth Devices'),
      ),
      body: ListView.builder(
        itemCount: dummyDevices.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(dummyDevices[index].name),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (context) =>
                  HeartRateMonitor(device: dummyDevices[index]),
            )),
          );
        },
      ),
    );
  }
}

class HeartRateMonitor extends StatelessWidget {
  final BluetoothDeviceMock device;

  const HeartRateMonitor({super.key, required this.device});

  /*
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
    var targetServiceUuid =
        "0000180d-0000-1000-8000-00805f9b34fb"; // Heart Rate Service UUID
    var targetCharUuid =
        "00002a37-0000-1000-8000-00805f9b34fb"; // Heart Rate Measurement Characteristic UUID

    for (var service in services) {
      if (service.uuid.toString() == targetServiceUuid) {
        var characteristic = service.characteristics.firstWhere(
            (c) => c.uuid.toString() == targetCharUuid,
            orElse: () => throw Exception('Characteristic not found.'));
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

  */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Heart Rate from ${device.name}'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite, color: Colors.red, size: 48),
            SizedBox(height: 20),
            Text('Heart Rate: Waiting for data...',
                style: TextStyle(fontSize: 24)),
          ],
        ),
      ),
    );
  }
}
