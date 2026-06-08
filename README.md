# TemuLapak

TemuLapak is a Flutter mobile app for discovering nearby street vendors, chatting with them, and tracking live merchant activity. It uses Firebase for authentication, database, messaging, and storage, plus Google Maps APIs for map and geocoding features.

## Local Setup

1. Install dependencies:
   ```bash
   flutter pub get
   ```

2. Create your local environment file:
   ```bash
   cp .env.example .env
   ```

3. Fill `.env` with your own Firebase app values and Google Maps API key.

4. Add Android Firebase config:
   ```bash
   cp android/app/google-services.json.example android/app/google-services.json
   ```
   Replace the example values with your real Firebase Android config.

5. Add iOS Firebase config:
   ```bash
   cp ios/Runner/GoogleService-Info.plist.example ios/Runner/GoogleService-Info.plist
   ```
   Replace the example values with your real Firebase iOS config.

6. Add your Maps key to `android/local.properties`:
   ```properties
   maps.api.key=your-google-maps-api-key
   ```

7. Run the app:
   ```bash
   flutter run
   ```

## Public Repo Notes

- Real keys and Firebase client config files are intentionally not committed.
- Realtime Database rules in [database.rules.json](database.rules.json) are now auth-only by default.
- Before publishing a public repo, restrict or rotate any Google Maps and Firebase keys that were previously committed.

## Contact

- axelg.bsns@gmail.com
- bagasdwiputramajid2003@gmail.com
- gslaudrey@gmail.com
