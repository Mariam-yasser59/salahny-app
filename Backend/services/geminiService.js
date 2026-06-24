import { GoogleGenAI } from '@google/genai';

const MODEL = process.env.GEMINI_MODEL || 'gemini-2.0-flash';
const FALLBACK_MODELS = [
  'gemini-2.5-flash-lite',
  'gemini-2.5-flash',
  'gemini-2.0-flash-lite',
  'gemini-2.0-flash',
  'gemini-1.5-flash',
];

let client;

const getClient = () => {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) {
    throw Object.assign(new Error('GEMINI_API_KEY is not configured'), {
      statusCode: 503,
    });
  }
  if (!client) {
    client = new GoogleGenAI({ apiKey });
  }
  return client;
};

const systemInstruction = `
You are Salahny's automotive assistant.
Answer briefly, clearly, and safely.
Help with car problems, OBD fault explanations, maintenance advice, emergency guidance, workshop/service questions, and Salahny app support.
Do not claim to replace a certified mechanic.
For dangerous symptoms such as overheating, smoke, brake failure, fuel leak, electrical burning smell, or severe warning lights, tell the driver to stop safely and use Salahny Emergency Service or contact a workshop.
Mention Salahny features when useful: Diagnostics, Emergency Request, Find Nearby Workshop, booking, and workshop chat.
Avoid unrelated topics. If the question is unrelated, politely redirect to vehicle or Salahny support.
`;

const buildPrompt = ({ message, userContext = {} }) => {
  const contextText = [
    userContext.role ? `User role: ${userContext.role}` : null,
    userContext.name ? `User name: ${userContext.name}` : null,
    userContext.latestDiagnostic
      ? `Latest diagnostic: ${JSON.stringify(userContext.latestDiagnostic)}`
      : null,
  ]
    .filter(Boolean)
    .join('\n');

  return `${contextText ? `${contextText}\n\n` : ''}Driver question: ${message}`;
};

const modelCandidates = () =>
  [...new Set([MODEL, ...FALLBACK_MODELS].filter(Boolean))];

const extractText = (response) => {
  if (!response) return '';
  if (typeof response.text === 'function') return response.text().trim();
  if (typeof response.text === 'string') return response.text.trim();
  const parts = response.candidates?.flatMap((candidate) => candidate.content?.parts ?? []) ?? [];
  return parts
    .map((part) => part.text)
    .filter(Boolean)
    .join('\n')
    .trim();
};

const sanitizeGeminiError = (error) => {
  const message = error?.message?.toString() || 'Gemini request failed';
  return message
    .replace(/AIza[0-9A-Za-z_-]+/g, '***')
    .replace(/key=[^&\s]+/g, 'key=***')
    .slice(0, 500);
};

const askGeminiSdk = async ({ message, userContext = {}, model }) => {
  const ai = getClient();

  const response = await ai.models.generateContent({
    model,
    contents: [
      {
        role: 'user',
        parts: [
          {
            text: buildPrompt({ message, userContext }),
          },
        ],
      },
    ],
    config: {
      systemInstruction,
      temperature: 0.35,
      maxOutputTokens: 600,
    },
  });

  const reply = extractText(response);
  if (!reply) {
    throw Object.assign(new Error('Gemini returned an empty reply'), {
      statusCode: 502,
    });
  }
  return reply;
};

const askGeminiRest = async ({ message, userContext = {}, model }) => {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) {
    throw Object.assign(new Error('GEMINI_API_KEY is not configured'), {
      statusCode: 503,
    });
  }

  const response = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(
      model,
    )}:generateContent?key=${encodeURIComponent(apiKey)}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        systemInstruction: {
          parts: [{ text: systemInstruction }],
        },
        contents: [
          {
            role: 'user',
            parts: [{ text: buildPrompt({ message, userContext }) }],
          },
        ],
        generationConfig: {
          temperature: 0.35,
          maxOutputTokens: 600,
        },
      }),
    },
  );

  const payload = await response.json().catch(() => ({}));
  if (!response.ok) {
    throw Object.assign(
      new Error(payload.error?.message || `Gemini REST returned HTTP ${response.status}`),
      { statusCode: response.status },
    );
  }

  const reply = extractText(payload);
  if (!reply) {
    throw Object.assign(new Error('Gemini REST returned an empty reply'), {
      statusCode: 502,
    });
  }
  return reply;
};

export const askGemini = async ({ message, userContext = {} }) => {
  const errors = [];
  for (const model of modelCandidates()) {
    try {
      return {
        reply: await askGeminiSdk({ message, userContext, model }),
        model,
        transport: 'sdk',
      };
    } catch (error) {
      errors.push(`${model}/sdk: ${sanitizeGeminiError(error)}`);
    }

    try {
      return {
        reply: await askGeminiRest({ message, userContext, model }),
        model,
        transport: 'rest',
      };
    } catch (error) {
      errors.push(`${model}/rest: ${sanitizeGeminiError(error)}`);
    }
  }

  throw Object.assign(new Error(errors.join(' | ') || 'Gemini request failed'), {
    statusCode: 502,
  });
};

export const isGeminiConfigured = () => Boolean(process.env.GEMINI_API_KEY);

export const currentGeminiModel = () => MODEL;

export { sanitizeGeminiError };
