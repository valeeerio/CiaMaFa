# Login Apple/Google: cosa manca per attivarlo

Il codice è pronto e provato (schermata di accesso, collegamento per chi è
ancora anonimo). Mancano solo le credenziali, che si collegano una volta sola.
Finché non ci sono, i pulsanti Apple/Google restano visibili ma le chiamate a
Supabase falliranno: non lanciare la Fase 10 sugli amici prima di aver seguito
questa guida.

## Già fatto
- Pacchetti `sign_in_with_apple` e `google_sign_in` aggiunti.
- `com.apple.developer.applesignin` nell'entitlements di iOS (Xcode registra
  la capability sul portale Apple da solo, al prossimo build con la firma
  automatica: non serve toccare nulla in Xcode per questa).
- `GOOGLE_WEB_CLIENT_ID` / `GOOGLE_IOS_CLIENT_ID` in `env.json` (gitignored; i
  nomi sono in `env.example.json`). Senza `GOOGLE_WEB_CLIENT_ID`, il pulsante
  Google fallisce all'inizializzazione.

## Da fare: Supabase (Authentication → Providers)
1. **Apple**: attivalo e incolla come "Client ID" il bundle id,
   `com.valeriomortella.ciamafa`. Non serve nessun'altra chiave: il
   flusso nativo (id token) non passa dal Service ID/redirect di Apple.
2. **Google**: attivalo e incolla il **Client ID Web** (vedi sotto) sia come
   "Client ID" sia in "Authorized Client IDs" (serve per validare i token del
   client iOS).
3. **Authentication → Settings → User Signups**: attiva "Allow manual linking
   of identities" (serve per `linkIdentityWithIdToken`, il collegamento di chi
   è ancora anonimo).

## Da fare: Google Cloud Console (stesso progetto di Firebase, `ciamafa`)
1. **APIs & Services → OAuth consent screen**: tipo "Esterno", nome app
   "CiaMaFa", email di supporto la vostra; salva (non serve la pubblicazione
   per un gruppo chiuso di tester).
2. **APIs & Services → Credentials → + Create credentials → OAuth client ID**:
   - Tipo **Web application** → copia il Client ID in `GOOGLE_WEB_CLIENT_ID`
     (in `env.json`).
   - Tipo **iOS** → Bundle ID `com.valeriomortella.ciamafa` → copia il
     Client ID in `GOOGLE_IOS_CLIENT_ID`.
   - Tipo **Android** → package `com.valeriomortella.ciamafa` + SHA-1
     del certificato di firma (debug: `keytool -list -v -keystore
     ~/.android/debug.keystore -alias androiddebugkey -storepass android`).
     Non serve incollarlo in `env.json`: Android lo trova da solo tramite
     `google-services.json`.
3. **iOS Info.plist**: apri il client iOS appena creato, copia il "Reversed
   client ID" (es. `com.googleusercontent.apps.123-abc`) e aggiungilo a
   `ios/Runner/Info.plist` dentro `CFBundleURLTypes` (nuovo `<dict>` con
   `CFBundleURLSchemes` = quel valore). Senza, Google Sign-In su iPhone non
   torna in app dopo il login.

## Prova
- Onboarding da zero: "Accedi con Apple"/"Accedi con Google" → schermata
  nickname → profilo creato.
- Da un profilo anonimo esistente: Profilo → sezione "Account" → collega
  Apple/Google → stesso nickname, stessi piani/voti, la sezione sparisce.
- Un account già collegato a un altro profilo del gruppo mostra l'avviso
  invece di rubarlo.
