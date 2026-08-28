-- ═══════════════════════════════════════════════════════════════
-- 무엇을 직원에게 보일지 관리자가 고릅니다
--
-- 0009 에서 금액·정산일·내부메모를 project_money 로 빼고 관리자만 읽게
-- 막았습니다. 그런데 회사마다 사정이 다릅니다 — 정산 상태는 직원도
-- 봐야 일이 도는 곳이 있고, 금액까지 다 열어 두는 곳도 있습니다.
--
-- 그래서 세 가지를 따로 켜고 끕니다. 기본은 지금과 같은 "다 잠금" 입니다.
--
-- 어떻게 막나
--   줄 단위 규칙(RLS)으로는 칸을 가릴 수 없습니다. 한 줄을 보여 주면
--   그 줄의 모든 칸이 나갑니다. 그래서 **칸을 가려 주는 창(view)** 을
--   따로 둡니다.
--     · project_money   원본 표. 여전히 관리자만 읽고 씁니다
--     · project_money_v 창. 회사 설정을 보고 칸마다 가립니다
--   앱은 창을 읽고, 쓰기는 원본에 합니다(관리자만).
--   창의 주인은 postgres 라 원본의 규칙을 지나칠 수 있습니다.
--   대신 창 안에서 회사를 반드시 걸러 다른 회사 것은 절대 안 나갑니다.
--
-- 화면에서 가리는 것이 아닙니다. 꺼 두면 개발자 도구로 직접 불러도
-- 0 과 빈칸만 돌아옵니다.
-- ═══════════════════════════════════════════════════════════════

alter table public.company_settings
  add column if not exists staff_money  boolean not null default false,
  add column if not exists staff_settle boolean not null default false,
  add column if not exists staff_memo   boolean not null default false;

comment on column public.company_settings.staff_money  is '직원도 금액(단가·추가품목)을 봅니다';
comment on column public.company_settings.staff_settle is '직원도 정산(청구·세금계산서·수금)을 봅니다';
comment on column public.company_settings.staff_memo   is '직원도 내부 메모를 봅니다';

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
-- 아래 두 줄이 격리를 맡습니다. 빼면 남의 회사 금액이나
-- 내가 못 보는 프로젝트의 금액이 나갑니다.
where m.company_id = public.current_company_id()
  and (public.is_admin() or p.owner_id = auth.uid() or auth.uid() = any(p.shared_ids));

grant select on public.project_money_v to authenticated;
grant select on public.project_money_v to service_role;
