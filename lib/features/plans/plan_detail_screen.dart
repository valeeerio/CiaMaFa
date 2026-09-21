import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../shared/map_pin.dart';
import '../../shared/press_effects.dart';
import '../../shared/screen_header.dart';
import '../onboarding/onboarding_provider.dart';
import '../places/map_tiles.dart';
import 'plan.dart';
import 'plan_delete_dialog.dart';
import 'plans_provider.dart';

/// Dettaglio di un piano: chi l'ha proposto, dove, e i voti "Ci sono" /
/// "Non ci sono" (ritoccare il proprio voto lo toglie).
class PlanDetailScreen extends ConsumerStatefulWidget {
  const PlanDetailScreen({super.key, required this.planId});

  final String planId;

  @override
  ConsumerState<PlanDetailScreen> createState() => _PlanDetailScreenState();
}

class _PlanDetailScreenState extends ConsumerState<PlanDetailScreen> {
  bool _voting = false;

  void _back() => context.canPop() ? context.pop() : context.go('/plans');

  Future<void> _vote(Plan plan, VoteChoice choice) async {
    final me = ref.read(currentProfileProvider).value;
    if (me == null || _voting) return;
    setState(() => _voting = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(plansRepositoryProvider)
          .setVote(
            planId: plan.id,
            profileId: me.id,
            choice: plan.voteOf(me.id) == choice ? null : choice,
          );
      ref.invalidate(livePlansProvider);
    } catch (_) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Non sono riuscito a registrare il voto.'),
          ),
        );
    } finally {
      if (mounted) setState(() => _voting = false);
    }
  }

  Future<void> _delete(Plan plan) async {
    if (_voting || !await confirmDeletePlan(context) || !mounted) return;
    setState(() => _voting = true);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    try {
      await ref.read(plansRepositoryProvider).deletePlan(plan.id);
      ref.invalidate(livePlansProvider);
      router.go('/home');
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Piano eliminato')));
    } catch (_) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Non sono riuscito a eliminare il piano.'),
          ),
        );
    } finally {
      if (mounted) setState(() => _voting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plans = ref.watch(livePlansProvider);
    final me = ref.watch(currentProfileProvider).value;
    final plan = plans.value?.where((p) => p.id == widget.planId).firstOrNull;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: switch ((plan, plans)) {
            (final Plan p, _) => _Found(
              plan: p,
              myId: me?.id,
              voting: _voting,
              onBack: _back,
              onVote: (c) => _vote(p, c),
              onDelete: () => _delete(p),
            ),
            (_, AsyncError()) => Column(
              children: [
                ScreenHeader(title: '', onBack: _back),
                const Spacer(),
                const Text('Non riesco a caricare il piano.'),
                TextButton(
                  onPressed: () => ref.invalidate(livePlansProvider),
                  child: const Text('Riprova'),
                ),
                const Spacer(),
              ],
            ),
            (_, AsyncData()) => _Gone(onBack: _back),
            _ => const Center(child: CircularProgressIndicator()),
          },
        ),
      ),
    );
  }
}

/// Piano scaduto o eliminato.
class _Gone extends StatelessWidget {
  const _Gone({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ScreenHeader(title: '', onBack: onBack),
        const Spacer(),
        const Text('⏳', style: TextStyle(fontSize: 64)),
        const SizedBox(height: 12),
        Text(
          'Questo piano non c\'è più',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 20),
        SolidPress(
          shadowColor: AppColors.orangeShadow,
          radius: 22,
          child: FilledButton(
            onPressed: () => context.go('/plans'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.orange,
              foregroundColor: AppColors.nightBlue,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
            ),
            child: const Text('Vedi i piani di oggi'),
          ),
        ),
        const Spacer(),
      ],
    );
  }
}

class _Found extends ConsumerWidget {
  const _Found({
    required this.plan,
    required this.myId,
    required this.voting,
    required this.onBack,
    required this.onVote,
    required this.onDelete,
  });

