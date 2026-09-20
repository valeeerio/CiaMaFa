import 'package:flutter/material.dart';

/// Conferma prima di eliminare un piano. `true` = elimina.
Future<bool> confirmDeletePlan(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Eliminare questo piano?'),
      content: const Text('Il gruppo verrà avvisato e i voti andranno persi.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Annulla'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Elimina'),
        ),
      ],
    ),
  );
  return ok ?? false;
}
