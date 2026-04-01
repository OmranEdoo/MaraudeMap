import 'package:flutter/material.dart';

import '../config/current_session.dart';
import '../config/theme.dart';
import 'map_address_picker_screen.dart';

class CreateMaraudeScreen extends StatefulWidget {
  const CreateMaraudeScreen({
    super.key,
    required this.initialAssociation,
    required this.initialDate,
  });

  final String initialAssociation;
  final DateTime initialDate;

  @override
  State<CreateMaraudeScreen> createState() => _CreateMaraudeScreenState();
}

class _CreateMaraudeScreenState extends State<CreateMaraudeScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _associationController;
  final _estimatedPlatesController = TextEditingController(text: '100');
  final _commentController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  PickedMapLocation? _pickedMapLocation;
  bool _showValidationErrors = false;

  @override
  void initState() {
    super.initState();
    _associationController =
        TextEditingController(text: CurrentSession.associationName);
    _selectedDate = DateUtils.dateOnly(widget.initialDate);
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
    if (_pickedMapLocation == null) {
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
