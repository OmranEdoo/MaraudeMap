import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../config/current_session.dart';
import '../config/theme.dart';
import '../models/maraude.dart';
import 'map_address_picker_screen.dart';

class EditMaraudeScreen extends StatefulWidget {
  const EditMaraudeScreen({
    super.key,
    required this.maraude,
  });

  final Maraude maraude;

  @override
  State<EditMaraudeScreen> createState() => _EditMaraudeScreenState();
}

class _EditMaraudeScreenState extends State<EditMaraudeScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _associationController;
  late final TextEditingController _estimatedPlatesController;
  late final TextEditingController _commentController;

  late DateTime _selectedDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late PickedMapLocation _pickedMapLocation;
  bool _showValidationErrors = false;

  String _safeComment(Maraude maraude) {
    try {
      return maraude.comment;
    } catch (_) {
      return '';
    }
  }

  bool get _canEditCurrentMaraude {
    return CurrentSession.belongsToCurrentAssociation(
      widget.maraude.associationName,
    );
  }

  @override
  void initState() {
    super.initState();
    _associationController =
        TextEditingController(text: widget.maraude.associationName);
    _estimatedPlatesController = TextEditingController(
      text: widget.maraude.estimatedPlates.toString(),
    );
    _commentController = TextEditingController(
      text: _safeComment(widget.maraude),
    );
    _selectedDate = widget.maraude.date;
    _startTime = _parseTime(widget.maraude.startTime);
    _endTime = _parseTime(widget.maraude.endTime);
    _pickedMapLocation = PickedMapLocation(
      point: LatLng(widget.maraude.latitude, widget.maraude.longitude),
      label: widget.maraude.address,
    );
  }

  @override
  void dispose() {
    _associationController.dispose();
    _estimatedPlatesController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
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
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
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
    final pickedLocation = await Navigator.of(context).push<PickedMapLocation>(
      MaterialPageRoute(
        builder: (context) => MapAddressPickerScreen(
          initialLocation: _pickedMapLocation,
        ),
      ),
    );

    if (pickedLocation == null) {
      return;
    }

    setState(() {
      _pickedMapLocation = pickedLocation;
    });
  }

  void _saveForm() {
    if (!_canEditCurrentMaraude) {
      return;
    }

    setState(() {
      _showValidationErrors = true;
    });

    final isFormValid = _formKey.currentState?.validate() ?? false;
    if (!isFormValid || _validateEndTime() != null) {
      return;
    }

    final updatedMaraude = widget.maraude.copyWith(
      associationName: _associationController.text.trim(),
      date: _selectedDate,
      startTime: _formatMaraudeTime(_startTime),
      endTime: _formatMaraudeTime(_endTime),
      address: _pickedMapLocation.label,
      estimatedPlates: int.parse(_estimatedPlatesController.text.trim()),
      comment: _commentController.text.trim(),
      latitude: _pickedMapLocation.point.latitude,
      longitude: _pickedMapLocation.point.longitude,
    );

    Navigator.of(context).pop(updatedMaraude);
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  String _formatPickerTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatMaraudeTime(TimeOfDay time) {
    if (time.minute == 0) {
      return '${time.hour}h';
    }

    return '${time.hour}h${time.minute.toString().padLeft(2, '0')}';
  }

  int _timeInMinutes(TimeOfDay time) => time.hour * 60 + time.minute;

  String? _validateEndTime() {
    if (_timeInMinutes(_endTime) <= _timeInMinutes(_startTime)) {
      return 'L\'heure de fin doit etre apres l\'heure de debut.';
    }

    return null;
  }

  TimeOfDay _parseTime(String value) {
    final normalized = value.trim().toLowerCase();
    final match = RegExp(r'^(\d{1,2})(?:h|:)?(\d{0,2})$').firstMatch(normalized);

    if (match == null) {
      return const TimeOfDay(hour: 19, minute: 0);
    }

    final hour = int.tryParse(match.group(1) ?? '') ?? 19;
    final minuteGroup = match.group(2) ?? '';
    final minute = minuteGroup.isEmpty ? 0 : int.tryParse(minuteGroup) ?? 0;

    return TimeOfDay(
      hour: hour.clamp(0, 23).toInt(),
      minute: minute.clamp(0, 59).toInt(),
    );
  }

  Widget _buildSelectionField({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
    String? errorText,
  }) {
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
          value,
          style: const TextStyle(
            fontSize: 16,
            color: AppTheme.textPrimaryColor,
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
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _pickedMapLocation.label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _pickedMapLocation.coordinatesLabel,
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
                  label: const Text('Modifier le point'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    side: const BorderSide(color: AppTheme.primaryColor),
                    minimumSize: const Size(0, 48),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_canEditCurrentMaraude) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Modifier une maraude'),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      size: 40,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Seules les maraudes de ${CurrentSession.associationName} peuvent etre modifiees.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondaryColor,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Fermer'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier une maraude'),
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
                    'Mettez a jour une maraude prevue ou deja effectuee.',
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
                  readOnly: true,
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
                  value: _formatDate(_selectedDate),
                  icon: Icons.calendar_today_outlined,
                  onTap: _pickDate,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildSelectionField(
                        label: 'Heure de debut *',
                        value: _formatPickerTime(_startTime),
                        icon: Icons.schedule_outlined,
                        onTap: () => _pickTime(isStartTime: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSelectionField(
                        label: 'Heure de fin *',
                        value: _formatPickerTime(_endTime),
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
                        onPressed: () => Navigator.of(context).pop(),
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
