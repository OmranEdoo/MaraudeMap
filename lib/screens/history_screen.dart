import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../models/maraude.dart';
import '../widgets/header_logo.dart';
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

  late final List<Maraude> _pastMaraudes = _buildPastMaraudes();
  String _selectedMonth = 'Tous';
  String _selectedAssociation = 'Tous';
  String _selectedZone = 'Tous';
  String _selectedType = 'Tous';

  List<Maraude> _buildPastMaraudes() {
    final today = DateUtils.dateOnly(DateTime.now());

    return [
      Maraude(
        id: 'history-1',
        associationName: 'TAYBA',
        location: 'Stalingrad',
        address: 'Place de la Bataille de Stalingrad, 75019 Paris',
        date: today.subtract(const Duration(days: 2)),
        startTime: '19h00',
        endTime: '20h30',
        estimatedPlates: 130,
        distributionType: 'Repas chaud',
        comment: 'Distribution terminee',
        latitude: 48.8841,
        longitude: 2.3701,
        status: MaraudeStatus.completed,
      ),
      Maraude(
        id: 'history-2',
        associationName: 'EILMY',
        location: 'Pont-Marie',
        address: 'Quai de l Hotel de Ville, 75004 Paris',
        date: today.subtract(const Duration(days: 7)),
        startTime: '20h00',
        endTime: '21h15',
        estimatedPlates: 95,
        distributionType: 'Colis alimentaire',
        comment: 'Affluence reguliere',
        latitude: 48.8529,
        longitude: 2.3576,
        status: MaraudeStatus.completed,
      ),
      Maraude(
        id: 'history-3',
        associationName: 'TAYBA',
        location: 'Bastille',
        address: 'Place de la Bastille, 75011 Paris',
        date: today.subtract(const Duration(days: 18)),
        startTime: '19h30',
        endTime: '21h00',
        estimatedPlates: 110,
        distributionType: 'Repas chaud',
        comment: 'Equipe complete',
        latitude: 48.8532,
        longitude: 2.3692,
        status: MaraudeStatus.completed,
      ),
      Maraude(
        id: 'history-4',
        associationName: 'Aurore',
        location: 'Porte de la Villette',
        address: 'Avenue de la Porte de la Villette, 75019 Paris',
        date: today.subtract(const Duration(days: 34)),
        startTime: '18h45',
        endTime: '20h00',
        estimatedPlates: 85,
        distributionType: 'Boissons chaudes',
        comment: 'Intervention en duo',
        latitude: 48.8985,
        longitude: 2.3887,
        status: MaraudeStatus.completed,
      ),
      Maraude(
        id: 'history-5',
        associationName: 'TAYBA',
        location: 'Foyer Ivry',
        address: 'Rue Michelet, 94200 Ivry-sur-Seine',
        date: today.subtract(const Duration(days: 48)),
        startTime: '19h15',
        endTime: '20h15',
        estimatedPlates: 140,
        distributionType: 'Repas chaud',
        comment: 'Distribution en exterieur',
        latitude: 48.8151,
        longitude: 2.3872,
        status: MaraudeStatus.completed,
      ),
      Maraude(
        id: 'history-6',
        associationName: 'EILMY',
        location: 'Nation',
        address: 'Place de la Nation, 75012 Paris',
        date: today.subtract(const Duration(days: 63)),
        startTime: '20h15',
        endTime: '21h00',
        estimatedPlates: 75,
        distributionType: 'Kits hygiene',
        comment: 'Bonne coordination terrain',
        latitude: 48.8483,
        longitude: 2.3959,
        status: MaraudeStatus.completed,
      ),
    ];
  }

  String _monthLabel(DateTime date) {
    return '${_monthNames[date.month - 1]} ${date.year}';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')} '
        '${_monthNames[date.month - 1]} ${date.year}';
  }

  List<String> _monthOptions() {
    final options = <String>{};
    for (final maraude in _pastMaraudes) {
      options.add(_monthLabel(maraude.date));
    }

    final sortedOptions = options.toList()
      ..sort((a, b) {
        final aParts = a.split(' ');
        final bParts = b.split(' ');
        final aMonth = _monthNames.indexOf(aParts.first);
        final bMonth = _monthNames.indexOf(bParts.first);
        final aYear = int.parse(aParts.last);
        final bYear = int.parse(bParts.last);
        if (aYear != bYear) {
          return bYear.compareTo(aYear);
        }
        return bMonth.compareTo(aMonth);
      });

    return ['Tous', ...sortedOptions];
  }

  List<String> _optionsFrom(String Function(Maraude maraude) selector) {
    final options = <String>{};
    for (final maraude in _pastMaraudes) {
      options.add(selector(maraude));
    }

    final sortedOptions = options.toList()..sort();
    return ['Tous', ...sortedOptions];
  }

  List<Maraude> _filteredMaraudes() {
    final today = DateUtils.dateOnly(DateTime.now());

    final filtered = _pastMaraudes.where((maraude) {
      final maraudeDay = DateUtils.dateOnly(maraude.date);
      final matchesHistory = maraudeDay.isBefore(today);
      final matchesMonth =
          _selectedMonth == 'Tous' || _monthLabel(maraude.date) == _selectedMonth;
      final matchesAssociation = _selectedAssociation == 'Tous' ||
          maraude.associationName == _selectedAssociation;
      final matchesZone =
          _selectedZone == 'Tous' || maraude.location == _selectedZone;
      final matchesType =
          _selectedType == 'Tous' || maraude.distributionType == _selectedType;

      return matchesHistory &&
          matchesMonth &&
          matchesAssociation &&
          matchesZone &&
          matchesType;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return filtered;
  }

  Widget _buildFilterChip({
    required String label,
    required String selectedValue,
    required List<String> options,
    required ValueChanged<String> onSelected,
  }) {
    final displayedLabel =
        selectedValue == 'Tous' ? label : '$label : $selectedValue';

    return PopupMenuButton<String>(
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
        constraints: const BoxConstraints(
          minWidth: 120,
          maxWidth: 190,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.primaryColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                displayedLabel,
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
    );
  }

  Widget _buildHistoryCard(Maraude maraude) {
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
                  color: AppTheme.successColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Effectuee',
                  style: TextStyle(
                    color: AppTheme.successColor,
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
                      maraude.location,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      maraude.address,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondaryColor,
                        height: 1.4,
                      ),
                    ),
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
              _buildInfoPill('Zone : ${maraude.location}'),
              _buildInfoPill('Type : ${maraude.distributionType}'),
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

  @override
  Widget build(BuildContext context) {
    final filteredMaraudes = _filteredMaraudes();

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => showNavigationMenuPanel(
            context,
            currentRoute: '/history',
          ),
        ),
        title: const Text('Historique'),
        centerTitle: true,
        actions: [
          const HeaderLogo(),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
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
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _buildFilterChip(
                        label: 'Mois',
                        selectedValue: _selectedMonth,
                        options: _monthOptions(),
                        onSelected: (value) {
                          setState(() {
                            _selectedMonth = value;
                          });
                        },
                      ),
                      _buildFilterChip(
                        label: 'Association',
                        selectedValue: _selectedAssociation,
                        options: _optionsFrom(
                          (maraude) => maraude.associationName,
                        ),
                        onSelected: (value) {
                          setState(() {
                            _selectedAssociation = value;
                          });
                        },
                      ),
                      _buildFilterChip(
                        label: 'Zone',
                        selectedValue: _selectedZone,
                        options: _optionsFrom(
                          (maraude) => maraude.location,
                        ),
                        onSelected: (value) {
                          setState(() {
                            _selectedZone = value;
                          });
                        },
                      ),
                      _buildFilterChip(
                        label: 'Type',
                        selectedValue: _selectedType,
                        options: _optionsFrom(
                          (maraude) => maraude.distributionType,
                        ),
                        onSelected: (value) {
                          setState(() {
                            _selectedType = value;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: filteredMaraudes.isEmpty
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
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
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
