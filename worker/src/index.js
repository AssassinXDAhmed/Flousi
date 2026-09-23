import { jwtVerify, createRemoteJWKSet } from "jose";

// ---------------------------------------------------------------------------
// Firebase JWT verification
// ---------------------------------------------------------------------------

const CLOCK_TOLERANCE_SECONDS = 60;

const JWKS = createRemoteJWKSet(
  new URL(
    "https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com"
  )
);

/**
 * Verify a Firebase Auth ID token. Throws on invalid/expired tokens.
 * @param {string} token  The raw JWT string
 * @param {string} projectId  Firebase project ID
 * @returns {Promise<object>}  The decoded payload (includes `sub` = uid)
 */
async function verifyFirebaseToken(token, projectId) {
  // Claim rules follow Firebase's "verify ID tokens using a third-party JWT
  // library" checklist.
  const { payload } = await jwtVerify(token, JWKS, {
    issuer: `https://securetoken.google.com/${projectId}`,
    audience: projectId,
    algorithms: ["RS256"],
    requiredClaims: ["exp", "iat", "auth_time"],
  });
  if (
    typeof payload.sub !== "string" ||
    payload.sub.length === 0 ||
    payload.sub.length > 128
  ) {
    throw new Error("token has no valid subject");
  }
  const now = Math.floor(Date.now() / 1000) + CLOCK_TOLERANCE_SECONDS;
  if (
    typeof payload.auth_time !== "number" ||
    payload.auth_time > now ||
    payload.iat > now
  ) {
    throw new Error("token was issued in the future");
  }
  return payload;
}

// ---------------------------------------------------------------------------
// CORS helpers
// ---------------------------------------------------------------------------

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
  "Access-Control-Max-Age": "86400",
};

function corsResponse() {
  return new Response(null, { status: 204, headers: CORS_HEADERS });
}

function jsonResponse(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json", ...CORS_HEADERS },
  });
}

// ---------------------------------------------------------------------------
// Request validation
// ---------------------------------------------------------------------------

// Caps keep a signed-in client from pushing arbitrarily large prompts/images
// through our AI keys.
const MAX_SUMMARY_CHARS = 8000;
const MAX_IMAGE_DATA_URI_CHARS = 15 * 1024 * 1024;

/**
 * Parse the request body as a JSON object. Returns null if it is not one.
 */
async function readJsonObject(request) {
  try {
    const body = await request.json();
    return body && typeof body === "object" && !Array.isArray(body)
      ? body
      : null;
  } catch {
    return null;
  }
}

function isNonEmptyString(value, maxLength) {
  return (
    typeof value === "string" && value.length > 0 && value.length <= maxLength
  );
}

/**
 * languageCode is interpolated into the system prompt, so only accept a
 * BCP-47-style code (e.g. "en", "ar", "ar-LY"); anything else falls back to "en".
 */
function sanitizeLanguageCode(value) {
  return typeof value === "string" && /^[a-z]{2,3}(-[A-Za-z0-9]{2,8})?$/.test(value)
    ? value
    : "en";
}

// ---------------------------------------------------------------------------
// Shared AI helpers
// ---------------------------------------------------------------------------

/**
 * Parse a JSON object out of a model's text reply. Returns null when the
 * model produced no usable JSON object.
 */
function parseModelJson(text) {
  if (typeof text !== "string" || !text) return null;
  const jsonStr = extractJsonObject(text);
  if (!jsonStr) return null;
  try {
    return JSON.parse(jsonStr);
  } catch {
    return null;
  }
}

/**
 * Non-2xx reply from an AI provider. Carries the HTTP status so callers can
 * decide whether a different model is worth trying.
 */
class AiApiError extends Error {
  constructor(status, body) {
    super(`AI API ${status}: ${body}`);
    this.status = status;
  }
}

/**
 * Call an OpenAI-compatible chat-completion endpoint with a per-request timeout.
 */
