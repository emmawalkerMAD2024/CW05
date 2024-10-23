import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  runApp(AquariumApp());
}

class AquariumApp extends StatelessWidget {
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

  @override
  void initState() {
    super.initState();
    _loadSettings(); // Load settings from local storage
  }

  // Initialize SQLite database
  Future<Database> _initDatabase() async {
    return openDatabase(
      join(await getDatabasesPath(), 'aquarium.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE settings(id INTEGER PRIMARY KEY, fishCount INTEGER, speed REAL, color TEXT)',
        );
      },
      version: 1,
    );
  }

  // Save settings to SQLite
  Future<void> _saveSettings() async {
    final db = await _initDatabase();
    await db.insert(
      'settings',
      {
        'fishCount': fishList.length,
        'speed': selectedSpeed,
        'color': selectedColor.value.toString(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Load settings from SQLite
  Future<void> _loadSettings() async {
    final db = await _initDatabase();
    final List<Map<String, dynamic>> settings = await db.query('settings');
    if (settings.isNotEmpty) {
      final Map<String, dynamic> savedSettings = settings.first;
      setState(() {
        selectedSpeed = savedSettings['speed'];
        selectedColor = Color(int.parse(savedSettings['color']));
        for (int i = 0; i < savedSettings['fishCount']; i++) {
          fishList.add(Fish(color: selectedColor, speed: selectedSpeed));
        }
      });
    }
  }

  // Add a new fish to the aquarium
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
          Slider(
            value: selectedSpeed,
            min: 0.5,
            max: 5.0,
            label: selectedSpeed.toString(),
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
            onPressed: _saveSettings,
            child: Text("Save Settings"),
          ),
        ],
      ),
    );
  }
}

class Fish extends StatefulWidget {
   Color color;
   double speed;

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

        // Reverse direction when hitting horizontal boundaries (width)
        if (dx >= 280 || dx <= 0) {
          dxSpeed = -dxSpeed;
        }
        
        // Reverse direction when hitting vertical boundaries (height)
        if (dy >= 280 || dy <= 0) {
          dySpeed = -dySpeed;
        }
      });
    });
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

