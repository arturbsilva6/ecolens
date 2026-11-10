// EcoLens — exclusão da conta pelo próprio usuário (LGPD, art. 18, VI).
// Exige sessão real do Supabase Auth (verify_jwt=true), a confirmação
// {"confirm":"EXCLUIR"} e uma prova recente de identidade:
//   * contas com senha: a senha atual ({"password": "..."});
//   * contas só com Google: login feito há no máximo 15 minutos.
// Ordem: fotos no Storage -> avistamentos -> conta.
// A chave administrativa existe só no servidor e nunca é devolvida.
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

const BUCKET = "community-photos";
const RECENT_LOGIN_SECONDS = 15 * 60;

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), { status, headers: headers() });
}

// Momento do último login (claim "amr" do token, que não muda ao renovar a
// sessão). O token já foi validado pela plataforma (verify_jwt=true).
function lastAuthentication(jwt: string): number {
  try {
    const part = jwt.split(".")[1].replace(/-/g, "+").replace(/_/g, "/");
    const payload = JSON.parse(atob(part.padEnd(Math.ceil(part.length / 4) * 4, "=")));
    const amr = Array.isArray(payload?.amr) ? payload.amr : [];
    return Math.max(
      0,
      ...amr.map((m: { timestamp?: unknown }) =>
        typeof m?.timestamp === "number" ? m.timestamp : 0
      ),
    );
  } catch {
    return 0;
  }
}

function readKey(envJson: string, fallback: string): string | undefined {
  try {
    const keys = JSON.parse(Deno.env.get(envJson) ?? "{}") as Record<
      string,
      string
    >;
    return keys.default ?? Deno.env.get(fallback);
  } catch {
    return Deno.env.get(fallback);
  }
}

function adminHeaders(key: string): Record<string, string> {
  // Chaves novas (sb_secret_) vão só no apikey; as legadas (JWT) também no
  // Authorization.
  return {
    apikey: key,
    ...(key.startsWith("eyJ") ? { authorization: `Bearer ${key}` } : {}),
  };
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
  const publicKey = readKey("SUPABASE_PUBLISHABLE_KEYS", "SUPABASE_ANON_KEY");
  const adminKey = readKey("SUPABASE_SECRET_KEYS", "SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !publicKey || !adminKey) {
    return json({ error: "Serviço indisponível." }, 503);
  }

  const authHeader = request.headers.get("authorization");
  const jwt = authHeader?.startsWith("Bearer ")
    ? authHeader.substring("Bearer ".length)
    : null;
  if (!jwt) return json({ error: "Sessão obrigatória." }, 401);

  let body: { confirm?: unknown; password?: unknown };
  try {
    const length = Number(request.headers.get("content-length") ?? 0);
    if (length > 4096) return json({ error: "Pedido muito grande." }, 413);
    body = await request.json();
  } catch {
    return json({ error: "JSON inválido." }, 400);
  }
  if (body.confirm !== "EXCLUIR") {
    return json({ error: "Confirmação ausente." }, 400);
  }

  // Confirma que o token é de um usuário real (não de uma chave pública).
  const userResponse = await fetch(`${supabaseUrl}/auth/v1/user`, {
    headers: { authorization: `Bearer ${jwt}`, apikey: publicKey },
    signal: AbortSignal.timeout(9000),
  });
  if (!userResponse.ok) {
    return json({ error: "Sessão inválida ou expirada." }, 401);
  }
  const user = await userResponse.json().catch(() => null) as
    | {
      id?: string;
      email?: string;
      is_anonymous?: boolean;
      app_metadata?: { providers?: unknown };
    }
    | null;
  const userId = user?.id;
  if (!userId || !/^[0-9a-f-]{36}$/i.test(userId)) {
    return json({ error: "Usuário não autenticado." }, 401);
  }
  if (user?.is_anonymous === true) {
    return json({ error: "Sessões anônimas não têm conta para excluir." }, 400);
  }

  // Prova recente de identidade, para quem pegar o celular desbloqueado (ou
  // uma sessão roubada) não conseguir apagar a conta.
  const providers = Array.isArray(user?.app_metadata?.providers)
    ? user!.app_metadata!.providers as unknown[]
    : [];
  if (providers.includes("email")) {
    const password = typeof body.password === "string" ? body.password : "";
    if (!password || password.length > 128 || !user?.email) {
      return json({ error: "Informe sua senha.", code: "password_required" }, 403);
    }
    const check = await fetch(
      `${supabaseUrl}/auth/v1/token?grant_type=password`,
      {
        method: "POST",
        headers: { apikey: publicKey, "content-type": "application/json" },
        body: JSON.stringify({ email: user.email, password }),
        signal: AbortSignal.timeout(9000),
      },
    );
    if (!check.ok) {
      return json({ error: "Senha incorreta.", code: "wrong_password" }, 403);
    }
  } else {
    const age = Date.now() / 1000 - lastAuthentication(jwt);
    if (age > RECENT_LOGIN_SECONDS) {
      return json({
        error: "Entre de novo para confirmar.",
        code: "reauthentication_required",
      }, 403);
    }
  }

  const admin = adminHeaders(adminKey);
  const owner = encodeURIComponent(userId);

  try {
    // 1. Fotos dos avistamentos do usuário.
    const rows = await fetch(
      `${supabaseUrl}/rest/v1/community_sightings?owner_id=eq.${owner}&select=photo_path`,
      { headers: admin, signal: AbortSignal.timeout(9000) },
    );
    if (!rows.ok) throw new Error(`listar avistamentos: ${rows.status}`);
    const sightings = await rows.json() as { photo_path?: string | null }[];
    const paths = sightings
      .map((s) => s.photo_path)
      .filter((p): p is string => typeof p === "string" && p.length > 0);
    for (let i = 0; i < paths.length; i += 100) {
      const removed = await fetch(`${supabaseUrl}/storage/v1/object/${BUCKET}`, {
        method: "DELETE",
        headers: { ...admin, "content-type": "application/json" },
        body: JSON.stringify({ prefixes: paths.slice(i, i + 100) }),
        signal: AbortSignal.timeout(15000),
      });
      if (!removed.ok) throw new Error(`remover fotos: ${removed.status}`);
    }

    // 2. Avistamentos (o gatilho exige que as fotos já tenham sido removidas).
    const deleted = await fetch(
      `${supabaseUrl}/rest/v1/community_sightings?owner_id=eq.${owner}`,
      {
        method: "DELETE",
        headers: { ...admin, prefer: "return=minimal" },
        signal: AbortSignal.timeout(9000),
      },
    );
    if (!deleted.ok) throw new Error(`apagar avistamentos: ${deleted.status}`);

    // 3. Conta (sessões e identidades são apagadas em cascata).
    const account = await fetch(`${supabaseUrl}/auth/v1/admin/users/${owner}`, {
      method: "DELETE",
      headers: admin,
      signal: AbortSignal.timeout(9000),
    });
    if (!account.ok) throw new Error(`apagar conta: ${account.status}`);
  } catch (error) {
    // Registra só a etapa e o status; nunca token, e-mail ou caminhos.
    console.error("delete-account", error instanceof Error ? error.message : "erro");
    return json({ error: "Não foi possível concluir a exclusão." }, 502);
  }

  return json({ deleted: true });
});
