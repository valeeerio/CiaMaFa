import 'package:flutter/material.dart';

import '../../core/motion.dart';
import '../../core/theme.dart';
import '../../shared/press_effects.dart';
import 'chat_image.dart';
import 'chat_message.dart';
import 'reaction_picker.dart';

/// Un messaggio: bolla (propria a destra, altrui a sinistra con il nome in
/// corallo), riga di reazioni e, solo sui propri, il cestino.
class MessageBubble extends StatefulWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.onReaction,
    required this.onDelete,
  });

  final ChatMessage message;

  /// Aggiunge o toglie la propria reazione con questo emoji.
  final ValueChanged<String> onReaction;
  final VoidCallback onDelete;

  static const _radius = Radius.circular(22);
  static const _corner = Radius.circular(6);

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  bool _picking = false;

  @override
  Widget build(BuildContext context) {
    final m = widget.message;
    final text = Theme.of(context).textTheme;
    final mine = m.isMine;
    final fg = mine ? AppColors.cream : AppColors.nightBlue;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        key: ValueKey('bubble:${m.id}'),
        crossAxisAlignment: mine
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          if (!mine)
            Padding(
              padding: const EdgeInsets.only(left: 6, bottom: 3),
              child: Text(
                m.senderNickname,
                style: text.labelMedium?.copyWith(
                  color: AppColors.coralText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.78,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: mine ? AppColors.nightBlue : AppColors.white,
                borderRadius: BorderRadius.only(
                  topLeft: MessageBubble._radius,
                  topRight: MessageBubble._radius,
                  bottomLeft: mine ? MessageBubble._radius : MessageBubble._corner,
                  bottomRight: mine ? MessageBubble._corner : MessageBubble._radius,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (m.hasImage) ChatImage(path: m.imagePath!),
                    if (m.hasImage && m.text != null) const SizedBox(height: 8),
                    if (m.text != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          m.text!,
                          style: text.bodyLarge?.copyWith(color: fg),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  alignment: mine ? WrapAlignment.end : WrapAlignment.start,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    for (final r in m.reactions)
                      _ReactionChip(
                        key: ValueKey('reaction:${m.id}:${r.emoji}'),
                        reaction: r,
                        onTap: () => widget.onReaction(r.emoji),
                      ),
                    _AddReaction(
                      key: ValueKey('add-reaction:${m.id}'),
                      open: _picking,
                      onTap: () => setState(() => _picking = !_picking),
                    ),
                    if (mine)
                      _TrashButton(
                        key: ValueKey('delete:${m.id}'),
                        onTap: widget.onDelete,
                      ),
                  ],
                ),
              ),
            ],
          ),
          AnimatedSize(
            duration: Motion.of(context, Motion.fast),
            curve: Motion.soft,
            alignment: Alignment.topCenter,
            child: _picking
                ? Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: ReactionPicker(
                      onPick: (emoji) {
                        setState(() => _picking = false);
                        widget.onReaction(emoji);
                      },
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _ReactionChip extends StatelessWidget {
  const _ReactionChip({super.key, required this.reaction, required this.onTap});

  final Reaction reaction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      selected: reaction.mine,
      label: '${reaction.emoji} ${reaction.count}',
      excludeSemantics: true,
      child: PressScale(
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: Motion.of(context, Motion.fast),
            curve: Motion.soft,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: reaction.mine ? AppColors.acidGreen : AppColors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${reaction.emoji} ${reaction.count}',
              style: text.labelMedium?.copyWith(
                color: AppColors.nightBlue,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AddReaction extends StatelessWidget {
  const _AddReaction({super.key, required this.open, required this.onTap});

  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Aggiungi una reazione',
      excludeSemantics: true,
      child: PressScale(
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: Motion.of(context, Motion.fast),
            curve: Motion.soft,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: open ? AppColors.cream : AppColors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text('🙂+', style: TextStyle(fontSize: 13)),
          ),
        ),
      ),
    );
  }
}

class _TrashButton extends StatelessWidget {
  const _TrashButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Elimina messaggio',
      excludeSemantics: true,
      child: PressScale(
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Text('🗑️', style: TextStyle(fontSize: 15)),
          ),
        ),
      ),
    );
  }
}
