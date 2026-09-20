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
- [ ] **Fase 4: Lancio piano + notifica push simulata/reale**
  Creazione del piano, schermata "Piano lanciato!", banner di notifica in-app simulato. Funzione `launch_plan` (RPC): salva il luogo se nuovo, fonde i punti entro ~30 m da uno esistente (luoghi senza `external_id`), crea il piano. I punti li aggiornano già i trigger su `plans`/`votes` (Fase 3).
- [ ] **Fase 5: Piani di oggi + Dettaglio proposta + voti**
  Lista piani di oggi, dettaglio (trovato / non c'è più), voti "Ci sono" / "Non ci sono" con toggle.
- [ ] **Fase 6: Eliminazione piano**
  Solo il creatore, con modale di conferma e notifica di annullamento al gruppo.
- [ ] **Fase 7: Profilo**
  Modifica nickname (univocità) e notifiche on/off. Pagina "Crediti" con l'attribuzione della mappa (© OpenStreetMap, © CARTO), tolta dalla schermata del posto su richiesta.
- [ ] **Fase 8: Push notification reali**
  FCM/APNs al posto della simulazione in-app.
