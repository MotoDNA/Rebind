-- ═══════════════════════════════════════════════════════════════
-- projects 표에서 옛 금액 칸을 지웁니다
--
-- 0009 에서 project_money 로 옮겨 두었습니다. 옮기기만 하고 옛 칸을
-- 남겨 두면 아무것도 막은 것이 아닙니다 — 직원은 여전히 그 칸을 읽습니다.
-- 그래서 여기서 지웁니다.
--
-- 순서가 중요합니다. 이 파일을 돌리기 전에
--   1) share-view 를 새로 배포하고 (옛 함수는 projects.unit_price 를 읽습니다)
--   2) 앱(bindery.html)을 올려 두어야 합니다
-- 둘 다 2026-08-28 에 끝냈습니다.
--
-- 되돌릴 수 없습니다. 옮긴 값이 project_money 에 다 있는지 먼저 셉니다.
-- 옛 값은 projects_money_backup_20260828 표에도 떠 두었습니다.
-- ═══════════════════════════════════════════════════════════════
do $$
declare 안옮긴것 int;
begin
  select count(*) into 안옮긴것
    from public.projects p
    left join public.project_money m on m.project_id = p.id
   where m.project_id is null;
  if 안옮긴것 > 0 then
    raise exception '금액 줄이 없는 프로젝트가 % 건 있습니다. 0009 를 먼저 돌리세요.', 안옮긴것;
  end if;
end $$;

alter table public.projects
  drop column if exists unit_price,
  drop column if exists vat_rate,
  drop column if exists extra_items,
  drop column if exists billed_on,
  drop column if exists taxed_on,
  drop column if exists paid_on,
  drop column if exists memo;
