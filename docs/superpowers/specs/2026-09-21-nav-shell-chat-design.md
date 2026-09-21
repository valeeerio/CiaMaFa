# Fase 2.5 (Bottom Navigation) + Fase 9 (Chat) — spec di implementazione

Stato: **da sviluppare** (nessun codice scritto). Decisioni prese il 2026-09-21.
Fanno fede su testi, colori e comportamento `docs/ciamafa-design-reference.md`
(sezioni 2, 2.5, 8) e `CLAUDE.md`. Questo documento aggiunge le scelte tecniche.

Ordine: prima 2.5 (la Chat è la quarta tab), poi 9. Ogni fase può chiudersi con
il proprio commit.

## Decisioni approvate

| Tema | Decisione |
|---|---|
| Branch | `feature/fase-2.5-nav-chat`, creato da `HEAD` di `feature/fase-3-posto` **portando** il working tree (Fase 8 push non committata + doc aggiornati). Committare solo i file di 2.5/9; `pubspec.yaml` ha hunk misti (push + `image_picker`): usare `git add -p`. |
| Schema | DDL dato + tre aggiustamenti: `ON DELETE CASCADE` su `sender_id` e `message_reactions.profile_id` (e `delete_my_profile()` cancella i messaggi), `expires_at` da trigger `BEFORE INSERT`, check sul contenuto. |
| Router | `StatefulShellRoute.indexedStack`, 4 branch. Le schermate a tutto schermo (`/places/:activityId`, `/launched`, `/plans/:id`, `/credits`) stanno sul navigator **root**, senza nav bar. |
| Reazioni | Riga di reazioni + "🙂+" che apre una fila fissa di 6 emoji: 👍 ❤️ 😂 😮 😢 🙏. Niente emoji libere. |
| Foto | "📷" apre uno sheet **Scatta / Galleria**. |
| Compressione | Nessuna utility esistente nel progetto. Si aggiunge `image_picker`: `maxWidth/maxHeight: 1600`, `imageQuality: 80` (output JPEG, HEIC convertito). Nessun altro pacchetto. |

Fuori scope (non aggiungere): push per i messaggi, contatore non letti, reply/thread,
storico oltre la giornata, modifica dei messaggi.

---

# FASE 2.5 — Bottom Navigation Shell

## Router (`lib/core/router.dart`)

```
GlobalKey<NavigatorState> rootNavigatorKey  (passato a GoRouter)
routes:
  /                    splash
  /onboarding
  StatefulShellRoute.indexedStack(builder: MainShell)
    branch 0: /home      HomeScreen
    branch 1: /plans     PlansScreen
    branch 2: /chat      ChatScreen
    branch 3: /profile   ProfileScreen
  /places/:activityId    parentNavigatorKey: root, expandingPage (invariato)
  /launched              parentNavigatorKey: root (redirect invariato)
  /plans/:id             parentNavigatorKey: root
  /credits               parentNavigatorKey: root
```

- `/plans/:id` è **top-level** (non figlia di `/plans`) per non cambiare il path
  usato da banner, push e test.
- Redirect di autenticazione invariato (`/` e `/onboarding` con profilo → `/home`).
- Ogni tab mantiene il proprio stack, ma di fatto le tab non hanno figli: le
  schermate a stack vivono sul root. `indexedStack` preserva lo stato di scroll e
  dei provider di ogni tab.

### Punti che oggi usano `push('/plans')` / `push('/profile')`
Con una shell, `push` di una route di tab non è più il gesto giusto: si usa `go`.

