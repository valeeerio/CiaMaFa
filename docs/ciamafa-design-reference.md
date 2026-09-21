# CiaMaFa — riferimento di design (dal prototipo approvato)

Questo file descrive a testo il prototipo interattivo approvato (Claude Artifact,
Design canvas) così che sia consultabile da Claude Code senza bisogno di accedere
al link (privato, richiede login claude.ai). Fa fede su look, testi, colori e flussi;
NON va reinterpretato o "migliorato" senza chiedere conferma.

## Palette (fissa, non modificare)

| Ruolo | Hex |
|---|---|
| Sfondo crema | `#FDF6E9` |
| Arancione (CTA primaria / Bar) | `#FF8C42` (ombra `#E06B25`) |
| Corallo (Bombolone) | `#FF6F61` (ombra `#D9524A`) |
| Corallo testo (label/eyebrow) | `#B33B30` |
| Blu notte (Posto Chill / testo scuro / CTA scura) | `#1B2A4A` |
| Verde acido (accento / badge / Mangiare) | `#C6F135` (ombra `#A9D01D`) |
| Grigio muted (testo secondario) | `#5C6670` |
| Bianco card | `#FFFFFF` |

Font: **Baloo 2** (titoli, display, peso 700-800) + **Poppins** (corpo testo, 400-700).

## Schermate e flusso

### 1. Onboarding
Sfondo blu notte. Logo 🙌 su quadrato verde acido arrotondato, titolo "CiaMaFa",
sottotitolo "Che si fa stasera?" in verde acido. Campo nickname (demo: tocca per
alternare Valerio/Marta, mostra errore "😬 Nickname già in uso" se ≠ Valerio).
Toggle notifiche. CTA finale "Entra nel gruppo 🎉" (arancione), attiva solo con
nickname = Valerio → naviga a Home e mostra un banner di notifica simulata.

### 2. Home
Titolo grande "CiaMaFa?" + sottotitolo corallo "Lancia un piano al gruppo."

**5 pulsanti attività (ordine fisso):**
1. 🍻 **Bar** — bg `#FF8C42`
2. 🍁 **Bombolone** — bg `#FF6F61` *(emoji aggiornata da 🍩 a 🍁 su richiesta)*
3. 🛋️ **Posto Chill** — bg `#1B2A4A`, testo crema
4. 🍽️ **Mangiare** — bg `#C6F135`, testo blu notte
5. 🎲 **Bho, vediamoci e decidiamo** — bg crema, bordo tratteggiato blu notte,
   ruotato leggermente (-1deg). Nessun bottom sheet: tap diretto come le altre 4.

Ogni tap naviga a "Scelta del posto" impostando `activityId`.

**Modifiche successive:** l'header con avatar (→ Profilo) e pillola "📅 Impegni"
(→ Piani di oggi) è stato **rimosso**: quelle due destinazioni si raggiungono ora
dalla bottom navigation (vedi 2.5). Home mostra solo titolo + sottotitolo + i 5
pulsanti attività.

### 2.5. Bottom Navigation (nuovo)
Barra fissa in basso, alta ~78px, sfondo bianco, ombra verso l'alto, visibile
**solo** sulle 4 schermate principali: **Home, Piani, Chat, Profilo**. Le
schermate a stack (Scelta del posto, Piano lanciato, Dettaglio proposta) restano
a tutto schermo con la propria freccia indietro, senza nav bar sopra.

4 voci, icona + etichetta, colore attivo `#1B2A4A` / inattivo `#5C6670`:
- 🏠 Home
- 📅 Piani (badge numerico col conteggio piani di oggi, verde acido)
- 💬 Chat
- 🙂 Profilo

Introduce una navigazione a tab per queste 4 sezioni al posto della vecchia
navigazione a stack con back button (Piani e Profilo non hanno più freccia
indietro: si esce cambiando tab).

