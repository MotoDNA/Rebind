-- ═══════════════════════════════════════════════════════════════
-- 어느 서비스를 산 회사인가 — Re:Bind · Re:Call
--
-- 두 앱이 한 데이터베이스, 한 계정 목록을 씁니다. 그래서 제본소 직원이
-- recall.dnalabs.kr 에 같은 아이디로 그냥 들어갔습니다. 지금은 그 회사의
-- Re:Call 자료가 비어 있어 빈 화면을 볼 뿐이지만, 팀원 목록에는 제본소
-- 사람들이 그대로 떴습니다.
--
--   apps  이 회사가 결제한 서비스. {rebind} · {recall} · {rebind,recall}
--
-- 사람(profiles)이 아니라 회사(companies)에 답니다. 구독은 회사가 합니다.
-- 한 회사 안에서 "제본 직원에게는 영업 고객을 감추기" 는 다른 이야기이고
-- 아직 안 했습니다 — 그건 사람 단위 칸이 하나 더 있어야 합니다.
--
-- 기본값을 비워 두는 이유
--   회사를 새로 열고 apps 를 안 채우면 아무도 못 들어갑니다. 반대로
--   {rebind,recall} 을 기본으로 두면 안 판 것까지 열립니다. 둘 중
--   막히는 쪽이 낫습니다 — 막히면 바로 알아채고 고칠 수 있지만,
--   열려 있는 것은 아무도 모르는 채로 굴러갑니다.
--   ⚠ 회사를 새로 만들 때 apps 를 반드시 함께 넣으세요.
--
-- 나중에 결제가 붙으면
--   Re:Call 쪽에 subscriptions 표 설계가 이미 있습니다(아직 적용 전).
--   그 표는 회사당 한 줄(company_id primary key)이라 "무엇을 샀는가" 를
--   담지 못합니다. 결제를 붙일 때 그 표를 (company_id, product) 로 넓히고,
--   결제가 성사되면 여기 apps 에 그 서비스를 더하도록 이으면 됩니다.
--   지금 apps 를 subscriptions 에서 끌어오게 만들지 않은 것은,
--   그 표가 아직 없고 설계도 Re:Call 것 하나뿐이기 때문입니다.
-- ═══════════════════════════════════════════════════════════════
alter table public.companies
  add column if not exists apps text[] not null default '{}';

comment on column public.companies.apps is
  '이 회사가 결제한 서비스 {rebind,recall}. 비면 아무 데도 못 들어갑니다.';

-- 지금 있는 두 회사 — 실제로 자료가 있는 쪽을 봅니다.
-- 아직 아무것도 안 정해진 회사(apps 가 빈 것)에만 넣습니다.
update public.companies set apps = '{rebind,recall}' where code = 'ACTIVA' and apps = '{}';
update public.companies set apps = '{rebind}'        where code = 'BKT'    and apps = '{}';

-- ───────────────── 자물쇠 ─────────────────
-- current_company_id() 를 그대로 쓰되, 산 서비스가 아니면 null 을 돌려줍니다.
-- 정책마다 `company_id = current_company_id()` 를 `company_id =
-- company_for_app('rebind')` 으로 바꾸기만 하면 됩니다.
-- null 과의 비교는 참이 되지 않으므로 그대로 닫힙니다.
--
-- 조건을 하나하나 늘려 쓰지 않고 이 함수로 감싼 이유는, 정책이 스무 개라
-- 한 군데만 빠뜨려도 그 표가 열린 채로 남기 때문입니다.
create or replace function public.company_for_app(app text)
returns uuid language sql stable security definer set search_path = public as $$
  select c.id
    from public.companies c
   where c.id = public.current_company_id()
     and app = any(c.apps)
$$;
grant execute on function public.company_for_app(text) to authenticated;

-- ═════ Re:Bind 의 표 ═════
drop policy if exists projects_read   on public.projects;
create policy projects_read on public.projects for select to authenticated
  using (company_id = public.company_for_app('rebind')
         and (public.is_admin() or coalesce(kind,'project') <> 'quote'));

drop policy if exists projects_insert on public.projects;
create policy projects_insert on public.projects for insert to authenticated
  with check (company_id = public.company_for_app('rebind')
              and (owner_id = auth.uid()
                   or (public.is_admin() and exists (
                         select 1 from public.profiles p
                          where p.id = projects.owner_id
                            and p.company_id = public.current_company_id()))));

drop policy if exists projects_update on public.projects;
create policy projects_update on public.projects for update to authenticated
  using (company_id = public.company_for_app('rebind')
         and (public.is_admin() or coalesce(kind,'project') <> 'quote'))
  with check (company_id = public.company_for_app('rebind')
              and exists (select 1 from public.profiles p
                           where p.id = projects.owner_id
                             and p.company_id = public.current_company_id()));