async function postChatCompletion(baseUrl, apiKey, body, extraHeaders = {}, timeoutMs = 12000) {
  const normalizedBase = baseUrl.endsWith("/")
    ? baseUrl.slice(0, -1)
    : baseUrl;
  const url = `${normalizedBase}/chat/completions`;

  const res = await fetch(url, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${apiKey}`,
      ...extraHeaders,
    },
    body: JSON.stringify(body),
    signal: AbortSignal.timeout(timeoutMs),
  });

  if (!res.ok) {
    const text = await res.text();
    throw new AiApiError(res.status, text);
  }
  return res.json();
}

/**
 * Whether another model might succeed after this upstream status: the model
 * is overloaded (5xx — Gemini answers 503 "high demand"), rate limited (429),
 * or unavailable to this key (403/404, and 401 ACCESS_TOKEN_TYPE_UNSUPPORTED,
 * which Gemini also returns for access-restricted models).
 */
function isModelFallbackStatus(status) {
  return (
    status === 401 ||
    status === 403 ||
    status === 404 ||
    status === 429 ||
    status >= 500
  );
}

/**
 * Call [postChatCompletion] with each model in turn, moving to the next one
 * only when the failure is model-specific or timed out. Rethrows the last error.
 */
async function postChatCompletionWithFallback(
  baseUrl,
  apiKey,
  models,
  body,
  extraHeaders = {},
  timeoutMs = 12000
) {
  let lastError;
  for (const model of models) {
    const startedAt = Date.now();
    try {
      const response = await postChatCompletion(
        baseUrl,
        apiKey,
        { ...body, model },
        extraHeaders,
        timeoutMs
      );
      console.log(`${model} answered in ${Date.now() - startedAt} ms`);
      return response;
    } catch (err) {
      const isTimeout = err?.name === "TimeoutError" || err?.name === "AbortError";
      const isFallbackStatus = err instanceof AiApiError && isModelFallbackStatus(err.status);
      if (!isTimeout && !isFallbackStatus) {
        throw err;
      }
      console.warn(
        `${model} failed after ${Date.now() - startedAt} ms${isTimeout ? " (timed out)" : ""}, trying next model: ${(err.message || String(err)).slice(0, 300)}`
      );
      lastError = err;
    }
  }
  throw lastError;
}

/**
 * Parse a comma-separated model list var (e.g. "a, b"); falls back to
 * [defaults] when the var is unset or empty.
 */
function modelList(value, defaults) {
  const models =
    typeof value === "string"
      ? value.split(",").map((m) => m.trim()).filter(Boolean)
      : [];
  return models.length > 0 ? models : defaults;
}

/**
 * Extract the first balanced `{...}` JSON object from a model response.
 */
function extractJsonObject(text) {
  let src = text.trim();
  if (src.startsWith("```")) {
    const firstNewline = src.indexOf("\n");
    src = firstNewline === -1 ? "" : src.substring(firstNewline + 1);
    if (src.endsWith("```")) {
      src = src.substring(0, src.length - 3);
    }
    src = src.trim();
  }

  const start = src.indexOf("{");
  if (start === -1) return null;

  let depth = 0;
  let inString = false;
  let escape = false;
  for (let i = start; i < src.length; i++) {
    const ch = src[i];
    if (inString) {
      if (escape) {
        escape = false;
      } else if (ch === "\\") {
        escape = true;
      } else if (ch === '"') {
        inString = false;
      }
    } else {
      if (ch === '"') {
        inString = true;
      } else if (ch === "{") {
        depth++;
      } else if (ch === "}") {
        depth--;
        if (depth === 0) {
          return src.substring(start, i + 1);
        }
      }
    }
  }
  return null;
}

// ---------------------------------------------------------------------------
// /extractReceipt — Google AI Studio (Gemma 4 / Gemini Flash) vision call
// ---------------------------------------------------------------------------

// Tried in order: Gemma 4 MoE (gemma-4-26b-a4b-it) first for high speed and
// low latency, then Gemma 4 31B (gemma-4-31b-it), followed by Gemini 3.5 Flash-Lite,
// Gemini 3.8 Flash, and Gemini 2.5 Flash as fallbacks.
const DEFAULT_RECEIPT_MODELS = [
  "gemma-4-26b-a4b-it",
  "gemini-3.5-flash-lite",
  "gemma-4-31b-it",
  "gemini-3.8-flash",
  "gemini-2.5-flash",
];

const NOTE_TEMPLATE =
  "اسم المكان: [Place Name]\n" +
  "التاريخ والوقت: [Date and Time]\n" +
  "الاصناف وعددهم وسعر الصنف والاجمالي لكل صنف:\n" +
  "- [Item 1]: [Quantity] x [Price] = [Total]\n" +
  "- [Item 2]: [Quantity] x [Price] = [Total]";

const RECEIPT_SYSTEM_PROMPT =
  "You are a receipt-scanning assistant that extracts transaction details from receipt images. " +
  "You MUST reply with ONLY a raw JSON object. Do NOT wrap it in markdown code blocks (no ```json fences) and do NOT add any conversational text. " +
  "The JSON object must contain EXACTLY these keys:\n" +
  '- "amount" (number): the total overall amount of the receipt.\n' +
  '- "category" (string): the inferred category, one of: groceries, dining, transport, shopping, utilities, health.\n' +
  '- "method" (string): the payment method, either "CASH" or "CARD".\n' +
  '- "note" (string): the receipt details formatted STRICTLY in Arabic using EXACTLY this template, ' +
  "filling in real values read from the image and listing every item found:\n" +
  `${NOTE_TEMPLATE}\n` +
  'If a value cannot be read from the image, write "غير متوفر" in its place. ' +
  "Never deviate from the Arabic template above and never wrap the output in markdown. Output the JSON object only.";

