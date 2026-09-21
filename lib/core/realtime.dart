import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Ascolta i cambiamenti Realtime di [tables] (nome tabella → evento) su un canale
/// [name]. [onEvent] trasforma la riga in un valore da emettere (null = ignora).
/// Il canale si apre all'ascolto e si chiude alla cancellazione.
Stream<T> realtimeStream<T>(
  SupabaseClient client,
  String name,
  Map<String, PostgresChangeEvent> tables,
  Future<T?> Function(String table, Map<String, dynamic> row) onEvent,
) {
  late final StreamController<T> controller;
  RealtimeChannel? channel;
  controller = StreamController<T>(
    onListen: () {
      var c = client.channel(name);
      tables.forEach((table, event) {
        c = c.onPostgresChanges(
          event: event,
          schema: 'public',
          table: table,
          callback: (payload) async {
            try {
              final out = await onEvent(table, payload.newRecord);
              if (out != null && !controller.isClosed) controller.add(out);
            } catch (_) {
              // Realtime è un di più: un evento perso non deve rompere nulla.
            }
          },
        );
      });
      channel = c.subscribe();
    },
    onCancel: () async {
      final c = channel;
      if (c != null) await client.removeChannel(c);
    },
  );
  return controller.stream;
}
