# Push notification: cosa manca per attivarle

Il codice è pronto e provato (app, database, Edge Function `send-push`). Mancano
solo le credenziali, che si collegano una volta sola.

## Già fatto
- Progetto Firebase **ciamafa** (piano Spark), app iOS e Android registrate con
  l'id `com.valeriomortella.ciamafa`.
- Valori Firebase in `env.json` (`FIREBASE_*`, gitignored; i nomi sono in
  `env.example.json`). Se mancano, l'app parte senza push.
- Tabella `device_tokens`, RPC `register_device_token` / `unregister_device_token`,
  trigger su piani/voti/annullamenti e Edge Function `send-push`.
- Senza `FIREBASE_SERVICE_ACCOUNT` la funzione risponde `skipped: no-credentials`
  e non fa nulla (i lanci non ne risentono).

## Da fare: iPhone (serve l'Apple Developer Program attivo)
1. **developer.apple.com → Certificates, Identifiers & Profiles → Keys → +**:
   nome "CiaMaFa APNs", spunta *Apple Push Notifications service (APNs)*, scarica
   il file `.p8` (si scarica UNA volta sola). Annota **Key ID** e **Team ID**
   (in alto a destra o in *Membership details*).
2. **Firebase → Impostazioni progetto → Cloud Messaging → Configurazione app
   Apple**: carica il `.p8` con Key ID e Team ID.
3. **Xcode → Runner → Signing & Capabilities**: scegli il tuo Team, poi
   *+ Capability* → *Push Notifications* e *Background Modes → Remote
   notifications*. Fatto questo l'iPhone reale può ricevere le push.

## Da fare: invio dal server (iPhone e Android)
4. **Firebase → Impostazioni progetto → Account di servizio → Genera nuova
   chiave privata**: scarica il JSON.
5. **Supabase → Edge Functions → Secrets**: aggiungi `FIREBASE_SERVICE_ACCOUNT`
   con il **contenuto intero** del JSON. Poi cancella il file scaricato.

## Prova
- Avvia l'app su un telefono, consenti le notifiche; in `device_tokens` compare
  il token.
- Da un altro profilo lancia un piano con l'app in secondo piano: arriva la push.
  Toccandola si apre il piano. Con l'app aperta vale il banner in-app.
- Sul simulatore iOS si può simulare la notifica (senza APNs vero):
  `xcrun simctl push booted com.valeriomortella.ciamafa payload.json`
  con `{"aps":{"alert":{"title":"Prova","body":"🍻 Bar · Pineta"}},"route":"/plans"}`.