  final Plan plan;
  final String? myId;
  final bool voting;
  final VoidCallback onBack;
  final ValueChanged<VoteChoice> onVote;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final place = plan.place;
    final mine = myId == null ? null : plan.voteOf(myId!);
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        ScreenHeader(title: '', onBack: onBack),
        const SizedBox(height: 14),
        Text(
          'Proposto da ${plan.creatorNickname}',
          style: text.labelLarge?.copyWith(color: AppColors.coralText),
        ),
        const SizedBox(height: 4),
        Text('${plan.emoji} ${plan.label}', style: text.headlineLarge),
        const SizedBox(height: 16),
        if (place != null) ...[
          _MiniMap(
            plan: plan,
            onTap: () => ref
                .read(mapLauncherProvider)
                .open(lat: place.lat, lng: place.lng, label: place.name),
          ),
          const SizedBox(height: 14),
          _PlaceCard(plan: plan),
          const SizedBox(height: 18),
        ],
        Row(
          children: [
            Expanded(
              child: _VoteButton(
                key: const ValueKey('vote-yes'),
                label: 'Ci sono 🙋',
                active: mine == VoteChoice.yes,
                color: AppColors.acidGreen,
                shadow: AppColors.acidGreenShadow,
                onPressed: voting ? null : () => onVote(VoteChoice.yes),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _VoteButton(
                key: const ValueKey('vote-no'),
                label: 'Non ci sono 😴',
                active: mine == VoteChoice.no,
                color: AppColors.coral,
                shadow: AppColors.coralShadow,
                onPressed: voting ? null : () => onVote(VoteChoice.no),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        _Voters(
          key: const ValueKey('voters-yes'),
          title: '🙋 Ci sono',
          votes: plan.voters(VoteChoice.yes),
          myId: myId,
        ),
        const SizedBox(height: 16),
        _Voters(
          key: const ValueKey('voters-no'),
          title: '😴 Non ci sono',
          votes: plan.voters(VoteChoice.no),
          myId: myId,
        ),
        // Solo chi ha lanciato il piano può eliminarlo.
        if (myId != null && plan.creatorId == myId) ...[
          const SizedBox(height: 28),
          Center(
            child: TextButton.icon(
              key: const ValueKey('delete-plan'),
              onPressed: voting ? null : onDelete,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Elimina piano'),
              style: TextButton.styleFrom(foregroundColor: AppColors.coralText),
            ),
          ),
        ],
      ],
    );
  }
}

/// Mappa piccola, non interattiva, col pin del luogo; il tocco la apre
/// nell'app di mappe.
class _MiniMap extends StatelessWidget {
  const _MiniMap({required this.plan, required this.onTap});

  final Plan plan;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = plan.activity;
    final point = plan.place!.point;
    return Semantics(
      button: true,
      label: 'Apri ${plan.place!.name} nelle mappe',
      child: GestureDetector(
        key: const ValueKey('mini-map'),
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: a.background,
            borderRadius: BorderRadius.circular(26),
            boxShadow: a.dashed
                ? null
                : [BoxShadow(color: a.shadow, offset: const Offset(0, 5))],
          ),
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(21),
              child: SizedBox(
                height: 170,
                child: AbsorbPointer(
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: point,
                      initialZoom: 16,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.none,
                      ),
                    ),
                    children: [
                      const MapTiles(),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: point,
                            width: MapPin.selectedSize.width,
                            height: MapPin.selectedSize.height,
                            alignment: Alignment.topCenter,
                            child: MapPin(selected: true, emoji: plan.emoji),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlaceCard extends StatelessWidget {
  const _PlaceCard({required this.plan});

  final Plan plan;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final place = plan.place!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(color: Color(0x1F1B2A4A), offset: Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(place.name, style: text.titleMedium),
                  if (place.address != null)
                    Text(
                      place.address!,
                      style: text.bodySmall?.copyWith(color: AppColors.muted),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'alle ${formatTime(plan.createdAt)}',
              style: text.bodySmall?.copyWith(color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pulsante di voto: attivo = blu notte con ✓.
class _VoteButton extends StatelessWidget {
  const _VoteButton({
    super.key,
    required this.label,
    required this.active,
    required this.color,
    required this.shadow,
    required this.onPressed,
  });

  final String label;
  final bool active;
  final Color color;
  final Color shadow;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SolidPress(
      shadowColor: active ? AppColors.nightBlue : shadow,
      enabled: onPressed != null,
      radius: 22,
      child: Semantics(
        selected: active,
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: active ? AppColors.nightBlue : color,
            foregroundColor: active ? AppColors.cream : AppColors.nightBlue,
            disabledBackgroundColor: active ? AppColors.nightBlue : color,
            disabledForegroundColor: active
                ? AppColors.cream
                : AppColors.nightBlue,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
          ),
          child: Text(active ? '✓ $label' : label, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}

/// Chip con i nomi di chi ha votato; il tuo è evidenziato.
class _Voters extends StatelessWidget {
  const _Voters({
    super.key,
    required this.title,
    required this.votes,
    required this.myId,
  });

  final String title;
  final List<PlanVote> votes;
  final String? myId;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$title · ${votes.length}', style: text.titleSmall),
        const SizedBox(height: 8),
        if (votes.isEmpty)
          Text(
            'Nessuno ancora.',
            style: text.bodyMedium?.copyWith(color: AppColors.muted),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final v in votes)
                DecoratedBox(
                  key: ValueKey('voter:${v.nickname}'),
                  decoration: BoxDecoration(
                    color: v.profileId == myId
                        ? AppColors.nightBlue
                        : AppColors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(color: Color(0x1F1B2A4A), offset: Offset(0, 2)),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    child: Text(
                      v.nickname,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: v.profileId == myId
                            ? AppColors.cream
                            : AppColors.nightBlue,
                      ),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
