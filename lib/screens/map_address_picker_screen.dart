import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../config/theme.dart';

class MapAddressPickerScreen extends StatefulWidget {
  const MapAddressPickerScreen({
    super.key,
    this.initialLocation,
  });

  final PickedMapLocation? initialLocation;

  @override
  State<MapAddressPickerScreen> createState() => _MapAddressPickerScreenState();
}

class _MapAddressPickerScreenState extends State<MapAddressPickerScreen> {
  static const LatLng _parisCenter = LatLng(48.8566, 2.3522);
  static const double _defaultZoom = 13.2;
  static const String _selectedPointLabel = 'Point selectionne sur la carte';

  final MapController _mapController = MapController();
  LatLng? _selectedPoint;

  @override
  void initState() {
    super.initState();
    _selectedPoint = widget.initialLocation?.point;
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _confirmSelection() {
    final selectedPoint = _selectedPoint;
    if (selectedPoint == null) {
      return;
    }

    Navigator.of(context).pop(
      PickedMapLocation(
        point: selectedPoint,
        label: _selectedPointLabel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedPoint = _selectedPoint;
    final previewText = selectedPoint == null
        ? 'Touchez la carte pour placer la maraude.'
        : 'Point selectionne. Vous pourrez nommer cet endroit dans le formulaire.';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choisir sur la carte'),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selectionnez l\'emplacement de la maraude.',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  previewText,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: selectedPoint ?? _parisCenter,
                initialZoom: selectedPoint == null ? _defaultZoom : 15,
                interactionOptions: InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                  cursorKeyboardRotationOptions:
                      CursorKeyboardRotationOptions.disabled(),
                ),
                onTap: (_, point) {
                  setState(() {
                    _selectedPoint = point;
                  });
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.maraude_map',
                  maxNativeZoom: 19,
                ),
                MarkerLayer(
                  markers: [
                    if (selectedPoint != null)
                      Marker(
                        point: selectedPoint,
                        width: 52,
                        height: 52,
                        child: const Icon(
                          Icons.location_on,
                          size: 46,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                  ],
                ),
                const SimpleAttributionWidget(
                  source: Text('OpenStreetMap contributors'),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        side: const BorderSide(color: AppTheme.primaryColor),
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          selectedPoint == null ? null : _confirmSelection,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: const Text('Utiliser ce point'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PickedMapLocation {
  const PickedMapLocation({
    required this.point,
    required this.label,
  });

  final LatLng point;
  final String label;
}
