import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/maraude.dart';

class ListScreen extends StatefulWidget {
  const ListScreen({super.key});

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  String selectedFilterDate = 'Tous';
  String selectedFilterAssociation = 'Tous';
  String selectedFilterAddress = 'Tous';

  void _goToAuthenticateScreen() {
    Navigator.pushReplacementNamed(context, '/authenticate');
  }

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
      bool matchDate = selectedFilterDate == 'Tous' ||
          maraude.date.day.toString() == selectedFilterDate;
      bool matchAssoc = selectedFilterAssociation == 'Tous' ||
          maraude.associationName.contains(selectedFilterAssociation);
      bool matchAddress = selectedFilterAddress == 'Tous' ||
          maraude.address.contains(selectedFilterAddress);

      return matchDate && matchAssoc && matchAddress;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredMaraudes = getFilteredMaraudes();

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
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/home');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filtrer par :',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        'Date',
                        selectedFilterDate,
                        ['Tous', 'Aujourd\'hui', 'Demain'],
                        (value) {
                          setState(() {
                            selectedFilterDate = value;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
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
                      const SizedBox(width: 8),
                      _buildFilterChip(
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
                    ],
                  ),
                ),
              ],
            ),
          ),
          // List of Maraudes
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.primaryColor),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 4),
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
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  maraude.associationName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${maraude.startTime} - ${maraude.endTime}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
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
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${maraude.estimatedPlates} Plats',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  maraude.distributionType,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
