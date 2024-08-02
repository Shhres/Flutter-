import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

class DeviceListPage extends StatelessWidget {
  final List<BluetoothDevice> devices;
  final Function(BluetoothDevice) onConnect;

  const DeviceListPage(
      {super.key, required this.devices, required this.onConnect});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(' Bluetooth Devices'),
      ),
      body: ListView.builder(
        itemCount: devices.length,
        itemBuilder: (context, index) {
          BluetoothDevice device = devices[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            elevation: 4,
            child: ListTile(
              leading: const Icon(Icons.devices, color: Colors.teal),
              title:
                  Text(device.name.isNotEmpty ? device.name : 'Unknown Device'),
              subtitle: Text(device.id.toString()),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                ),
                child: const Text('Connect'),
                onPressed: () => onConnect(device),
              ),
            ),
          );
        },
      ),
    );
  }
}
