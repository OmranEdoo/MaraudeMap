import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../config/theme.dart';
import '../models/maraude.dart';
import '../widgets/date_selector_bar.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const LatLng _parisCenter = LatLng(48.8566, 2.3522);
  static const double _ileDeFranceZoom = 9.4;
  static const double _minMapZoom = 5;
  static const double _maxMapZoom = 18;

  final MapController _mapController = MapController();
  DateTime selectedDate = DateTime.now();
  String selectedFilterAssociation = 'Tous';
  bool isAssociationFilterVisible = false;

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

  void _toggleAssociationFilterBar() {
    setState(() {
      isAssociationFilterVisible = !isAssociationFilterVisible;
    });
  }

  void _recenterMap() {
    _mapController.move(_parisCenter, _ileDeFranceZoom);
  }

  void _zoomIn() {
    final camera = _mapController.camera;
    final zoom = (camera.zoom + 1).clamp(_minMapZoom, _maxMapZoom).toDouble();
    _mapController.move(camera.center, zoom);
  }

  void _zoomOut() {
    final camera = _mapController.camera;
    final zoom = (camera.zoom - 1).clamp(_minMapZoom, _maxMapZoom).toDouble();
    _mapController.move(camera.center, zoom);
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

  List<String> _associationOptions() {
    final options = <String>['Tous'];
    for (final maraude in maraudes) {
      if (!options.contains(maraude.associationName)) {
        options.add(maraude.associationName);
      }
    }
    return options;
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
        .where(
          (maraude) =>
              selectedFilterAssociation == 'Tous' ||
              maraude.associationName == selectedFilterAssociation,
        )
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

  Widget _buildMapControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    BorderRadius? borderRadius,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: borderRadius,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(
            icon,
            size: 24,
            color: AppTheme.textPrimaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildMapControls() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildMapControlButton(
            icon: Icons.add,
            onPressed: _zoomIn,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          Divider(height: 1, color: Colors.grey[300]),
          _buildMapControlButton(
            icon: Icons.remove,
            onPressed: _zoomOut,
          ),
          Divider(height: 1, color: Colors.grey[300]),
          _buildMapControlButton(
            icon: Icons.gps_fixed,
            onPressed: _recenterMap,
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(16)),
          ),
        ],
      ),
    );
  }

  Widget _buildAssociationFilterChip() {
    final label = selectedFilterAssociation == 'Tous'
        ? 'Association'
        : 'Association : $selectedFilterAssociation';

    return PopupMenuButton<String>(
      onSelected: (value) {
        setState(() {
          selectedFilterAssociation = value;
        });
      },
      itemBuilder: (BuildContext context) {
        return _associationOptions().map<PopupMenuItem<String>>((String value) {
          return PopupMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.primaryColor),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_drop_down,
              color: AppTheme.primaryColor,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssociationFilterBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          const Text(
            'Filtrer par :',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildAssociationFilterChip(),
          ),
        ],
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
            icon: Image.asset(
              'assets/images/logo_sans_texte.png',
              width: 28,
              height: 28,
            ),
            onPressed: _recenterMap,
          ),
        ],
      ),
      body: Column(
        children: [
          DateSelectorBar(
            selectedDate: selectedDate,
            onLeftPressed: _goToPreviousDay,
            onRightPressed: _goToNextDay,
          ),
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _parisCenter,
                    initialZoom: _ileDeFranceZoom,
                    minZoom: _minMapZoom,
                    maxZoom: _maxMapZoom,
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
                  top: 16,
                  left: 16,
                  child: _buildMapControls(),
                ),
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: 64,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(36),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 24,
                          offset: Offset(0, 12),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Ajouter une maraude'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_rounded, size: 28),
                      label: const Text('Ajouter une maraude'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3558D4),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        minimumSize: const Size.fromHeight(72),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 18,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(36),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeInOut,
            child: isAssociationFilterVisible
                ? _buildAssociationFilterBar()
                : const SizedBox.shrink(),
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
                GestureDetector(
                  onTap: _toggleAssociationFilterBar,
                  child: Column(
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
                ),
                GestureDetector(
                  onTap: _goToListScreen,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.list,
                        color: AppTheme.primaryColor,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Liste',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
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
