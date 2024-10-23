import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Virtual Aquarium',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: AquariumHomePage(),
    );
  }
}

class AquariumHomePage extends StatefulWidget {
  @override
  _AquariumHomePageState createState() => _AquariumHomePageState();
}

class _AquariumHomePageState extends State<AquariumHomePage> {
  List<Fish> fishList = [];
  Color selectedColor = Colors.blue;
  double selectedSpeed = 1.0;
  late Database database;

  @override
  void initState() {
    super.initState();
    _initializeDatabase().then((_) => _loadSettingsFromDatabase());
  }

  Future<void> _initializeDatabase() async {
    database = await openDatabase(
      join(await getDatabasesPath(), 'aquarium.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE aquarium_settings(id INTEGER PRIMARY KEY, fish_count INTEGER, speed REAL, color INTEGER)',
        );
      },
      version: 1,
    );
  }

  Future<void> _saveSettingsToDatabase() async {
    await database.insert(
      'aquarium_settings',
      {
        'id': 1,
        'fish_count': fishList.length,
        'speed': selectedSpeed,
        'color': selectedColor.value,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print('Settings saved');
  }

  Future<void> _loadSettingsFromDatabase() async {
    final List<Map<String, dynamic>> settings =
        await database.query('aquarium_settings', where: 'id = 1');

    if (settings.isNotEmpty) {
      setState(() {
        selectedSpeed = settings[0]['speed'];
        selectedColor = Color(settings[0]['color']);
        int fishCount = settings[0]['fish_count'];

        fishList = List.generate(fishCount, (_) => Fish(color: selectedColor, speed: selectedSpeed));
      });
      print('Settings restored');
    } else {
      print('No settings found to restore');
    }
  }

  void _addFish() {
    if (fishList.length < 10) {
      setState(() {
        fishList.add(Fish(color: selectedColor, speed: selectedSpeed));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Virtual Aquarium'),
      ),
      body: Column(
        children: [
          Container(
            width: 300,
            height: 300,
            color: Colors.blue[100],
            child: Stack(
              children: fishList.map((fish) => fish).toList(),
            ),
          ),
          SizedBox(height: 20), 
          Text(
            "Fish Speed: ${selectedSpeed.toStringAsFixed(1)}x",
            style: TextStyle(fontSize: 18),
          ),
          Slider(
            value: selectedSpeed,
            min: 0.5,
            max: 5.0,
            divisions: 9,
            label: "${selectedSpeed.toStringAsFixed(1)}x",
            onChanged: (double value) {
              setState(() {
                selectedSpeed = value;
              });
            },
          ),
          DropdownButton<Color>(
            value: selectedColor,
            items: [Colors.red, Colors.green, Colors.blue, Colors.orange]
                .map((color) => DropdownMenuItem<Color>(
                      value: color,
                      child: Container(width: 20, height: 20, color: color),
                    ))
                .toList(),
            onChanged: (Color? newColor) {
              setState(() {
                selectedColor = newColor!;
              });
            },
          ),
          ElevatedButton(
            onPressed: _addFish,
            child: Text("Add Fish"),
          ),
          ElevatedButton(
            onPressed: _saveSettingsToDatabase,
            child: Text("Save Settings"),
          ),
          ElevatedButton(
            onPressed: _loadSettingsFromDatabase,
            child: Text("Restore Settings"),
          ),
        ],
      ),
    );
  }
}

class Fish extends StatefulWidget {
  final Color color;
  final double speed;

  Fish({required this.color, required this.speed});

  @override
  _FishState createState() => _FishState();
}

class _FishState extends State<Fish> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double dx = 0;
  double dy = 0;
  double dxSpeed = 1.0;
  double dySpeed = 1.0;
  Random random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: (6 ~/ widget.speed)),
      vsync: this,
    )..repeat(reverse: false);

    _controller.addListener(() {
      setState(() {
        dx += dxSpeed * widget.speed;
        dy += dySpeed * widget.speed;

        if (random.nextDouble() > 0.98) {
          dxSpeed = randomDirection(dxSpeed);
          dySpeed = randomDirection(dySpeed);
        }

        if (dx >= 280 || dx <= 0) {
          dxSpeed = -dxSpeed;
        }

        if (dy >= 280 || dy <= 0) {
          dySpeed = -dySpeed;
        }
      });
    });
  }

 
  double randomDirection(double currentSpeed) {
    return random.nextBool() ? currentSpeed : -currentSpeed;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: dx,
      top: dy,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
