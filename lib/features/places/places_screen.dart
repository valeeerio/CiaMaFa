import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../core/motion.dart';
import '../../core/theme.dart';
import '../../shared/dashed_border.dart';
import '../../shared/press_effects.dart';
import '../../shared/staggered_entrance.dart';
import '../plans/activity.dart';
import 'camera_animator.dart';
import 'location_service.dart';
import 'place_candidate.dart';
import 'place_list_sheet.dart';
import 'places_map.dart';
import 'places_provider.dart';

/// Centro iniziale (città del prototipo): Bitetto.
const bitetto = LatLng(41.0414, 16.7487);

/// Ombra piena morbida di ricerca, chip e card (blu notte al 12%).
const _softShadow = BoxShadow(color: Color(0x1F1B2A4A), offset: Offset(0, 4));

class PlacesScreen extends ConsumerStatefulWidget {
  const PlacesScreen({super.key, required this.activityId});

  final String activityId;

  @override
  ConsumerState<PlacesScreen> createState() => _PlacesScreenState();
}

class _PlacesScreenState extends ConsumerState<PlacesScreen>
    with SingleTickerProviderStateMixin {
  final _search = TextEditingController();
  final _map = MapController();
  final _searchFocus = FocusNode();
  final _searchLink = LayerLink();
  late final CameraAnimator _camera = CameraAnimator(
    vsync: this,
    controller: _map,
  );
  LatLng _center = bitetto;
  bool _fitted = false;
  bool _locating = false;

  /// Posizione dell'utente, se già trovata: le distanze dell'elenco partono da qui.

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(() => setState(() {}));
    // Se i preset sono già in cache, la mappa è pronta dopo il primo frame.
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitToPresets());
  }

  /// Alla prima apertura inquadra TUTTI i preset (una sola volta, e solo se non
  /// hai già scelto un luogo). Con punti lontani la vista è ampia: i pin vicini
  /// si raggruppano in cerchi col numero e i tasti +/− fanno il resto.
  void _fitToPresets() {
    if (_fitted || !mounted) return;
    final presets = ref.read(suggestedPlacesProvider(widget.activityId)).value;
    if (presets == null || presets.isEmpty) return;
    if (ref.read(placeSelectionProvider) != null) return;
    try {
      final reduced = Motion.reduced(context);
      if (presets.length == 1) {
        _camera.flyTo(presets.first.point, zoom: 16, reduced: reduced);
      } else {
        final fitted = CameraFit.bounds(
          bounds: LatLngBounds.fromPoints([for (final p in presets) p.point]),
          padding: const EdgeInsets.all(56),
          maxZoom: 16,
        ).fit(_map.camera);
        _camera.flyTo(fitted.center, zoom: fitted.zoom, reduced: reduced);
      }
      _fitted = true;
    } catch (_) {
      // Mappa non ancora pronta: riprova al prossimo cambio dei preset.
    }
  }

  /// Tocco su un cerchio: inquadra i suoi luoghi (sempre almeno un livello più
  /// in dentro, così si separano davvero).
  void _onTapCluster(List<PlaceCandidate> places) {
    final camera = _map.camera;
    final fitted = CameraFit.bounds(
      bounds: LatLngBounds.fromPoints([for (final p in places) p.point]),
      padding: const EdgeInsets.all(72),
      maxZoom: 17,
    ).fit(camera);
    _camera.flyTo(
      fitted.center,
      zoom: math.max(fitted.zoom, camera.zoom + 1),
      reduced: Motion.reduced(context),
    );
  }

  void _zoomBy(double delta) =>
      _camera.zoomBy(delta, reduced: Motion.reduced(context));

  Activity get _activity => activityById(widget.activityId);

  @override
  void dispose() {
    _search.dispose();
    _searchFocus.dispose();
    _camera.dispose();
    _map.dispose();
    super.dispose();
  }

  void _choose(PlaceCandidate place) {
    ref.read(placeSelectionProvider.notifier).select(place);
    _camera.flyTo(place.point, minZoom: 16, reduced: Motion.reduced(context));
  }

  void _pickSearchResult(PlaceCandidate place) {
    _search.clear();
    ref.read(placeSearchProvider.notifier).clear();
    FocusScope.of(context).unfocus();
    setState(() {});
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

  /// Riga "La tua posizione": cerca la posizione dell'utente e, se la trova, la
  /// sceglie come luogo (puntino blu, alone e volo della camera); poi ricava la
  /// via. Se non riesce, dice perché.
  Future<void> _locate() async {
    if (_locating) return; // un tocco alla volta
    setState(() => _locating = true);
    final result = await ref.read(locationServiceProvider).locate();
    if (!mounted) return;
    setState(() => _locating = false);
    switch (result) {
      case LocationFound(:final point, :final accuracyMeters):
        _choose(
          PlaceCandidate.userPosition(
            point: point,
            accuracyMeters: accuracyMeters,
          ),
        );
        unawaited(_resolveStreet(point, accuracyMeters));
      case LocationFailure(:final reason):
        _showLocationError(reason);
    }
  }

  /// Aggiunge la via ("Via Roma 12") alla posizione scelta, se non è cambiata
  /// nel frattempo. Se non si trova, resta "La tua posizione".
  Future<void> _resolveStreet(LatLng point, double? accuracyMeters) async {
    try {
      final street = await ref
          .read(placeSearchRepositoryProvider)
          .streetAt(point);
      if (!mounted || street == null) return;
      final current = ref.read(placeSelectionProvider);
      if (current == null ||
          !current.isUserPosition ||
          current.point != point) {
        return;
      }
      ref
          .read(placeSelectionProvider.notifier)
          .select(
            PlaceCandidate.userPosition(
              point: point,
              street: street,
              accuracyMeters: accuracyMeters,
            ),
          );
    } catch (_) {
      // La via è un di più: resta "La tua posizione".
    }
  }

  Future<void> _openPlaces() async {
    _searchFocus.unfocus();
    final choice = await showPlaceListSheet(
      context,
      activity: _activity,
      presets:
          ref.read(suggestedPlacesProvider(widget.activityId)).value ??
          const [],
      selected: ref.read(placeSelectionProvider),
    );
    if (!mounted) return;
    switch (choice) {
      case ChoseMe():
        await _locate();
      case ChosePlace(:final place):
        _choose(place);
      case null:
        break;
    }
  }

  void _showLocationError(LocationFailureReason reason) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(reason.message),
        action: SnackBarAction(
          label: reason.needsSettings ? 'Impostazioni' : 'Riprova',
          onPressed: reason.needsSettings
              ? () => ref.read(locationServiceProvider).openSettings(reason)
              : _locate,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(placeSelectionProvider);
    final presets =
        ref.watch(suggestedPlacesProvider(widget.activityId)).value ?? const [];
    final search = ref.watch(placeSearchProvider);
    final searching = _search.text.trim().length >= searchMinChars;
    final a = _activity;

    ref.listen(suggestedPlacesProvider(widget.activityId), (_, next) {
      if (next.hasValue) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _fitToPresets());
      }
    });

    return Scaffold(
      // La tastiera copre mappa e CTA invece di schiacciare la pagina.
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: _Header(onBack: () => context.pop()),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
                  child: CompositedTransformTarget(
                    link: _searchLink,
                    child: _SearchBar(
                      locating: _locating,
                      onOpenPlaces: _openPlaces,
                      controller: _search,
                      focusNode: _searchFocus,
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
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
                    child: _MapFrame(
                      activity: a,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: PlacesMap(
                              controller: _map,
                              initialCenter: bitetto,
                              presets: presets,
                              selected: selected,
                              emoji: a.emoji,
                              onTapPoint: _onMapTap,
                              onTapPlace: _choose,
                              onTapCluster: _onTapCluster,
                              onCenterChanged: (c) => _center = c,
                            ),
                          ),
                          Positioned(
                            right: 12,
                            bottom: 12,
                            child: _ZoomButtons(
                              onZoomIn: () => _zoomBy(1),
                              onZoomOut: () => _zoomBy(-1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                  child: _LaunchButton(
                    label: a.launchCta,
                    enabled: selected != null,
                    onPressed: () => context.push('/launched'),
                  ),
                ),
              ],
            ),
            // Risultati di ricerca: sopra a tutto, sotto la barra.
            if (searching)
              Positioned(
                left: 24,
                right: 24,
                top: 0,
                child: CompositedTransformFollower(
                  link: _searchLink,
                  showWhenUnlinked: false,
                  targetAnchor: Alignment.bottomLeft,
                  followerAnchor: Alignment.topLeft,
                  offset: const Offset(0, 8),
                  child: _SearchResults(
                    state: search,
                    onPick: _pickSearchResult,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Testata simmetrica: freccia a sinistra, "Dove?" al centro, spazio vuoto a
/// destra della stessa larghezza della freccia.
class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  static const _side = 44.0;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Semantics(
          button: true,
          label: 'Indietro',
          child: PressScale(
            child: GestureDetector(
              onTap: onBack,
              behavior: HitTestBehavior.opaque,
              child: const CircleAvatar(
                radius: _side / 2,
                backgroundColor: AppColors.nightBlue,
                child: Icon(Icons.arrow_back, color: AppColors.cream, size: 20),
              ),
            ),
          ),
        ),
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              'Dove?',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineLarge,
            ),
          ),
        ),
        const SizedBox(width: _side),
      ],
    );
  }
}

