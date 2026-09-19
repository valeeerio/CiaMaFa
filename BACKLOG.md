# CiaMaFa — Backlog

Riferimento UX: `docs/ciamafa-design-reference.md`. Ogni fase verrà dettagliata quando ci arriviamo.

- [x] **Fase 0: Scaffold**
  Progetto Flutter, struttura cartelle, tema, migrazioni Supabase (schema, scadenza a mezzanotte, RLS, seed gruppo), CLAUDE.md.
- [ ] **Fase 1: Onboarding**
  Anonymous sign-in, nickname univoco nel gruppo, toggle notifiche, join al gruppo unico.
- [ ] **Fase 2: Home**
  5 attività fisse: Bar, Bombolone, Posto Chill, Mangiare, "Bho, vediamoci e decidiamo". Header con avatar (Profilo) e pillola Impegni.
- [ ] **Fase 3: Scelta del posto**
  Preset auto-alimentati per attività/gruppo (`place_activity_stats`) + ricerca e mappa Mapbox (Search Box API).
- [ ] **Fase 4: Lancio piano + notifica push simulata/reale**
  Creazione del piano, schermata "Piano lanciato!", banner di notifica in-app simulato.
- [ ] **Fase 5: Piani di oggi + Dettaglio proposta + voti**
  Lista piani di oggi, dettaglio (trovato / non c'è più), voti "Ci sono" / "Non ci sono" con toggle.
- [ ] **Fase 6: Eliminazione piano**
  Solo il creatore, con modale di conferma e notifica di annullamento al gruppo.
- [ ] **Fase 7: Profilo**
  Modifica nickname (univocità) e notifiche on/off.
- [ ] **Fase 8: Push notification reali**
  FCM/APNs al posto della simulazione in-app.
