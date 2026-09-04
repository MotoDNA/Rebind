#!/usr/bin/env bash
# 작업의뢰서 스캔이 어떻게 되고 있는지 봅니다.
#
#   bash scan-log.sh          최근 30건
#   bash scan-log.sh BKT      그 회사만
#
# 2026-09-02 부터 실패도 기록합니다. 그 전 것은 성공만 있습니다.
set -euo pipefail
cd "$(dirname "$0")"
WHO="${1:-}"
COND=""
[ -n "$WHO" ] && COND="and c.code = '$(echo "$WHO" | tr '[:lower:]' '[:upper:]')'"
supabase db query --linked "
select to_char(l.at at time zone 'Asia/Seoul','MM-DD HH24:MI') as 언제,
       coalesce(c.code,'—') as 회사,
       coalesce(p.login_id,'—') as 누가,
       case when l.action='order.read' then '성공' else '실패' end as 결과,
       coalesce(l.target,'') as 사유,
       coalesce(l.detail::text,'') as 자세히
  from audit_log l
  left join companies c on c.id = l.company_id
  left join profiles  p on p.id = l.actor_id
 where l.action like 'order.read%' $COND
 order by l.at desc limit 30" 2>/dev/null | python3 -c "
import sys,json,re
m=re.search(r'\"rows\":\s*(\[.*?\])\s*,\s*\"warning\"', sys.stdin.read(), re.S)
rows=json.loads(m.group(1)) if m else []
if not rows: print('  기록이 없습니다.'); raise SystemExit
print('  %-12s %-8s %-9s %-5s %-14s %s' % ('언제','회사','누가','결과','사유','자세히'))
print('  '+'─'*96)
for r in rows:
    print('  %-12s %-8s %-9s %-5s %-14s %s' % (r['언제'],r['회사'],r['누가'],r['결과'],r['사유'],r['자세히'][:44]))
"
