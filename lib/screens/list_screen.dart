import 'package:flutter/material.dart';

import '../config/current_session.dart';
import '../config/theme.dart';
import '../config/view_selected_date.dart';
import '../models/maraude.dart';
import '../repositories/app_repositories.dart';
import '../screens/create_maraude_screen.dart';
import '../screens/edit_maraude_screen.dart';
import '../screens/map_screen.dart';
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
  final _repository = AppRepositories.maraudes;

  String selectedFilterAssociation = 'Tous';
  String selectedFilterAddress = 'Tous';
  late DateTime selectedDate;
  bool isFilterBarVisible = false;
  bool _isLoading = true;
  String? _loadError;

  List<Maraude> maraudes = [];

  @override
  void initState() {
    super.initState();
    selectedDate = ViewSelectedDate.selectedDate;
    _loadMaraudesForSelectedDate();
  }

  void _goToMapScreen() {
    Navigator.pushReplacementNamed(context, '/home');
  }

  Future<void> _goToMapForMaraude(Maraude maraude) async {
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => MapScreen(
          initialDate: maraude.date,
          initialFocusMaraudeId: maraude.id,
        ),
      ),
    );
  }

  void _goToNextDay() {
    setState(() {
      selectedDate = selectedDate.add(const Duration(days: 1));
    });
    ViewSelectedDate.update(selectedDate);
    _loadMaraudesForSelectedDate();
  }

  void _goToPreviousDay() {
    setState(() {
      selectedDate = selectedDate.subtract(const Duration(days: 1));
    });
    ViewSelectedDate.update(selectedDate);
    _loadMaraudesForSelectedDate();
  }

  Future<void> _pickDateFromBar() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );

    if (pickedDate == null || !mounted) {
      return;
    }

    setState(() {
      selectedDate = DateUtils.dateOnly(pickedDate);
    });
    ViewSelectedDate.update(selectedDate);
    await _loadMaraudesForSelectedDate();
  }

  void _toggleFilterBar() {
    setState(() {
      isFilterBarVisible = !isFilterBarVisible;
    });
  }

  bool _canCreateMaraudeForSelectedDate() {
    final today = DateUtils.dateOnly(DateTime.now());
    final selectedDay = DateUtils.dateOnly(selectedDate);
    return !selectedDay.isBefore(today);
  }

  Future<void> _loadMaraudesForSelectedDate() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final loadedMaraudes = await _repository.listForDate(selectedDate);
      if (!mounted) {
        return;
      }

      setState(() {
        maraudes = loadedMaraudes;

        final addresses = _addressOptions();
        final associations = _associationOptions();
        if (!associations.contains(selectedFilterAssociation)) {
          selectedFilterAssociation = 'Tous';
        }
        if (!addresses.contains(selectedFilterAddress)) {
          selectedFilterAddress = 'Tous';
        }
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loadError = 'Impossible de charger les maraudes.';
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

  List<String> _associationOptions() {
    final options = <String>{'Tous'};
    for (final maraude in maraudes) {
      options.add(maraude.associationName);
    }

    final items = options.toList();
    items.sort();
    return items;
  }

  List<String> _addressOptions() {
    final options = <String>{'Tous'};
    for (final maraude in maraudes) {
      options.add(maraude.location);
    }

    final items = options.toList();
    items.sort();
    return items;
  }

  List<Maraude> getFilteredMaraudes() {
    return maraudes.where((maraude) {
      final matchDate = DateUtils.isSameDay(maraude.date, selectedDate);
      final matchAssoc = selectedFilterAssociation == 'Tous' ||
          maraude.associationName == selectedFilterAssociation;
      final matchAddress = selectedFilterAddress == 'Tous' ||
          maraude.location == selectedFilterAddress;

      return matchDate && matchAssoc && matchAddress;
    }).toList();
  }

  bool _canEditMaraude(Maraude maraude) {
    return CurrentSession.belongsToCurrentAssociation(maraude.associationName);
  }

  void _showEditRestrictionMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Vous ne pouvez modifier que les maraudes de ${CurrentSession.associationName}.',
        ),
      ),
    );
  }

  Future<void> _openEditMaraudeScreen(Maraude maraude) async {
    if (!_canEditMaraude(maraude)) {
      _showEditRestrictionMessage();
      return;
    }

    final updatedMaraude = await Navigator.of(context).push<Maraude>(
      MaterialPageRoute(
        builder: (context) => EditMaraudeScreen(maraude: maraude),
      ),
    );

    if (updatedMaraude == null || !mounted) {
      return;
    }

    await _loadMaraudesForSelectedDate();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Maraude modifiee.'),
      ),
    );
  }

  Future<void> _openCreateMaraudeScreen() async {
    final createdMaraude = await Navigator.of(context).push<Maraude>(
      MaterialPageRoute(
        builder: (context) => CreateMaraudeScreen(
          initialAssociation: CurrentSession.associationName,
          initialDate: selectedDate,
        ),
      ),
    );

    if (createdMaraude == null || !mounted) {
      return;
    }

    await _loadMaraudesForSelectedDate();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Maraude enregistree.'),
      ),
    );
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

  String _cleanLocationText(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || _looksLikeCoordinateText(trimmed)) {
      return '';
    }

    return trimmed;
  }

  String _displayLocationLabel(Maraude maraude) {
    final location = _cleanLocationText(maraude.location);
    if (location.isNotEmpty) {
      return location;
    }

    final address = _cleanLocationText(maraude.address);
    if (address.isNotEmpty) {
      final firstPart = address.split(',').first.trim();
      return firstPart.isNotEmpty ? firstPart : address;
    }

    return 'Zone selectionnee sur la carte';
  }

  String _displayAddressLabel(Maraude maraude) {
    final primaryLabel = _displayLocationLabel(maraude);
    final address = _cleanLocationText(maraude.address);
    if (address.isNotEmpty && address != primaryLabel) {
      return address;
    }

    final location = _cleanLocationText(maraude.location);
    if (location.isNotEmpty && location != primaryLabel) {
      return location;
    }

    return '';
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _loadError!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadMaraudesForSelectedDate,
              child: const Text('Reessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasActiveFilters =
        selectedFilterAssociation != 'Tous' || selectedFilterAddress != 'Tous';
    final canCreate = _canCreateMaraudeForSelectedDate();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              hasActiveFilters
                  ? 'Aucune maraude ne correspond aux filtres.'
                  : 'Aucune maraude pour cette date.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: canCreate ? _openCreateMaraudeScreen : null,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Ajouter une maraude'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppTheme.dividerColor,
                  disabledForegroundColor: Colors.white70,
                ),
              ),
            ),
          ],
        ),
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
            onDatePressed: _pickDateFromBar,
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _loadError != null
                    ? _buildErrorState()
                    : filteredMaraudes.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
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
                                _associationOptions(),
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
                                _addressOptions(),
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
                selectedValue == 'Tous' ? label : selectedValue,
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
    final canEdit = _canEditMaraude(maraude);
    final locationLabel = _displayLocationLabel(maraude);
    final addressLabel = _displayAddressLabel(maraude);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.grey[200],
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
                      IconButton(
                        onPressed: canEdit
                            ? () => _openEditMaraudeScreen(maraude)
                            : _showEditRestrictionMessage,
                        icon: Icon(
                          canEdit ? Icons.edit_outlined : Icons.lock_outline,
                          size: 18,
                          color: canEdit
                              ? AppTheme.primaryColor
                              : AppTheme.textSecondaryColor,
                        ),
                        tooltip: canEdit
                            ? 'Modifier la maraude'
                            : 'Modification non autorisee',
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints(
                          minWidth: 24,
                          minHeight: 24,
                        ),
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
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                locationLabel,
                                style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => _goToMapForMaraude(maraude),
                              icon: const Icon(
                                Icons.location_on,
                                color: AppTheme.primaryColor,
                                size: 20,
                              ),
                              tooltip: 'Voir sur la carte',
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                              constraints: const BoxConstraints(
                                minWidth: 24,
                                minHeight: 24,
                              ),
                            ),
                          ],
                        ),
                        if (addressLabel.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            addressLabel,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                        ],
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
    );
  }
}
