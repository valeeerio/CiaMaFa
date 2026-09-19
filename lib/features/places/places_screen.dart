import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme.dart';
import '../plans/activity.dart';
import 'place_candidate.dart';
import 'places_map.dart';
import 'places_provider.dart';

/// Centro iniziale (città del prototipo): Bitetto.
const bitetto = LatLng(41.0414, 16.7487);

class PlacesScreen extends ConsumerStatefulWidget {
  const PlacesScreen({super.key, required this.activityId});

  final String activityId;

  @override
  ConsumerState<PlacesScreen> createState() => _PlacesScreenState();
}

class _PlacesScreenState extends ConsumerState<PlacesScreen> {
  final _search = TextEditingController();
  final _map = MapController();
  final _searchFocus = FocusNode();
  LatLng _center = bitetto;

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(() => setState(() {}));
  }

  Activity get _activity => activityById(widget.activityId);

  @override
  void dispose() {
    _search.dispose();
    _searchFocus.dispose();
    _map.dispose();
    super.dispose();
  }

  void _choose(PlaceCandidate place) {
    ref.read(placeSelectionProvider.notifier).select(place);
    _map.move(place.point, math.max(_map.camera.zoom, 16));
  }

  void _pickSearchResult(PlaceCandidate place) {
    _search.clear();
    ref.read(placeSearchProvider.notifier).clear();
    FocusScope.of(context).unfocus();
    _choose(place);
  }

  Future<void> _onMapTap(LatLng point) async {
    final selection = ref.read(placeSelectionProvider.notifier);
    selection.select(
      PlaceCandidate(
        name: 'Punto sulla mappa',
        lat: point.latitude,
        lng: point.longitude,
      ),
    );
    try {
      final found = await ref
          .read(placeSearchRepositoryProvider)
          .reverse(point);
      if (!mounted || found == null) return;
      if (ref.read(placeSelectionProvider)?.point != point) return; // superato
      // Solo nome/indirizzo: il pin resta dove hai toccato.
      selection.select(
        PlaceCandidate(
          name: found.name,
          address: found.address,
          lat: point.latitude,
          lng: point.longitude,
        ),
      );
    } catch (_) {
      // Il reverse è un di più: resta "Punto sulla mappa".
    }
  }

  Future<void> _locate() async {
    final pos = await ref.read(locationServiceProvider).currentPosition();
    if (!mounted) return;
    if (pos == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Non riesco a trovarti: controlla i permessi di posizione.',
          ),
        ),
      );
      return;
    }
    _choose(
      PlaceCandidate(
        name: 'La tua posizione',
        lat: pos.latitude,
        lng: pos.longitude,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final selected = ref.watch(placeSelectionProvider);
    final presets =
        ref.watch(suggestedPlacesProvider(widget.activityId)).value ?? const [];
    final search = ref.watch(placeSearchProvider);
    final searching = _search.text.trim().length >= searchMinChars;
    final showTitle = _search.text.isEmpty && !_searchFocus.hasFocus;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: PlacesMap(
              controller: _map,
              initialCenter: bitetto,
              presets: presets,
              selected: selected,
              onTapPoint: _onMapTap,
              onTapPlace: _choose,
              onCenterChanged: (c) => _center = c,
            ),
          ),
          // In alto: pillola di ricerca + chip / risultati, sopra la mappa.
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                    child: _SearchPill(
                      controller: _search,
                      focusNode: _searchFocus,
                      eyebrow: '${_activity.emoji} ${_activity.label} · adesso',
                      title: _activity.placeTitle,
                      showTitle: showTitle,
                      onBack: () => context.pop(),
                      onChanged: (v) {
                        setState(() {});
                        ref
                            .read(placeSearchProvider.notifier)
                            .onQueryChanged(v, near: _center);
                      },
                      onClear: () {
                        _search.clear();
                        ref.read(placeSearchProvider.notifier).clear();
                        setState(() {});
                      },
                    ),
                  ),
                  if (searching)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                      child: _SearchResults(
                        state: search,
                        onPick: _pickSearchResult,
                      ),
                    )
                  else
                    SizedBox(
                      height: 52,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                        children: [
                          _PlaceChip(
                            label: '📍 La tua posizione',
                            selected: false,
                            onTap: _locate,
                          ),
                          for (final p in presets)
                            _PlaceChip(
                              label: p.name,
                              selected: p == selected,
                              onTap: () => _choose(p),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          // In basso: 🎯 e pannello con luogo scelto + CTA.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 16, bottom: 12),
                  child: FloatingActionButton.small(
                    heroTag: null,
                    tooltip: 'La tua posizione',
                    backgroundColor: AppColors.white,
                    foregroundColor: AppColors.nightBlue,
                    onPressed: _locate,
                    child: const Text('🎯'),
                  ),
                ),
                _BottomPanel(
                  selected: selected,
                  ctaLabel: _activity.launchCta,
                  onLaunch: () => context.push('/launched'),
                  textTheme: text,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchPill extends StatelessWidget {
  const _SearchPill({
    required this.controller,
    required this.focusNode,
    required this.eyebrow,
    required this.title,
    required this.showTitle,
    required this.onBack,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String eyebrow;
  final String title;
  final bool showTitle;
  final VoidCallback onBack;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Material(
      elevation: 6,
      shadowColor: const Color(0x66000000),
      color: AppColors.white,
      borderRadius: BorderRadius.circular(30),
      child: SizedBox(
        height: 60,
        child: Row(
          children: [
            IconButton(
              tooltip: 'Indietro',
              icon: const Icon(Icons.arrow_back),
              onPressed: onBack,
            ),
            Expanded(
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  TextField(
                    controller: controller,
                    focusNode: focusNode,
                    textInputAction: TextInputAction.search,
                    onChanged: onChanged,
                    decoration: const InputDecoration(
                      hintText: 'Cerca un locale, indirizzo, piazza…',
                      border: InputBorder.none,
                    ),
                  ),
                  if (showTitle)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: ColoredBox(
                          color: AppColors.white,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                eyebrow,
                                style: text.labelSmall?.copyWith(
                                  color: AppColors.coralText,
                                ),
                              ),
                              Text(title, style: text.titleMedium),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (controller.text.isNotEmpty)
              IconButton(
                tooltip: 'Cancella',
                icon: const Icon(Icons.close),
                onPressed: onClear,
              )
            else
              const Padding(
                padding: EdgeInsets.only(right: 16),
                child: Icon(Icons.search, color: AppColors.muted),
              ),
          ],
        ),
      ),
    );
  }
}

class _BottomPanel extends StatelessWidget {
  const _BottomPanel({
    required this.selected,
    required this.ctaLabel,
    required this.onLaunch,
    required this.textTheme,
  });

  final PlaceCandidate? selected;
  final String ctaLabel;
  final VoidCallback onLaunch;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 16)],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0x33000000),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              if (selected != null) ...[
                Text(selected!.name, style: textTheme.titleMedium),
                if (selected!.address != null)
                  Text(
                    selected!.address!,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
              ] else
                Text(
                  'Tocca un punto sulla mappa per spostare il pin 📍',
                  style: textTheme.bodySmall?.copyWith(color: AppColors.muted),
                ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: selected == null ? null : onLaunch,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: AppColors.nightBlue,
                  disabledBackgroundColor: AppColors.muted,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Text(
                  ctaLabel,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceChip extends StatelessWidget {
  const _PlaceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        key: ValueKey('chip:$label'),
        elevation: 3,
        shadowColor: const Color(0x55000000),
        color: selected ? AppColors.nightBlue : AppColors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColors.cream : AppColors.nightBlue,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({required this.state, required this.onPick});

  final AsyncValue<List<PlaceCandidate>> state;
  final ValueChanged<PlaceCandidate> onPick;

  @override
  Widget build(BuildContext context) {
    final body = state.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Ricerca non disponibile. Riprova o tocca la mappa.'),
      ),
      data: (results) => results.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Nessun risultato.'),
            )
          : Column(
              children: [
                for (final r in results)
                  ListTile(
                    dense: true,
                    title: Text(r.name),
                    subtitle: r.address == null ? null : Text(r.address!),
                    onTap: () => onPick(r),
                  ),
              ],
            ),
    );
    return Material(
      elevation: 6,
      shadowColor: const Color(0x66000000),
      color: AppColors.white,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 280),
        child: SingleChildScrollView(child: body),
      ),
    );
  }
}
