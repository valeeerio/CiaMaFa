import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/motion.dart';
import '../../core/theme.dart';
import '../../shared/press_effects.dart';
import '../../shared/screen_header.dart';
import '../../shared/staggered_entrance.dart';
import 'chat_message.dart';
import 'chat_provider.dart';
import 'image_source_sheet.dart';
import 'message_bubble.dart';

/// Tab Chat: unica per il gruppo, solo i messaggi di oggi.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();

  /// Id già visti: solo i messaggi arrivati dopo il primo caricamento entrano
  /// con l'animazione, lo storico compare subito.
  final _seen = <String>{};
  final _fresh = <String>{};
  bool _loaded = false;

  /// Foto scelta, in attesa di essere inviata (con il testo come didascalia).
  Uint8List? _pending;
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _track(List<ChatMessage> messages) {
    final ids = {for (final m in messages) m.id};
    if (!_loaded) {
      _loaded = true;
      _seen.addAll(ids);
      return;
    }
    _fresh.addAll(ids.difference(_seen));
    _seen.addAll(ids);
  }

  void _toBottom() {
    if (!_scroll.hasClients) return;
    // La lista è rovesciata: il fondo è l'offset 0.
    _scroll.animateTo(
      0,
      duration: Motion.of(context, Motion.base),
      curve: Motion.soft,
    );
  }

  void _snack(String text) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));

  Future<void> _pickImage() async {
    final source = await showImageSourceSheet(context);
    if (source == null || !mounted) return;
    final bytes = await ref.read(imagePickerServiceProvider).pick(source);
    if (bytes != null && mounted) setState(() => _pending = bytes);
  }

  Future<void> _send() async {
    if (_sending) return;
    final text = _controller.text;
    final image = _pending;
    if (image == null && text.trim().isEmpty) return;
    // Il campo si svuota subito; se va male torna com'era.
    _controller.clear();
    setState(() {
      _pending = null;
      _sending = true;
    });
    final composer = ref.read(chatComposerProvider.notifier);
    final ok = image == null
        ? await composer.sendText(text)
        : await composer.sendImage(image, caption: text);
    if (!mounted) return;
    setState(() => _sending = false);
    if (ok) {
      _toBottom();
    } else {
      _controller.text = text;
      setState(() => _pending = image);
      _snack('Non sono riuscito a inviare 😬');
    }
  }

  Future<void> _react(ChatMessage m, String emoji) async {
    final ok = await ref
        .read(chatComposerProvider.notifier)
        .toggleReaction(m, emoji);
    if (!ok && mounted) _snack('Non sono riuscito a reagire 😬');
  }

  Future<void> _delete(ChatMessage m) async {
    final ok = await ref.read(chatComposerProvider.notifier).delete(m);
    if (!ok && mounted) _snack('Non sono riuscito a eliminare 😬');
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(liveMessagesProvider);
    final loaded = messages.value;
    if (loaded != null) _track(loaded);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ScreenHeader(title: 'Chat'),
                  const SizedBox(height: 2),
                  Text(
                    'Messaggi di oggi · spariscono a mezzanotte 🕛',
                    style: text.bodyMedium?.copyWith(color: AppColors.muted),
                  ),
                ],
              ),
            ),
            Expanded(
              child: switch (messages) {
                // Con dati già in mano (anche durante un ricaricamento) si mostrano.
                AsyncValue(:final value?) when value.isEmpty =>
                  const _EmptyState(),
                AsyncValue(:final value?) => _MessageList(
                  controller: _scroll,
                  messages: value,
                  fresh: _fresh,
                  onReaction: _react,
                  onDelete: _delete,
                ),
                AsyncError() => _ErrorState(
                  onRetry: () => ref.invalidate(liveMessagesProvider),
                ),
                _ => const Center(child: CircularProgressIndicator()),
              },
            ),
            if (_pending != null)
              _PendingImage(
                bytes: _pending!,
                onRemove: () => setState(() => _pending = null),
              ),
            _InputBar(
              controller: _controller,
              hasImage: _pending != null,
              sending: _sending,
              onAttach: _pickImage,
              onSend: _send,
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList({
    required this.controller,
    required this.messages,
    required this.fresh,
    required this.onReaction,
    required this.onDelete,
  });

  final ScrollController controller;
  final List<ChatMessage> messages;
  final Set<String> fresh;
  final void Function(ChatMessage, String) onReaction;
  final ValueChanged<ChatMessage> onDelete;

  @override
  Widget build(BuildContext context) {
    // Rovesciata: il messaggio più recente sta in basso, ancorato.
    final items = messages.reversed.toList();
    return ListView.builder(
      controller: controller,
      reverse: true,
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final m = items[i];
        final bubble = MessageBubble(
          message: m,
          onReaction: (emoji) => onReaction(m, emoji),
          onDelete: () => onDelete(m),
        );
        return Align(
          key: ValueKey(m.id),
          alignment: m.isMine ? Alignment.centerRight : Alignment.centerLeft,
          child: fresh.contains(m.id)
              ? StaggeredEntrance(
                  offset: const Offset(0, 14),
                  fromScale: 0.92,
                  child: bubble,
                )
              : bubble,
        );
      },
    );
  }
}

