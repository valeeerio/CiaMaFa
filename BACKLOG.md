# CiaMaFa — Backlog

Riferimento UX: `docs/ciamafa-design-reference.md`. Ogni fase verrà dettagliata quando ci arriviamo.

- [x] **Fase 0: Scaffold**
  Progetto Flutter, struttura cartelle, tema, migrazioni Supabase (schema, scadenza a mezzanotte, RLS, seed gruppo), CLAUDE.md.
- [x] **Fase 1: Onboarding**
  Anonymous sign-in, nickname univoco nel gruppo, toggle notifiche, join al gruppo unico.
- [x] **Fase 2: Home**
  5 attività fisse: Bar, Bombolone, Posto Chill, Mangiare, "Bho, vediamoci e decidiamo". Header con avatar (Profilo) e pillola Impegni.
- [x] **Fase 2.5: Bottom Navigation Shell**
  Nuova barra di navigazione fissa in basso (Home / Piani / Chat / Profilo), visibile solo su queste 4
  schermate principali; le schermate a stack (Scelta del posto, Piano lanciato, Dettaglio) restano invariate
  con la propria freccia indietro. Rimuove header avatar+pillola da Home e freccia indietro da Piani/Profilo
  (si naviga cambiando tab). Badge conteggio piani di oggi si sposta sull'icona Piani della nav bar.
  Va fatta prima della Fase 9 (Chat), che è la quarta tab.
  **Spec di implementazione:** `docs/superpowers/specs/2026-09-21-nav-shell-chat-design.md` (sezione Fase 2.5).
  Fatto: `StatefulShellRoute.indexedStack` con 4 branch (`/home`, `/plans`, `/chat`, `/profile`) e `MainShell` + `BottomNavBar` (`lib/shared/`); `/places`, `/launched`, `/plans/:id` e `/credits` sul navigator root, quindi senza nav bar. Home solo titolo + 5 pulsanti; Piani e Profilo senza freccia (`ScreenHeader.onBack` opzionale); badge dei piani di oggi verde acido sull'icona Piani. "Vedi piano", banner di annullamento e tocco su push usano `go('/plans')` (+ `push` del dettaglio). La tab Chat è un segnaposto fino alla Fase 9.
- [x] **Fase 3: Scelta del posto**
  Preset auto-alimentati per attività/gruppo (`place_activity_stats`) + ricerca Photon e mappa flutter_map/OSM (al posto di Mapbox). Statistiche e riga `places` scritte al lancio (Fase 4).
