/// Base URL for the Cloudflare Worker that proxies AI API calls.
///
/// The worker (see worker/README.md) stores the Groq and Google AI Studio
/// keys as Cloudflare secrets, so no AI API key is ever compiled into the app.
///
/// Developers can override this URL during build or run:
/// `flutter run --dart-define=AI_WORKER_URL=https://your-worker.workers.dev`
const String cloudflareWorkerUrl = String.fromEnvironment(
  'AI_WORKER_URL',
  defaultValue: 'https://flousi-ai-worker.been5-oco-1.workers.dev',
);
