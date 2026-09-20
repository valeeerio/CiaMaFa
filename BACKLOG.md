# CiaMaFa — Backlog

Riferimento UX: `docs/ciamafa-design-reference.md`. Ogni fase verrà dettagliata quando ci arriviamo.

- [x] **Fase 0: Scaffold**
  Progetto Flutter, struttura cartelle, tema, migrazioni Supabase (schema, scadenza a mezzanotte, RLS, seed gruppo), CLAUDE.md.
- [x] **Fase 1: Onboarding**
  Anonymous sign-in, nickname univoco nel gruppo, toggle notifiche, join al gruppo unico.
- [x] **Fase 2: Home**
  5 attività fisse: Bar, Bombolone, Posto Chill, Mangiare, "Bho, vediamoci e decidiamo". Header con avatar (Profilo) e pillola Impegni.
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
- [ ] **Fase 8: Push notification reali**
  FCM/APNs al posto della simulazione in-app.