### 3. Scelta del posto (Luogo)
Back button + eyebrow "{emoji} {label} · adesso" (corallo). Titolo per attività:
- Bar → "Dove andiamo al bar?"
- Bombolone → "Dove prendiamo il bombolone?"
- Posto Chill → "Dove ci rilassiamo?"
- Mangiare → "Dove mangiamo?"
- Bho, vediamoci e decidiamo → "Intanto dove ci vediamo?"

Barra ricerca finta (placeholder "Cerca un locale, indirizzo, piazza…").
Chips orizzontali scrollabili dei luoghi suggeriti. Testo helper "Tocca un punto
sulla mappa per spostare il pin 📍". Mappa stilizzata (illustrazione statica,
palette terrosa/crema) con badge "🗺️ Anteprima mappa · sarà una mappa reale"
(riferimento diretto: in produzione qui va Mapbox) e pulsante 🎯 per centrare sulla
posizione utente. Pin sui luoghi preimpostati (verde = non selezionato, corallo =
selezionato). Card riepilogo luogo selezionato (nome + indirizzo). CTA finale
in basso, testo per attività:
- default: "Lancia {label} qui 🚀"
- Bho, vediamoci e decidiamo → "Lanciamo e decidiamo lì 🚀" (label troppo lunga
  per il default)

Città di riferimento demo: **Bitetto**. Luoghi demo attuali: Piazza Aldo Moro,
Bar Centrale (Via Roma 12), Corso Vittorio Emanuele, + "La tua posizione".

**Modifiche successive alla schermata Scelta del posto (sostituiscono quanto sopra dove diverso):**
- Testata simmetrica: freccia a sinistra, titolo unico **"Dove?"** al centro (uguale per tutte le attività), spazio vuoto a destra. Niente pillola con l'attività, niente eyebrow "· adesso", niente titolo lungo per attività.
- Mappa reale (flutter_map, tile CARTO) al posto dell'illustrazione, a blocco con cornice nel colore del pulsante toccato. Nessun badge "Anteprima mappa", nessun 🎯, nessuna attribuzione visibile (da riportare nella pagina Crediti del Profilo).
- Tasti **+ / −** in basso a destra sulla mappa. All'apertura la mappa inquadra **tutti** i punti; i pin che si sovrapporrebbero diventano cerchi col numero (tocco = zoom).
- Nessuna card riepilogo né testo helper: il luogo scelto si vede dall'etichetta sul pin. I luoghi stanno in un foglio quasi a schermo pieno, aperto dal pulsante con la sola icona di una mappa accanto alla ricerca (righe: nome, barra di popolarità e "×N · ultima volta" per i posti già scelti, medaglie 🥇🥈🥉 sui primi tre; "La tua posizione" per prima; niente chilometri). La posizione scelta è un puntino blu con alone e l'etichetta "Sei qui · via e civico".

### 4. Piano lanciato
Sfondo blu notte, confetti animati, icona 🎉, titolo "Piano lanciato!", riepilogo
"Il gruppo ha ricevuto una notifica per {label} a {luogo}.". Due CTA: "Vedi piano"
(verde acido) e "Torna alla home" (trasparente).

### 5. Piani di oggi
Titolo (nessuna freccia indietro, è una tab della bottom nav). Stato vuoto: 🫥
"Nessun piano per oggi." + CTA "Lancia il primo? 🚀". Stato pieno: lista card
(emoji, label · luogo, "di {creatore} · {ora}", conteggio "🙋 N · 😴 N"), tap
apre Dettaglio. Ordine: più "Ci sono" prima, poi i più recenti; si aggiorna in
tempo reale. Il link "Cercavi un piano di ieri sera?" del prototipo è stato tolto.

**Regola di business:** i piani scadono/spariscono a mezzanotte.

### 6. Dettaglio proposta
Due stati: `cpFound` (piano esiste) e `cpNotFound` (scaduto/eliminato → schermata
"⏳ Questo piano non c'è più" con CTA per tornare ai piani).

