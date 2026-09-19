# CiaMaFa

App Flutter (iOS/Android) per proporre attività di gruppo a una cerchia chiusa di amici.
Stack: Flutter + Riverpod (riverpod_generator) + go_router + Supabase (Postgres/Auth/Realtime) + Mapbox.

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
- Chiavi via `--dart-define` (`SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`, `MAPBOX_ACCESS_TOKEN`), mai committate.
- Test con `flutter_test` + `mocktail`, in `test/` con struttura speculare a `lib/`.

## Comandi
```
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # codegen Riverpod
flutter analyze                                            # lint
flutter test                                               # test
flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_PUBLISHABLE_KEY=... --dart-define=MAPBOX_ACCESS_TOKEN=...
```
Migrazioni DB: `supabase/migrations/` (applicare con Supabase CLI: `supabase db push`).