drop policy if exists projects_delete on public.projects;
create policy projects_delete on public.projects for delete to authenticated
  using (company_id = public.company_for_app('rebind') and public.is_admin());

drop policy if exists steps_read   on public.project_steps;
create policy steps_read on public.project_steps for select to authenticated
  using (company_id = public.company_for_app('rebind')
         and exists (select 1 from public.projects p where p.id = project_steps.project_id));

drop policy if exists steps_insert on public.project_steps;
create policy steps_insert on public.project_steps for insert to authenticated
  with check (company_id = public.company_for_app('rebind')
              and exists (select 1 from public.projects p
                           where p.id = project_steps.project_id
                             and p.company_id = public.current_company_id()));

drop policy if exists steps_update on public.project_steps;
create policy steps_update on public.project_steps for update to authenticated
  using (company_id = public.company_for_app('rebind')
         and exists (select 1 from public.projects p where p.id = project_steps.project_id))
  with check (company_id = public.company_for_app('rebind'));

drop policy if exists steps_delete on public.project_steps;
create policy steps_delete on public.project_steps for delete to authenticated
  using (company_id = public.company_for_app('rebind') and public.is_admin());

drop policy if exists money_read   on public.project_money;
create policy money_read on public.project_money for select to authenticated
  using (company_id = public.company_for_app('rebind') and public.is_admin());

drop policy if exists money_insert on public.project_money;
create policy money_insert on public.project_money for insert to authenticated
  with check (company_id = public.company_for_app('rebind') and public.is_admin()
              and exists (select 1 from public.projects p
                           where p.id = project_money.project_id
                             and p.company_id = public.current_company_id()));

drop policy if exists money_update on public.project_money;
create policy money_update on public.project_money for update to authenticated
  using (company_id = public.company_for_app('rebind') and public.is_admin())
  with check (company_id = public.company_for_app('rebind') and public.is_admin());

drop policy if exists money_delete on public.project_money;
create policy money_delete on public.project_money for delete to authenticated
  using (company_id = public.company_for_app('rebind') and public.is_admin());

drop policy if exists fav_read   on public.client_favorites;
create policy fav_read on public.client_favorites for select to authenticated
  using (company_id = public.company_for_app('rebind') and user_id = auth.uid());

drop policy if exists fav_insert on public.client_favorites;
create policy fav_insert on public.client_favorites for insert to authenticated
  with check (company_id = public.company_for_app('rebind') and user_id = auth.uid());

drop policy if exists fav_delete on public.client_favorites;
create policy fav_delete on public.client_favorites for delete to authenticated
  using (company_id = public.company_for_app('rebind') and user_id = auth.uid());

-- ═════ Re:Call 의 표 ═════
drop policy if exists customers_read   on public.customers;
create policy customers_read on public.customers for select to authenticated
  using (company_id = public.company_for_app('recall')
         and (public.is_admin() or owner_id = auth.uid() or auth.uid() = any(shared_ids)));

drop policy if exists customers_insert on public.customers;
create policy customers_insert on public.customers for insert to authenticated
  with check (company_id = public.company_for_app('recall')
              and (owner_id = auth.uid()
                   or (public.is_admin() and exists (
                         select 1 from public.profiles p
                          where p.id = customers.owner_id
                            and p.company_id = public.current_company_id()))));

drop policy if exists customers_update on public.customers;
create policy customers_update on public.customers for update to authenticated
  using (company_id = public.company_for_app('recall')
         and (public.is_admin() or owner_id = auth.uid() or auth.uid() = any(shared_ids)))
  with check (company_id = public.company_for_app('recall')
              and exists (select 1 from public.profiles p
                           where p.id = customers.owner_id
                             and p.company_id = public.current_company_id()));

drop policy if exists customers_delete on public.customers;
create policy customers_delete on public.customers for delete to authenticated
  using (company_id = public.company_for_app('recall') and public.is_admin());

drop policy if exists activities_read   on public.activities;
create policy activities_read on public.activities for select to authenticated
  using (company_id = public.company_for_app('recall')
         and exists (select 1 from public.customers c where c.id = activities.customer_id));

drop policy if exists activities_insert on public.activities;
create policy activities_insert on public.activities for insert to authenticated
  with check (company_id = public.company_for_app('recall')
              and exists (select 1 from public.customers c
                           where c.id = activities.customer_id
                             and c.company_id = public.current_company_id()));

drop policy if exists activities_update on public.activities;
create policy activities_update on public.activities for update to authenticated
  using (company_id = public.company_for_app('recall')
         and exists (select 1 from public.customers c where c.id = activities.customer_id))
  with check (company_id = public.company_for_app('recall'));

drop policy if exists activities_delete on public.activities;
create policy activities_delete on public.activities for delete to authenticated
  using (company_id = public.company_for_app('recall') and public.is_admin());
