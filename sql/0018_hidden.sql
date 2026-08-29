-- ═══════════════════════════════════════════════════════════════
-- 숨기기 — 접수는 했는데 미뤄진 건
--
-- 고객사가 "잠깐 미뤄 달라" 고 하는 일이 있습니다. 지우면 안 되고,
-- 그렇다고 목록 맨 위에 계속 두면 오늘 할 일이 안 보입니다.
-- 보류(status='hold')와는 다릅니다 — 보류는 목록에 남아 있습니다.
-- 숨기면 목록 · 칩 · 현황 · 미수금에서 모두 빠지고, "숨김" 칸에만 남습니다.
--
-- 체크(true/false)가 아니라 날짜로 둡니다. 정산 세 단계와 같은 판단입니다 —
-- 체크만 해 두면 며칠째 묵고 있는지 셀 수가 없습니다.
-- 비어 있으면 안 숨긴 것입니다. 지금 있는 줄은 전부 비어 있으니
-- 지금까지와 똑같이 보입니다.
--
-- deleted 와 따로 두는 이유
--   지운 것은 서버가 아예 안 내려 줍니다(pull 에서 deleted=false 로 거릅니다).
--   숨긴 것은 내려받아 두었다가 "숨김" 을 누르면 그 자리에서 보여 줘야 합니다.
--   같은 칸에 담으면 되돌릴 목록을 볼 방법이 없어집니다.
-- ═══════════════════════════════════════════════════════════════
alter table public.projects
  add column if not exists hidden_on date;

comment on column public.projects.hidden_on is
  '목록에서 숨긴 날. 비면 안 숨긴 것입니다. 지운 것(deleted)과 다릅니다.';

-- 목록을 그릴 때마다 숨긴 것을 걸러 냅니다. 회사 안에서만 보므로
-- company_id 와 함께 묶어 둡니다.
create index if not exists projects_hidden_idx
  on public.projects (company_id, hidden_on)
  where deleted = false;
