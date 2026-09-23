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

## Da fare, solo per Android
- Client OAuth **Android** su Google Cloud Console: package
  `com.valeriomortella.ciamafa` + SHA-1 del certificato di firma (debug:
  `keytool -list -v -keystore ~/.android/debug.keystore -alias
  androiddebugkey -storepass android`; per il rilascio, la chiave di upload,
  vedi `docs/release-setup.md`). Non serve incollare nulla in `env.json`:
  Android lo trova da solo tramite `google-services.json`, basta che il
  client esista con l'SHA-1 giusto.

## Prova
- Onboarding da zero: "Accedi con Apple"/"Accedi con Google" → schermata
  nickname → profilo creato.
- Da un profilo anonimo esistente: Profilo → sezione "Account" → collega
  Apple/Google → stesso nickname, stessi piani/voti, la sezione sparisce.
- Un account già collegato a un altro profilo del gruppo mostra l'avviso
  invece di rubarlo.
