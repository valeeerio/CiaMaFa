import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'push_provider.dart';

/// Sopra a tutte le schermate: tiene attivi la registrazione del token e
/// l'apertura delle notifiche.
class PushHost extends ConsumerWidget {
  const PushHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref
      ..watch(pushControllerProvider)
      ..watch(pushRoutingProvider);
    return child;
  }
}
