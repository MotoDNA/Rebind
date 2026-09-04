#!/usr/bin/env bash
# 작업의뢰서 스캔이 어떻게 되고 있는지 봅니다.
#
#   bash scan-log.sh          최근 30건
#   bash scan-log.sh BKT      그 회사만
#
# 2026-09-04 부터 **실패도** 기록합니다. 그 전 것은 성공만 있습니다.
#
# ⚠ 처음 만들 때 오류를 2>/dev/null 로 감췄더니, 물어보기가 실패했는데도
#   "기록이 없습니다" 라고 말했습니다. 없는 것과 못 물어본 것은 다릅니다 —
#   앞의 것은 "아직 안 써 봤다", 뒤의 것은 "여기 말고 딴 데를 봐야 한다" 입니다.
#   그래서 지금은 감추지 않고, 실패하면 실패했다고 합니다.
set -uo pipefail
cd "$(dirname "$0")"

WHO="${1:-}"
COND=""
if [ -n "$WHO" ]; then
  WHO="$(echo "$WHO" | tr '[:lower:]' '[:upper:]')"
  # SQL 문장에 그대로 끼워 넣으니 회사 코드 모양이 아니면 아예 진행하지 않습니다
  if ! echo "$WHO" | grep -qE '^[A-Z0-9]{2,12}$'; then
    echo "  ‼ 회사 코드는 영문 대문자와 숫자입니다: $WHO"; exit 1
  fi
  COND="and c.code = '$WHO'"
fi

OUT="$(supabase db query --linked "
select to_char(l.at at time zone 'Asia/Seoul','MM-DD HH24:MI') as when_,
       coalesce(c.code,'-')     as co,
       coalesce(p.login_id,'-') as who,
       case when l.action='order.read' then 'OK' else 'FAIL' end as res,
       coalesce(l.target,'')       as why,
       coalesce(l.detail::text,'') as detail
  from audit_log l
  left join companies c on c.id = l.company_id
  left join profiles  p on p.id = l.actor_id
 where l.action like 'order.read%' $COND
 order by l.at desc limit 30" 2>&1)"

# 물어보기 자체가 실패했으면 그렇다고 말합니다
if ! printf '%s' "$OUT" | grep -q '"rows"'; then
  echo "  ‼ 기록을 물어보지 못했습니다. 아래가 그 이유입니다 —"
  printf '%s\n' "$OUT" | grep -viE '^\s*$|A new version|We recommend' | head -6 | sed 's/^/     /'
  echo
  echo "     인터넷이나 supabase 로그인 문제일 때가 많습니다. 잠시 뒤 다시 해 보세요."
  exit 1
fi

printf '%s' "$OUT" | python3 -c "
import sys, json, re
m = re.search(r'\"rows\":\s*(\[.*?\])\s*,\s*\"warning\"', sys.stdin.read(), re.S)
rows = json.loads(m.group(1)) if m else []
if not rows:
    print('  스캔을 쓴 기록이 아직 없습니다.')
    print('  (실패 기록은 2026-09-04 부터 남습니다. 그 전에는 성공만 남았습니다.)')
    raise SystemExit
print('  %-12s %-8s %-9s %-5s %-14s %s' % ('언제','회사','누가','결과','사유','자세히'))
print('  ' + '─'*96)
for r in rows:
    결과 = '성공' if r['res'] == 'OK' else '실패'
    print('  %-12s %-8s %-9s %-5s %-14s %s'
          % (r['when_'], r['co'], r['who'], 결과, r['why'], r['detail'][:44]))
실패 = [r for r in rows if r['res'] != 'OK']
if 실패:
    print()
    print('  실패 %d건 — 사유별' % len(실패))
    뜻 = {'daily-limit':'하루 한도에 걸림', 'too-big':'사진이 8MB 넘음',
          'network':'인식 서버에 못 닿음', 'not-json':'사진은 갔는데 표를 못 읽음',
          'no-image':'사진이 안 실려 옴'}
    본것 = {}
    for r in 실패: 본것[r['why']] = 본것.get(r['why'], 0) + 1
    for k, v in sorted(본것.items(), key=lambda x: -x[1]):
        print('    %-14s %d번   %s' % (k, v, 뜻.get(k, 'api- 로 시작하면 인식 서버가 거절한 것입니다')))
"