| File | Oggi | Dopo |
|---|---|---|
| `home_screen.dart:34,49` | `push('/profile')`, `push('/plans')` | rimossi (header tolto) |
| `launched_screen.dart:60-62` | `go('/home'); push('/plans'); push('/plans/id')` | `go('/plans'); push('/plans/id')` ("Vedi piano") |
| `places_screen.dart:254-255` | `push('/plans'); push('/plans/id')` | `go('/plans'); push('/plans/id')` |
| `push_provider.dart:99` | `go('/home'); push(route)` | se `route == '/plans'` → `go('/plans')`; se `/plans/:id` → `go('/plans'); push(route)` |
| `plan_banner_host.dart:56` | `push('/plans')` / `push('/plans/id')` | idem: `go('/plans')` per la lista; per il dettaglio `push` sopra la tab corrente (nessun cambio di tab obbligatorio) |
| `plan_detail_screen.dart:30,148` | `_back` → `pop` o `go('/home')`; `go('/plans')` | `_back` → `pop` o `go('/plans')`; `go('/plans')` invariato |
| `plans_screen.dart:92` | `push('/plans/id')` | invariato (apre il dettaglio sul root) |
| `plans_screen.dart:266`, `plan_detail_screen.dart:67` | `go('/home')` | invariato |
| `profile_screen.dart:238` | `push('/credits')` | invariato (root) |

Verificare nel branch `go('/plans')` da fuori shell che la tab si selezioni e
che "back" dal dettaglio ritorni ai Piani.

## `MainShell` (nuovo: `lib/shared/main_shell.dart` + `lib/shared/bottom_nav_bar.dart`)

- `Scaffold(body: navigationShell, bottomNavigationBar: BottomNavBar(...))`.
- Tap su una voce: `navigationShell.goBranch(i, initialLocation: i == currentIndex)`
  (ritoccare la tab attiva torna alla sua radice).
- Il banner globale (`PlanBannerHost`) resta sopra la shell come oggi.

## `BottomNavBar` — stile (spec 2.5)

- Altezza ~78 px + `MediaQuery.padding.bottom` (safe area iOS).
- Sfondo `AppColors.white`, ombra verso l'alto (`BoxShadow(offset: (0,-4), blur ~16, nightBlue @ 8%)`). Nessun bordo.
- 4 voci, ordine fisso, icona = emoji `Text` + etichetta Poppins:
  🏠 Home · 📅 Piani · 💬 Chat · 🙂 Profilo.
- Attiva: etichetta `AppColors.nightBlue` (peso 700); inattiva: `AppColors.muted`
  (`#5C6670`, già in `theme.dart`, nessuna modifica alla palette). Le emoji non
  si colorano: l'inattiva usa `Opacity(0.55)`.
- Badge "Piani": pallino `AppColors.acidGreen` con testo `nightBlue`, in alto a
  destra sull'icona, visibile se `livePlans.length > 0`, chiave
  `ValueKey('plans-badge')` (riusa la chiave dei test). Sostituisce il badge corallo
  della vecchia pillola Impegni.
- Tap: `PressScale` da `lib/shared/press_effects.dart`; cambio colore con
  `AnimatedDefaultTextStyle` / `AnimatedOpacity` e `Motion.fast` + `Motion.soft`
  (via `Motion.of(context, …)`), nessun valore sparso.
- Semantics: ogni voce `button: true, selected: attiva, label: 'Home' …`; il badge
  espone "N piani di oggi".

## Modifiche alle schermate

- **Home** (`home_screen.dart`): via l'intera `Row` avatar + pillola Impegni e la
  lettura di `nickname`/`plansToday`. Restano titolo "CiaMaFa?", sottotitolo, 5
  pulsanti. Nota: la Home non ha più un `Scaffold` con safe area bottom da gestire
  (lo fa la shell).
- **Piani** (`plans_screen.dart`) e **Profilo** (`profile_screen.dart`): titolo
  senza freccia. `ScreenHeader` oggi richiede `onBack`: renderlo opzionale
  (`onBack == null` → nessuna freccia, il titolo resta centrato con lo spazio
  simmetrico eliminato) **oppure** creare `TabHeader(title)`. Preferito: `onBack`
  nullable in `ScreenHeader`, così Dettaglio/Crediti/Scelta posto restano invariati.
