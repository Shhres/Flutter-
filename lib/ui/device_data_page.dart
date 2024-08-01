import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'dart:convert';

class DeviceDataPage extends StatefulWidget {
  final BluetoothDevice device;

  const DeviceDataPage({super.key, required this.device});

  @override
  DeviceDataPageState createState() => DeviceDataPageState();
}

class DeviceDataPageState extends State<DeviceDataPage> {
  late BluetoothDevice device;
  List<double> temperatureData = [];
  List<double> humidityData = [];
  BluetoothCharacteristic? tempCharacteristic;
  BluetoothCharacteristic? humCharacteristic;

  @override
  void initState() {
    super.initState();
    device = widget.device;
    connectToDevice();
  }

  Future<void> connectToDevice() async {
    try {
      List<BluetoothService> services = await device.discoverServices();
      for (BluetoothService service in services) {
        for (BluetoothCharacteristic characteristic
            in service.characteristics) {
          if (characteristic.uuid.toString() ==
              '12345678-1234-5678-1234-56789abcdef1') {
            tempCharacteristic = characteristic;
            await tempCharacteristic!.setNotifyValue(true);
            tempCharacteristic!.value.listen((value) {
              print('Temperature data received: $value');
              processTemperatureData(value);
            });
          } else if (characteristic.uuid.toString() ==
              '12345678-1234-5678-1234-56789abcdef2') {
            humCharacteristic = characteristic;
            await humCharacteristic!.setNotifyValue(true);
            humCharacteristic!.value.listen((value) {
              print('Humidity data received: $value');
              processHumidityData(value);
            });
          }
        }
      }
    } catch (e) {
      print('Error connecting to device: $e');
    }
  }

  void processTemperatureData(List<int> value) {
    String dataString = utf8.decode(value);
    print('Processing temperature data: $dataString');
    List<String> values = dataString
        .replaceAll('[', '')
        .replaceAll(']', '')
        .split(',')
        .map((e) => e.trim())
        .toList();
    List<double> decodedValues =
        values.map((e) => double.tryParse(e) ?? 0.0).toList();

    setState(() {
      temperatureData.addAll(decodedValues);
    });
  }

  void processHumidityData(List<int> value) {
    String dataString = utf8.decode(value);
    print('Processing humidity data: $dataString');
    List<String> values = dataString
        .replaceAll('[', '')
        .replaceAll(']', '')
        .split(',')
        .map((e) => e.trim())
        .toList();
    List<double> decodedValues =
        values.map((e) => double.tryParse(e) ?? 0.0).toList();

    setState(() {
      humidityData.addAll(decodedValues);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Storm Watch'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Temperature Data:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: temperatureData.length,
                itemBuilder: (context, index) {
                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: const Icon(Icons.thermostat, color: Colors.red),
                      title: Text(
                          'Temperature: ${temperatureData[index].toStringAsFixed(1)}°C'),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Humidity Data:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: humidityData.length,
                itemBuilder: (context, index) {
                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: const Icon(Icons.water_drop, color: Colors.blue),
                      title: Text(
                          'Humidity: ${humidityData[index].toStringAsFixed(1)}%'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
