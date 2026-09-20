# CiaMaFa

App Flutter (iOS/Android) per proporre attività di gruppo a una cerchia chiusa di amici.
Stack: Flutter + Riverpod (riverpod_generator) + go_router + Supabase (Postgres/Auth/Realtime) + flutter_map (tile CARTO Voyager, fallback OSM) + Photon (ricerca luoghi, gratuita, senza chiave).

## Riferimenti
- Fasi e stato del lavoro: `BACKLOG.md`
- UX approvata (testi, colori, flussi, stati; da replicare fedelmente): `docs/ciamafa-design-reference.md`

## Regole di business (non violare)
- Nessuna chat, nessun feed social, nessun calendario/eventi programmati.
- Un solo gruppo per utente; nessuna gestione multi-gruppo (gruppo unico seedato, vedi `supabase/migrations`).
- I piani scadono a mezzanotte (Europe/Rome): `expires_at` è impostato da trigger e la RLS nasconde i piani scaduti.
- Onboarding minimale: anonymous sign-in Supabase + nickname univoco nel gruppo, niente foto profilo.
- 5 attività fisse, nell'ordine e nei colori del design reference.
- Palette e font in `lib/core/theme.dart` (Baloo 2 + Poppins): non modificare la palette.

## Convenzioni di codice
- Struttura `lib/`: `core/` (theme, router, supabase client, costanti), `features/<feature>/`, `shared/` (widget riusabili).
- Provider Riverpod in file `*_provider.dart` (con `riverpod_generator`); un file provider per feature come punto di partenza.
- Config (`SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`, opzionale `CARTO_API_KEY` per i tile Voyager) in `env.json` (gitignored, da `env.example.json`), letto come asset da `Env.load()`; `--dart-define` ha la precedenza. Mai committata.
- Animazioni: stile "fluido e morbido", solo in risposta ai tocchi. Durate/curve in `lib/core/motion.dart` (mai valori sparsi); rispettare `Motion.reduced(context)` ("Riduci movimento"). Effetti condivisi in `lib/shared/` (`staggered_entrance`, `press_effects`, `route_transitions`).
- Schermata del posto: stessa grammatica della Home (sfondo crema, blocchi piatti con raggio 22 e ombra piena della stessa tinta più scura, nessun bordo scuro); la mappa è un blocco con cornice nel colore del pulsante toccato.
- Classifica dei preset (`activity_presets`, ordine deciso dal server): punteggio = piani lanciati + 0,5 × adesioni "Ci sono"; poi uso più recente; poi vicinanza al centro del gruppo (`groups.center_*`). Visibili: `curated` o lanciati ≥ 2 volte. I punti li aggiornano SOLO i trigger su `plans`/`votes` (mai l'app); un piano eliminato prima della scadenza li toglie, uno scaduto no. Nuovi seed di preset: inserire le statistiche con `curated = true`.
- Test con `flutter_test` + `mocktail`, in `test/` con struttura speculare a `lib/`.

## Comandi
```
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # codegen Riverpod
flutter analyze                                            # lint
flutter test                                               # test
flutter run                                                # legge env.json (asset); ./run.sh equivale a usare --dart-define-from-file
```
Migrazioni DB: `supabase/migrations/` (applicare con Supabase CLI: `supabase db push`).
