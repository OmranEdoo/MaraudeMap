import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../config/theme.dart';
import '../models/maraude.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const LatLng _parisCenter = LatLng(48.8566, 2.3522);
  static const double _ileDeFranceZoom = 9.4;

  final MapController _mapController = MapController();
  DateTime selectedDate = DateTime.now();

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
      distributionType: 'Distribution',
      latitude: 48.8530,
      longitude: 2.3610,
      status: MaraudeStatus.planned,
    ),
  ];

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

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

  void _recenterMap() {
    _mapController.move(_parisCenter, _ileDeFranceZoom);
  }

  Color _markerColorFor(Maraude maraude) {
    switch (maraude.status) {
      case MaraudeStatus.completed:
        return AppTheme.successColor;
      case MaraudeStatus.ongoing:
        return AppTheme.dangerColor;
      case MaraudeStatus.planned:
        return maraude.estimatedPlates >= 100
            ? AppTheme.dangerColor
            : AppTheme.warningColor;
    }
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
                  const SnackBar(content: Text('Prevoir une maraude')),
                );
              },
              child: const Text('Prevoir une maraude'),
            ),
          ],
        ),
      ),
    );
  }

  List<Marker> _buildMarkers() {
    return maraudes
        .map(
          (maraude) => Marker(
            point: LatLng(maraude.latitude, maraude.longitude),
            width: 48,
            height: 48,
            child: GestureDetector(
              onTap: () => _openMaraudeDetail(maraude),
              child: Icon(
                Icons.location_on,
                size: 42,
                color: _markerColorFor(maraude),
              ),
            ),
          ),
        )
        .toList();
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
            onPressed: _recenterMap,
          ),
        ],
      ),
      body: Column(
        children: [
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
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _parisCenter,
                    initialZoom: _ileDeFranceZoom,
                    minZoom: 5,
                    maxZoom: 18,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.maraude_map',
                      maxNativeZoom: 19,
                    ),
                    MarkerLayer(
                      markers: _buildMarkers(),
                    ),
                    const SimpleAttributionWidget(
                      source: Text('OpenStreetMap contributors'),
                    ),
                  ],
                ),
                Positioned(
                  bottom: 20,
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
