import 'package:flutter/material.dart';

class RoomControlScreen extends StatefulWidget {
  const RoomControlScreen({super.key});

  @override
  State<RoomControlScreen> createState() => _RoomControlScreenState();
}

class _RoomControlScreenState extends State<RoomControlScreen> {
  // Dữ liệu giả lập (Mock Data)
  final List<Map<String, dynamic>> _devices = [
    {'name': 'Đèn trần', 'icon': Icons.lightbulb_outline, 'isOn': false},
    {'name': 'Quạt trần', 'icon': Icons.mode_fan_off, 'isOn': false},
    {'name': 'Điều hòa', 'icon': Icons.ac_unit, 'isOn': false},
    {'name': 'Khóa cửa', 'icon': Icons.door_front_door, 'isOn': true},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phòng của tôi'),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      backgroundColor: Colors.blue[50],
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.85,
          ),
          itemCount: _devices.length,
          itemBuilder: (context, index) {
            final device = _devices[index];
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: device['isOn'] ? 4 : 1,
              color: device['isOn'] ? Colors.white : Colors.grey[200],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      device['icon'],
                      size: 48,
                      color: device['isOn'] ? Colors.blueAccent : Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      device['name'],
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: device['isOn'] ? Colors.black87 : Colors.grey,
                      ),
                    ),
                    const Spacer(),
                    Switch(
                      value: device['isOn'],
                      activeColor: Colors.blueAccent,
                      onChanged: (value) {
                        setState(() {
                          _devices[index]['isOn'] = value;
                          if (device['name'] == 'Quạt trần')
                            _devices[index]['icon'] = value
                                ? Icons.wind_power
                                : Icons.mode_fan_off;
                          if (device['name'] == 'Đèn trần')
                            _devices[index]['icon'] = value
                                ? Icons.lightbulb
                                : Icons.lightbulb_outline;
                        });
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
