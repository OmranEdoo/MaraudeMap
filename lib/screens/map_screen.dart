import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../config/current_session.dart';
import '../config/theme.dart';
import '../config/view_selected_date.dart';
import '../models/maraude.dart';
import '../repositories/app_repositories.dart';
import '../screens/create_maraude_screen.dart';
import '../screens/edit_maraude_screen.dart';
import '../widgets/app_help_button.dart';
import '../widgets/bottom_bar_action.dart';
import '../widgets/date_selector_bar.dart';
import '../widgets/navigation_menu_panel.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({
    super.key,
    this.initialDate,
    this.initialFocusMaraudeId,
  });

  final DateTime? initialDate;
  final String? initialFocusMaraudeId;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const LatLng _parisCenter = LatLng(48.8566, 2.3522);
  static const double _ileDeFranceZoom = 10.4;
  static const double _minMapZoom = 5;
  static const double _maxMapZoom = 18;

  final MapController _mapController = MapController();
  final _repository = AppRepositories.maraudes;
  final GlobalKey _menuHelpKey = GlobalKey();
  final GlobalKey _dateHelpKey = GlobalKey();
  final GlobalKey _createHelpKey = GlobalKey();
  final GlobalKey _filterHelpKey = GlobalKey();
  final GlobalKey _listHelpKey = GlobalKey();

  late DateTime selectedDate;
  String selectedFilterAssociation = 'Tous';
  bool isAssociationFilterVisible = false;
  bool _isLoading = true;
  String? _loadError;
  String? _pendingFocusMaraudeId;

  List<Maraude> maraudes = [];

  @override
  void initState() {
    super.initState();
    selectedDate = DateUtils.dateOnly(
      widget.initialDate ?? ViewSelectedDate.selectedDate,
    );
    ViewSelectedDate.update(selectedDate);
    _pendingFocusMaraudeId = widget.initialFocusMaraudeId;
    _loadMaraudesForSelectedDate();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
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

  void _goToListScreen() {
    Navigator.pushReplacementNamed(context, '/list');
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

        final hasAssociation = selectedFilterAssociation == 'Tous' ||
            loadedMaraudes.any(
              (maraude) => maraude.associationName == selectedFilterAssociation,
            );
        if (!hasAssociation) {
          selectedFilterAssociation = 'Tous';
        }
      });

      _focusInitialMaraudeIfNeeded(loadedMaraudes);
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

  void _focusInitialMaraudeIfNeeded(List<Maraude> loadedMaraudes) {
    final focusMaraudeId = _pendingFocusMaraudeId;
    if (focusMaraudeId == null || focusMaraudeId.isEmpty) {
      return;
    }

    Maraude? focusedMaraude;
    for (final maraude in loadedMaraudes) {
      if (maraude.id == focusMaraudeId) {
        focusedMaraude = maraude;
        break;
      }
    }

    if (focusedMaraude == null) {
      return;
    }

    _pendingFocusMaraudeId = null;
    final point = LatLng(focusedMaraude.latitude, focusedMaraude.longitude);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      _mapController.move(point, 15.2);
    });
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

  bool _canCreateMaraudeForSelectedDate() {
    final today = DateUtils.dateOnly(DateTime.now());
    final selectedDay = DateUtils.dateOnly(selectedDate);
    return !selectedDay.isBefore(today);
  }

  Color _markerColorFor(Maraude maraude) {
    return AppTheme.primaryColor;
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
    final canEdit = _canEditMaraude(maraude);

    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => Container(
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
            if (!canEdit) ...[
              Text(
                'Modification reservee a l\'association ${CurrentSession.associationName}.',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 12),
            ],
            ElevatedButton(
              onPressed: canEdit
                  ? () {
                      Navigator.pop(sheetContext);
                      _openEditMaraudeScreen(maraude);
                    }
                  : null,
              child: const Text('Modifier la maraude'),
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

  Widget _buildLoadStateCard({
    required String message,
    required VoidCallback onRetry,
  }) {
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
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Reessayer'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canCreateMaraude = _canCreateMaraudeForSelectedDate();
    final helpTargets = [
      AppHelpTarget(
        targetKey: _menuHelpKey,
        title: 'Menu',
        description:
            'Ouvrez ici la navigation principale pour passer a la carte, a la liste, a l historique ou au profil.',
        onTargetTap: () => showNavigationMenuPanel(
          context,
          currentRoute: '/home',
        ),
        closeAfterTap: true,
      ),
      AppHelpTarget(
        targetKey: _dateHelpKey,
        title: 'Date',
        description:
            'Changez de jour avec les fleches ou touchez la date pour choisir directement un jour dans le calendrier.',
        onTargetTap: () {
          _pickDateFromBar();
        },
        closeAfterTap: true,
      ),
      AppHelpTarget(
        targetKey: _createHelpKey,
        title: 'Ajouter une maraude',
        description:
            'Ce bouton permet d annoncer une nouvelle maraude pour le jour selectionne. Il est desactive pour une date passee.',
        placement: AppHelpPlacement.above,
        onTargetTap: canCreateMaraude ? _openCreateMaraudeScreen : null,
        closeAfterTap: canCreateMaraude,
      ),
      AppHelpTarget(
        targetKey: _filterHelpKey,
        title: 'Filtre',
        description:
            'Affichez ici le filtre d association pour ne voir que certaines maraudes sur la carte.',
        placement: AppHelpPlacement.above,
        onTargetTap: _toggleAssociationFilterBar,
        closeAfterTap: true,
      ),
      AppHelpTarget(
        targetKey: _listHelpKey,
        title: 'Liste',
        description:
            'Passez en vue liste tout en conservant la meme date selectionnee.',
        placement: AppHelpPlacement.above,
        onTargetTap: _goToListScreen,
        closeAfterTap: true,
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
            currentRoute: '/home',
          ),
        ),
        title: const Text('MaraudeMap'),
        centerTitle: true,
        actions: [
          AppHelpButton(targets: helpTargets),
        ],
      ),
      body: Column(
        children: [
          DateSelectorBar(
            key: _dateHelpKey,
            selectedDate: selectedDate,
            onLeftPressed: _goToPreviousDay,
            onRightPressed: _goToNextDay,
            onDatePressed: _pickDateFromBar,
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
                    interactionOptions: InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                      cursorKeyboardRotationOptions:
                          CursorKeyboardRotationOptions.disabled(),
                    ),
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
                if (_isLoading)
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
                if (_loadError != null)
                  _buildLoadStateCard(
                    message: _loadError!,
                    onRetry: _loadMaraudesForSelectedDate,
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
                      key: _createHelpKey,
                      onPressed:
                          canCreateMaraude && !_isLoading && _loadError == null
                              ? _openCreateMaraudeScreen
                              : null,
                      icon: const Icon(Icons.add_rounded, size: 28),
                      label: const Text('Ajouter une maraude'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppTheme.dividerColor,
                        disabledForegroundColor: Colors.white70,
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
              children: [
                Expanded(
                  child: BottomBarAction(
                    key: _filterHelpKey,
                    icon: Icons.tune,
                    label: 'Filtre',
                    onTap: _toggleAssociationFilterBar,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: BottomBarAction(
                    key: _listHelpKey,
                    icon: Icons.list,
                    label: 'Liste',
                    onTap: _goToListScreen,
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
