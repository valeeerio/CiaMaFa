# Login Apple/Google: stato

## Fatto e collegato
- Pacchetti `sign_in_with_apple` e `google_sign_in`.
- `com.apple.developer.applesignin` nell'entitlements di iOS (capability
  registrata da Xcode al prossimo build con la firma automatica).
- Supabase Auth (Authentication → Providers):
  - **Apple** attivo, Client ID = bundle id `com.valeriomortella.ciamafa`.
  - **Google** attivo, Client IDs = client Web + client iOS (sotto), "Skip
    nonce checks" attivo (il flusso nativo Google non genera un nonce
    controllato dall'app, a differenza di Apple).
  - **Allow manual linking of identities** attivo (serve a
    `linkIdentityWithIdToken`, il collegamento di chi è ancora anonimo).
- Google Cloud Console, progetto `ciamafa` (stesso di Firebase):
  - Schermata di consenso OAuth (Esterno, "CiaMaFa").
  - Client OAuth **Web** ("CiaMaFa Web (Supabase)"): usato come
    `GOOGLE_WEB_CLIENT_ID` e come `serverClientId` nell'app.
  - Client OAuth **iOS** ("CiaMaFa iOS", bundle id
    `com.valeriomortella.ciamafa`): usato come `GOOGLE_IOS_CLIENT_ID`.
- `GOOGLE_WEB_CLIENT_ID` / `GOOGLE_IOS_CLIENT_ID` in `env.json` (gitignored; i
  nomi sono in `env.example.json`).
- `CFBundleURLTypes` in `ios/Runner/Info.plist` con il Reversed Client ID del
  client iOS (`com.googleusercontent.apps.…`): senza, Google Sign-In su
  iPhone non torna in app dopo il login.

## Fatto, solo per Android
- Client OAuth **Android** su Google Cloud Console ("CiaMaFa Android"):
  package `com.valeriomortella.ciamafa` + SHA-1 del certificato di firma
  **debug** (`82:76:9D:0B:40:5C:E3:69:07:2A:91:12:EA:29:22:F5:C1:28:35:D5`,
  da `keytool -list -v -keystore ~/.android/debug.keystore -alias
  androiddebugkey -storepass android`). Non serve incollare nulla in
  `env.json`: Android lo trova da solo tramite `android/app/google-services.json`
  (gitignored, scaricato da Firebase → Impostazioni progetto → App Android).
- **Da fare quando si genera la chiave di upload per il rilascio** (vedi
  `docs/release-setup.md`): aggiungere anche il SHA-1 di quella chiave (su
  Firebase → App Android → "Aggiungi impronta digitale", poi riscaricare
  `google-services.json`), altrimenti il login Google non funziona nelle
  build firmate per il rilascio/Play Store.

## Prova
- Onboarding da zero: "Accedi con Apple"/"Accedi con Google" → schermata
  nickname → profilo creato.
- Da un profilo anonimo esistente: Profilo → sezione "Account" → collega
  Apple/Google → stesso nickname, stessi piani/voti, la sezione sparisce.
- Un account già collegato a un altro profilo del gruppo mostra l'avviso
  invece di rubarlo.
