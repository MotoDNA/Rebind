// 작업의뢰서 자동 인식 — Claude API 대행
//
// Re:Call 의 명함 인식(read-card)과 같은 틀입니다.
// API 키를 브라우저에 두지 않으려고 서버가 대신 부릅니다.
// 키는 환경변수에만 있고, 로그인한 사람만 부를 수 있습니다.
//
// 배포:
//   supabase functions deploy read-order --project-ref izrtclsqhsgkuwsffifn
import { createClient } from 'jsr:@supabase/supabase-js@2';
import { mkJson } from '../_shared/cors.ts';

const URL_ = Deno.env.get('SUPABASE_URL')!;
const SERVICE = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const ANON = Deno.env.get('SUPABASE_ANON_KEY')!;
const ANTHROPIC_KEY = Deno.env.get('ANTHROPIC_API_KEY') ?? '';
const MODEL = Deno.env.get('ANTHROPIC_MODEL') ?? 'claude-sonnet-5';
const DAILY_LIMIT = Number(Deno.env.get('ORDER_DAILY_LIMIT') ?? '200');
const MAX_BYTES = 8 * 1024 * 1024;

const admin = createClient(URL_, SERVICE, { auth: { persistSession: false } });

// 제본소 작업의뢰서는 회사마다 양식이 다릅니다.
// 칸 위치로 찾지 않고 "무슨 뜻의 칸인지"로 찾게 합니다.
const PROMPT = [
  '제본소가 받은 작업의뢰서(작업지시서) 사진입니다. 표를 읽어 아래 항목을 뽑아 주세요.',
  '회사마다 양식이 달라서 칸 이름이 제각각입니다. 뜻이 같으면 같은 항목으로 넣으세요.',
  '',
  '- name : 만들 것의 이름. "제품명 · 품명 · 제목 · 건명" 중 있는 것',
  '- client : 이 의뢰서를 발행한 회사. 곧 우리에게 일을 준 곳입니다.',
  '           찾는 법 — "발주처" 칸이 있으면 그것. 없으면 종이 맨 위나 맨 아래의',
  '           상호·로고(예: "○○컴퍼니 제작의뢰서", 오른쪽 위 로고, 맨 아래 회사 주소줄).',
  '           ※ "거래처" 칸은 발행한 회사의 고객입니다. 우리 고객이 아닐 때가 많습니다.',
  '              발행한 회사가 어디인지 분명하면 그것을 넣습니다.',
  '              분명하지 않으면 비우고 uncertain 에 client 를 적으세요.',
  '           ※ 다음 공장 이름은 client 가 아닙니다 —',
  '              입고처 · 출고처 · 납품업체 · 물류 · 지업사 · 제지사 · 인쇄사 · 인쇄소 · 제책사.',
  '           ※ "BKT · 비케이티 · bkt" 는 우리 자신입니다. 절대 client 가 아닙니다.',
  '- person : 담당자 이름. 발주처(client) 쪽 담당자만.',
  '           입고처 · 물류 · 제책사 옆에 적힌 담당자는 넣지 마세요.',
  '- phone : 그 담당자의 연락처. 숫자와 하이픈만',
  '- code : 발주번호 · 오더번호 · 관리번호',
  '- qty : 수량. "부수 · 수량 · 매수 · EA". 숫자만 (쉼표 빼고)',
  '- unit : 단위. 부 · 권 · 매 · 세트 중 하나. 안 적혀 있으면 "부"',
  '- size : 완성 규격. "판형 · 규격 · 내지규격 · 사이즈". 예 "250*175"',
  '         ※ 인쇄용지 전지 규격(788*1090, 880*625 같은 것)은 size 가 아닙니다.',
  '- pages : 면수. "페이지 · 면수 · 쪽 · 내지구성". 숫자만.',
  '          "면지 2P + 본문 208P + 면지 2P" 처럼 나뉘어 있으면 모두 더한 값(212)',
  '- color : 도수. "4도 · 1도 · 4도 양면 · 표지 4도 / 내지 1도"',
  '- paperCover : 표지(커버) 용지. 예 "스노우지 200g"',
  '- paperInner : 내지(본문) 용지. 예 "아르떼고백 210g"',
  '                ※ 종이 이름과 평량만 적습니다. 옆에 붙은 "5*7 · 4*6 · 국전 · 788*1091 · 545*788" 은',
  '                  전지 규격이나 절수라서 용지 이름이 아닙니다. 빼고 적으세요.',
  '                ※ 표지·내지 구분이 없으면 하나만 채우고 나머지는 빈 문자열',
  '                ※ 면지(전후면지)는 표지가 아닙니다. paperCover 에 넣지 말고 options 에 "면지" 로 적으세요.',
  '- bind : 제본 방식. 스프링(트윈링/링) · 무선 · 중철 · 사철 · 양장 중 보이는 것.',
  '         ※ 근거는 작업 지시 칸(제책방식 · 제본방식 · 작업순서 · 후가공)뿐입니다.',
  '            제품 이름에 든 "링"(예: "링 단어장", "스프링다이어리")은 근거가 아닙니다.',
  '            이름에는 링이 있는데 우리에게 시킨 일이 "재단+타공" 뿐이면 타공입니다.',
  '         ※ "링 · 스프링 · 트윈링 · 와이어 · 몇 코" 가 지시 칸에 있으면 스프링제본입니다.',
  '         ※ 구멍만 뚫는 일(타공 · 육공 · 6공 · 3공)은 스프링제본이 아닙니다.',
  '            링을 끼운다는 말이 없으면 "6공 타공" 처럼 타공이라고만 적으세요.',
  '         ※ 제본 업체가 여러 줄이면(1차 제책사 따로, 스프링 업체 따로)',
  '            "BKT · 비케이티 · bkt" 라고 적힌 줄의 지시만 봅니다. 다른 줄은 남의 일입니다.',
  '- finish : 후가공. 코팅 · 라미네이팅 · 박 · 귀도리 · 삼각대 · 바니쉬 · 톰슨 등. 여러 개면 " · " 로 이어서',
  '- dueOn : 납품일. "납품 · 납기 · 입고예정 · 출고일". YYYY-MM-DD.',
  '          ※ 발주일 · 발주일자 · 인쇄완료일은 납품일이 아닙니다.',
  '          ※ 연도까지 분명할 때만 넣습니다. 연도가 안 적혀 있으면 비우세요 —',
  '             다음 해 것을 만드는 달력·다이어리는 그 해 연말에 납품하는 일이 많아',
  '             발주일 연도를 그대로 쓰면 한 해가 어긋납니다.',
  '          ※ 납품일이 아예 안 적힌 의뢰서가 많습니다. 비우고 uncertain 에 적으세요.',
  '             발주일을 대신 넣지 마세요.',
  '- options : 그 밖에 적힌 지시. [{"label":"칸 이름","value":"내용"}] 형태.',
  '            예 링 색상 · 코수 · 삼각대 · 면지 · 제지사 · 여분 · 포장 방법',
  '            ※ "X · x · 무 · 없음" 으로 표시된 칸은 없다는 뜻입니다. 넣지 마세요.',
  '               (날개 X · 띠지 X · 귀따기 없음 → options 에 안 들어갑니다)',
  '            ※ 빈 칸도 넣지 마세요.',
  '- memo : 특이사항 · 비고에 손으로 적힌 말',
  '- uncertain : 비워 둔 항목의 이름들. 예 ["client","dueOn"]',
  '',
  '규칙',
  '1. 확실한 것만 넣습니다. 절대 지어내지 마세요.',
  '2. **애매하면 넣지 말고 비웁니다.** 빈 문자열(숫자는 0)로 두고',
  '   uncertain 에 그 이름을 적으세요. 사람이 보고 직접 넣습니다.',
  '   애매하다는 것은 이런 경우입니다 —',
  '     · 글씨가 흐리거나 잘려서 확실히 못 읽겠다',
  '     · 비슷한 칸이 둘인데 어느 쪽인지 모르겠다 (발주처와 거래처, 발주일과 납품일)',
  '     · 적혀 있긴 한데 그 뜻이 우리가 찾는 항목이 맞는지 자신이 없다',
  '   반쯤 맞는 값을 넣는 것보다 비워 두는 편이 낫습니다. 값이 들어가 있으면',
  '   사람이 맞는 줄 알고 그냥 넘기지만, 비어 있으면 반드시 보게 됩니다.',
  '3. 다만 "안 적혀 있는 것" 과 "애매한 것" 은 다릅니다. 아예 안 적힌 항목은',
  '   그냥 비우고 uncertain 에 넣지 않아도 됩니다. 넣어도 상관없습니다.',
  '4. 오직 JSON 하나만 출력하고 다른 말은 쓰지 마세요.',
  '',
  '{"name":"","client":"","person":"","phone":"","code":"","qty":0,"unit":"부","size":"",',
  ' "pages":0,"color":"","paperCover":"","paperInner":"","bind":"","finish":"","dueOn":"",',
  ' "options":[],"memo":"","uncertain":[]}',
].join('\n');