async function handleExtractReceipt(request, env) {
  // Reading the body waits for the client's upload, so this is upload time.
  const uploadStartedAt = Date.now();
  const body = await readJsonObject(request);
  console.log(`extractReceipt: body received in ${Date.now() - uploadStartedAt} ms`);
  const imageDataUri = body?.imageDataUri;

  if (
    !isNonEmptyString(imageDataUri, MAX_IMAGE_DATA_URI_CHARS) ||
    !/^data:image\/[a-z0-9.+-]+;base64,/i.test(imageDataUri)
  ) {
    return jsonResponse(
      { error: "imageDataUri (base64 image data URI, max 15 MB) is required." },
      400
    );
  }

  const apiKey = env.GOOGLE_AI_API_KEY;
  if (!apiKey) {
    console.error("extractReceipt: GOOGLE_AI_API_KEY secret is not set");
    return jsonResponse({ error: "AI service is not configured." }, 500);
  }
  const models = modelList(env.AI_STUDIO_MODEL, DEFAULT_RECEIPT_MODELS);
  const baseUrl =
    env.AI_STUDIO_BASE_URL ||
    "https://generativelanguage.googleapis.com/v1beta/openai/";

  const chatBody = {
    messages: [
      { role: "system", content: RECEIPT_SYSTEM_PROMPT },
      {
        role: "user",
        content: [
          {
            type: "text",
            text: "Extract the transaction from this receipt image and return the JSON object now.",
          },
          { type: "image_url", image_url: { url: imageDataUri } },
        ],
      },
    ],
    response_format: { type: "json_object" },
  };

  try {
    const response = await postChatCompletionWithFallback(
      baseUrl,
      apiKey,
      models,
      chatBody,
      {
        "HTTP-Referer": "https://firstrproject.app",
        "X-Title": "First Project",
      }
    );

    const decoded = parseModelJson(response?.choices?.[0]?.message?.content);
    if (!decoded) {
      console.warn("extractReceipt: no JSON object found in model response");
      return jsonResponse(null);
    }

    return jsonResponse({
      amount:
        typeof decoded.amount === "number"
          ? decoded.amount
          : parseFloat(decoded.amount) || 0,
      category: String(decoded.category || "groceries").toLowerCase(),
      note: String(decoded.note || ""),
      method: String(decoded.method || "CASH").toUpperCase(),
    });
  } catch (err) {
    // Upstream details stay in the worker logs (`wrangler tail`), not the client.
    console.error("extractReceipt error:", err);
    return jsonResponse({ error: "Receipt extraction failed." }, 502);
  }
}

// ---------------------------------------------------------------------------
// /getPredictiveInsight — Groq API (gpt-oss-20b) forecasting call
// ---------------------------------------------------------------------------

function buildPredictiveSystemPrompt(languageCode) {
  return (
    "You are a financial forecasting assistant. You MUST perform real predictive math and trend analysis before answering. " +
    "Do NOT echo totals back as predictions. Follow these steps strictly:\n" +
    "1. From the provided weekly spending summary, identify the category the user spent the MOST on over the past 7 days. " +
    "That category's actual 7-day total goes into weeklySpent.\n" +
    "2. Use the provided daily breakdown for that top category to analyze spending velocity: count the number of transactions, " +
    "see whether spending is spread evenly across multiple days (a recurring daily habit) or concentrated in one or two large purchases " +
    "(a one-time bulk/outlier buy), and determine whether daily amounts are rising, falling, or stable across the week.\n" +
    "3. Forecast predictedNextWeek for the SAME category using this dynamic logic:\n" +
    "   - You MUST NOT simply copy the weeklySpent value into predictedNextWeek. That is strictly forbidden.\n" +
    "   - If the week contains a one-time bulk/outlier purchase with little other activity, predict a LOWER amount for next week, because that large spend is unlikely to repeat.\n" +
    "   - If spending is a recurring daily habit (many small transactions across several days), predict a HIGHER or at least sustained amount, scaling by the number of active days.\n" +
    "   - If spending is accelerating (daily totals rising day over day), predict a HIGHER amount that reflects the upward trend.\n" +
    "   - If spending is decelerating or occurred only early in the week then stopped, predict a LOWER amount.\n" +
    "   - Round predictedNextWeek to a realistic number with at most two decimals. " +
    "It MUST be a meaningfully different value from weeklySpent unless the trend is perfectly flat and stable, in which case it may be close but still reasoned.\n" +
    "4. Write advice that targets the PREDICTED behavior and the predictedNextWeek amount for next week, not just the past week. " +
    "Tell the user concretely how to handle that specific predicted figure (e.g., cap it, reallocate it, avoid the trigger causing the trend). Do not give generic platitudes.\n" +
    "CONSTRAINTS:\n" +
    "- You MUST output ONLY a raw JSON object with EXACTLY these keys: category, weeklySpent, predictedNextWeek, advice. " +
    "No other keys. No snake_case variants.\n" +
    "- weeklySpent is a number (the actual past-week total). predictedNextWeek is a number (your forecast for next week). " +
    "category is the category string. advice is a string.\n" +
    `- You MUST reply in this language code: ${languageCode}.\n` +
    "- You MUST NOT wrap the output in markdown code blocks (no ```json). Output the JSON object only, with no conversational text before or after it."
  );
}

