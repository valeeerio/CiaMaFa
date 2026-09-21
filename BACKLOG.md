# CiaMaFa — Backlog

Riferimento UX: `docs/ciamafa-design-reference.md`. Ogni fase verrà dettagliata quando ci arriviamo.

- [x] **Fase 0: Scaffold**
  Progetto Flutter, struttura cartelle, tema, migrazioni Supabase (schema, scadenza a mezzanotte, RLS, seed gruppo), CLAUDE.md.
- [x] **Fase 1: Onboarding**
  Anonymous sign-in, nickname univoco nel gruppo, toggle notifiche, join al gruppo unico.
- [x] **Fase 2: Home**
  5 attività fisse: Bar, Bombolone, Posto Chill, Mangiare, "Bho, vediamoci e decidiamo". Header con avatar (Profilo) e pillola Impegni.
  **Da rivedere in Fase 2.5:** header semplificato (via avatar e pillola Impegni), sostituiti dalla bottom navigation.
- [ ] **Fase 2.5: Bottom Navigation Shell**
  Nuova barra di navigazione fissa in basso (Home / Piani / Chat / Profilo), visibile solo su queste 4
  schermate principali; le schermate a stack (Scelta del posto, Piano lanciato, Dettaglio) restano invariate
  con la propria freccia indietro. Rimuove header avatar+pillola da Home e freccia indietro da Piani/Profilo
  (si naviga cambiando tab). Badge conteggio piani di oggi si sposta sull'icona Piani della nav bar.
  Va fatta prima della Fase 9 (Chat), che è la quarta tab.
  **Spec di implementazione:** `docs/superpowers/specs/2026-09-21-nav-shell-chat-design.md` (sezione Fase 2.5).
- [ ] **Fase 3: Scelta del posto**
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
  **Da rivedere in Fase 2.5:** freccia indietro rimossa (tab della bottom nav); badge piani si sposta sulla nav bar.
- [~] **Fase 8: Push notification reali** (codice pronto; mancano le credenziali, vedi `docs/push-setup.md`)
  FCM/APNs al posto della simulazione in-app.
  Fatto: progetto Firebase `ciamafa` (iOS + Android), `device_tokens` + RPC, trigger su piani/voti/annullamenti → Edge Function `send-push` (FCM HTTP v1), registrazione del token e apertura del piano al tocco; con l'app aperta vale il banner in-app. Da fare: account Apple Developer attivo (chiave APNs + capability in Xcode) e segreto `FIREBASE_SERVICE_ACCOUNT` su Supabase.

- [ ] **Fase 9: Chat**
  Chat unica di gruppo (non per piano), effimera: i messaggi spariscono a mezzanotte come i piani. Testo,
  immagini, reazioni emoji; nessun thread/reply. Eliminazione del proprio messaggio (nessuna conferma).
  Realtime su `messages`/`message_reactions`; immagini in bucket Supabase Storage `chat-images` con cleanup
  programmato a mezzanotte. Quarta tab della bottom nav (dipende da Fase 2.5). Vedi `docs/ciamafa-design-reference.md`
  sezione 8 per lo spec UI completo.
  **Spec di implementazione:** `docs/superpowers/specs/2026-09-21-nav-shell-chat-design.md` (sezione Fase 9: schema, RLS, storage, cleanup, UI, test).