class _PendingImage extends StatelessWidget {
  const _PendingImage({required this.bytes, required this.onRemove});

  final Uint8List bytes;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.memory(
                bytes,
                key: const ValueKey('pending-image'),
                width: 96,
                height: 72,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox(
                  width: 96,
                  height: 72,
                  child: ColoredBox(
                    color: AppColors.white,
                    child: Center(child: Text('📷')),
                  ),
                ),
              ),
            ),
            Positioned(
              top: -8,
              right: -8,
              child: Semantics(
                button: true,
                label: 'Togli la foto',
                child: GestureDetector(
                  key: const ValueKey('remove-pending'),
                  onTap: onRemove,
                  child: const CircleAvatar(
                    radius: 12,
                    backgroundColor: AppColors.nightBlue,
                    child: Icon(Icons.close, size: 14, color: AppColors.cream),
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

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.hasImage,
    required this.sending,
    required this.onAttach,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool hasImage;
  final bool sending;
  final VoidCallback onAttach;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Semantics(
            button: true,
            label: 'Allega una foto',
            child: PressScale(
              child: GestureDetector(
                key: const ValueKey('attach'),
                onTap: onAttach,
                child: const CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.white,
                  child: Text('📷', style: TextStyle(fontSize: 20)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: TextField(
                key: const ValueKey('message-field'),
                controller: controller,
                minLines: 1,
                maxLines: 4,
                maxLength: 1000,
                textCapitalization: TextCapitalization.sentences,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  hintText: hasImage
                      ? 'Aggiungi una didascalia…'
                      : 'Scrivi al gruppo…',
                  counterText: '',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              final enabled =
                  !sending && (hasImage || value.text.trim().isNotEmpty);
              return Semantics(
                button: true,
                enabled: enabled,
                label: 'Invia',
                child: PressScale(
                  child: AnimatedContainer(
                    duration: Motion.of(context, Motion.fast),
                    curve: Motion.soft,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: enabled
                          ? AppColors.orange
                          : AppColors.orange.withValues(alpha: 0.4),
                    ),
                    child: GestureDetector(
                      key: const ValueKey('send'),
                      onTap: enabled ? onSend : null,
                      behavior: HitTestBehavior.opaque,
                      child: const SizedBox(
                        width: 44,
                        height: 44,
                        child: Center(
                          child: Text(
                            '➤',
                            style: TextStyle(
                              fontSize: 18,
                              color: AppColors.nightBlue,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('💬', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 12),
          Text(
            'Ancora nessun messaggio oggi.',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          const Text('Rompi il ghiaccio 🧊'),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('😵', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 8),
          const Text('Non riesco a caricare la chat.'),
          TextButton(onPressed: onRetry, child: const Text('Riprova')),
        ],
      ),
    );
  }
}