- I `Scaffold` interni alle tab restano (sfondo crema); la shell non aggiunge padding.

## Test da aggiornare / aggiungere (2.5)

- `test/features/home/home_screen_test.dart`: rimuovere le attese su `'V'`,
  `'📅 Impegni'`, i tap su profilo/impegni e i test del badge (righe ~84-140).
  Restano titolo, sottotitolo, ordine dei 5 pulsanti, navigazione a `places:<id>`.
- `test/features/plans/plans_screens_test.dart`: header senza freccia in `/plans`;
  la freccia resta nel dettaglio (`/plans/p1`).
- `test/features/profile/profile_screen_test.dart`: niente freccia; `Crediti` porta a `/credits`.
- `test/features/plans/launched_screen_test.dart`, `test/features/places/launch_flow_test.dart`,
  `test/features/plans/plan_banner_host_test.dart`, `test/features/push/push_test.dart`:
  router di test con la stessa shell (o rotte finte) e nuove attese `go('/plans')` + `push('/plans/id')`.
- Nuovo `test/shared/bottom_nav_bar_test.dart`: 4 voci e ordine; tap cambia branch;
  voce attiva `nightBlue`, inattive `muted`; badge visibile con N>0 e assente con 0;
  la nav bar **non** compare su `/plans/:id`, `/places/:id`, `/launched`, `/credits`.
- Nuovo test router (shell): tab mantiene lo stato (scroll/testo digitato in Chat
  sopravvive a un cambio tab).

Verifica finale: `flutter analyze` pulito, `flutter test` verde, controllo a mano
su simulatore (tab, back dal dettaglio, "Vedi piano", apertura da push).

---

# FASE 9 — Chat

## 9.1 Database — `supabase/migrations/20260921000006_chat.sql`

```sql
create table public.messages (
  id          uuid primary key default gen_random_uuid(),
  group_id    uuid not null references public.groups (id),
  sender_id   uuid not null references public.profiles (id) on delete cascade,
  text        text check (text is null or char_length(btrim(text)) between 1 and 1000),
  image_path  text,
  created_at  timestamptz not null default now(),
  expires_at  timestamptz not null,   -- impostato dal trigger
  constraint messages_has_content check (text is not null or image_path is not null),
  constraint messages_image_path_shape check (
    image_path is null or image_path = group_id::text || '/' || id::text || '.jpg')
);
create index messages_group_created_idx on public.messages (group_id, created_at);

create table public.message_reactions (
  message_id  uuid not null references public.messages (id) on delete cascade,
  profile_id  uuid not null references public.profiles (id) on delete cascade,
  emoji       text not null check (char_length(emoji) between 1 and 16),
  created_at  timestamptz not null default now(),
  primary key (message_id, profile_id, emoji)
);
```

- **Trigger** `messages_set_expiry` (`BEFORE INSERT`, stessa espressione di
  `set_plan_expiry`): `expires_at := date_trunc('day', (now() at time zone 'Europe/Rome') + interval '1 day') at time zone 'Europe/Rome'`.
  Sovrascrive qualsiasi valore inviato dal client.
- Il check su `image_path` impone il path `{group_id}/{message_id}.jpg` e quindi
  che l'id sia scelto dal client (UUID v4 generato in app, vedi 9.3).
- **RLS** (abilitata su entrambe, `to authenticated`):
  - `messages_select`: `group_id = current_group_id() and expires_at > now()`.
  - `messages_insert`: `sender_id = auth.uid() and group_id = current_group_id()`.
  - `messages_delete`: `sender_id = auth.uid()` (nessuna policy UPDATE: i messaggi non si modificano).
  - `message_reactions_select`: `exists (select 1 from messages m where m.id = message_id)` (la RLS di `messages` nasconde gli scaduti e gli altri gruppi).
  - `message_reactions_insert`: `profile_id = auth.uid()` + stesso `exists`.
  - `message_reactions_delete`: `profile_id = auth.uid()`. Nessun UPDATE.