/// Barra di ricerca: bianca, raggio 22, ombra piena morbida.
class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.locating,
    required this.onOpenPlaces,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
  });

  final bool locating;
  final VoidCallback onOpenPlaces;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _field()),
        const SizedBox(width: 8),
        _PlacesButton(locating: locating, onTap: onOpenPlaces),
      ],
    );
  }

  Widget _field() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [_softShadow],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textInputAction: TextInputAction.search,
        onChanged: onChanged,
        style: const TextStyle(
          color: AppColors.nightBlue,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: 'Cerca un posto…',
          hintStyle: const TextStyle(color: AppColors.muted),
          prefixIcon: const Icon(Icons.search, color: AppColors.muted),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Cancella',
                  icon: const Icon(Icons.close, color: AppColors.muted),
                  onPressed: onClear,
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}

/// Pulsante solo icona (mappa): apre l'elenco dei luoghi.
class _PlacesButton extends StatelessWidget {
  const _PlacesButton({required this.locating, required this.onTap});

  final bool locating;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Luoghi',
      child: PressScale(
        child: GestureDetector(
          key: const ValueKey('open-places'),
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.nightBlue,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Center(
              child: locating
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.cream,
                      ),
                    )
                  : const Icon(
                      Icons.map_outlined,
                      color: AppColors.cream,
                      size: 24,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// La mappa come blocco della Home: cornice nel colore del pulsante toccato,
/// con la sua ombra piena. Bho: cornice crema con bordo tratteggiato.
class _MapFrame extends StatelessWidget {
  const _MapFrame({required this.activity, required this.child});

  final Activity activity;
  final Widget child;

  static const _radius = 26.0;

  @override
  Widget build(BuildContext context) {
    final a = activity;
    final frame = DecoratedBox(
      decoration: BoxDecoration(
        color: a.background,
        borderRadius: BorderRadius.circular(_radius),
        boxShadow: a.dashed
            ? null
            : [BoxShadow(color: a.shadow, offset: const Offset(0, 5))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_radius - 6),
          child: child,
        ),
      ),
    );
    return a.dashed
        ? CustomPaint(
            foregroundPainter: DashedBorderPainter(
              color: a.foreground,
              radius: _radius,
            ),
            child: frame,
          )
        : frame;
  }
}

/// Tasti + e − sulla mappa: cerchi bianchi con ombra piena morbida.
class _ZoomButtons extends StatelessWidget {
  const _ZoomButtons({required this.onZoomIn, required this.onZoomOut});

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _MapButton(icon: Icons.add, tooltip: 'Ingrandisci', onTap: onZoomIn),
        const SizedBox(height: 10),
        _MapButton(icon: Icons.remove, tooltip: 'Riduci', onTap: onZoomOut),
      ],
    );
  }
}

