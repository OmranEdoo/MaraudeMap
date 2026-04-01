import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../models/maraude.dart';
import '../screens/edit_maraude_screen.dart';
import '../widgets/bottom_bar_action.dart';
import '../widgets/date_selector_bar.dart';
import '../widgets/header_logo.dart';
import '../widgets/navigation_menu_panel.dart';

class ListScreen extends StatefulWidget {
  const ListScreen({super.key});

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  String selectedFilterAssociation = 'Tous';
  String selectedFilterAddress = 'Tous';
  DateTime selectedDate = DateTime.now();
  bool isFilterBarVisible = false;

  void _goToMapScreen() {
    Navigator.pushReplacementNamed(context, '/home');
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

  void _toggleFilterBar() {
    setState(() {
      isFilterBarVisible = !isFilterBarVisible;
    });
  }

  List<Maraude> maraudes = [
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
      status: MaraudeStatus.completed,
    ),
    Maraude(
      id: '3',
      associationName: 'egdrieh',
      location: 'Stallingrad',
      address: '75 010 Paris',
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
      id: '4',
      associationName: 'dherherh',
      location: 'Bastille',
      address: '75 011 Paris',
      date: DateTime.now(),
      startTime: '19h',
      endTime: '20h',
      estimatedPlates: 80,
      distributionType: 'Repas',
      latitude: 48.8530,
      longitude: 2.3810,
      status: MaraudeStatus.planned,
    ),
    Maraude(
      id: '5',
      associationName: 'ehseh',
      location: 'Foyer Ivry',
      address: '75 013 Paris',
      date: DateTime.now(),
      startTime: '19h',
      endTime: '20h',
      estimatedPlates: 95,
      distributionType: 'Repas',
      latitude: 48.8210,
      longitude: 2.3855,
      status: MaraudeStatus.planned,
    ),
  ];

  List<Maraude> getFilteredMaraudes() {
    return maraudes.where((maraude) {
      final matchDate = DateUtils.isSameDay(maraude.date, selectedDate);
      bool matchAssoc = selectedFilterAssociation == 'Tous' ||
          maraude.associationName.contains(selectedFilterAssociation);
      bool matchAddress = selectedFilterAddress == 'Tous' ||
          maraude.address.contains(selectedFilterAddress);

      return matchDate && matchAssoc && matchAddress;
    }).toList();
  }

  Future<void> _openEditMaraudeScreen(Maraude maraude) async {
    final updatedMaraude = await Navigator.of(context).push<Maraude>(
      MaterialPageRoute(
        builder: (context) => EditMaraudeScreen(maraude: maraude),
      ),
    );

    if (updatedMaraude == null || !mounted) {
      return;
    }

    setState(() {
      final index = maraudes.indexWhere((item) => item.id == updatedMaraude.id);
      if (index != -1) {
        maraudes[index] = updatedMaraude;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Maraude modifiee.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredMaraudes = getFilteredMaraudes();

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => showNavigationMenuPanel(
            context,
            currentRoute: '/list',
          ),
        ),
        title: const Text('MaraudeMap'),
        centerTitle: true,
        actions: [
          const HeaderLogo(),
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
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: filteredMaraudes.length,
              itemBuilder: (context, index) {
                final maraude = filteredMaraudes[index];
                return _buildMaraudeCard(maraude);
              },
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeInOut,
            child: isFilterBarVisible
                ? Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        top: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Filtrer par :',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildFilterChip(
                                'Association',
                                selectedFilterAssociation,
                                [
                                  'Tous',
                                  'TAYBA',
                                  'EILMY',
                                  'egdrieh',
                                  'dherherh',
                                  'ehseh'
                                ],
                                (value) {
                                  setState(() {
                                    selectedFilterAssociation = value;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildFilterChip(
                                'Adresse',
                                selectedFilterAddress,
                                [
                                  'Tous',
                                  'Stallingrad',
                                  'Pont-Marie',
                                  'Bastille',
                                  'Foyer Ivry'
                                ],
                                (value) {
                                  setState(() {
                                    selectedFilterAddress = value;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
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
              children: [
                Expanded(
                  child: BottomBarAction(
                    icon: Icons.tune,
                    label: 'Filtre',
                    onTap: _toggleFilterBar,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: BottomBarAction(
                    icon: Icons.location_on,
                    label: 'Carte',
                    onTap: _goToMapScreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String selectedValue,
    List<String> options,
    Function(String) onSelected,
  ) {
    return PopupMenuButton<String>(
      onSelected: onSelected,
      itemBuilder: (BuildContext context) {
        return options.map<PopupMenuItem<String>>((String value) {
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

  Widget _buildMaraudeCard(Maraude maraude) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => _openEditMaraudeScreen(maraude),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        maraude.associationName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Row(
                      children: [
                        Text(
                          '${maraude.startTime} - ${maraude.endTime}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.edit_outlined,
                          size: 16,
                          color: AppTheme.primaryColor,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            maraude.location,
                            style: const TextStyle(
                              color: AppTheme.dangerColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            maraude.address,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        '${maraude.estimatedPlates} Plats',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
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