- **`delete_my_profile()`**: `create or replace` aggiungendo, prima della delete del
  profilo, `delete from public.messages where sender_id = v_uid` (il CASCADE le
  reazioni). Il `on delete cascade` sulla FK è la rete di sicurezza. Le immagini di
  quei messaggi le libera il cleanup (9.5). Rimuovere anche le reazioni date dall'utente
  a messaggi altrui (già coperto da `profile_id ... on delete cascade`).
- **Realtime**: aggiungere `messages` e `message_reactions` alla publication
  `supabase_realtime` con lo stesso blocco `if not exists (select … pg_publication_tables …)`
  usato in `20260921000002_creator_auto_vote.sql`.
- **Purge fisico** `purge_expired_messages()` (security definer, revocata a tutti,
  come `purge_expired_plans`): `delete from messages where expires_at <= now()`. La
  chiama l'Edge Function di cleanup (9.5).
- Non aggiungere trigger di push per i messaggi.

### Storage (nella stessa migrazione)
```sql
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('chat-images', 'chat-images', false, 5242880, array['image/jpeg']);
```
Policy su `storage.objects` (`to authenticated`), primo segmento del path = gruppo:
- `chat_images_select`, `chat_images_insert`:
  `bucket_id = 'chat-images' and (storage.foldername(name))[1] = current_group_id()::text`.
- `chat_images_delete`: come sopra **e** `exists (select 1 from messages m where m.id::text = split_part(split_part(name,'/',2),'.',1) and m.sender_id = auth.uid())`.
  Quindi per cancellare un messaggio con foto l'app rimuove **prima** il file, **poi** la riga.
- Nessuna policy UPDATE. Bucket privato: l'app legge con signed URL.

## 9.2 Struttura `lib/features/chat/`

| File | Contenuto |
|---|---|
| `chat_message.dart` | modello immutabile `ChatMessage` (`id`, `senderId`, `senderNickname`, `text`, `imagePath`, `createdAt`, `reactions`) + `Reaction {emoji, count, mine}` e `fromJson` |
| `chat_repository.dart` | interfaccia `ChatRepository` + `SupabaseChatRepository` (stesso stile di `plans_repository.dart`) |
| `chat_provider.dart` (+ `.g.dart`) | provider Riverpod generator |
| `chat_screen.dart` | schermata, header, lista, input bar |
| `message_bubble.dart` | bolla + riga reazioni + 🗑️ |
| `reaction_picker.dart` | fila dei 6 emoji del "🙂+" |
| `image_source_sheet.dart` | sheet Scatta / Galleria |
| `chat_image.dart` | placeholder 📷 → immagine da signed URL |

