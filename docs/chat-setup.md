# Chat: setup del cleanup notturno

Le righe dei messaggi scaduti le nasconde già la RLS. Questo setup serve a **liberare lo
storage** delle immagini (cancellare da SQL `storage.objects` non elimina il file vero) e a
ripulire fisicamente le righe. Va fatto una volta sola, dopo aver applicato la migrazione
`20260921000006_chat.sql` (`supabase db push`).

1. **Deploy** della funzione (senza verifica JWT: la chiama pg_cron con il segreto, come `send-push`):
   ```
   supabase functions deploy cleanup-chat-images --no-verify-jwt
   ```
2. **URL** della funzione nella configurazione (stessa riga di `send-push`, SQL editor):
   ```sql
   update public.push_config
   set cleanup_url = 'https://<project-ref>.supabase.co/functions/v1/cleanup-chat-images';
   ```
3. **pg_cron**: abilita l'estensione dal dashboard (Database → Extensions), poi:
   ```sql
   select cron.schedule('chat-cleanup', '5 22,23 * * *', 'select public.run_chat_cleanup()');
   ```
   Il cron lavora in UTC: `22,23` copre 00:05 a Roma sia con ora legale sia solare. La funzione è
   idempotente, il secondo giro è innocuo.
4. **Prova a mano** (risponde `{ "removed": N, ... }`; con segreto sbagliato 401):
   ```
   curl -X POST -H "x-push-secret: <secret di push_config>" \
     https://<project-ref>.supabase.co/functions/v1/cleanup-chat-images
   ```

Test della logica pura: `node --test supabase/functions/cleanup-chat-images/cleanup_test.mjs`.
Se il cleanup non gira, la chat resta corretta (i messaggi scaduti sono comunque invisibili):
si accumulano solo i file nel bucket.
