// import 'package:flutter/material.dart';

// class MoodTrackingScreen extends StatefulWidget {
//   const MoodTrackingScreen({super.key});

//   @override
//   _MoodTrackingScreenState createState() => _MoodTrackingScreenState();
// }

// class _MoodTrackingScreenState extends State<MoodTrackingScreen> {
//   final List<Map<String, String>> moodHistory = [
//     {'date': 'Dec 7, 2024', 'mood': 'Happy', 'note': 'Had a great day!'},
//     {'date': 'Dec 6, 2024', 'mood': 'Stressed', 'note': 'Busy with work.'},
//     {'date': 'Dec 5, 2024', 'mood': 'Calm', 'note': 'Enjoyed meditation.'},
//   ];

//   String selectedMood = '';
//   final TextEditingController noteController = TextEditingController();

//   void logMood(String mood) {
//     setState(() {
//       moodHistory.insert(0, {
//         'date': DateTime.now().toString().split(' ')[0],
//         'mood': mood,
//         'note': noteController.text,
//       });
//       selectedMood = '';
//       noteController.clear();
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Mood Tracker'),
//         backgroundColor: Colors.purple
//       ),
//       body: SingleChildScrollView(
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Section: Log Current Mood
//               SectionTitle(title: 'Log Your Mood'),
//               Wrap(
//                 spacing: 10,
//                 children: [
//                   MoodButton(
//                     mood: 'Happy',
//                     icon: Icons.sentiment_very_satisfied,
//                     isSelected: selectedMood == 'Happy',
//                     onTap: () {
//                       setState(() {
//                         selectedMood = 'Happy';
//                       });
//                     },
//                   ),
//                   MoodButton(
//                     mood: 'Sad',
//                     icon: Icons.sentiment_dissatisfied,
//                     isSelected: selectedMood == 'Sad',
//                     onTap: () {
//                       setState(() {
//                         selectedMood = 'Sad';
//                       });
//                     },
//                   ),
//                   MoodButton(
//                     mood: 'Calm',
//                     icon: Icons.self_improvement,
//                     isSelected: selectedMood == 'Calm',
//                     onTap: () {
//                       setState(() {
//                         selectedMood = 'Calm';
//                       });
//                     },
//                   ),
//                   MoodButton(
//                     mood: 'Stressed',
//                     icon: Icons.sentiment_neutral,
//                     isSelected: selectedMood == 'Stressed',
//                     onTap: () {
//                       setState(() {
//                         selectedMood = 'Stressed';
//                       });
//                     },
//                   ),
//                 ],
//               ),
//               SizedBox(height: 10),
//               TextField(
//                 controller: noteController,
//                 decoration: InputDecoration(
//                   labelText: 'Add a note (optional)',
//                   border: OutlineInputBorder(),
//                 ),
//                 maxLines: 3,
//               ),
//               SizedBox(height: 10),
//               ElevatedButton(
//                 onPressed: selectedMood.isNotEmpty
//                     ? () => logMood(selectedMood)
//                     : null,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.purple
//                 ),
//                 child: Text(
//                   'Save Mood',
//                   style: TextStyle(color: Colors.black),
//                 ),
//               ),
//               SizedBox(height: 20),

//               // Section: Mood History
//               SectionTitle(title: 'Mood History'),
//               ListView.builder(
//                 shrinkWrap: true,
//                 physics: NeverScrollableScrollPhysics(),
//                 itemCount: moodHistory.length,
//                 itemBuilder: (context, index) {
//                   final mood = moodHistory[index];
//                   return Card(
//                     margin: EdgeInsets.symmetric(vertical: 8),
//                     child: ListTile(
//                       leading: Icon(
//                         _getMoodIcon(mood['mood'] ?? ''),
//                         color: Colors.purple
//                       ),
//                       title: Text(mood['mood'] ?? ''),
//                       subtitle: Text(
//                           '${mood['date'] ?? ''}\n${mood['note'] ?? ''}'),
//                       isThreeLine: true,
//                     ),
//                   );
//                 },
//               ),
//               SizedBox(height: 20),

