import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../config/theme.dart';

enum _AddressInputMode { manual, map }

class CreateMaraudeScreen extends StatefulWidget {
  const CreateMaraudeScreen({
    super.key,
    required this.initialAssociation,
  });

  final String initialAssociation;

  @override
  State<CreateMaraudeScreen> createState() => _CreateMaraudeScreenState();
}

class _CreateMaraudeScreenState extends State<CreateMaraudeScreen> {
  static const List<String> _distributionTypes = [
    'Repas',
    'Distribution',
    'Petit-dejeuner',
    'Boissons',
    'Collation',
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _associationController;
  final _addressController = TextEditingController();
  final _estimatedPlatesController = TextEditingController(text: '100');
  final _commentController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String _selectedDistributionType = _distributionTypes.first;
  _AddressInputMode _addressInputMode = _AddressInputMode.manual;
  _PickedMapLocation? _pickedMapLocation;
  bool _showValidationErrors = false;

  @override
  void initState() {
    super.initState();
    _associationController =
        TextEditingController(text: widget.initialAssociation);
  }

  @override
  void dispose() {
    _associationController.dispose();
    _addressController.dispose();
    _estimatedPlatesController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );

    if (pickedDate == null) {
      return;
    }

    setState(() {
      _selectedDate = pickedDate;
    });
  }

  Future<void> _pickTime({
    required bool isStartTime,
  }) async {
    final fallbackInitialTime = isStartTime
        ? const TimeOfDay(hour: 19, minute: 0)
        : const TimeOfDay(hour: 20, minute: 0);
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: isStartTime
          ? (_startTime ?? fallbackInitialTime)
          : (_endTime ?? fallbackInitialTime),
    );

    if (pickedTime == null) {
      return;
    }

