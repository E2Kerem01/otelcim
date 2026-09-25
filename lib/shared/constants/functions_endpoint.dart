/// Base URL of the HTTPS callable Cloud Functions.
///
/// Production by default. E2E builds point it at the local Functions emulator
/// (`--dart-define=E2E_FUNCTIONS_BASE=http://10.0.2.2:5001/otelcim-7f0ba/europe-west1`)
/// so tests never reach the live payment/boost functions.
const String functionsBaseUrl = String.fromEnvironment(
  'E2E_FUNCTIONS_BASE',
  defaultValue: 'https://europe-west1-otelcim-7f0ba.cloudfunctions.net',
);

Uri functionsEndpoint(String name) => Uri.parse('$functionsBaseUrl/$name');
