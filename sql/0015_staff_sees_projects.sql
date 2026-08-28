-- ═══════════════════════════════════════════════════════════════
-- 회사 사람은 회사 프로젝트를 다 봅니다
--
-- 규칙을 Re:Call 의 고객 규칙에서 그대로 본떠 왔습니다. 거기서는
-- 영업 담당이 자기 고객만 보는 것이 맞습니다 — 내 고객과 남의 고객이
-- 나뉘니까요.
--
-- 제본소는 다릅니다. 공장에 올라온 일은 그날 손이 비는 사람이 잡습니다.
-- 그런데 "담당이거나 공유받았거나" 로 걸려 있었고, Re:Bind 에는
-- **담당자를 지정하는 기능이 아예 없습니다.** shared_ids 는 늘 비어
-- 있어서, 직원 계정을 만들어도 목록이 영영 비어 있었습니다.
--
-- 그래서 프로젝트는 회사 사람이면 다 봅니다.
--
-- 무엇이 그대로 잠겨 있나 (푸는 것이 아닙니다)
--   · 견적서(kind='quote')  — 금액이 본체라 관리자만
--   · 금액 · 정산 · 내부메모 — 0014 의 창이 그대로 가립니다
--   · 지우기               — 관리자만
--   · 다른 회사            — 회사 격리는 그대로입니다
--
-- 고치는 것도 함께 엽니다. 공정을 적고 자재 입고를 켜는 일은 현장 일이라
-- 직원이 해야 합니다.
-- ═══════════════════════════════════════════════════════════════
drop policy if exists projects_read on public.projects;
create policy projects_read on public.projects
  for select to authenticated
  using (
    company_id = public.current_company_id()
    and (public.is_admin() or coalesce(kind,'project') <> 'quote')
  );

drop policy if exists projects_update on public.projects;
create policy projects_update on public.projects
  for update to authenticated
  using (
    company_id = public.current_company_id()
    and (public.is_admin() or coalesce(kind,'project') <> 'quote')
  )
  with check (
    company_id = public.current_company_id()
    and exists (select 1 from public.profiles p
                 where p.id = owner_id and p.company_id = public.current_company_id())
  );

-- 금액을 가려 주는 창도 같은 기준으로 맞춥니다.
-- 안 맞추면 프로젝트는 보이는데 그 줄의 금액만 안 보이는, 설명하기
-- 어려운 상태가 됩니다.
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
-- 이 두 줄이 격리를 맡습니다. 회사가 다르거나, 직원이 볼 수 없는
-- 견적서면 아예 나오지 않습니다.
where m.company_id = public.current_company_id()
  and (public.is_admin() or coalesce(p.kind,'project') <> 'quote');

grant select on public.project_money_v to authenticated;
grant select on public.project_money_v to service_role;