Stato trovato: back + eyebrow "Proposto da {creatore}", titolo "{emoji} {label}",
mini mappa reale non interattiva col pin (tocco → app di mappe), card luogo + orario.
Il creatore conta già come "Ci sono". Due pulsanti voto "Ci sono 🙋" /
"Non ci sono 😴" con stato attivo (bg blu notte, check ✓ se già votato — toggle:
ritoccare rimuove il voto). Liste chip dei nomi votanti per sì/no (empty state
"Nessuno ancora."). Solo il creatore vede "Elimina piano" (conferma via modale:
"Il gruppo verrà avvisato e i voti andranno persi."; anche scorrendo la card nella lista;
banner "… ha annullato il piano" agli amici; poi Home con "Piano eliminato").

### 7. Profilo
Titolo (nessuna freccia indietro, è una tab della bottom nav). Avatar + nickname
corrente. Sezione modifica nickname (2–20 caratteri, univoco senza distinguere
maiuscole; "😬 Nickname già in uso"). Un solo interruttore notifiche, con nota
"Non vedrai i piani degli amici." se spento. Riga "Crediti" (attribuzioni
OSM/CARTO e Photon, licenze open source, versione) e, in fondo, "Cancella il
mio profilo" con conferma (elimina profilo, voti e piani attivi; poi onboarding).

### 8. Chat (nuovo)
Tab della bottom navigation. Chat **unica di gruppo** (non per singolo piano),
**effimera**: i messaggi di oggi spariscono a mezzanotte, nessuno storico oltre
la giornata corrente — stessa filosofia dei piani.

Header: titolo "Chat" + sottotitolo "Messaggi di oggi · spariscono a mezzanotte 🕛".
Lista messaggi scrollabile: bolle proprie allineate a destra (sfondo blu notte,
testo crema, angolo smussato in basso a destra), bolle altrui a sinistra (sfondo
bianco, testo blu notte, nome del mittente in corallo sopra la bolla). Messaggio
immagine: blocco placeholder 📷 dentro la bolla, con didascalia di testo opzionale
sotto. Sotto ogni bolla, riga di reazioni emoji con conteggio (tap per
aggiungere/togliere la propria reazione) + pulsante "🙂+" per aggiungerne una
veloce. Solo sui messaggi propri compare 🗑️ per eliminarli (nessuna conferma,
coerente con lo stile "un tap e via" del resto dell'app).

Barra di input in basso: pulsante 📷 (allega immagine), campo testo, pulsante ➤
(invia).

**Contenuti supportati:** testo, immagini, reazioni emoji. Non è previsto reply/
thread a un messaggio specifico.

### 9. Banner notifica push (overlay globale)
Compare in alto, slide-down, su sfondo blu notte semitrasparente. Tap → naviga
al piano collegato (se presente) e chiude il banner; ✕ chiude senza navigare.
Trigger attuali nel prototipo: onboarding completato, voto ricevuto (con nome
del votante), eliminazione piano.

## Regole di business ferme (da NON violare in implementazione)
- Nessun feed, nessun calendario/eventi programmati
- Nessuna cronologia oltre "oggi": piani e messaggi chat spariscono a mezzanotte
- Un solo gruppo per utente (nessuna gestione multi-gruppo)
- Login/onboarding minimale: nickname univoco nel gruppo, no foto profilo
- Le 5 attività sono fisse nell'ordine e nei colori sopra elencati
- Chat: unica per il gruppo (non per piano), solo testo/immagini/reazioni, niente
  thread/reply a un messaggio specifico

## Cosa NON è ancora nel prototipo (da progettare in fase di sviluppo)
- Luoghi preimpostati realmente auto-alimentati per attività/gruppo (schema
  `place_activity_stats`, vedi BACKLOG.md fase 3) — nel prototipo sono statici
- Ricerca e mappa reali (Mapbox/flutter_map) — nel prototipo era un'illustrazione statica
- Notifiche push reali (nel prototipo sono banner simulati in-app)
- Persistenza reale della chat (schema DB, storage immagini, cleanup a mezzanotte)
