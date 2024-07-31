import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_application_1/ui/device_data_page.dart';

class Welcome extends StatefulWidget {
  const Welcome({super.key});

  @override
  _WelcomeState createState() => _WelcomeState();
}

class _WelcomeState extends State<Welcome> {
  FlutterBlue flutterBlue = FlutterBlue.instance;
  List<BluetoothDevice> devicesList = [];
  Map<DeviceIdentifier, String> deviceNames = {};
  StreamSubscription? scanSubscription;
  bool isBluetoothOn = false;
  bool isScanning = false;
  DateTime? scanStartTime;

  @override
  void initState() {
    super.initState();
    requestPermissions();
    checkBluetoothState();
  }

  Future<void> requestPermissions() async {
    if (await Permission.bluetoothScan.request().isGranted &&
        await Permission.bluetoothConnect.request().isGranted &&
        await Permission.location.request().isGranted) {
      checkBluetoothState(); // Ensure Bluetooth state is checked after permissions
    } else {
      print("Permissions not granted");
    }
  }

  Future<void> checkBluetoothState() async {
    isBluetoothOn = await flutterBlue.isOn;
    setState(() {});
    if (isBluetoothOn) {
      // Automatically start scan if Bluetooth is on
      startScan();
    }
  }

  @override
  void dispose() {
    scanSubscription?.cancel();
    super.dispose();
  }

  void startScan() {
    if (isScanning) {
      print('Another scan is already in progress.');
      return;
    }

    setState(() {
      isScanning = true;
      scanStartTime = DateTime.now();
      devicesList.clear(); // Clear the list before starting a new scan
      deviceNames.clear();
    });

    scanSubscription = flutterBlue.scan(timeout: Duration(seconds: 10)).listen(
      (scanResult) {
        setState(() {
          if (!devicesList.contains(scanResult.device)) {
            devicesList.add(scanResult.device);
            deviceNames[scanResult.device.id] = scanResult.device.name;
          }
        });
        print(
            'Device found: ${scanResult.device.name} (${scanResult.device.id})');
      },
      onError: (error) {
        // Handle scan error
        print('Scan error: $error');
        setState(() {
          isScanning = false;
        });
      },
      onDone: () {
        setState(() {
          isScanning = false;
          if (scanStartTime != null) {
            Duration scanDuration = DateTime.now().difference(scanStartTime!);
            print('Scan completed in ${scanDuration.inSeconds} seconds');
          }
          print('Total devices found: ${devicesList.length}');
        });
      },
    );
  }

  void stopScan() {
    scanSubscription?.cancel();
    setState(() {
      isScanning = false;
      scanSubscription = null;
      if (scanStartTime != null) {
        Duration scanDuration = DateTime.now().difference(scanStartTime!);
        print('Scan stopped after ${scanDuration.inSeconds} seconds');
      }
    });
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DeviceDataPage(device: device),
        ),
      );
    } catch (e) {
      // Handle connection error
      print('Connection error: $e');
    }
  }

  void toggleBluetooth() async {
    if (isBluetoothOn) {
      await flutterBlue.stopScan();
      setState(() {
        isBluetoothOn = false;
        devicesList.clear();
      });
    } else {
      await flutterBlue.startScan();
      setState(() {
        isBluetoothOn = true;
      });
      startScan();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Devices'),
        actions: [
          IconButton(
            icon: Icon(
                isBluetoothOn ? Icons.bluetooth : Icons.bluetooth_disabled),
            onPressed: toggleBluetooth,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: checkBluetoothState,
          ),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: Image.asset(
              'assets/be.png',
              fit: BoxFit.cover,
              color: Colors.black.withOpacity(0.2),
              colorBlendMode: BlendMode.darken,
            ),
          ),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  isBluetoothOn
                      ? 'Bluetooth is ON'
                      : 'Bluetooth is OFF. Please enable Bluetooth.',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                ),
              ),
              if (isScanning)
                const SpinKitCircle(
                  color: Colors.teal,
                  size: 50.0,
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: devicesList.length,
                    itemBuilder: (context, index) {
                      BluetoothDevice device = devicesList[index];
                      String deviceName =
                          deviceNames[device.id] ?? device.id.toString();
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 16.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        elevation: 4,
                        child: ListTile(
                          leading:
                              const Icon(Icons.devices, color: Colors.teal),
                          title: Text(
                            deviceName.isNotEmpty
                                ? deviceName
                                : 'Unknown Device',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(device.id.toString()),
                          trailing: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                            ),
                            child: const Text('Connect'),
                            onPressed: () => connectToDevice(device),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: startScan,
                    child: const Text('Start Scan'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: stopScan,
                    child: const Text('Stop Scan'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
