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
  final ScrollController _tempScrollController = ScrollController();
  final ScrollController _humScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    device = widget.device;
    connectToDevice();
  }

  @override
  void dispose() {
    _tempScrollController.dispose();
    _humScrollController.dispose();
    super.dispose();
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
        values.map((e) => double.tryParse(e) ?? double.nan).toList();

    setState(() {
      if (decodedValues.isNotEmpty && !decodedValues.contains(double.nan)) {
        temperatureData.addAll(decodedValues);
      }
      print('Updated temperature data: $temperatureData');
    });
    _scrollToBottom(_tempScrollController);
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
        values.map((e) => double.tryParse(e) ?? double.nan).toList();

    setState(() {
      if (decodedValues.isNotEmpty && !decodedValues.contains(double.nan)) {
        humidityData.addAll(decodedValues);
      }
      print('Updated humidity data: $humidityData');
    });
    _scrollToBottom(_humScrollController);
  }

  void _scrollToBottom(ScrollController controller) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.hasClients) {
        controller.animateTo(
          controller.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            device.disconnect(); // Disconnect from the device
            Navigator.pop(context); // Navigate back to the previous screen
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    const Text(
                      'Temperature',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const Icon(Icons.thermostat,
                                color: Colors.red, size: 40),
                            Text(
                              temperatureData.isNotEmpty
                                  ? '${temperatureData.last.toStringAsFixed(1)}°C'
                                  : '--°C',
                              style: const TextStyle(fontSize: 24),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Text(
                      'Humidity',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const Icon(Icons.water_drop,
                                color: Colors.blue, size: 40),
                            Text(
                              humidityData.isNotEmpty
                                  ? '${humidityData.last.toStringAsFixed(1)}%'
                                  : '--%',
                              style: const TextStyle(fontSize: 24),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Temperature Data:',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Expanded(
                          child: ListView.builder(
                            controller: _tempScrollController,
                            itemCount: temperatureData.length,
                            itemBuilder: (context, index) {
                              return Card(
                                elevation: 4,
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                child: ListTile(
                                  leading: const Icon(Icons.thermostat,
                                      color: Colors.red),
                                  title: Text(
                                    'Temperature: ${temperatureData[index].toStringAsFixed(1)}°C',
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Humidity Data:',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Expanded(
                          child: ListView.builder(
                            controller: _humScrollController,
                            itemCount: humidityData.length,
                            itemBuilder: (context, index) {
                              return Card(
                                elevation: 4,
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                child: ListTile(
                                  leading: const Icon(Icons.water_drop,
                                      color: Colors.blue),
                                  title: Text(
                                    'Humidity: ${humidityData[index].toStringAsFixed(1)}%',
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