Deno.serve(async (req) => {
  const { cors, json } = mkJson(req);
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors });
  if (req.method !== 'POST') return json({ ok: false, error: 'POST 만 받습니다.' }, 405);
  if (!ANTHROPIC_KEY) return json({ ok: false, error: '서버에 API 키가 설정되지 않았습니다.' }, 500);

  let body: Record<string, unknown>;
  try { body = await req.json() } catch { return json({ ok: false, error: '잘못된 요청입니다.' }, 400) }

  // ── 로그인 확인 ──
  const auth = req.headers.get('Authorization') ?? '';
  if (!auth.startsWith('Bearer ')) return json({ ok: false, error: '로그인이 필요합니다.' }, 401);
  const anon = createClient(URL_, ANON, {
    global: { headers: { Authorization: auth } }, auth: { persistSession: false },
  });
  const { data: udata } = await anon.auth.getUser();
  if (!udata?.user) return json({ ok: false, error: '로그인이 만료되었습니다.' }, 401);

  const { data: prof } = await admin.from('profiles')
    .select('id, company_id, disabled').eq('id', udata.user.id).single();
  if (!prof || prof.disabled) return json({ ok: false, error: '사용할 수 없는 계정입니다.' }, 403);

  // ── 하루 한도 ── (키가 새어도 피해가 한정되도록)
  const since = new Date(Date.now() - 86400000).toISOString();
  const { count } = await admin.from('audit_log')
    .select('id', { count: 'exact', head: true })
    .eq('actor_id', prof.id).eq('action', 'order.read').gte('at', since);
  if ((count ?? 0) >= DAILY_LIMIT) {
    return json({ ok: false, error: '오늘 인식 한도를 넘었습니다. 직접 입력해 주세요.' }, 429);
  }

  const b64 = String(body.image ?? '');
  if (!b64) return json({ ok: false, error: '사진이 없습니다.' }, 400);
  if (b64.length * 0.75 > MAX_BYTES) return json({ ok: false, error: '사진이 너무 큽니다.' }, 413);

  let res: Response;
  try {
    res = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        'x-api-key': ANTHROPIC_KEY,
        'anthropic-version': '2023-06-01',
      },
      body: JSON.stringify({
        model: MODEL,
        max_tokens: 1500,
        messages: [{
          role: 'user',
          content: [
            { type: 'image', source: { type: 'base64', media_type: 'image/jpeg', data: b64 } },
            { type: 'text', text: PROMPT },
          ],
        }],
      }),
    });
  } catch {
    return json({ ok: false, error: '인식 서버에 닿지 못했습니다.' }, 502);
  }
  if (!res.ok) {
    console.error('anthropic error', res.status, (await res.text()).slice(0, 300));
    if (res.status === 401 || res.status === 403) {
      return json({ ok: false, error: '서버의 API 키가 올바르지 않습니다. 관리자에게 알려 주세요.' }, 502);
    }
    if (res.status === 429) return json({ ok: false, error: '요청이 몰렸습니다. 잠시 뒤 다시 시도해 주세요.' }, 502);
    return json({ ok: false, error: '인식에 실패했습니다 (' + res.status + ')' }, 502);
  }

  const data = await res.json();
  const txt = (data.content ?? []).map((c: { text?: string }) => c.text ?? '').join('')
    .replace(/```json|```/g, '').trim();

  let p: Record<string, unknown>;
  try {
    p = JSON.parse(txt.slice(txt.indexOf('{'), txt.lastIndexOf('}') + 1));
  } catch {
    return json({ ok: false, error: '표를 읽지 못했습니다. 더 밝은 곳에서 반듯하게 다시 찍어 주세요.' }, 200);
  }

  const str = (k: string, n = 200) => String(p[k] ?? '').trim().slice(0, n);
  const int = (k: string) => {
    const v = Number(String(p[k] ?? '').replace(/[^0-9]/g, ''));
    return Number.isFinite(v) ? Math.min(v, 99999999) : 0;
  };
  const opts = Array.isArray(p.options) ? (p.options as Record<string, string>[])
    .filter((o) => o && (o.label || o.value)).slice(0, 12)
    .map((o) => ({ label: String(o.label ?? '').slice(0, 40), value: String(o.value ?? '').slice(0, 80) })) : [];
  const uncertain = Array.isArray(p.uncertain)
    ? (p.uncertain as string[]).map((x) => String(x).slice(0, 24)).slice(0, 20) : [];

  const iso = str('dueOn', 10);
  const out = {
    name: str('name', 120), client: str('client', 80), person: str('person', 40),
    phone: str('phone', 30).replace(/[^0-9+\-() ]/g, ''),
    code: str('code', 40),
    qty: int('qty'), unit: str('unit', 10) || '부',
    size: str('size', 60), pages: int('pages'),
    color: str('color', 60), paperCover: str('paperCover', 80), paperInner: str('paperInner', 80),
    bind: str('bind', 60), finish: str('finish', 160),
    dueOn: /^\d{4}-\d{2}-\d{2}$/.test(iso) ? iso : '',
    options: opts, memo: str('memo', 400),
  };

  // 무엇을 읽었는지는 남기지 않습니다. 부른 사실만 기록합니다.
  await admin.from('audit_log').insert({
    company_id: prof.company_id, actor_id: prof.id,
    action: 'order.read', target: null, detail: { model: MODEL },
  });

  return json({ ok: true, order: out, uncertain });
});
