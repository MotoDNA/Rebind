-- ═══════════════════════════════════════════════════════════════
-- Re:Bind — 거래처 즐겨찾기
--
-- 사람마다 자주 붙는 거래처가 다릅니다. 그래서 회사가 아니라
-- 사람 단위로 둡니다. 내가 별을 단 것은 나만 보이고, 기기를 바꿔도
-- 따라옵니다(기기에 두면 폰을 바꿀 때 사라집니다).
--
-- 거래처를 따로 표로 만들지 않고 이름만 담습니다.
-- 프로젝트의 client_company 가 이미 이름이라, 표를 하나 더 만들면
-- 둘을 맞춰 두는 일이 새로 생깁니다.
-- ═══════════════════════════════════════════════════════════════

create table if not exists public.client_favorites (
  company_id uuid not null references public.companies(id) on delete cascade,
  user_id    uuid not null references public.profiles(id)  on delete cascade,
  client     text not null,
  created_at timestamptz not null default now(),
  primary key (company_id, user_id, client),
  constraint client_favorites_name_chk check (length(btrim(client)) > 0)
);

alter table public.client_favorites enable row level security;
alter table public.client_favorites force row level security;

-- 내 것만 보고, 내 것만 답니다
do $$
begin
  create policy fav_read on public.client_favorites
    for select to authenticated
    using (company_id = public.current_company_id() and user_id = auth.uid());
exception when duplicate_object then null; end $$;

do $$
begin
  create policy fav_insert on public.client_favorites
    for insert to authenticated
    with check (company_id = public.current_company_id() and user_id = auth.uid());
exception when duplicate_object then null; end $$;

do $$
begin
  create policy fav_delete on public.client_favorites
    for delete to authenticated
    using (company_id = public.current_company_id() and user_id = auth.uid());
exception when duplicate_object then null; end $$;

grant select, insert, delete on public.client_favorites to authenticated;
grant all privileges       on public.client_favorites to service_role;