`ChatRepository`:
```
Future<List<ChatMessage>> todaysMessages();
Future<void> send({required String id, String? text, String? imagePath});
Future<String> uploadImage({required String messageId, required Uint8List bytes}); // → path
Future<void> delete(ChatMessage m);            // remove file (se c'è) poi riga
Future<void> toggleReaction({required String messageId, required String emoji, required bool mine});
Future<String> signedImageUrl(String path);    // 1 h
Stream<void> changes();                        // realtime messages + message_reactions
```
- `todaysMessages()`: una sola select con embed
  `messages.select('id, sender_id, text, image_path, created_at, profiles!messages_sender_id_fkey(nickname), message_reactions(emoji, profile_id)').order('created_at')`.
  Le reazioni si aggregano lato client per `emoji` (conteggio + `mine` con l'id del profilo corrente).
  Il filtro sugli scaduti lo fa la RLS.
- `changes()`: riusa il metodo privato `_realtime` di `SupabasePlansRepository` →
  estrarlo in un helper condiviso (`lib/core/realtime.dart`) invece di duplicarlo.
  Sui DELETE il payload ha solo la PK: qualunque evento provoca un refetch completo
  (cerchia ristretta, volumi bassi).
- `toggleReaction`: `mine ? delete(...) : insert(...)`; un `unique violation` sull'insert
  (doppio tap/race) si ignora.

## 9.3 Provider (`chat_provider.dart`)

- `chatRepositoryProvider` (`keepAlive`).
- `liveMessages` (`Stream<List<ChatMessage>>`): `yield await repo.todaysMessages()` poi
  refetch a ogni `changes()`; identico al pattern di `livePlans`.
- `ChatComposer` (Notifier): `sendText(String)`, `sendImage(Uint8List, {String? caption})`,
  `delete(ChatMessage)`, `toggleReaction(ChatMessage, String)`.
  - `sendImage`: `id = const Uuid().v4()` (aggiungere `uuid`; oppure generarlo con
    `gen_random_uuid` non è possibile perché il path lo richiede) → `uploadImage` →
    `send(id:, imagePath:, text: caption)`. Se l'upload riesce e l'insert fallisce, il
    file orfano lo elimina il cleanup.
  - `delete`: ammesso solo se `m.senderId == currentProfile.id` (guardia anche lato client;
    la vera barriera è la RLS). Su messaggio altrui non chiama il repository.
  - Errori di rete → `SnackBar` breve ("Non sono riuscito a inviare 😬"), testo digitato ripristinato.
- `chatImageUrl(path)` (family, cache): signed URL con 1 h di validità.
- Nessun aggiornamento ottimistico complicato: il campo si svuota subito, il messaggio
  compare quando arriva il refetch realtime (locale, quasi immediato).

### Compressione immagine
- `ImagePicker().pickImage(source: camera|gallery, maxWidth: 1600, maxHeight: 1600, imageQuality: 80)`,
  bytes → `uploadImage` con `contentType: 'image/jpeg'`. Limite bucket 5 MB come rete di sicurezza.
- Permessi: iOS `NSCameraUsageDescription` e `NSPhotoLibraryUsageDescription` in
  `ios/Runner/Info.plist` (testi in italiano, tono dell'app); Android nessun permesso
  runtime per il picker di sistema, `CAMERA` solo se necessario per l'intent (verificare
  con `image_picker` corrente). Se l'utente nega: nessun crash, sheet chiuso.
- Astrarre il picker dietro `ImagePickerService` (interfaccia) per poterlo mockare nei test.

## 9.4 UI (spec sezione 8, da replicare)

- **Header**: titolo "Chat" + sottotitolo "Messaggi di oggi · spariscono a mezzanotte 🕛"
  (nessuna freccia: è una tab). Stesso `TabHeader`/`ScreenHeader` senza `onBack`.
- **Lista**: `ListView.builder(reverse: true)` ancorata in basso, padding 16–24; messaggi
  in ordine cronologico (il più recente in basso). Stato vuoto: 💬 "Ancora nessun messaggio oggi."
  + "Rompi il ghiaccio 🧊" (testi da concordare con lo stile dell'empty state dei Piani).
- **Bolla propria** (destra): sfondo `nightBlue`, testo `cream`, angolo in basso a destra
  poco arrotondato (raggio 22 sugli altri; ~6 sull'angolo smussato).
- **Bolla altrui** (sinistra): sfondo `white`, testo `nightBlue`, nome mittente sopra in
  `AppColors.coralText` (`#B33B30`, "corallo testo" della palette: l'unico corallo
  leggibile su crema), angolo smussato in basso a sinistra.
- **Messaggio immagine**: dentro la bolla un blocco placeholder 📷 (rapporto 4:3, raggio
  interno 16) che si sostituisce con l'immagine (`Image.network(signedUrl)`, `fit: cover`,
  `frameBuilder` con fade di `Motion.base`) appena caricata; errore → resta il placeholder.
  Didascalia opzionale sotto l'immagine, dentro la stessa bolla.
- **Riga reazioni** sotto ogni bolla (allineata al lato della bolla): chip `😂 3` per ogni
  emoji, evidenziato (bordo/sfondo `acidGreen`) se c'è la propria reazione; tap = toggle.
  Pulsante "🙂+" in coda che apre `reaction_picker` (fila dei 6 emoji, sotto la bolla).
  Scegliere un emoji già messo da te lo toglie.
- **🗑️** solo sui messaggi propri, accanto alla riga reazioni, **nessuna conferma**.
  Non c'è alcun controllo di eliminazione sulle bolle altrui.
- **Input bar** (fissa sopra la nav bar): 📷 (apre `image_source_sheet`) · `TextField`
  (multi-riga fino a 4, `maxLength: 1000`, hint "Scrivi al gruppo…") · ➤ (attivo solo con
  testo non vuoto). Mandare un'immagine chiede una didascalia opzionale: dopo la scelta
  si mostra un'anteprima sopra la barra con ✕ per annullare; ➤ la invia (con il testo
  come didascalia se presente).
- **Tastiera**: `resizeToAvoidBottomInset` gestito dalla shell; la nav bar si nasconde
  sotto la tastiera (è nel body-bottom della shell, non deve salire sopra la tastiera).
- Stessa grammatica visiva della Home: sfondo crema, blocchi piatti, raggio 22, ombra piena
  della tinta più scura, nessun bordo scuro.

### Animazioni
- Solo valori da `Motion` e `Motion.of(context, …)`; con `Motion.reduced` tutto istantaneo.
- Messaggi **nuovi** (propri o in arrivo dopo il primo caricamento) entrano con
  `StaggeredEntrance` (`index: 0`, `offset: Offset(0, 14)`, `fromScale: 0.92`). Lo storico
  del primo caricamento compare senza animazione: tenere in un `Set<String>` gli id già
  visti; anima solo gli id assenti dopo il primo `data`.
- Tap sulle reazioni: `PressScale` + `AnimatedContainer(Motion.fast)` per il cambio di evidenziazione.
- Scroll-to-bottom all'arrivo di un messaggio solo se l'utente è già vicino al fondo o
  se il messaggio è suo, con `animateTo(Motion.base, Motion.soft)`.

## 9.5 Cleanup delle immagini scadute

La RLS nasconde le righe scadute ma non libera lo storage, e **cancellare da SQL
`storage.objects` non elimina il file reale**: serve l'API di Storage. Quindi Edge Function.

- **`supabase/functions/cleanup-chat-images/index.ts`** (service role, stesso pattern di
  `send-push`: header `x-push-secret` verificato contro il segreto configurato).
  1. Calcola l'ultima mezzanotte Europe/Rome (`Intl.DateTimeFormat` con `timeZone: 'Europe/Rome'`).
  2. Lista gli oggetti di `chat-images` (per cartella-gruppo) con `created_at` < quella mezzanotte
     e li rimuove con `storage.from('chat-images').remove([...])` a lotti da 100. Questa regola
     copre sia le immagini dei messaggi scaduti sia i file orfani (upload riuscito, insert no)
     e le immagini di profili cancellati.
  3. Chiama `purge_expired_messages()` (rpc) per eliminare fisicamente le righe scadute.
  4. Risponde con `{ removed, purgedMessages }`. Idempotente.
- Logica pura (calcolo mezzanotte, filtro dei path) in `cleanup.ts` con test
  `node --test supabase/functions/cleanup-chat-images/cleanup_test.mjs`, come per `messages_test.mjs`.
- **Schedulazione**: `pg_cron` + `pg_net` (estensioni da abilitare dal dashboard, come già
  scritto in `20260919000002_midnight_expiry.sql`). Il cron lavora in UTC: usare
  `'5 22,23 * * *'` (00:05 Roma sia con ora legale sia solare; il secondo giro è innocuo
  perché la funzione è idempotente). L'URL della funzione si legge da una nuova colonna
  nullable `push_config.cleanup_url` e si riusa `push_config.secret`; il job chiama una
  funzione SQL `run_chat_cleanup()` (security definer, revocata) che fa `net.http_post`.
- Documentare setup e deploy in `docs/push-setup.md` (o nuovo `docs/chat-setup.md`):
  deploy funzione, `cleanup_url`, `cron.schedule(...)`.
- **Non eseguire `supabase db push` né il deploy senza conferma esplicita** (toccano il
  progetto remoto).

## 9.6 Test (`test/features/chat/`, speculari a `lib/`, `flutter_test` + `mocktail`)

Mock: `MockChatRepository`, `MockImagePickerService`; override dei provider come in
`plans_screens_test.dart`.

- `chat_message_test.dart`: `fromJson`, aggregazione delle reazioni (conteggio, `mine`).
- `chat_provider_test.dart`:
  - **invio messaggio**: `sendText('ciao')` → `repo.send(text: 'ciao')`; testo vuoto/solo spazi non invia.
  - **invio immagine**: genera id, `uploadImage` prima di `send`, path `{group}/{id}.jpg`, didascalia passata come `text`.
  - **toggle reazione**: senza la mia → insert; con la mia → delete; due tap tornano allo stato iniziale.
  - **eliminazione propria**: chiama `repo.delete`; con immagine, file rimosso **prima** della riga.
  - **eliminazione altrui**: `delete` su messaggio di un altro **non** chiama il repository.
  - `liveMessages` riemette al `changes()`.
- `chat_screen_test.dart` / `message_bubble_test.dart`:
  - bolla propria a destra (`nightBlue`), altrui a sinistra con nome in `coralText`;
  - 🗑️ presente solo sui messaggi propri, tap elimina senza dialog;
  - riga reazioni con conteggio, evidenziata se mia, tap = toggle, "🙂+" apre il picker con i 6 emoji;
  - **rendering bolla immagine**: placeholder 📷 iniziale, poi immagine, didascalia visibile; errore URL → placeholder;
  - input bar: ➤ disabilitato a campo vuoto, invio svuota il campo, 📷 apre lo sheet Scatta/Galleria;
  - `Motion.reduced`: nessuna animazione di entrata (`StaggeredEntrance` istantaneo).
- Test DB/RLS: come `test/supabase` (se contiene test di migrazione) verificare presenza di RLS,
  trigger di scadenza e policy; altrimenti verifica manuale con due utenti (vedi sotto).
- `node --test supabase/functions/cleanup-chat-images/cleanup_test.mjs`.

## 9.7 Verifica manuale (prima di chiudere la fase)

1. Due simulatori/utenti: messaggio testo arriva in tempo reale all'altro.
2. Foto da galleria e da fotocamera: max 1600 px lato lungo, visibile all'altro utente, nessun accesso senza sessione.
3. Reazioni: aggiungi/togli, conteggio corretto per entrambi.
4. 🗑️ sul proprio messaggio con foto: sparisce la riga **e** il file dal bucket; sugli altrui non compare.
5. Tentativo diretto di `delete`/`insert` con `sender_id` altrui (SQL come altro utente) → rifiutato dalla RLS.
6. Simulare la scadenza (`update messages set expires_at = now() - interval '1 min'` da service role): il messaggio sparisce dalla lista; eseguire la funzione di cleanup: file e riga eliminati.
7. "Cancella il mio profilo" con messaggi e reazioni presenti: nessun errore di FK.

## 9.8 Chiusura

Aggiornare `BACKLOG.md` segnando `[x]` Fase 2.5 e Fase 9 con un "Fatto:" nello stile
delle fasi precedenti; togliere i "Da rivedere in Fase 2.5" dalle Fasi 2 e 7. Aggiornare
`CLAUDE.md` (riga Chat già presente; aggiungere comando test della funzione e regola
"bottom nav solo sulle 4 tab").
