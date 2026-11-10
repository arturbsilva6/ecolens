// EcoLens — integração de identificação experimental com Gemini.
// Exige sessão real do Supabase Auth e GEMINI_API_KEY no servidor.
// Não salva imagens; envia bytes à API Gemini após consentimento do usuário.
// O app Android não usa CORS. Navegadores só são aceitos se a origem estiver
// em ALLOWED_ORIGINS (lista separada por vírgulas nos segredos da função).
const allowedOrigins = (Deno.env.get("ALLOWED_ORIGINS") ?? "")
  .split(",").map((o) => o.trim()).filter((o) => o.length > 0);
let corsOrigin: string | null = null;

function headers(): Record<string, string> {
  const base: Record<string, string> = {
    "content-type": "application/json; charset=utf-8",
    "cache-control": "no-store",
    "vary": "origin",
  };
  if (corsOrigin) {
    base["access-control-allow-origin"] = corsOrigin;
    base["access-control-allow-headers"] =
      "authorization, apikey, content-type, x-client-info";
    base["access-control-allow-methods"] = "POST, OPTIONS";
  }
  return base;
}

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), { status, headers: headers() });
}

// Lê o corpo com teto real de bytes, mesmo sem o cabeçalho content-length.
async function readLimited(
  request: Request,
  maxBytes: number,
): Promise<string | null> {
  const reader = request.body?.getReader();
  if (!reader) return "";
  const chunks: Uint8Array[] = [];
  let total = 0;
  while (true) {
    const { done, value } = await reader.read();
    if (done) break;
    total += value.byteLength;
    if (total > maxBytes) {
      await reader.cancel().catch(() => {});
      return null;
    }
    chunks.push(value);
  }
  const all = new Uint8Array(total);
  let offset = 0;
  for (const chunk of chunks) {
    all.set(chunk, offset);
    offset += chunk.byteLength;
  }
  return new TextDecoder().decode(all);
}

// Hash do IP com o dia, para limitar por rede sem guardar o endereço.
async function networkHash(request: Request): Promise<string | null> {
  const ip = request.headers.get("x-forwarded-for")?.split(",")[0]?.trim() ||
    request.headers.get("x-real-ip")?.trim();
  if (!ip) return null;
  const day = new Date().toISOString().slice(0, 10);
  const digest = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(`ecolens:${day}:${ip}`),
  );
  return Array.from(new Uint8Array(digest))
    .map((b) => b.toString(16).padStart(2, "0")).join("");
}

function safeText(value: unknown, maxLength: number): string | null {
  if (typeof value !== "string") return null;
  const text = value.trim().slice(0, maxLength);
  return text.length > 0 ? text : null;
}