//               // Section: Insights
//               SectionTitle(title: 'Your Mood Insights'),
//               Center(
//                 child: Container(
//                   height: 200,
//                   width: double.infinity,
//                   decoration: BoxDecoration(
//                     color: Colors.blue.shade50,
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   child: Center(
//                     child: Text(
//                       'Mood analytics and graphs will be here.',
//                       textAlign: TextAlign.center,
//                       style: TextStyle(color: Colors.blueGrey),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   IconData _getMoodIcon(String mood) {
//     switch (mood) {
//       case 'Happy':
//         return Icons.sentiment_very_satisfied;
//       case 'Sad':
//         return Icons.sentiment_dissatisfied;
//       case 'Calm':
//         return Icons.self_improvement;
//       case 'Stressed':
//         return Icons.sentiment_neutral;
//       default:
//         return Icons.sentiment_satisfied;
//     }
//   }
// }

// class SectionTitle extends StatelessWidget {
//   final String title;

//   const SectionTitle({super.key, required this.title});

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8.0),
//       child: Text(
//         title,
//         style: TextStyle(
//           fontSize: 18,
//           fontWeight: FontWeight.bold,
//           color: Colors.purple,
//         ),
//       ),
//     );
//   }
// }

// class MoodButton extends StatelessWidget {
//   final String mood;
//   final IconData icon;
//   final bool isSelected;
//   final VoidCallback onTap;

//   const MoodButton({super.key,
//     required this.mood,
//     required this.icon,
//     required this.isSelected,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Column(
//         children: [
//           CircleAvatar(
//             radius: 30,
//             backgroundColor: isSelected ? Colors.purple : Colors.grey[200],
//             child: Icon(icon, color: isSelected ? Colors.white : Colors.grey),
//           ),
//           SizedBox(height: 5),
//           Text(mood, style: TextStyle(fontSize: 12)),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:myapp/theme/app_theme.dart';
import 'package:provider/provider.dart';

// State management for user ID
class MoodUserProvider with ChangeNotifier {
  String? _userId;

  String? get userId => _userId;

  void setUserId(String userId) {
    _userId = userId;
    notifyListeners();
  }

  void clearUserId() {
    _userId = null;
    notifyListeners();
  }
}

// Login Screen
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login(BuildContext context) async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(
            'http:// 192.168.2.102:3000/api/users/login'), // Replace with your backend IP
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': emailController.text,
          'password': passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final userId = data['userId'];
        Provider.of<MoodUserProvider>(context, listen: false).setUserId(userId);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MoodTrackingScreen()),
        );
      } else {
        final error = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error['error'] ?? 'Login failed')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : () => _login(context),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Login', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

// Mood Tracking Screen
class MoodTrackingScreen extends StatefulWidget {
  const MoodTrackingScreen({super.key});

  @override
  _MoodTrackingScreenState createState() => _MoodTrackingScreenState();
}