- [x] **Fase 4: Lancio piano + notifica push simulata/reale**
  Creazione del piano, schermata "Piano lanciato!", banner di notifica in-app simulato. Funzione `launch_plan` (RPC): salva il luogo se nuovo, fonde i punti entro ~30 m da uno esistente (luoghi senza `external_id`), crea il piano. I punti li aggiornano già i trigger su `plans`/`votes` (Fase 3).
  Fatto: `launch_plan` (esiti `launched` / `duplicate` → porta al piano dell'amico / `needs_confirmation` se hai già piani oggi), "Piano lanciato!" con coriandoli, banner "nuovo piano" degli amici via Realtime (solo app aperta; le push vere restano Fase 8). "Vedi piano" porta ai Piani di oggi, ancora segnaposto fino alla Fase 5.
- [x] **Fase 5: Piani di oggi + Dettaglio proposta + voti**
  Lista piani di oggi, dettaglio (trovato / non c'è più), voti "Ci sono" / "Non ci sono" con toggle.
  Fatto: ordine per più "Ci sono" poi più recenti, aggiornamento Realtime (piani e voti), il creatore vota "Ci sono" in automatico (`launch_plan`), banner anche per i voti sui tuoi piani, mini mappa nel dettaglio (tocco → app di mappe). Senza "Elimina piano" (Fase 6).
- [x] **Fase 6: Eliminazione piano**
  Solo il creatore, con modale di conferma e notifica di annullamento al gruppo.
  Fatto: "Elimina piano" nel dettaglio e scorrimento della card nella lista (solo i tuoi piani), poi Home con "Piano eliminato". Il trigger su `plans` scrive `plan_cancellations` (solo prima della scadenza) → banner "… ha annullato il piano" via Realtime; i punti li toglie già `plans_points_delete`.
- [x] **Fase 7: Profilo**
  Modifica nickname (univocità) e notifiche on/off. Pagina "Crediti" con l'attribuzione della mappa (© OpenStreetMap, © CARTO), tolta dalla schermata del posto su richiesta.
  Fatto: nickname (2–20, univoco senza distinguere maiuscole: indice su `lower(btrim(nickname))`), interruttore notifiche unico, Crediti (OSM/CARTO, Photon/Komoot, licenze open source, versione), "Cancella il mio profilo" (`delete_my_profile()`: piani, profilo, utente anonimo) e badge dei piani di oggi sul pulsante Impegni della Home.
- [x] **Fase 8: Push notification reali** (server collegato a FCM; resta la prova su un telefono vero, vedi `docs/push-setup.md`)
  FCM/APNs al posto della simulazione in-app.
  Fatto: progetto Firebase `ciamafa` (iOS + Android), `device_tokens` + RPC, trigger su piani/voti/annullamenti → Edge Function `send-push` (FCM HTTP v1), registrazione del token e apertura del piano al tocco; con l'app aperta vale il banner in-app. Collegato: chiave APNs su Firebase, capability Push Notifications in Xcode, segreto `FIREBASE_SERVICE_ACCOUNT` su Supabase (verificato: FCM risponde 400 a un token finto, cioè autenticazione OK). Da provare: consegna reale su iPhone/Android.

- [x] **Fase 9: Chat**
  Chat unica di gruppo (non per piano), effimera: i messaggi spariscono a mezzanotte come i piani. Testo,
  immagini, reazioni emoji; nessun thread/reply. Eliminazione del proprio messaggio (nessuna conferma).
  Realtime su `messages`/`message_reactions`; immagini in bucket Supabase Storage `chat-images` con cleanup
  programmato a mezzanotte. Quarta tab della bottom nav (dipende da Fase 2.5). Vedi `docs/ciamafa-design-reference.md`
  sezione 8 per lo spec UI completo.
  **Spec di implementazione:** `docs/superpowers/specs/2026-09-21-nav-shell-chat-design.md` (sezione Fase 9: schema, RLS, storage, cleanup, UI, test).
  Fatto: migrazione `20260921000006_chat.sql` (`messages`, `message_reactions`, RLS per gruppo con scadenza a mezzanotte, INSERT/DELETE solo del mittente, `expires_at` da trigger, `ON DELETE CASCADE` e `delete_my_profile()` che toglie anche i messaggi, Realtime, bucket privato `chat-images` con policy per gruppo). Tab Chat: bolle proprie/altrui, foto (📷 → Scatta/Galleria, max 1600 px, JPEG q80 via `image_picker`) con placeholder e didascalia, reazioni con toggle e "🙂+" (👍 ❤️ 😂 😮 😢 🙏), 🗑️ senza conferma solo sui propri, aggiornamento Realtime, entrata morbida solo per i messaggi nuovi; la nav bar si toglie con la tastiera aperta. Cleanup: Edge Function `cleanup-chat-images` + `run_chat_cleanup()` (pg_cron, vedi `docs/chat-setup.md`). Applicato sul progetto `CiaMaFa` (migrazione `chat`, funzione `cleanup-chat-images` senza verifica JWT, `pg_cron` attivo con job `chat-cleanup` alle 22:05 e 23:05 UTC); RLS provata in transazione con due profili reali e cleanup provato end-to-end (200, `removed: 0`). **Ancora da provare a mano:** la chat con due telefoni veri e la rimozione di un file vero dal bucket (checklist in spec, sezione 9.7).

## v2 — Identità persistente e multi-gruppo

Cambia due regole fondanti oggi in `CLAUDE.md` ("un solo gruppo per utente", "onboarding anonimo"). Sviluppo su `main` verso il rilascio pubblico, non su un branch separato. Ogni fase va progettata (spec) quando viene affrontata.

- [ ] **Fase 10: Migrazione auth (anonimo → email)**
  Sign-in anonimo → email + magic link; utenti anonimi esistenti collegati (`updateUser`) al nuovo metodo senza perdita di dati (stesso `profile_id`). Aggiornamento onboarding e di `CLAUDE.md`.
- [ ] **Fase 11: Schema multi-gruppo (`group_members`) + RLS**
  Tabella `group_members` (ruolo owner/member) al posto di `profiles.group_id`; migrazione dei dati esistenti (owner = primo membro); riscrittura di tutte le RLS che oggi assumono un gruppo per profilo (piani, voti, messaggi, reazioni, preset, storage chat-images, push). `profiles.group_id` deprecato solo dopo verifica completa con `get_advisors`.
- [ ] **Fase 12: Crea un nuovo gruppo**
  Chi crea un gruppo ne diventa owner. Necessaria perché la Fase 13 abbia gruppi da trovare oltre a quello esistente.
- [ ] **Fase 13: Ricerca gruppi pubblici e richiesta di join**
  `groups.is_discoverable` + nome/slug pubblico; ricerca per nome; richiesta di join con approvazione dell'owner (nuova sezione "Richieste" in Profilo o area admin del gruppo).
- [ ] **Fase 14: Amicizie**
  Tabella `friendships` (richiesta/accetta/rifiuta), indipendente dai gruppi; ricerca profili solo per nickname (non email, per evitare enumerazione di indirizzi). Nessuna interazione con i piani in questa fase.
- [ ] **Fase 15: Switcher multi-gruppo in Home**
  Selettore di gruppo attivo; il "gruppo attivo" diventa contesto trasversale per piani, chat, push e classifica preset, non solo un widget isolato in Home.