    setState(() {
      if (isStartTime) {
        _startTime = pickedTime;
      } else {
        _endTime = pickedTime;
      }
    });
  }

  Future<void> _pickAddressOnMap() async {
    final pickedLocation = await Navigator.of(context).push<_PickedMapLocation>(
      MaterialPageRoute(
        builder: (context) => _MapAddressPickerScreen(
          initialLocation: _pickedMapLocation,
        ),
      ),
    );

    if (pickedLocation == null) {
      return;
    }

    setState(() {
      _pickedMapLocation = pickedLocation;
      _addressController.text = pickedLocation.label;
    });
  }

  void _saveForm() {
    setState(() {
      _showValidationErrors = true;
    });

    final isFormValid = _formKey.currentState?.validate() ?? false;
    final hasSelectionErrors = _validateDate() != null ||
        _validateStartTime() != null ||
        _validateEndTime() != null ||
        _validateMapAddress() != null;

    if (!isFormValid || hasSelectionErrors) {
      return;
    }

    Navigator.of(context).pop(true);
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  int _timeInMinutes(TimeOfDay time) => time.hour * 60 + time.minute;

  String? _validateDate() {
    if (_selectedDate == null) {
      return 'Selectionnez une date.';
    }

    return null;
  }

  String? _validateStartTime() {
    if (_startTime == null) {
      return 'Selectionnez une heure de debut.';
    }

    return null;
  }

  String? _validateEndTime() {
    if (_endTime == null) {
      return 'Selectionnez une heure de fin.';
    }

    if (_startTime != null &&
        _timeInMinutes(_endTime!) <= _timeInMinutes(_startTime!)) {
      return 'L\'heure de fin doit etre apres l\'heure de debut.';
    }

    return null;
  }

  String? _validateMapAddress() {
    if (_addressInputMode == _AddressInputMode.map && _pickedMapLocation == null) {
      return 'Selectionnez une adresse sur la carte.';
    }

    return null;
  }

  Widget _buildSelectionField({
    required String label,
    required String placeholder,
    required String? value,
    required IconData icon,
    required VoidCallback onTap,
    String? errorText,
  }) {
    final hasValue = value != null && value.isNotEmpty;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: Icon(icon),
          errorText: errorText,
        ),
        child: Text(
          hasValue ? value : placeholder,
          style: TextStyle(
            fontSize: 16,
            color: hasValue
                ? AppTheme.textPrimaryColor
                : AppTheme.textSecondaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildAddressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Adresse *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 12),
        SegmentedButton<_AddressInputMode>(
          segments: const [
            ButtonSegment<_AddressInputMode>(
              value: _AddressInputMode.manual,
              icon: Icon(Icons.edit_location_alt_outlined),
              label: Text('Saisie'),
            ),
            ButtonSegment<_AddressInputMode>(
              value: _AddressInputMode.map,
              icon: Icon(Icons.map_outlined),
              label: Text('Carte'),
            ),
          ],
          selected: <_AddressInputMode>{_addressInputMode},
          onSelectionChanged: (selection) {
            setState(() {
              _addressInputMode = selection.first;
              if (_addressInputMode == _AddressInputMode.map &&
                  _pickedMapLocation != null) {
                _addressController.text = _pickedMapLocation!.label;
              }
            });
          },
          showSelectedIcon: false,
          style: ButtonStyle(
            foregroundColor:
                MaterialStateProperty.all(AppTheme.primaryColor),
          ),
        ),
        const SizedBox(height: 16),
        if (_addressInputMode == _AddressInputMode.manual)
          TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'Adresse de la maraude *',
              hintText: 'Ex : 15 rue de Paris, 75010 Paris',
            ),
            validator: (value) {
              if (_addressInputMode != _AddressInputMode.manual) {
                return null;
              }

              if (value == null || value.trim().isEmpty) {
                return 'Saisissez une adresse.';
              }

              return null;
            },
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _showValidationErrors && _validateMapAddress() != null
                    ? Theme.of(context).colorScheme.error
                    : AppTheme.dividerColor,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _pickedMapLocation?.label ?? 'Aucun point selectionne.',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _pickedMapLocation?.coordinatesLabel ??
                      'Touchez la carte pour choisir l\'emplacement.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _pickAddressOnMap,
                    icon: const Icon(Icons.place_outlined),
                    label: Text(
                      _pickedMapLocation == null
                          ? 'Choisir sur la carte'
                          : 'Modifier le point',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                      side: const BorderSide(color: AppTheme.primaryColor),
                      minimumSize: const Size(0, 48),
                    ),
                  ),
                ),
                if (_showValidationErrors && _validateMapAddress() != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _validateMapAddress()!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Creer une maraude'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode: _showValidationErrors
              ? AutovalidateMode.always
              : AutovalidateMode.disabled,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x12000000),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Text(
                    'Annoncez une maraude avec les informations principales ',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondaryColor,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _associationController,
                  decoration: const InputDecoration(
                    labelText: 'Association *',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Indiquez le nom de l\'association.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildSelectionField(
                  label: 'Date *',
                  placeholder: 'Selectionnez une date',
                  value: _selectedDate == null ? null : _formatDate(_selectedDate!),
                  icon: Icons.calendar_today_outlined,
                  onTap: _pickDate,
                  errorText: _showValidationErrors ? _validateDate() : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildSelectionField(
                        label: 'Heure de debut *',
                        placeholder: 'Selectionnez',
                        value: _startTime == null ? null : _formatTime(_startTime!),
                        icon: Icons.schedule_outlined,
                        onTap: () => _pickTime(isStartTime: true),
                        errorText:
                            _showValidationErrors ? _validateStartTime() : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSelectionField(
                        label: 'Heure de fin *',
                        placeholder: 'Selectionnez',
                        value: _endTime == null ? null : _formatTime(_endTime!),
                        icon: Icons.schedule_outlined,
                        onTap: () => _pickTime(isStartTime: false),
                        errorText:
                            _showValidationErrors ? _validateEndTime() : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildAddressSection(),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _estimatedPlatesController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de plats prevus *',
                    hintText: 'Ex : 120',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Indiquez le nombre de plats prevus.';
                    }

                    final estimatedPlates = int.tryParse(value.trim());
                    if (estimatedPlates == null || estimatedPlates <= 0) {
                      return 'Saisissez un nombre valide.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedDistributionType,
                  decoration: const InputDecoration(
                    labelText: 'Type de distribution',
                  ),
                  items: _distributionTypes
                      .map(
                        (type) => DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }

                    setState(() {
                      _selectedDistributionType = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _commentController,
                  minLines: 4,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Commentaire',
                    hintText: 'Ajoutez une precision utile pour la maraude',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryColor,
                          side: const BorderSide(color: AppTheme.primaryColor),
                          minimumSize: const Size.fromHeight(52),
                        ),
                        child: const Text('Annuler'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saveForm,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                        ),
                        child: const Text('Enregistrer'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MapAddressPickerScreen extends StatefulWidget {
  const _MapAddressPickerScreen({
    this.initialLocation,
  });

  final _PickedMapLocation? initialLocation;

  @override
  State<_MapAddressPickerScreen> createState() => _MapAddressPickerScreenState();
}

class _MapAddressPickerScreenState extends State<_MapAddressPickerScreen> {
  static const LatLng _parisCenter = LatLng(48.8566, 2.3522);
  static const double _defaultZoom = 13.2;

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

  String _formatCoordinate(double value) {
    return value.toStringAsFixed(5);
  }

  String _buildLocationLabel(LatLng point) {
    return 'Point selectionne '
        '(${_formatCoordinate(point.latitude)}, '
        '${_formatCoordinate(point.longitude)})';
  }

  void _confirmSelection() {
    final selectedPoint = _selectedPoint;
    if (selectedPoint == null) {
      return;
    }

    Navigator.of(context).pop(
      _PickedMapLocation(
        point: selectedPoint,
        label: _buildLocationLabel(selectedPoint),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedPoint = _selectedPoint;
    final previewText = selectedPoint == null
        ? 'Touchez la carte pour placer la maraude.'
        : 'Lat ${_formatCoordinate(selectedPoint.latitude)} / '
            'Lng ${_formatCoordinate(selectedPoint.longitude)}';

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

class _PickedMapLocation {
  const _PickedMapLocation({
    required this.point,
    required this.label,
  });

  final LatLng point;
  final String label;

  String get coordinatesLabel =>
      'Lat ${point.latitude.toStringAsFixed(5)} / '
      'Lng ${point.longitude.toStringAsFixed(5)}';
}
