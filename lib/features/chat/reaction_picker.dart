import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../shared/press_effects.dart';
import 'chat_message.dart';

/// La fila fissa dei 6 emoji del "🙂+".
class ReactionPicker extends StatelessWidget {
  const ReactionPicker({super.key, required this.onPick});

  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final emoji in quickReactions)
              Semantics(
                button: true,
                label: 'Reagisci con $emoji',
                excludeSemantics: true,
                child: PressScale(
                  child: GestureDetector(
                    key: ValueKey('pick:$emoji'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onPick(emoji),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(emoji, style: const TextStyle(fontSize: 22)),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
