-- ═══════════════════════════════════════════════════════════════
-- 원가 내역 — 부당 단가를 어떻게 뽑았는지
--
-- 턴키로 받은 주문은 표지 수량·단가, 내지 수량·단가, 인쇄비, 재단비,
-- 제본비를 따로 셈해 총비용을 내고, 그것을 전체 부수로 나눠 부당 단가를
-- 냅니다. 고객에게 나가는 견적서에는 **부당 단가만** 적히고, 어떻게 나온
-- 값인지는 제작사만 봅니다.
--
-- 그래서 이 칸은 project_money 에 둡니다. 그 표는 관리자만 읽고 쓰며,
-- 0014 의 창이 금액 잠금 설정에 따라 가려 줍니다.
--
-- ⚠ 고객사 공개 링크(share-view)는 이 칸을 절대 고르지 않습니다.
--   함수가 칸 이름을 하나씩 적어 꺼내므로, 여기에 더한다고 저절로
--   나가지는 않습니다. 앞으로도 그 목록에 넣지 마세요.
--
-- 모양: [{"n":"표지 인쇄","q":2000,"p":180,"u":"부"}, …]
--   n 항목 이름 · q 수량 · p 단가 · u 단위
--   금액은 q × p 로 그때그때 셈합니다. 따로 담아 두면 두 값이 어긋납니다.
-- ═══════════════════════════════════════════════════════════════
alter table public.project_money
  add column if not exists cost_items jsonb not null default '[]'::jsonb;

comment on column public.project_money.cost_items is
  '원가 내역 [{n,q,p,u}]. 부당 단가를 어떻게 뽑았는지. 제작사만 봅니다.';

-- 금액을 가려 주는 창에도 같은 기준으로 얹습니다.
-- 금액이 잠긴 직원에게는 빈 목록으로 나갑니다.
drop view if exists public.project_money_v;
create view public.project_money_v
with (security_barrier = true) as
select
  m.project_id,
  m.company_id,
  case when public.is_admin() or coalesce(s.staff_money,false)
       then m.unit_price  else 0 end                    as unit_price,
  case when public.is_admin() or coalesce(s.staff_money,false)
       then m.vat_rate    else 10 end                   as vat_rate,
  case when public.is_admin() or coalesce(s.staff_money,false)
       then m.extra_items else '[]'::jsonb end          as extra_items,
  case when public.is_admin() or coalesce(s.staff_money,false)
       then m.cost_items  else '[]'::jsonb end          as cost_items,
  case when public.is_admin() or coalesce(s.staff_settle,false)
       then m.billed_on   else null end                 as billed_on,
  case when public.is_admin() or coalesce(s.staff_settle,false)
       then m.taxed_on    else null end                 as taxed_on,
  case when public.is_admin() or coalesce(s.staff_settle,false)
       then m.paid_on     else null end                 as paid_on,
  case when public.is_admin() or coalesce(s.staff_memo,false)
       then m.memo        else '' end                   as memo,
  m.updated_at
from public.project_money m
join public.projects p on p.id = m.project_id
left join public.company_settings s on s.company_id = m.company_id
where m.company_id = public.current_company_id()
  and (public.is_admin() or coalesce(p.kind,'project') <> 'quote');

grant select on public.project_money_v to authenticated;
grant select on public.project_money_v to service_role;
