import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/motion.dart';
import '../../core/theme.dart';
import 'chat_provider.dart';

/// Immagine di un messaggio: il blocco 📷 finché il link non c'è o se
/// qualcosa va storto, poi la foto con una dissolvenza morbida.
class ChatImage extends ConsumerWidget {
  const ChatImage({super.key, required this.path});

  final String path;

  static const _radius = 16.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final url = ref.watch(chatImageUrlProvider(path));
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_radius),
        child: switch (url) {
          AsyncData(:final value) => Image.network(
            value,
            key: const ValueKey('chat-image'),
            fit: BoxFit.cover,
            frameBuilder: (context, child, frame, sync) => AnimatedOpacity(
              opacity: frame == null && !sync ? 0 : 1,
              duration: Motion.of(context, Motion.base),
              curve: Motion.soft,
              child: child,
            ),
            errorBuilder: (_, _, _) => const _Placeholder(),
          ),
          _ => const _Placeholder(),
        },
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      key: ValueKey('image-placeholder'),
      color: AppColors.cream,
      child: Center(child: Text('📷', style: TextStyle(fontSize: 40))),
    );
  }
}
