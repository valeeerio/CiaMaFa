# Rilascio: firma e identificativi

Bundle ID / applicationId: `com.valeriomortella.ciamafa` (iOS e Android).
Una volta pubblicata l'app sugli store non si può più cambiare.

## Android: chiave di upload

Una volta sola, fuori dal repo (es. `~/keys/`):

```
keytool -genkey -v -keystore ~/keys/ciamafa-upload.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Poi crea `android/key.properties` (gitignored):

```
storePassword=<password del keystore>
keyPassword=<password della chiave>
keyAlias=upload
storeFile=/Users/<tu>/keys/ciamafa-upload.jks
```

`flutter build appbundle` firma con questa chiave; senza `key.properties` il
build di release usa la chiave di debug (ok in locale, rifiutato dal Play Store).
Su Play Console attiva **Play App Signing**: Google custodisce la chiave
dell'app, tu solo quella di upload (se la perdi si può sostituire).
Salva keystore e password in un posto sicuro (password manager + backup).

Google Sign-In su Android vuole anche l'SHA-1 della chiave di upload e di
quella di Play App Signing (vedi `docs/auth-setup.md`):

```
keytool -list -v -keystore ~/keys/ciamafa-upload.jks -alias upload
```

## iOS

- `ITSAppUsesNonExemptEncryption = false` in `Info.plist`: l'app usa solo
  HTTPS, quindi è esente dagli obblighi sulla crittografia (niente domanda a
  ogni upload su App Store Connect).
- La firma la gestisce Xcode (team dell'Apple Developer Program).

## Dopo il cambio di bundle ID

Le app registrate col vecchio id (`com.valeriomortella.ciamafa.ciamafa`) non
valgono più. Da rifare:

1. **Firebase**: aggiungi un'app iOS e una Android con il nuovo id, aggiorna
   `FIREBASE_IOS_APP_ID` / `FIREBASE_ANDROID_APP_ID` (e le API key se cambiano)
   in `env.json`. La chiave APNs caricata su Firebase resta valida.
2. **Apple Developer**: nuovo App ID con Push Notifications e Sign in with
   Apple.
3. **Supabase Auth → Apple**: Client ID = nuovo bundle id.
4. **Google Cloud**: client OAuth iOS/Android col nuovo id.
