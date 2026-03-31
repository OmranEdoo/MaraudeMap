import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/maraude.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  DateTime selectedDate = DateTime.now();

  // Sample data - à remplacer par des vraies données
  final List<Maraude> maraudes = [
    Maraude(
      id: '1',
      associationName: 'TAYBA',
      location: 'Stallingrad',
      address: '75 001 Paris',
      date: DateTime.now(),
      startTime: '19h',
      endTime: '20h',
      estimatedPlates: 100,
      distributionType: 'Repas',
      latitude: 48.8835,
      longitude: 2.3619,
      status: MaraudeStatus.planned,
    ),
    Maraude(
      id: '2',
      associationName: 'EILMY',
      location: 'Pont-Marie',
      address: '75 004 Paris',
      date: DateTime.now(),
      startTime: '20h30',
      endTime: '21h',
      estimatedPlates: 120,
      distributionType: 'Distribustion',
      latitude: 48.8530,
      longitude: 2.3610,
      status: MaraudeStatus.planned,
    ),
  ];

  void _goToNextDay() {
    setState(() {
      selectedDate = selectedDate.add(const Duration(days: 1));
    });
  }

  void _goToPreviousDay() {
    setState(() {
      selectedDate = selectedDate.subtract(const Duration(days: 1));
    });
  }

  void _goToListScreen() {
    Navigator.pushReplacementNamed(context, '/list');
  }

  void _goToAuthenticateScreen() {
    Navigator.pushReplacementNamed(context, '/authenticate');
  }

  void _openMaraudeDetail(Maraude maraude) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              maraude.associationName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text('${maraude.startTime} - ${maraude.endTime}'),
            const SizedBox(height: 10),
            Text(maraude.location),
            const SizedBox(height: 10),
            Text('${maraude.estimatedPlates} Plats'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Prévoir une maraude')),
                );
              },
              child: const Text('Prévoir une maraude'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: _goToAuthenticateScreen,
        ),
        title: const Text('MaraudeMap'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.location_on),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Calendar Navigation Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _goToPreviousDay,
                ),
                Column(
                  children: [
                    Text(
                      'Aujourd\'hui',
                      style: TextStyle(
                        fontSize: 14,
                        color: selectedDate.day == DateTime.now().day
                            ? AppTheme.primaryColor
                            : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${selectedDate.day}/${selectedDate.month}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _goToNextDay,
                ),
              ],
            ),
          ),
          // Map (placeholder)
          Expanded(
            child: Container(
              color: Colors.white,
              child: Stack(
                children: [
                  // Map placeholder
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.map,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Carte intégrée\n(Google Maps / Leaflet)',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Markers (sample)
                  Positioned(
                    top: 100,
                    left: 150,
                    child: GestureDetector(
                      onTap: () => _openMaraudeDetail(maraudes[0]),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: AppTheme.dangerColor,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(8),
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 200,
                    right: 80,
                    child: GestureDetector(
                      onTap: () => _openMaraudeDetail(maraudes[1]),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: AppTheme.warningColor,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(8),
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  // Add maraude button
                  Positioned(
                    bottom: 80,
                    right: 20,
                    child: FloatingActionButton.extended(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Ajouter une maraude'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Ajouter une maraude'),
                      backgroundColor: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Bottom Navigation Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.tune,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Filtre',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: _goToListScreen,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.list,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Liste',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
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
    );
  }
}