async function handleGetPredictiveInsight(request, env) {
  const body = await readJsonObject(request);
  const weeklySummary = body?.weeklySummary;
  const dailyBreakdown = body?.dailyBreakdown;

  if (
    !isNonEmptyString(weeklySummary, MAX_SUMMARY_CHARS) ||
    !isNonEmptyString(dailyBreakdown, MAX_SUMMARY_CHARS)
  ) {
    return jsonResponse(
      {
        error: `weeklySummary and dailyBreakdown are required strings (max ${MAX_SUMMARY_CHARS} chars).`,
      },
      400
    );
  }

  const apiKey = env.GROQ_API_KEY;
  if (!apiKey) {
    console.error("getPredictiveInsight: GROQ_API_KEY secret is not set");
    return jsonResponse({ error: "AI service is not configured." }, 500);
  }
  const modelId = env.GROQ_MODEL || "openai/gpt-oss-20b";
  const baseUrl = env.GROQ_BASE_URL || "https://api.groq.com/openai/v1";
  const lang = sanitizeLanguageCode(body.languageCode);

  const chatBody = {
    model: modelId,
    messages: [
      { role: "system", content: buildPredictiveSystemPrompt(lang) },
      {
        role: "user",
        content: `Weekly spending summary: ${weeklySummary}.\n${dailyBreakdown}`,
      },
    ],
    response_format: { type: "json_object" },
  };

  try {
    const response = await postChatCompletion(baseUrl, apiKey, chatBody);
    const decoded = parseModelJson(response?.choices?.[0]?.message?.content);
    if (!decoded) {
      console.warn(
        "getPredictiveInsight: no JSON object found in model response"
      );
      return jsonResponse(null);
    }

    return jsonResponse({
      category: String(decoded.category || "Unknown"),
      weeklySpent: parseFloat(decoded.weeklySpent) || 0,
      predictedNextWeek: parseFloat(decoded.predictedNextWeek) || 0,
      advice: String(decoded.advice || ""),
    });
  } catch (err) {
    // Upstream details stay in the worker logs (`wrangler tail`), not the client.
    console.error("getPredictiveInsight error:", err);
    return jsonResponse({ error: "Predictive insight failed." }, 502);
  }
}

// ---------------------------------------------------------------------------
// Main Worker entry point
// ---------------------------------------------------------------------------

async function handleRequest(request, env) {
  // Handle CORS preflight
  if (request.method === "OPTIONS") {
    return corsResponse();
  }

  const url = new URL(request.url);

  // Health check (no auth needed)
  if (url.pathname === "/" || url.pathname === "/health") {
    return jsonResponse({ status: "ok", service: "flousi-ai-worker" });
  }

  // All other routes require POST
  if (request.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  // Verify Firebase Auth token
  const authHeader = request.headers.get("Authorization");
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return jsonResponse({ error: "Missing or invalid Authorization header" }, 401);
  }

  const token = authHeader.slice(7);
  const projectId = env.FIREBASE_PROJECT_ID;
  if (!projectId) {
    console.error("FIREBASE_PROJECT_ID var is not set");
    return jsonResponse({ error: "AI service is not configured." }, 500);
  }

  try {
    await verifyFirebaseToken(token, projectId);
  } catch (err) {
    console.warn("Auth verification failed:", err.message);
    return jsonResponse({ error: `Invalid auth token: ${err.message}` }, 401);
  }

  // Route to handlers
  if (url.pathname === "/extractReceipt") {
    return handleExtractReceipt(request, env);
  }

  if (url.pathname === "/getPredictiveInsight") {
    return handleGetPredictiveInsight(request, env);
  }

  return jsonResponse({ error: "Not found" }, 404);
}

export default {
  async fetch(request, env) {
    try {
      return await handleRequest(request, env);
    } catch (err) {
      // Last-resort guard so every response is JSON with CORS headers.
      console.error("Unhandled worker error:", err);
      return jsonResponse({ error: "Internal error" }, 500);
    }
  },
};