class _MapButton extends StatelessWidget {
  const _MapButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      child: PressScale(
        child: Tooltip(
          message: tooltip,
          child: GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
                boxShadow: [_softShadow],
              ),
              child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(icon, color: AppColors.nightBlue),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// CTA come un pulsante della Home: arancione, raggio 22, ombra piena che
/// affonda alla pressione. Il razzo dondola una volta quando si attiva.
class _LaunchButton extends StatelessWidget {
  const _LaunchButton({
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SolidPress(
      shadowColor: AppColors.orangeShadow,
      enabled: enabled,
      radius: 22,
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: enabled ? onPressed : null,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.orange,
            foregroundColor: AppColors.nightBlue,
            disabledBackgroundColor: AppColors.muted,
            disabledForegroundColor: AppColors.cream,
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
          ),
          child: _CtaLabel(label: label, active: enabled),
        ),
      ),
    );
  }
}

/// Testo della CTA con l'emoji finale che dondola una volta quando si attiva.
class _CtaLabel extends StatefulWidget {
  const _CtaLabel({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  State<_CtaLabel> createState() => _CtaLabelState();
}

class _CtaLabelState extends State<_CtaLabel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );

  @override
  void didUpdateWidget(_CtaLabel old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active && !Motion.reduced(context)) {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // "Lancia Bar qui 🚀" → testo + emoji finale.
    final i = widget.label.lastIndexOf(' ');
    final text = i < 0 ? widget.label : widget.label.substring(0, i);
    final emoji = i < 0 ? '' : widget.label.substring(i + 1);
    final style = Theme.of(context).textTheme.titleLarge
        ?.copyWith(fontSize: 20);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(text, style: style, textAlign: TextAlign.center),
        ),
        if (emoji.isNotEmpty) ...[
          const SizedBox(width: 8),
          AnimatedBuilder(
            animation: _c,
            builder: (context, child) => Transform.rotate(
              angle: 0.4 * math.sin(_c.value * math.pi * 3) * (1 - _c.value),
              child: child,
            ),
            child: Text(emoji, style: style),
          ),
        ],
      ],
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
                for (var i = 0; i < results.length; i++)
                  StaggeredEntrance(
                    key: ValueKey('result:${results[i].lat},${results[i].lng}'),
                    index: i,
                    maxIndex: 5,
                    step: const Duration(milliseconds: 30),
                    duration: Motion.fast,
                    offset: const Offset(0, 8),
                    fromScale: 1,
                    child: ListTile(
                      dense: true,
                      title: Text(results[i].name),
                      subtitle: results[i].address == null
                          ? null
                          : Text(results[i].address!),
                      onTap: () => onPick(results[i]),
                    ),
                  ),
              ],
            ),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(color: Color(0x331B2A4A), offset: Offset(0, 5)),
        ],
      ),
      // Material trasparente: le ListTile disegnano qui i loro effetti al tocco.
      child: Material(
        type: MaterialType.transparency,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: SingleChildScrollView(child: body),
          ),
        ),
      ),
    );
  }
}
