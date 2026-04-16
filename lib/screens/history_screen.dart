import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../models/maraude.dart';
import '../repositories/app_repositories.dart';
import '../widgets/app_help_button.dart';
import '../widgets/navigation_menu_panel.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  static const List<String> _monthNames = [
    'janvier',
    'fevrier',
    'mars',
    'avril',
    'mai',
    'juin',
    'juillet',
    'aout',
    'septembre',
    'octobre',
    'novembre',
    'decembre',
  ];

  final _repository = AppRepositories.maraudes;
  final GlobalKey _menuHelpKey = GlobalKey();
  final GlobalKey _filtersHelpKey = GlobalKey();
  final GlobalKey _listHelpKey = GlobalKey();

  List<Maraude> _pastMaraudes = [];
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  String _selectedAssociation = 'Tous';
  String _selectedZone = 'Tous';
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadPastMaraudes();
  }

  Future<void> _loadPastMaraudes() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final loaded = await _repository.listPast(
        beforeDate: DateTime(2100, 1, 1),
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _pastMaraudes = loaded;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loadError = 'Impossible de charger l\'historique.';
      });
    } finally {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')} '
        '${_monthNames[date.month - 1]} ${date.year}';
  }

  String _formatFilterDate(DateTime? date) {
    if (date == null) {
      return 'Toutes';
    }

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  Future<void> _pickStartDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate ?? _selectedEndDate ?? DateTime.now(),
      firstDate: DateTime(2020, 1, 1),
      lastDate: _selectedEndDate ?? DateTime(2100, 1, 1),
    );

    if (pickedDate == null || !mounted) {
      return;
    }

    setState(() {
      _selectedStartDate = DateUtils.dateOnly(pickedDate);
    });
  }

  Future<void> _pickEndDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedEndDate ?? _selectedStartDate ?? DateTime.now(),
      firstDate: _selectedStartDate ?? DateTime(2020, 1, 1),
      lastDate: DateTime(2100, 1, 1),
    );

    if (pickedDate == null || !mounted) {
      return;
    }

    setState(() {
      _selectedEndDate = DateUtils.dateOnly(pickedDate);
    });
  }

  List<String> _optionsFrom(String Function(Maraude maraude) selector) {
    final options = <String>{};
    for (final maraude in _pastMaraudes) {
      final value = selector(maraude).trim();
      if (value.isNotEmpty) {
        options.add(value);
      }
    }

    final sortedOptions = options.toList()..sort();
    return ['Tous', ...sortedOptions];
  }

  List<Maraude> _filteredMaraudes() {
    final filtered = _pastMaraudes.where((maraude) {
      final maraudeDay = DateUtils.dateOnly(maraude.date);
      final matchesStart = _selectedStartDate == null ||
          !maraudeDay.isBefore(_selectedStartDate!);
      final matchesEnd =
          _selectedEndDate == null || !maraudeDay.isAfter(_selectedEndDate!);
      final matchesAssociation = _selectedAssociation == 'Tous' ||
          maraude.associationName == _selectedAssociation;
      final matchesZone =
          _selectedZone == 'Tous' ||
          _displayLocationLabel(maraude) == _selectedZone;

      return matchesStart &&
          matchesEnd &&
          matchesAssociation &&
          matchesZone;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return filtered;
  }

  bool _looksLikeCoordinateText(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) {
      return false;
    }

    if (normalized.contains('point selectionne') ||
        normalized.contains('lat ') ||
        normalized.contains('lng ')) {
      return true;
    }

    return RegExp(
      r'-?\d{1,2}\.\d{3,}.*-?\d{1,3}\.\d{3,}',
    ).hasMatch(normalized);
  }

  String _cleanReadableText(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty ||
        trimmed == 'Point selectionne sur la carte' ||
        _looksLikeCoordinateText(trimmed)) {
      return '';
    }

    return trimmed;
  }

  String _displayLocationLabel(Maraude maraude) {
    final location = _cleanReadableText(maraude.location);
    if (location.isNotEmpty) {
      return location;
    }

    final address = _cleanReadableText(maraude.address);
    if (address.isNotEmpty) {
      final firstPart = address.split(',').first.trim();
      return firstPart.isNotEmpty ? firstPart : address;
    }

    return 'Zone selectionnee sur la carte';
  }

  String _displayAddressLabel(Maraude maraude) {
    final primaryLabel = _displayLocationLabel(maraude);
    final address = _cleanReadableText(maraude.address);
    if (address.isNotEmpty && address != primaryLabel) {
      return address;
    }

    final location = _cleanReadableText(maraude.location);
    if (location.isNotEmpty && location != primaryLabel) {
      return location;
    }

    return '';
  }

  String _statusLabel(Maraude maraude) {
    switch (maraude.status) {
      case MaraudeStatus.completed:
        return 'Effectuee';
      case MaraudeStatus.ongoing:
        return 'En cours';
      case MaraudeStatus.planned:
        return 'Prevue';
    }
  }

  Color _statusColor(Maraude maraude) {
    switch (maraude.status) {
      case MaraudeStatus.completed:
        return AppTheme.successColor;
      case MaraudeStatus.ongoing:
        return AppTheme.warningColor;
      case MaraudeStatus.planned:
        return AppTheme.primaryColor;
    }
  }

  Widget _buildFilterField({
    required String label,
    required String selectedValue,
    required List<String> options,
    required ValueChanged<String> onSelected,
    required double width,
  }) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          PopupMenuButton<String>(
            onSelected: onSelected,
            itemBuilder: (context) {
              return options
                  .map(
                    (value) => PopupMenuItem<String>(
                      value: value,
                      child: Text(value),
                    ),
                  )
                  .toList();
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.primaryColor),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedValue,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
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
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilterField({
    required String label,
    required DateTime? selectedDate,
    required VoidCallback onTap,
    required VoidCallback onClear,
    required double width,
  }) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.primaryColor),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _formatFilterDate(selectedDate),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (selectedDate != null)
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onClear,
                        child: const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Icon(
                            Icons.close,
                            color: AppTheme.primaryColor,
                            size: 16,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(Maraude maraude) {
    final locationLabel = _displayLocationLabel(maraude);
    final addressLabel = _displayAddressLabel(maraude);
    final statusColor = _statusColor(maraude);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      maraude.associationName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(maraude.date),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _statusLabel(maraude),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                Icons.schedule_outlined,
                size: 16,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                '${maraude.startTime} - ${maraude.endTime}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 16,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      locationLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    if (addressLabel.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        addressLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondaryColor,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildInfoPill('${maraude.estimatedPlates} plats'),
              _buildInfoPill('Zone : $locationLabel'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _loadError!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textSecondaryColor,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadPastMaraudes,
              child: const Text('Reessayer'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredMaraudes = _filteredMaraudes();
    final helpTargets = [
      AppHelpTarget(
        targetKey: _menuHelpKey,
        title: 'Menu',
        description:
            'Ouvrez ici la navigation principale pour revenir a la carte, a la liste ou au profil.',
        onTargetTap: () => showNavigationMenuPanel(
          context,
          currentRoute: '/history',
        ),
        closeAfterTap: true,
      ),
      AppHelpTarget(
        targetKey: _filtersHelpKey,
        title: 'Filtres',
        description:
            'Filtrez l historique avec une date de debut, une date de fin, puis par association ou par zone.',
      ),
      AppHelpTarget(
        targetKey: _listHelpKey,
        title: 'Resultats',
        description:
            'Les maraudes correspondant a vos filtres s affichent ici dans l historique.',
        placement: AppHelpPlacement.above,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          key: _menuHelpKey,
          icon: const Icon(Icons.menu),
          onPressed: () => showNavigationMenuPanel(
            context,
            currentRoute: '/history',
          ),
        ),
        title: const Text('Historique'),
        centerTitle: true,
        actions: [
          AppHelpButton(targets: helpTargets),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              key: _filtersHelpKey,
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x12000000),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filtres',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      const spacing = 12.0;
                      final hasTwoColumns = constraints.maxWidth >= 520;
                      final dateFieldWidth =
                          (constraints.maxWidth - spacing) / 2;
                      final fieldWidth = hasTwoColumns
                          ? dateFieldWidth
                          : constraints.maxWidth;

                      return Column(
                        children: [
                          Row(
                            children: [
                              _buildDateFilterField(
                                label: 'Date debut',
                                selectedDate: _selectedStartDate,
                                width: dateFieldWidth,
                                onTap: _pickStartDate,
                                onClear: () {
                                  setState(() {
                                    _selectedStartDate = null;
                                  });
                                },
                              ),
                              const SizedBox(width: spacing),
                              _buildDateFilterField(
                                label: 'Date fin',
                                selectedDate: _selectedEndDate,
                                width: dateFieldWidth,
                                onTap: _pickEndDate,
                                onClear: () {
                                  setState(() {
                                    _selectedEndDate = null;
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: spacing,
                            runSpacing: 12,
                            children: [
                              _buildFilterField(
                                label: 'Association',
                                selectedValue: _selectedAssociation,
                                options: _optionsFrom(
                                  (maraude) => maraude.associationName,
                                ),
                                width: fieldWidth,
                                onSelected: (value) {
                                  setState(() {
                                    _selectedAssociation = value;
                                  });
                                },
                              ),
                              _buildFilterField(
                                label: 'Zone',
                                selectedValue: _selectedZone,
                                options: _optionsFrom(_displayLocationLabel),
                                width: fieldWidth,
                                onSelected: (value) {
                                  setState(() {
                                    _selectedZone = value;
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              key: _listHelpKey,
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : _loadError != null
                      ? _buildErrorState()
                      : filteredMaraudes.isEmpty
                          ? Center(
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.history_toggle_off,
                                      size: 38,
                                      color: AppTheme.primaryColor,
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      'Aucune maraude ne correspond aux filtres.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: AppTheme.textSecondaryColor,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.separated(
                              itemCount: filteredMaraudes.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final maraude = filteredMaraudes[index];
                                return _buildHistoryCard(maraude);
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