Deno.serve(async (request: Request) => {
  const origin = request.headers.get("origin");
  corsOrigin = origin && allowedOrigins.includes(origin) ? origin : null;
  if (request.method === "OPTIONS") {
    return new Response(null, {
      status: corsOrigin ? 204 : 403,
      headers: headers(),
    });
  }
  if (request.method !== "POST") {
    return json({ error: "Método não permitido." }, 405);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const apiKey = Deno.env.get("GEMINI_API_KEY");
  if (!supabaseUrl || !apiKey) {
    return json({ error: "O serviço de IA ainda não está configurado." }, 503);
  }

  // O teste de JWT na plataforma deve permanecer ativado (verify_jwt=true).
  // Aqui confirmamos que o bearer é de um usuário REAL, não uma chave pública.
  const authHeader = request.headers.get("authorization");
  const jwt = authHeader?.startsWith("Bearer ")
    ? authHeader.substring("Bearer ".length)
    : null;
  if (!jwt) return json({ error: "Sessão obrigatória." }, 401);

  let publicKey: string | undefined = Deno.env.get("SUPABASE_ANON_KEY");
  try {
    const keys = JSON.parse(
      Deno.env.get("SUPABASE_PUBLISHABLE_KEYS") ?? "{}",
    ) as Record<string, string>;
    publicKey = keys.default ?? publicKey;
  } catch {
    // Local development may expose only the legacy ANON key.
  }
  if (!publicKey) return json({ error: "Autenticação indisponível." }, 503);

  const userResponse = await fetch(`${supabaseUrl}/auth/v1/user`, {
    headers: { authorization: `Bearer ${jwt}`, apikey: publicKey },
    signal: AbortSignal.timeout(9000),
  });
  if (!userResponse.ok) {
    return json({ error: "Sessão inválida ou expirada." }, 401);
  }
  const user = await userResponse.json().catch(() => null) as
    | { id?: string; is_anonymous?: boolean }
    | null;
  if (!user?.id) return json({ error: "Usuário não autenticado." }, 401);
  // Visitantes (sessão anônima) têm cota menor e separada das contas.
  const anonymous = user.is_anonymous === true;

  // A quota é persistida no PostgreSQL e consumida ANTES da chamada Gemini.
  // Limites por dia: ver a migração 20261110025232_ai_quota_anonymous.sql.
  // A RPC só pode ser executada com chave administrativa do servidor.
  let privilegedKey: string | undefined;
  try {
    const keys = JSON.parse(
      Deno.env.get("SUPABASE_SECRET_KEYS") ?? "{}",
    ) as Record<string, string>;
    privilegedKey = keys.default ??
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  } catch {
    privilegedKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  }
  if (!privilegedKey) {
    return json({ error: "Controle de uso indisponível." }, 503);
  }

  const length = Number(request.headers.get("content-length") ?? 0);
  if (length > 5_700_000) return json({ error: "Imagem muito grande." }, 413);

  let body: { imageBase64?: unknown; mimeType?: unknown };
  try {
    const text = await readLimited(request, 5_700_000);
    if (text === null) return json({ error: "Imagem muito grande." }, 413);
    body = JSON.parse(text);
  } catch {
    return json({ error: "JSON inválido." }, 400);
  }

  const mimeType = body.mimeType;
  const encoded = body.imageBase64;
  if (
    (mimeType !== "image/jpeg" && mimeType !== "image/png") ||
    typeof encoded !== "string" ||
    encoded.length === 0 ||
    encoded.length > 5_600_000 ||
    !/^[A-Za-z0-9+/]*={0,2}$/.test(encoded)
  ) {
    return json({ error: "Envie apenas imagens JPEG ou PNG de até 4 MB." }, 400);
  }

  let bytes: Uint8Array;
  try {
    bytes = Uint8Array.from(atob(encoded), (c) => c.charCodeAt(0));
  } catch {
    return json({ error: "Imagem inválida." }, 400);
  }
  if (bytes.byteLength > 4 * 1024 * 1024) {
    return json({ error: "Imagem muito grande." }, 413);
  }
  const jpeg = bytes.length >= 3 &&
    bytes[0] === 0xFF && bytes[1] === 0xD8 && bytes[2] === 0xFF;
  const png = bytes.length >= 8 &&
    bytes[0] === 0x89 && bytes[1] === 0x50 && bytes[2] === 0x4E &&
    bytes[3] === 0x47 && bytes[4] === 0x0D && bytes[5] === 0x0A &&
    bytes[6] === 0x1A && bytes[7] === 0x0A;
  if ((mimeType === "image/jpeg" && !jpeg) ||
      (mimeType === "image/png" && !png)) {
    return json({ error: "Formato de imagem inconsistente." }, 400);
  }

  let quotaResponse: Response;
  try {
    const key = privilegedKey;
    quotaResponse = await fetch(
      `${supabaseUrl}/rest/v1/rpc/ecolens_consume_ai_quota`,
      {
        method: "POST",
        headers: {
          "content-type": "application/json",
          "apikey": key,
          ...(key.startsWith("eyJ")
            ? { "authorization": `Bearer ${key}` }
            : {}),
        },
        body: JSON.stringify({
          p_user_id: user.id,
          p_anonymous: anonymous,
          p_ip_hash: await networkHash(request),
        }),
        signal: AbortSignal.timeout(7000),
      },
    );
  } catch {
    return json({ error: "Limite de uso indisponível." }, 503);
  }
  if (!quotaResponse.ok) {
    return json({ error: "Não foi possível validar a cota." }, 503);
  }
  const allowed = await quotaResponse.json().catch(() => false);
  if (allowed !== true) {
    return json({
      error: anonymous
        ? "Limite diário de análises para visitantes atingido. Entre na sua conta para analisar mais fotos."
        : "Limite diário de análises atingido.",
    }, 429);
  }

  const model = Deno.env.get("GEMINI_MODEL") ??
    "gemini-3.5-flash-lite";
  try {
    const response = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(model)}:generateContent`,
      {
        method: "POST",
        headers: {
          "content-type": "application/json",
          "x-goog-api-key": apiKey,
        },
        body: JSON.stringify({
          contents: [{
            parts: [
              {
                text:
                  "Você está analisando uma única fotografia para um TCC " +
                  "sobre fauna e flora brasileira. A tarefa é SOMENTE " +
                  "sugerir taxonomia. É obrigatório responder em JSON. " +
                  "Se a imagem não permitir identificação responsável, " +
                  "retorne identified=false, nomes vazios e explique " +
                  "por quê. Não invente certeza, percentuais, fontes, " +
                  "periculosidade, tratamento ou primeiros socorros. " +
                  "Não infira localização. A foto pode mostrar um animal " +
                  "(inclusive insetos e aracnídeos), uma planta ou um " +
                  "fungo. Para plantas, observe formato e margem das " +
                  "folhas, como se distribuem no caule, flores, frutos, " +
                  "espinhos e presença de látex; para animais, cores, " +
                  "padrões, escamas ou pelos e formato do corpo. Se " +
                  "sugerir espécie, explique brevemente os traços " +
                  "visuais observados e use o nome popular mais comum " +
                  "no Brasil. Campos: identified(boolean), " +
                  "kind(\"animal\" | \"planta\" | \"fungo\" | " +
                  "\"indefinido\"), commonName(string), " +
                  "scientificName(string), explanation(string).",
              },
              { inlineData: { mimeType, data: encoded } },
            ],
          }],
          generationConfig: {
            responseMimeType: "application/json",
            temperature: 0.2,
          },
        }),
        // O Gemini pode levar mais que 25s em algumas análises.
        // Mantemos prazo inferior ao timeout da plataforma Supabase.
        signal: AbortSignal.timeout(45000),
      },
    );

    if (!response.ok) {
      return json({ error: "Serviço de IA indisponível. Tente depois." }, 502);
    }

    const result = await response.json();
    const raw = result?.candidates?.[0]?.content?.parts?.[0]?.text;
    if (typeof raw !== "string") {
      return json({ error: "Análise inconclusiva." }, 502);
    }

    const parsed: unknown = JSON.parse(raw);
    if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) {
      return json({ error: "Resposta inesperada da IA." }, 502);
    }
    const v = parsed as Record<string, unknown>;
    const commonName = safeText(v.commonName, 100);
    const scientificName = safeText(v.scientificName, 100);
    const identified = v.identified === true &&
      (commonName !== null || scientificName !== null);

    const kind = ["animal", "planta", "fungo"].includes(String(v.kind))
      ? String(v.kind)
      : "indefinido";

    return json({
      identified,
      kind,
      commonName: identified ? commonName : null,
      scientificName: identified ? scientificName : null,
      explanation: safeText(v.explanation, 500) ??
        "Não foi possível concluir a análise.",
    });
  } catch (error) {
    // Não registrar a imagem, resposta do provedor ou a chave em logs.
    // Distinguir timeout evita que o app apresente uma falha genérica.
    if (error instanceof Error &&
        (error.name === "TimeoutError" || error.name === "AbortError")) {
      return json({
        error: "A análise demorou mais que o esperado. Tente novamente mais tarde.",
      }, 504);
    }
    return json({ error: "Falha na análise. Tente depois." }, 502);
  }
});
