-- ═══════════════════════════════════════════════════════════════
-- Re:Bind — 견적서 · 용지 분리
--
-- 표를 새로 만들지 않고 projects 에 칸만 더합니다.
-- 견적서와 프로젝트는 담는 내용이 거의 같습니다. 표를 나누면
-- "견적서를 프로젝트로 옮기기"가 표 사이를 건너다니는 일이 되고,
-- 명세서·청구서를 그리는 코드도 두 벌이 됩니다.
-- 그래서 kind 한 칸으로 가릅니다.
-- ═══════════════════════════════════════════════════════════════

alter table public.projects
  add column if not exists kind             text not null default 'project',
  add column if not exists spec_paper_cover text not null default '',
  add column if not exists spec_paper_inner text not null default '',
  -- 어느 견적서에서 옮겨 온 것인지. 나중에 "이 건은 얼마에 견적 냈었지" 를 찾을 때 씁니다.
  add column if not exists quote_of         uuid references public.projects(id) on delete set null;

do $$
begin
  alter table public.projects add constraint projects_kind_chk check (kind in ('project','quote'));
exception when duplicate_object then null;
end $$;

-- 목록은 늘 둘 중 하나만 봅니다. 섞어 보는 화면이 없어 이렇게 나눠 둡니다.
create index if not exists projects_kind_idx on public.projects(company_id, kind) where not deleted;

-- 지금까지 만든 것은 모두 프로젝트입니다 (기본값이 이미 그렇습니다)
update public.projects set kind = 'project' where kind is null;
