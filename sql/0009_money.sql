-- ═══════════════════════════════════════════════════════════════
-- 금액을 딴 표로 뺍니다 — 화면에서 가리는 것을 진짜로 막습니다
--
-- 지금까지 금액·내부메모·정산일은 projects 표 안에 있었습니다.
-- 화면에서는 직원에게 안 보였지만, 데이터베이스는 회사 사람 모두에게
-- 그 칸을 내려 주고 있었습니다. 개발자 도구를 열 줄 아는 직원이라면
-- 볼 수 있었고, 고쳐 쓸 수도 있었습니다.
--
-- 왜 "칸 단위 권한"이 아니라 "표를 나누기" 인가
--   Postgres 는 칸 단위로 권한을 줄 수 있지만, 그 단위가 '역할'입니다.
--   여기서는 로그인한 사람이 관리자든 직원이든 모두 같은 역할
--   (authenticated) 이라 칸으로는 가를 수가 없습니다. 관리자냐 아니냐는
--   줄 단위 규칙(is_admin())으로만 물을 수 있고, 줄 단위 규칙은
--   표에만 걸립니다. 그래서 표를 나눕니다.
--   덤으로 select * 가 그대로 동작합니다 — 칸 권한을 뺐으면
--   직원의 select * 자체가 통째로 막혔을 것입니다.
-- ═══════════════════════════════════════════════════════════════

create table if not exists public.project_money (
  project_id  uuid primary key references public.projects(id) on delete cascade,
  company_id  uuid not null references public.companies(id) on delete restrict,

  unit_price  numeric(14,2) not null default 0,
  vat_rate    numeric(5,2)  not null default 10,
  extra_items jsonb not null default '[]'::jsonb,   -- [{name,spec,qty,price}]

  -- 정산 세 단계. 날짜로 둡니다 (체크만 하면 며칠째인지 못 셉니다)
  billed_on   date,
  taxed_on    date,
  paid_on     date,

  memo        text not null default '',             -- 내부 메모

  updated_at  timestamptz not null default now()
);
create index if not exists money_company_idx on public.project_money(company_id);
create index if not exists money_unpaid_idx  on public.project_money(company_id, billed_on)
  where paid_on is null;

drop trigger if exists money_touch on public.project_money;
create trigger money_touch before update on public.project_money
  for each row execute function public.touch_updated_at();

-- ───────────────── 있던 값을 옮깁니다 ─────────────────
-- 0 원짜리 빈 줄까지 다 옮깁니다. 관리자가 나중에 금액을 넣을 때
-- 줄이 있느냐 없느냐를 앱이 따지지 않아도 되게 하려고요.
insert into public.project_money
  (project_id, company_id, unit_price, vat_rate, extra_items,
   billed_on, taxed_on, paid_on, memo)
select p.id, p.company_id,
       coalesce(p.unit_price,0), coalesce(p.vat_rate,10), coalesce(p.extra_items,'[]'::jsonb),
       p.billed_on, p.taxed_on, p.paid_on, coalesce(p.memo,'')
from public.projects p
on conflict (project_id) do nothing;

-- ═══════════════════════════════════════════════════════════════
-- 접근 규칙 — 관리자만. 읽기도 쓰기도.
-- ═══════════════════════════════════════════════════════════════
alter table public.project_money enable row level security;
alter table public.project_money force  row level security;

drop policy if exists money_read   on public.project_money;
drop policy if exists money_insert on public.project_money;
drop policy if exists money_update on public.project_money;
drop policy if exists money_delete on public.project_money;

create policy money_read on public.project_money
  for select to authenticated
  using (company_id = public.current_company_id() and public.is_admin());

create policy money_insert on public.project_money
  for insert to authenticated
  with check (
    company_id = public.current_company_id() and public.is_admin()
    and exists (select 1 from public.projects p
                 where p.id = project_id and p.company_id = public.current_company_id())
  );

create policy money_update on public.project_money
  for update to authenticated
  using  (company_id = public.current_company_id() and public.is_admin())
  with check (company_id = public.current_company_id() and public.is_admin());

create policy money_delete on public.project_money
  for delete to authenticated
  using (company_id = public.current_company_id() and public.is_admin());

grant select, insert, update, delete on public.project_money to authenticated;
grant all privileges                 on public.project_money to service_role;

-- ───────────────── 견적서도 관리자만 ─────────────────
-- 견적서는 금액이 본체입니다. 금액을 뺀 견적서 줄을 직원에게 보여 줄 이유가
-- 없어서 줄 자체를 감춥니다.
drop policy if exists projects_read on public.projects;
create policy projects_read on public.projects
  for select to authenticated
  using (
    company_id = public.current_company_id()
    and (public.is_admin() or owner_id = auth.uid() or auth.uid() = any(shared_ids))
    and (public.is_admin() or coalesce(kind,'project') <> 'quote')
  );
