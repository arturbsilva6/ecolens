// EcoLens — exclusão da conta pelo próprio usuário (LGPD, art. 18, VI).
// Exige sessão real do Supabase Auth (verify_jwt=true) e a confirmação
// {"confirm":"EXCLUIR"}. Ordem: fotos no Storage -> avistamentos -> conta.
// A chave administrativa existe só no servidor e nunca é devolvida.
const jsonHeaders = {
  "content-type": "application/json; charset=utf-8",
  "cache-control": "no-store",
  "access-control-allow-origin": "*",
  "access-control-allow-headers": "authorization, apikey, content-type",
  "access-control-allow-methods": "POST, OPTIONS",
};

const BUCKET = "community-photos";

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), { status, headers: jsonHeaders });
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
  if (request.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: jsonHeaders });
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

  let body: { confirm?: unknown };
  try {
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
    | { id?: string; is_anonymous?: boolean }
    | null;
  const userId = user?.id;
  if (!userId || !/^[0-9a-f-]{36}$/i.test(userId)) {
    return json({ error: "Usuário não autenticado." }, 401);
  }
  if (user?.is_anonymous === true) {
    return json({ error: "Sessões anônimas não têm conta para excluir." }, 400);
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