class _MoodTrackingScreenState extends State<MoodTrackingScreen> {
  List<MoodEntry> moodHistory = [];
  String selectedMood = '';
  final TextEditingController noteController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchMoodHistory();
  }

  Future<void> _fetchMoodHistory() async {
    final userId = Provider.of<MoodUserProvider>(context, listen: false).userId;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('http:// 192.168.2.102:3000/api/users/$userId/mood'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          moodHistory = data.map((json) => MoodEntry.fromJson(json)).toList();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load mood history')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _logMood() async {
    if (selectedMood.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a mood')),
      );
      return;
    }

    final userId = Provider.of<MoodUserProvider>(context, listen: false).userId;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final body = jsonEncode({
        'userId': userId,
        'mood': selectedMood,
        'note': noteController.text,
      });
      print('Sending mood entry: $body');
      final response = await http.post(
        Uri.parse('http:// 192.168.2.102:3000/api/users/$userId/mood'),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mood entry saved successfully')),
        );
        setState(() {
          selectedMood = '';
          noteController.clear();
        });
        await _fetchMoodHistory();
      } else {
        final error = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error['error'] ?? 'Failed to save mood')),
        );
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteMoodEntry(String moodId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.delete(
        Uri.parse(
            'https://mindease-backend-production.up.railway.app/api/mood/$moodId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mood entry deleted successfully')),
        );
        await _fetchMoodHistory();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete mood entry')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mood Tracker'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle(title: 'Log Your Mood'),
                  Wrap(
                    spacing: 10,
                    children: [
                      MoodButton(
                        mood: 'Happy',
                        icon: Icons.sentiment_very_satisfied,
                        isSelected: selectedMood == 'Happy',
                        onTap: () {
                          setState(() {
                            selectedMood = 'Happy';
                          });
                        },
                      ),
                      MoodButton(
                        mood: 'Sad',
                        icon: Icons.sentiment_dissatisfied,
                        isSelected: selectedMood == 'Sad',
                        onTap: () {
                          setState(() {
                            selectedMood = 'Sad';
                          });
                        },
                      ),
                      MoodButton(
                        mood: 'Calm',
                        icon: Icons.self_improvement,
                        isSelected: selectedMood == 'Calm',
                        onTap: () {
                          setState(() {
                            selectedMood = 'Calm';
                          });
                        },
                      ),
                      MoodButton(
                        mood: 'Stressed',
                        icon: Icons.sentiment_neutral,
                        isSelected: selectedMood == 'Stressed',
                        onTap: () {
                          setState(() {
                            selectedMood = 'Stressed';
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(
                      labelText: 'Add a note (optional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: selectedMood.isNotEmpty && !_isLoading
                        ? _logMood
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                    ),
                    child: const Text(
                      'Save Mood',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const SectionTitle(title: 'Mood History'),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : moodHistory.isEmpty
                          ? const Center(child: Text('No mood entries yet'))
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: moodHistory.length,
                              itemBuilder: (context, index) {
                                final mood = moodHistory[index];
                                return Card(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  child: ListTile(
                                    leading: Icon(
                                      _getMoodIcon(mood.mood),
                                      color: AppTheme.primaryColor,
                                    ),
                                    title: Text(mood.mood),
                                    subtitle: Text(
                                      '${DateFormat('MMM d, yyyy').format(mood.createdAt)}\n${mood.note.isEmpty ? 'No note' : mood.note}',
                                    ),
                                    isThreeLine: true,
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title:
                                                const Text('Delete Mood Entry'),
                                            content: const Text(
                                                'Are you sure you want to delete this mood entry?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                child: const Text('Cancel'),
                                              ),
                                              ElevatedButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                  _deleteMoodEntry(mood.id);
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.red,
                                                ),
                                                child: const Text('Delete',
                                                    style: TextStyle(
                                                        color: Colors.white)),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                  const SizedBox(height: 20),
                  const SectionTitle(title: 'Your Mood Insights'),
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Text(
                        'Mood analytics and graphs will be here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.blueGrey),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  IconData _getMoodIcon(String mood) {
    switch (mood) {
      case 'Happy':
        return Icons.sentiment_very_satisfied;
      case 'Sad':
        return Icons.sentiment_dissatisfied;
      case 'Calm':
        return Icons.self_improvement;
      case 'Stressed':
        return Icons.sentiment_neutral;
      default:
        return Icons.sentiment_satisfied;
    }
  }
}

class SectionTitle extends StatelessWidget {
  final String title;

  const SectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }
}

class MoodButton extends StatelessWidget {
  final String mood;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const MoodButton({
    super.key,
    required this.mood,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor:
                isSelected ? AppTheme.primaryColor : Colors.grey[200],
            child: Icon(icon, color: isSelected ? Colors.white : Colors.grey),
          ),
          const SizedBox(height: 5),
          Text(mood, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class MoodEntry {
  final String id;
  final String mood;
  final String note;
  final DateTime createdAt;

  MoodEntry({
    required this.id,
    required this.mood,
    required this.note,
    required this.createdAt,
  });

  factory MoodEntry.fromJson(Map<String, dynamic> json) {
    return MoodEntry(
      id: json['_id'] ?? '',
      mood: json['mood'] ?? '',
      note: json['note'] ?? '',
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

// Main function
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => MoodUserProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mood Tracker',
      theme: ThemeData(
        primarySwatch: Colors.indigo, // Closest to AppTheme.primaryColor
        primaryColor: AppTheme.primaryColor,
      ),
      home: const LoginScreen(),
    );
  }
}
