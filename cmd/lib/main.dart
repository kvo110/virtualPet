import 'dart:async';
import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(
    home: DigitalPetApp(),
    theme: ThemeData(
      scaffoldBackgroundColor: Colors.blueGrey[300], // sets background color to a light grey 
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.orange, // text color set to orange
        ),
      ),
    ),
  ));
}

class DigitalPetApp extends StatefulWidget {
  @override
  _DigitalPetAppState createState() => _DigitalPetAppState();
}

class _DigitalPetAppState extends State<DigitalPetApp> {
  // State variables
  String petName = "Your Pet";
  int happinessLevel = 50;
  int hungerLevel = 50;
  int _energyLevel = 100;

  // Name input
  TextEditingController _nameController = TextEditingController();
  bool _nameSet = false;

  // Timers
  Timer? _hungerTimer;
  Timer? _statusTimer;
  Duration _happyAccumulated = Duration.zero;
  bool _gameOver = false;
  bool _win = false;

  // Activity selection drop down menu
  final List<String> _activities = ['Walk', 'Sleep', 'Dance', 'Cuddle'];
  String _selectedActivity = 'Walk';

  @override
  void initState() {
    super.initState();
    _startTimers();
  }

  @override
  void dispose() {
    _hungerTimer?.cancel();
    _statusTimer?.cancel();
    _nameController.dispose();
    super.dispose();
  }


  String getPetImage() {
    if (happinessLevel > 70) return 'assets/images/pet_happy.png'; // sets the happy dino if the happiness level is above 70
    if (happinessLevel >= 30) return 'assets/images/pet_neutral.png'; // sets the neutral feeling dino when happiness level is between 30 and 70
    return 'assets/images/pet_sad.png'; // otherwise, shows mad dino
  }

  String _getMood() {
    if (happinessLevel > 70) return 'Happy 😀'; // shows happy if happiness level is above 70
    if (happinessLevel >= 30) return 'Neutral 😐'; // shows neutral if happiness level is between 30 and 70
    return 'Unhappy 😢'; // shows unhappy if levels is below 30
  }

  void _clampStats() {
    if (happinessLevel > 100) happinessLevel = 100;
    if (happinessLevel < 0) happinessLevel = 0;
    if (hungerLevel > 100) hungerLevel = 100;
    if (hungerLevel < 0) hungerLevel = 0;
    if (_energyLevel > 100) _energyLevel = 100;
    if (_energyLevel < 0) _energyLevel = 0;
  }

  void _updateHappiness() {
    if (hungerLevel < 30) happinessLevel -= 20;
    else happinessLevel += 10;
  }

  void _updateHunger({int delta = 5}) {
    hungerLevel += delta;
    if (hungerLevel > 100) {
      hungerLevel = 100;
      happinessLevel -= 20;
    }
  }

  void _checkGameStatus() {
    if (hungerLevel >= 100 && happinessLevel <= 10 && !_gameOver) {
      _gameOver = true;
      _cancelTimers();
      if (mounted) _showEndDialog(
          'Game Over', 'Your pet became too hungry and too unhappy.');
    }
  }

  void _showEndDialog(String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetGame();
            },
            child: Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _cancelTimers() {
    _hungerTimer?.cancel();
    _statusTimer?.cancel();
  }

