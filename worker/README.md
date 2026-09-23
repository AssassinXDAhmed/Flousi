# Flousi AI Worker (Cloudflare)

A Cloudflare Worker that proxies AI API calls so API keys stay server-side.

## Endpoints

| Route | Purpose | Secret Used |
|---|---|---|
| `POST /extractReceipt` | Scans receipt images via Google AI Studio (Gemma 4 / Gemini Flash) | `GOOGLE_AI_API_KEY` |
| `POST /getPredictiveInsight` | Forecasts weekly spending via Groq (gpt-oss-20b) | `GROQ_API_KEY` |
| `GET /health` | Health check (no auth) | — |

Both authenticated endpoints require a Firebase Auth ID token in the
`Authorization: Bearer <token>` header.

## Prerequisites

- [Node.js 18+](https://nodejs.org/)
- A [Cloudflare account](https://dash.cloudflare.com/sign-up) (free tier is fine)
- `wrangler` CLI: `npm install -g wrangler`

## Setup

```bash
cd worker
npm install
wrangler login            # browser-based auth, one-time
```

## Set Secrets (one-time, or whenever keys rotate)

```bash
wrangler secret put GROQ_API_KEY
wrangler secret put GOOGLE_AI_API_KEY
```

Each command prompts you to paste the key value. Secrets are encrypted at rest
and are only injected into the worker at runtime — they never appear in code or git.

If a secret is missing, the matching endpoint returns
`500 {"error":"AI service is not configured."}` and logs which secret is unset.

### Optional model overrides

Add any of these under `"vars"` in `wrangler.jsonc` to change models without
touching code or rebuilding the app:

| Var | Default |
|---|---|
| `GROQ_MODEL` | `openai/gpt-oss-20b` |
| `GROQ_BASE_URL` | `https://api.groq.com/openai/v1` |
| `AI_STUDIO_MODEL` | `gemma-4-26b-a4b-it,gemma-4-31b-it,gemini-3.5-flash-lite,gemini-3.8-flash,gemini-2.5-flash` |
| `AI_STUDIO_BASE_URL` | `https://generativelanguage.googleapis.com/v1beta/openai/` |

`AI_STUDIO_MODEL` is a comma-separated list tried in order: when a model is
overloaded (5xx), rate limited (429) or not available to the key
(401/403/404), the receipt scan retries with the next one. A single model
disables the fallback.

## Local Development (optional)

Create a `.dev.vars` file in this directory (already `.gitignore`d) for local testing:

```
GROQ_API_KEY=your_groq_key_here
GOOGLE_AI_API_KEY=your_google_ai_key_here
```

Then run:

```bash
wrangler dev
```

## Deploy

```bash
wrangler deploy
```

The worker is deployed at:
```
https://your-worker-name.your-subdomain.workers.dev
```

## Flutter app

The app calls the worker through `lib/core/network/ai_http_client.dart`
(`postToAiWorker`); the base URL lives in `lib/core/network/worker_config.dart`.
Pass your worker URL using `--dart-define=AI_WORKER_URL=https://your-worker.workers.dev`
when building or running Flutter.

## Verify it works

```bash
curl https://your-worker-name.your-subdomain.workers.dev/health
# {"status":"ok","service":"flousi-ai-worker"}

curl -X POST https://your-worker-name.your-subdomain.workers.dev/getPredictiveInsight
# {"error":"Missing or invalid Authorization header"}   (401 — auth gate works)
```

## Logs

```bash
wrangler tail
```