  void _startTimers() {
    _hungerTimer?.cancel();
    _statusTimer?.cancel();

    // Increment the increase of the pet's hunger every 30 seconds
    _hungerTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      if (!_gameOver && !_win) {
        setState(() {
          _updateHunger(delta: 5);
          _clampStats();
          _checkGameStatus();
        });
      }
    });

    // Tracks the consistency of the happiness of the pet to determine if user is winning 
    _statusTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!_gameOver && !_win) {
        setState(() {
          if (happinessLevel > 80) {
            _happyAccumulated += Duration(seconds: 1);
            if (_happyAccumulated >= Duration(minutes: 3)) {
              _win = true;
              _cancelTimers();
              if (mounted)
                _showEndDialog(
                    'Congratulations!', 'You kept your pet happy for 3 minutes');
            }
          } else {
            _happyAccumulated = Duration.zero;
          }
        });
      }
    });
  }

  void _resetGame() {
    setState(() {
      petName = 'Your Pet';
      _nameSet = false;
      happinessLevel = 50;
      hungerLevel = 50;
      _energyLevel = 100;
      _happyAccumulated = Duration.zero;
      _gameOver = false;
      _win = false;
      _selectedActivity = _activities[0];
    });
    _startTimers();
  }

  void _playWithPet() {
    if (_gameOver || _win) return;
    setState(() {
      happinessLevel += 10;
      hungerLevel += 5;
      _energyLevel -= 10;
      _updateHappiness();
      _clampStats();
      _checkGameStatus();
    });
  }

  void _feedPet() {
    if (_gameOver || _win) return;
    setState(() {
      hungerLevel -= 10;
      if (hungerLevel < 0) hungerLevel = 0;
      _updateHappiness();
      _clampStats();
      _checkGameStatus();
    });
  }

  void _performActivity() {
    if (_gameOver || _win) return;
    setState(() {
      switch (_selectedActivity) {
        case 'Walk':
          happinessLevel += 15;
          _energyLevel -= 20;
          hungerLevel += 10;
          break;
        case 'Sleep':
          _energyLevel += 25;
          happinessLevel += 5;
          hungerLevel += 5;
          break;
        case 'Dance':
          happinessLevel += 20;
          _energyLevel -= 30;
          hungerLevel += 15;
          break;
        case 'Cuddle':
        default:
          happinessLevel += 10;
      }
      _clampStats();
      _checkGameStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Digital Pet')),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 24),

              // Pet name input
              if (!_nameSet) ...[
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Enter your pet\'s name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      petName = _nameController.text.trim().isEmpty
                          ? 'Your Pet'
                          : _nameController.text.trim();
                      _nameSet = true;
                    });
                  },
                  child: Text('Set Name'),
                ),
                SizedBox(height: 16),
              ],

              // Pet Image
              Image.asset(
                getPetImage(),
                width: 300,
                height: 300,
                fit: BoxFit.cover,
              ),

              SizedBox(height: 15),

              // Name and Mood
              Text('Name: $petName', style: TextStyle(fontSize: 20)),
              SizedBox(height: 8),
              Text('Mood: ${_getMood()}', style: TextStyle(fontSize: 18)),

              SizedBox(height: 16),

              // Status bars
              _buildStatusBar('Happiness', happinessLevel, Colors.yellow),
              _buildStatusBar('Hunger', hungerLevel, Colors.red),
              _buildStatusBar('Energy', _energyLevel, Colors.blue),

              SizedBox(height: 24),

              // Play / Feed buttons
              ElevatedButton(onPressed: _playWithPet, child: Text('Play')),
              SizedBox(height: 16),
              ElevatedButton(onPressed: _feedPet, child: Text('Feed')),

              SizedBox(height: 24),

              // Activity selection
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButton<String>(
                        value: _selectedActivity,
                        isExpanded: true,
                        onChanged: (String? newValue) {
                          if (newValue == null) return;
                          setState(() => _selectedActivity = newValue);
                        },
                        items: _activities
                            .map((activity) => DropdownMenuItem<String>(
                                  value: activity,
                                  child: Text(activity),
                                ))
                            .toList(),
                      ),
                    ),
                    SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _performActivity,
                      child: Text('Do Activity'),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),

              // Reset button
              ElevatedButton(
                onPressed: _resetGame,
                child: Text('Reset'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
              ),

              SizedBox(height: 32),

              if (_gameOver)
                Text('Game Over!', style: TextStyle(color: Colors.red)),
              if (_win)
                Text('You Win!', style: TextStyle(color: Colors.green)),
            ],
          ),
        ),
      ),
    );
  }

  // Helper for status bars
  Widget _buildStatusBar(String label, int value, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 4),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label),
              Text('$value%', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 4),
          LinearProgressIndicator(
            value: value / 100,
            color: color,
            backgroundColor: Colors.grey[300],
            minHeight: 10,
          ),
        ],
      ),
    );
  }
}